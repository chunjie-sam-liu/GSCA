
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
filepath_box <- args[3]
apppath <- args[4]


# tableuuid <- 'bdf577e5-a984-4e59-8f05-2651825b475f'
# tablecol <- 'preanalysised_gsva'
# filepath <- "/home/huff/github/GSCA/gsca-r-plot/pngs/b5546ec5-c924-4d1e-aef5-629942c6d6af.png"
# apppath <- '/home/huff/github/GSCA'

# Mongo -------------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsva_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_subtype"), url = gsca_conf)

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

fields <- '{"cancer_types": true, "sample_name": true,"subtype": true, "_id": false}'
fetched_subtype_data <- purrr::map(.x = "all_subtype", .f = fn_fetch_mongo, pattern="_subtype",fields = fields,.key=gsva_score_nest$cancertype,.keyindex="cancer_types") %>%
  dplyr::bind_rows() %>%
  dplyr::select(-cancertype) %>%
  dplyr::rename(cancertype=cancer_types)%>%
  dplyr::group_by(cancertype) %>%
  tidyr::nest()

# subtype analysis -------------------------------------------------------
gsva_score_nest %>%
  dplyr::inner_join(fetched_subtype_data, by="cancertype") -> combine_data


source(file.path(apppath,"gsca-r-app/utils/fn_gsva_subtype.R"))
combine_data %>%
  dplyr::mutate(sur_res = purrr::map2(gsva,data,fn_subtype)) %>%
  dplyr::select(cancertype,sur_res) %>%
  tidyr::unnest() %>%
  tidyr::unnest() -> gsva_score_subtype_test_res

gsva_score_subtype_test_res %>%
  dplyr::mutate(subtype.mean.n = paste(subtype," (",paste(signif(mean_exp,2),n,sep = "/"), ")", sep="")) %>%
  dplyr::select(-mean_exp,-n) %>%
  dplyr::group_by(cancertype) %>%
  dplyr::arrange(subtype) %>%
  dplyr::mutate(n = 1:n())%>%
  dplyr::mutate(subtypename = paste("Subtype",n,sep=""))  %>%
  dplyr::select(-subtype,-n) %>%
  dplyr::ungroup() %>%
  tidyr::spread(key="subtypename",value="subtype.mean.n") -> gsva_score_subtype

# Insert table ------------------------------------------------------------
insert_data <- list(uuid = tableuuid, res_table = gsva_score_subtype)
#post_gsva_coll$drop()
uuid_query <- post_gsva_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"uuid": true, "_id": false}'
)

if (nrow(uuid_query) == 0) {
  post_gsva_coll$insert(data = insert_data)
  post_gsva_coll$index(add = '{"uuid": 1}')
  message("insert data into preanalysised_gsva_subtype")
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
  tidyr::unnest(cols = c(combine))-> for_plot

color <- c("#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D", "#666666")
len_subtype <- length(unique(for_plot$cancertype))

color_list <- for_plot %>%
  dplyr::select(cancertype) %>%
  unique() %>%
  dplyr::arrange(cancertype) %>%
  dplyr::mutate(color=color[1:len_subtype])

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size_width <- 4+length(unique(for_plot$cancertype))*0.5

box_plot <- box_plot_single_gene_multi_cancers(data = for_plot,aesx = "subtype",aesy="gsva",facets=".~cancertype",color = "cancertype",color_name = "",color_labels = color_list$cancertype,color_values = color_list$color,title = "GSVA score in subtypes of selected cancer types", xlab = 'Subtype', ylab = 'GSVA score') +
  facet_grid(".~cancertype",scales = "free_x",space = "free") +
  theme(axis.text.x = element_text(colour = "black",size=10, angle = 45, hjust = 1, vjust = 1)) 


ggsave(filename = filepath_box, plot = box_plot, device = 'png', width = size_width, height =  4)
pdf_name <- gsub("\\.png",".pdf", filepath_box)
ggsave(filename = pdf_name, plot = box_plot, device = 'pdf', width = size_width, height = 4)
