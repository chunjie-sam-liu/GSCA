
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
filepath <- args[3]
apppath <- args[4]


# tableuuid <- 'e496623d-57e7-4cbb-a03c-57b7da877dd8'
# tablecol <- 'preanalysised_cnvgeneset'
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

# Process -----------------------------------------------------------------

fetched_data <- fn_fetch_data(.uuid = tableuuid)

fetched_data$cnvgeneset[[1]] %>% 
  tibble::as_tibble() %>% 
  tidyr::nest(-cancertype) -> gsva_score_nest


fetched_immu_data <- readr::read_rds(file.path("/home/huff/data/GSCA/TIL","pan33_ImmuneCellAI.rds.gz")) %>%
  dplyr::filter(cancer_types %in% gsva_score_nest$cancertype) %>%
  dplyr::rename("cancertype"="cancer_types")

# stage analysis -------------------------------------------------------
gsva_score_nest %>%
  dplyr::inner_join(fetched_immu_data, by="cancertype") -> combine_data


# function to get correlation ---------------------------------------------

fn_gsva_immu_cor <- function(genesetcnv,data){
  
  data %>%
    dplyr::filter(substr(aliquot,14,14)=="0") %>%
    dplyr::select(-barcode) %>%
    tidyr::gather(-sample_name,-aliquot,key="celltype",value="TIL") -> .combined_immu
  
  genesetcnv %>%
    dplyr::inner_join(.combined_immu,by="sample_name") -> .combined_gsva_rppa
  
  .combined_gsva_rppa %>%
    dplyr::filter(group != "Excluded") %>%
    dplyr::filter(!is.na(TIL)) %>%
    dplyr::group_by(celltype) %>%
    tidyr::nest() -> .combined_gsva_rppa_nested
  
  .combined_gsva_rppa_nested %>%
    dplyr::mutate(cor = purrr::map(data,.f=function(.x){
      if(length(unique(.x$group)) == 2){
        broom::tidy(wilcox.test(TIL~group,data=.x))
      }else if(length(unique(.x$group)) > 2){
        broom::tidy(oneway.test(TIL~group,data=.x))
      }else{
        tibble::tibble()
      }
    })) %>%
    dplyr::select(-data) %>%
    tidyr::unnest() %>%
    dplyr::ungroup() -> .cor_res
  
  .fdr <- p.adjust(.cor_res$p.value)
  
  .cor_res %>%
    dplyr::mutate(fdr = .fdr)
}

# calculation -------------------------------------------------------------
suppressWarnings(
  combine_data %>%
    dplyr::mutate(res = purrr::map2(data,ImmuneCellAI,fn_gsva_immu_cor)) %>%
    dplyr::select(cancertype,res) %>%
    tidyr::unnest()  -> gsva_score_rppa_test_res
)



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
  message("insert data into preanalysised_cnvgeneset_immu")
}

# Plot --------------------------------------------------------------------
gsva_score_rppa_test_res %>%
  dplyr::mutate(label=ifelse(p.value<=0.05 & fdr <=0.05, "*#","")) %>%
  dplyr::mutate(label=ifelse(p.value<=0.05 & fdr >0.05, "*",label)) %>%
  dplyr::mutate(label=ifelse(p.value>0.05 & fdr <=0.05, "#",label)) %>%
  dplyr::mutate(logFDR=-log10(fdr))-> gsva_score_rppa_test_res.label

gsva_score_rppa_test_res.label %>%
  dplyr::group_by(cancertype) %>%
  tidyr::nest() %>%
  dplyr::mutate(cancerrank = purrr::map(data,.f=function(.x){
    .x %>%
      dplyr::filter(!is.na(fdr)) %>%
      dplyr::mutate(score = ifelse(p.value<=0.05,1,0)) %>%
      dplyr::mutate(score = ifelse(fdr <=0.05,2,score)) %>%
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
      dplyr::filter(!is.na(fdr)) %>%
      dplyr::mutate(score = ifelse(p.value<=0.05,1,0)) %>%
      dplyr::mutate(score = ifelse(fdr <=0.05,2,score)) %>%
      .$score %>%
      sum()
  })) %>%
  dplyr::select(-data) %>%
  tidyr::unnest() %>%
  dplyr::arrange(cellrank) -> cellrank


gsva_score_rppa_test_res.label %>% dplyr::filter(!is.na(logFDR)) %>% .$logFDR %>% range() -> cor_range
min(cor_range) %>% floor() -> cor_min
max(cor_range) %>% ceiling() -> cor_max
fillbreaks <- sort(unique(c(1.3,round(c(cor_min,cor_max,seq(cor_min,cor_max,length.out = 5))))))


gsva_score_rppa_test_res.label %>%
  dplyr::filter(!is.na(fdr)) %>%
  dplyr::mutate(celltypecor=ifelse(p.value<0.05,"p<0.05","Not significant")) %>%
  dplyr::mutate(celltypecor=ifelse(fdr<0.05,"fdr<0.05",celltypecor)) %>%
  dplyr::mutate(labelcor=ifelse(celltypecor=="Not significant",NA,celltypecor)) %>%
  ggplot(aes(x=-log10(p.value),y=-log10(fdr))) +
  geom_point(aes(color=celltypecor)) +
  facet_wrap(.~cancertype, nrow=ceiling(length(unique(gsva_score_rppa_test_res.label$cancertype))/5)) +
  ggrepel::geom_text_repel(aes(label=celltype,color=labelcor)) +
  scale_color_manual(values = c("black","#d0021b","#366a70"),
                     name="Significance") +
  theme(
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
  ylab("-log10(FDR)") +
  xlab("-log10(P value)") -> plot
  
# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size_height <- ceiling(length(unique(gsva_score_rppa_test_res.label$cancertype))/5)*4


ggsave(filename = filepath, plot = plot, device = 'png', width = 8, height =  size_height)
pdf_name <- gsub("\\.png",".pdf", filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 8, height = size_height)

