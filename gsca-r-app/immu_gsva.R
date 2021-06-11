
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
filepath <- args[3]
apppath <- args[4]


# tableuuid <- 'ba16c786-93ca-421e-a426-7a361f4c3e7a'
# tablecol <- 'preanalysised_gsva'
# filepath <- "/home/huff/github/GSCA/gsca-r-plot/pngs/5b9339bf-b9a8-4fdb-8c7a-2fd535f841ee.png"
# apppath <- '/home/huff/github/GSCA'

# Mongo -------------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsva_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_immu"), url = gsca_conf)

# Function ----------------------------------------------------------------


fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"uuid": "<.xx>"}', .open = '<', .close = '>')
}

fn_fetch_data <- function(.uuid) {
  pre_gsva_coll$find(query = fn_query_str(.x = .uuid), fields = '{"_id": false}')
}

fn_reorg <- function(.x) {
  
  .x %>%
    tibble::as_tibble() %>%
    tidyr::gather(key = "barcode", value = "gsva") %>%
    tidyr::separate(col = "barcode", into = c("barcode", "type"), sep = "#") %>%
    dplyr::mutate(type = factor(x = type, levels = c("tumor", "normal"))) %>%
    dplyr::mutate(sample_name = substr(barcode,1,12))->
    .xx
  .xx
}

# Process -----------------------------------------------------------------

fetched_data <- fn_fetch_data(.uuid = tableuuid)

fetched_data$gsva_score %>% 
  tibble::as_tibble() %>% 
  tidyr::gather(key = "cancertype", value = "gsva") %>% 
  dplyr::mutate(gsva = purrr::map(.x = gsva, .f = fn_reorg)) ->
  gsva_score_nest

fields <- '{"_id": false}'

fetched_immu_data <- purrr::map(.x =paste(gsva_score_nest$cancertype,"all_immune",sep="_"), .f = fn_fetch_mongo_all, pattern="_all_immune",fields = fields) %>%
  bind_rows() %>%
  dplyr::group_by(cancertype) %>%
  tidyr::nest() %>%
  dplyr::ungroup()

# stage analysis -------------------------------------------------------
gsva_score_nest %>%
  dplyr::inner_join(fetched_immu_data, by="cancertype") -> combine_data


# function to get correlation ---------------------------------------------

fn_gsva_immu_cor <- function(gsva,data){
 
  data %>%
    dplyr::filter(substr(aliquot,14,14)=="0") %>%
    dplyr::select(-barcode) -> .combined_immu
  
  gsva %>%
    dplyr::filter(type  == "tumor") %>%
    dplyr::inner_join(.combined_immu,by="sample_name") -> .combined_gsva_rppa
  
  .combined_gsva_rppa %>%
    dplyr::filter(!is.na(gsva)) %>%
    dplyr::filter(!is.na(TIL)) %>%
    dplyr::group_by(cell_type) %>%
    tidyr::nest() -> .combined_gsva_rppa_nested
  
  .combined_gsva_rppa_nested %>%
    dplyr::mutate(cor = purrr::map(data,.f=function(.x){
      broom::tidy(cor.test(.x$gsva,.x$TIL,method = "spearman"))
    })) %>%
    dplyr::select(-data) %>%
    tidyr::unnest() %>%
    dplyr::ungroup() -> .cor_res
  
  .fdr <- p.adjust(.cor_res$p.value)
  
  .cor_res %>%
    dplyr::mutate(fdr = .fdr)
}

# calculation -------------------------------------------------------------

combine_data %>%
  dplyr::mutate(res = purrr::map2(gsva,data,fn_gsva_immu_cor)) %>%
  dplyr::select(cancertype,res) %>%
  tidyr::unnest()  -> gsva_score_rppa_test_res


# Insert table ------------------------------------------------------------
insert_data <- list(uuid = tableuuid, res_table = gsva_score_rppa_test_res)
#post_gsva_coll$drop()
uuid_query <- post_gsva_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"uuid": true, "_id": false}'
)

if (nrow(uuid_query) == 0) {
  post_gsva_coll$insert(data = insert_data)
  post_gsva_coll$index(add = '{"uuid": 1}')
  message("insert data into preanalysised_gsva_immu")
}

# Plot --------------------------------------------------------------------
gsva_score_rppa_test_res %>%
  dplyr::mutate(label=ifelse(p.value<=0.05 & fdr <=0.05, "*#","")) %>%
  dplyr::mutate(label=ifelse(p.value<=0.05 & fdr >0.05, "*",label)) %>%
  dplyr::mutate(label=ifelse(p.value>0.05 & fdr <=0.05, "#",label)) -> gsva_score_rppa_test_res.label

gsva_score_rppa_test_res.label %>%
  dplyr::group_by(cancertype) %>%
  tidyr::nest() %>%
  dplyr::mutate(cancerrank = purrr::map(data,.f=function(.x){
    .x %>%
      dplyr::mutate(score = ifelse(p.value<=0.05,1,0)) %>%
      dplyr::mutate(score = ifelse(fdr <=0.05,2,score)) %>%
      dplyr::mutate(score=score*estimate) %>%
      .$score %>%
      sum()
  })) %>%
  dplyr::select(-data) %>%
  tidyr::unnest() %>%
  dplyr::arrange(cancerrank) -> cancerrank

gsva_score_rppa_test_res.label %>%
  dplyr::filter(celltype != "InfiltrationScore") %>%
  dplyr::group_by(celltype) %>%
  tidyr::nest() %>%
  dplyr::mutate(cellrank = purrr::map(data,.f=function(.x){
    .x %>%
      dplyr::mutate(score = ifelse(p.value<=0.05,1,0)) %>%
      dplyr::mutate(score = ifelse(fdr <=0.05,2,score)) %>%
      dplyr::mutate(score=score*estimate) %>%
      .$score %>%
      sum()
  })) %>%
  dplyr::select(-data) %>%
  tidyr::unnest() %>%
  dplyr::arrange(cellrank) -> cellrank

gsva_score_rppa_test_res.label$estimate %>% range() -> cor_range
min(cor_range*10) %>% floor() -> cor_min
max(cor_range*10) %>% ceiling() -> cor_max
fillbreaks <- sort(unique(c(0,round(c(cor_min,cor_max,seq(cor_min,cor_max,length.out = 5))))))/10

gsva_score_rppa_test_res.label %>%
  ggplot(aes(x=celltype,y=cancertype)) +
  geom_tile(aes(fill=estimate),color="white") +
  geom_text(aes(label=label)) +
  scale_x_discrete(limit=c("InfiltrationScore",cellrank$celltype)) +
  scale_y_discrete(limit=cancerrank$cancertype) +
  scale_fill_gradient2(
    name = "Spearman cor.", # "Methylation diff (T - N)",
    high = "red",
    mid = "white",
    low = "blue",
    limits=c(min(fillbreaks),max(fillbreaks)),
    breaks =fillbreaks
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
    axis.text = element_text(colour = "black",size = 10),
    axis.title = element_text(size = 13),
    # legend.key.size = unit(0.25, "cm"),
    legend.position = "bottom",
    plot.margin = rep(unit(0, "null"), 4),
    axis.ticks.length = unit(0, "cm"),
    # legend.text = element_text(size = 5),
    # axis.title.x = element_text(size = 6),
    # axis.title.y = element_text(size = 6),
    # legend.title = element_text(size = 6),
    panel.background = element_rect(fill = "white", color = NA),
    panel.grid = element_line(colour = "grey", linetype = "dashed"),
    panel.grid.major = element_line(
      colour = "grey",
      linetype = "dashed",
      size = 0.2
    )
  ) +
  ylab("Cancer type") +
  xlab("Immune cell type") -> plot

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size_height <- 3+length(unique(gsva_score_rppa_test_res.label$cancertype))*0.2


ggsave(filename = filepath, plot = plot, device = 'png', width = 8, height =  size_height)
pdf_name <- gsub("\\.png",".pdf", filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 8, height = size_height)

