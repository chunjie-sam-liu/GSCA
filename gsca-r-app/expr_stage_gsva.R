
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


# tableuuid <- 'de6a6b34-4be7-439c-bf90-e25d35849400'
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

stages_included <- tibble::tibble(stage=c("Stage I","Stage II","Stage III","Stage IV","intermediate","poor","good"),
                                  rank=c(1,2,3,4,2,3,1))
fields <- '{"cancer_types": true, "sample_name": true,"stage": true, "stage_type": true,"_id": false}'
fetched_stage_data <- purrr::map(.x = "all_stage", .f = fn_fetch_mongo, pattern="_stage",fields = fields,.key=gsva_score_nest$cancertype,.keyindex="cancer_types") %>%
  dplyr::bind_rows() %>%
  dplyr::select(-cancertype) %>%
  dplyr::rename(cancertype=cancer_types) %>%
  dplyr::group_by(cancertype, stage_type) %>%
  tidyr::nest()

# stage analysis -------------------------------------------------------
gsva_score_nest %>%
  dplyr::inner_join(fetched_stage_data, by="cancertype") -> combine_data


source(file.path(apppath,"gsca-r-app/utils/fn_gsva_stage.R"))
combine_data %>%
  dplyr::mutate(sur_res = purrr::map2(gsva,data,fn_stage)) %>%
  dplyr::select(cancertype,sur_res,stage_type) %>%
  tidyr::unnest() %>%
  tidyr::unnest() -> gsva_score_stage_test_res

stages_class <- tibble::tibble(stage=c("StageI","StageII","StageIII","StageIV","intermediate","poor","good"),
                               stage1=c("StageI","StageII","StageIII","StageIV","StageII","StageIII","StageI"),)
gsva_score_stage_test_res %>%
  dplyr::mutate(mean.n = paste(signif(mean_exp,2),n,sep = "/"),
              stage = purrr::map(stage,.f=function(.x){
                gsub(" ","",.x)
              })) %>%
  tidyr::unnest(stage) %>%
  dplyr::select(-mean_exp,-n) %>%
  unique() %>%
  dplyr::mutate(mean.n = ifelse(stage_type=="igcccg_stage",paste(mean.n,"(",stage,")",sep=""),mean.n)) %>%
  dplyr::inner_join(stages_class,by="stage") %>%
  dplyr::select(-stage) %>%
  dplyr::rename(stage=stage1) %>%
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
  dplyr::select(cancertype,combine,stage_type) %>%
  tidyr::unnest(cols = c(combine)) -> for_plot

color <- c("#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D", "#666666")
len_stage <- length(unique(for_plot$stage))

color_list <- for_plot %>%
  dplyr::inner_join(stages_included,by="stage") %>%
  dplyr::select(stage,rank) %>%
  unique() %>%
  dplyr::arrange(rank) %>%
  dplyr::mutate(color=color[1:len_stage])

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size_width <- 4+length(unique(for_plot$cancertype))*0.5


box_plot <- box_plot_single_gene_multi_cancers_facetgrid(data = for_plot,aesx = "stage",aesy="gsva",facets="stage_type~cancertype",color = "stage",color_name = "Stages",color_labels = color_list$stage,color_values = color_list$color,title = "GSVA score in stages of selected cancer types", xlab = 'Cancer type', ylab = 'GSVA score')

for_plot$stage_type %>% unique() %>% length() -> n.stagetype
if(n.stagetype>1){
  height=3*n.stagetype
}else{
  height=4
}
ggsave(filename = filepath_box, plot = box_plot, device = 'png', width = size_width, height =  height)
pdf_name <- gsub("\\.png",".pdf", filepath_box)
ggsave(filename = pdf_name, plot = box_plot, device = 'pdf', width = size_width, height = height)

# trend Plot --------------------------------------------------------------------
stages_trend <- tibble::tibble(stage=c("Stage I","Stage II","Stage III","Stage IV","intermediate","poor","good"),
                                  stage1=c("Stage I","Stage II","Stage III","Stage IV","Stage II","Stage III","Stage II"),
                                  rank=c(1,2,3,4,2,3,1))
gsva_score_stage_test_res %>%
  dplyr::select(-diff_p, -diff_method,-trend_method) %>%
  dplyr::inner_join(stages_trend,by="stage") %>%
  dplyr::mutate(`Trend P`=ifelse(trend_p>0.05,">0.05","<=0.05")) %>%
  dplyr::mutate(stage = purrr::map(stage1,.f=function(.x){
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
tibble::tibble(fillbreaks=fillbreaks_trend) %>%
  dplyr::mutate(color=ifelse(fillbreaks>0,"#ee0e27","#1678f3")) %>%
  dplyr::mutate(color=ifelse(fillbreaks==0,"grey",color)) %>%
  dplyr::mutate(colorlabel=ifelse(fillbreaks>0,"Up","Down")) %>%
  dplyr::mutate(colorlabel=ifelse(fillbreaks==0,"Equal",colorlabel)) -> fillbreaks
xlabels <- sort(unique(for_plot_trend$stage))
names(xlabels) <- sort(unique(for_plot_trend$rank))

source(file.path(apppath,"gsca-r-app/utils/fn_trend_plot.R"))
trendplot <- trend_plot(data = for_plot_trend,
                        aesx="rank",
                        aesy="mean_exp",
                        linecolor="trend_score",
                        linetype="`Trend P`",
                        facetgrid="stage_type~cancertype",
                        xlabels=xlabels,
                        colorname="Trend",
                        color_list = fillbreaks$color,
                        fillbreaks=fillbreaks$fillbreaks,
                        color_lables=fillbreaks$colorlabel,
                        title="Tendency of GSVA score among stages",
                        xlab="Stage",
                        ylab="Symbol") 


# Save image --------------------------------------------------------------
for_plot_trend$stage_type %>% unique() %>% length() -> n.stagetype
if(n.stagetype>1){
  height=2*n.stagetype
}else{
  height=3
}
ggsave(filename = filepath_trend, plot = trendplot, device = 'png', width = size_width, height =  height)
pdf_name <- gsub("\\.png",".pdf", filepath_trend)
ggsave(filename = pdf_name, plot = trendplot, device = 'pdf', width = size_width, height = height)
