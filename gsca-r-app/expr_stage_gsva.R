
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
filepath_box <- args[3]
filepath_trend <- args[4]
apppath <- args[5]


# tableuuid <- 'ba16c786-93ca-421e-a426-7a361f4c3e7a'
# tablecol <- 'preanalysised_gsva'
# filepath <- "/home/huff/github/GSCA/gsca-r-plot/pngs/91fec0d9-74ce-4036-b1b6-b5fdd8afa1b0.png"
# apppath <- '/home/huff/github/GSCA'

# Mongo -------------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsva_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_stage"), url = gsca_conf)

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
    dplyr::mutate(type = factor(x = type, levels = c("tumor", "normal"))) ->
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

stages_included <- tibble::tibble(stage=c("Stage I","Stage II","Stage III","Stage IV"),
                                  rank=c(1,2,3,4))
fields <- '{"cancer_types": true, "sample_name": true,"stage": true, "_id": false}'
fetched_stage_data <- purrr::map(.x = "all_stage", .f = fn_fetch_mongo, pattern="_stage",fields = fields,.key=gsva_score_nest$cancertype,.keyindex="cancer_types") %>%
  dplyr::bind_rows() %>%
  dplyr::select(-cancertype) %>%
  dplyr::rename(cancertype=cancer_types) %>%
  dplyr::mutate(stage = purrr::map(stage,.f=function(.x){
    sub1 <- gsub(pattern = "[a-cA-C1-9]$",replacement = "",.x)
    sub2 <- gsub(pattern = "[a-cA-C1-9]$",replacement = "",.x)
    return(sub2)
  })) %>%
  tidyr::unnest() %>%
  dplyr::filter(stage %in% stages_included$stage) %>%
  dplyr::group_by(cancertype) %>%
  tidyr::nest()

# stage analysis -------------------------------------------------------
gsva_score_nest %>%
  dplyr::inner_join(fetched_stage_data, by="cancertype") -> combine_data


source(file.path(apppath,"gsca-r-app/utils/fn_gsva_stage.R"))
combine_data %>%
  dplyr::mutate(sur_res = purrr::map2(gsva,data,fn_stage)) %>%
  dplyr::select(cancertype,sur_res) %>%
  tidyr::unnest() %>%
  tidyr::unnest() -> gsva_score_stage_test_res

gsva_score_stage_test_res %>%
  dplyr::mutate(mean.n = paste(signif(mean_exp,2),n,sep = "/"),
              stage = purrr::map(stage,.f=function(.x){
                gsub(" ","",.x)
              })) %>%
  tidyr::unnest(stage) %>%
  dplyr::select(-mean_exp,-n) %>%
  tidyr::spread(key="stage",value="mean.n") -> gsva_score_stage

# Insert table ------------------------------------------------------------
insert_data <- list(uuid = tableuuid, res_table = gsva_score_stage)
#post_gsva_coll$drop()
uuid_query <- post_gsva_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"uuid": true, "_id": false}'
)

if (nrow(uuid_query) == 0) {
  post_gsva_coll$insert(data = insert_data)
  post_gsva_coll$index(add = '{"uuid": 1}')
  message("insert data into preanalysised_gsva_stage")
}

# Plot boxplot--------------------------------------------------------------------

source(file.path(apppath,"gsca-r-app/utils/fn_boxplot_single_gene_in_cancer.R"))

combine_data %>% 
  dplyr::mutate(combine=purrr::map2(gsva,data,.f=function(.x,.y){
    .x %>%
      dplyr::filter(type=="tumor") %>%
      dplyr::mutate(sample_name = substr(barcode,1,12))->.gsva_t
    .y %>%
      dplyr::inner_join(.gsva_t,by="sample_name") %>%
      dplyr::distinct() 
  })) %>%
  dplyr::select(cancertype,combine) %>%
  tidyr::unnest(cols = c(combine)) %>%
  dplyr::inner_join(stages_included,by="stage")-> for_plot

color <- c("#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D", "#666666")
len_stage <- length(unique(for_plot$stage))

color_list <- for_plot %>%
  dplyr::select(stage,rank) %>%
  unique() %>%
  dplyr::arrange(rank) %>%
  dplyr::mutate(color=color[1:len_stage])

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size_width <- 4+length(unique(for_plot$cancertype))*0.5

box_plot <- box_plot_single_gene_multi_cancers(data = for_plot,aesx = "stage",aesy="gsva",facets=".~cancertype",color = "stage",color_name = "Satges",color_labels = color_list$stage,color_values = color_list$color,title = "GSVA score in selected cancer types stages", xlab = 'Stages', ylab = 'GSVA score')


ggsave(filename = filepath_box, plot = box_plot, device = 'png', width = size_width, height =  4)
pdf_name <- gsub("\\.png",".pdf", filepath_box)
ggsave(filename = pdf_name, plot = box_plot, device = 'pdf', width = size_width, height = 4)

# trend Plot --------------------------------------------------------------------
gsva_score_stage_test_res %>%
  dplyr::select(-diff_p, -diff_method,-trend_method) %>%
  dplyr::inner_join(stages_included,by="stage") %>%
  dplyr::mutate(`Trend P`=ifelse(trend_p>0.05,">0.05","<0.05")) %>%
  dplyr::mutate(stage = purrr::map(stage,.f=function(.x){
    sub3 <- gsub(pattern = "Stage ",replacement = "",.x)
    return(sub3)
  })) %>%
  tidyr::unnest(cols = c(stage)) -> for_plot_trend


for_plot_trend %>%
  dplyr::filter(!is.na(trend_score)) %>%
  .$trend_score -> statistic_value
min(statistic_value) %>% floor() -> min_trend
max(statistic_value) %>% ceiling() -> max_trend
fillbreaks_trend <- sort(unique(c(0,min_trend,max_trend)))
CPCOLS_trend <- c("#ee0e27", "grey", "#1678f3")
xlabels <- sort(unique(for_plot_trend$stage))
names(xlabels) <- sort(unique(for_plot_trend$rank))

source(file.path(apppath,"gsca-r-app/utils/fn_trend_plot.R"))
trendplot <- trend_plot(data = for_plot_trend,
                        aesx="rank",
                        aesy="mean_exp",
                        linecolor="trend_score",
                        linetype="`Trend P`",
                        facetgrid=".~cancertype",
                        xlabels=xlabels,
                        colorname="Trend",
                        color_list = CPCOLS_trend,
                        fillbreaks=fillbreaks_trend,
                        color_lables=c("Down","Equal","Up"),
                        title="GSVA score tendency in cancer type stages",
                        xlab="Stages",
                        ylab="Symbol") +
  facet_wrap(.~cancertype,scales = "free_y", nrow = 1)


# Save image --------------------------------------------------------------

ggsave(filename = filepath_trend, plot = trendplot, device = 'png', width = size_width, height =  4)
pdf_name <- gsub("\\.png",".pdf", filepath_trend)
ggsave(filename = pdf_name, plot = trendplot, device = 'pdf', width = size_width, height = 4)