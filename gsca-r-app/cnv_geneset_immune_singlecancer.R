################### imm gsva cor singlegene####################

# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
search_cancertype <-args[3]
search_surtype <- args[4]
filepath <- args[5]
apppath <- args[6]

# tableuuid <- "e496623d-57e7-4cbb-a03c-57b7da877dd8"
# tablecol <- "preanalysised_cnvgeneset"
# search_cancertype <- "KICH"
# search_surtype <- "CD4_naive"
# filepath <- "/home/huff/github/GSCA/gsca-r-plot/pngs/1ebbb617-1034-40a7-9b8d-dbc7947c9fcb.png"
# apppath <- "/home/huff/github/GSCA"

# Mongo -------------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsva_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_immu"), url = gsca_conf)

# fetch gsva score --------------------------------------------------------

fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"uuid": "<.xx>"}', .open = '<', .close = '>')
}

fn_fetch_data <- function(.uuid) {
  pre_gsva_coll$find(query = fn_query_str(.x = .uuid), fields = '{"_id": false}')
}


fetched_data <- fn_fetch_data(.uuid = tableuuid)

fetched_data$cnvgeneset[[1]] %>% 
  tibble::as_tibble() %>% 
  dplyr::filter(cancertype == search_cancertype) ->  gsva_score


# fetch immune score data -------------------------------------------------


fields <- '{"cell_type": true,"barcode": true,"sample_name":true, "TIL":true, "_id": false}'
fetched_immune <- purrr::map(.x = paste(search_cancertype,"_all_immune",sep=""), .f = fn_fetch_mongo, pattern="_all_immune",fields = fields,.key=search_surtype,.keyindex="cell_type") %>%
  dplyr::bind_rows()%>%
  dplyr::filter(substr(barcode,14,14)==0)

# fetch cor ---------------------------------------------------------------

fields <- '{"uuid": true, "res_table": true,"_id": false}'
fetched_gsvaimmucor_data <- purrr::map(.x = "preanalysised_cnvgeneset_immu", .f = fn_fetch_mongo, pattern="preanalysised_cnvgeneset_",fields = fields,.key=tableuuid,.keyindex="uuid") %>%
  dplyr::bind_rows() %>%
  dplyr::filter(celltype  %in% search_surtype)%>%
  dplyr::filter(cancertype == search_cancertype)
# combine -----------------------------------------------------------------

gsva_score %>%
  dplyr::filter(!is.na(group)) %>%
  dplyr::inner_join(fetched_immune, by=c("sample_name")) %>%
  dplyr::filter(group!="Excluded") %>%
  dplyr::group_by(group) %>%
  dplyr::mutate(n=dplyr::n()) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(group_n= paste(group,", n=",n,sep=""))-> combine_data

# plot --------------------------------------------------------------------

source(file.path(apppath,"gsca-r-app/utils/fn_boxplot_single_gene_in_cancer.R"))
color_labels <- combine_data$group_n %>% unique() %>% sort()
combn_matrix <- combn(sort(unique(combine_data$group)),2)
comp_list <- list()
for(i in 1:ncol(combn_matrix)){
  comp_list[[i]] <- combn_matrix[,i]
}
color <- c("#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D", "#666666")
len_stage <- length(unique(combine_data$group_n))

color_list <- combine_data %>%
  dplyr::mutate(rank=ifelse(group=="Amp.",1,2)) %>%
  dplyr::mutate(rank=ifelse(group=="WT",3,rank)) %>%
  dplyr::select(group_n,rank) %>%
  unique() %>%
  dplyr::arrange(rank) %>%
  dplyr::mutate(color=color[1:len_stage])

plot <- box_plot_single_gene_single_cancer(data = combine_data,aesx = "group",aesy="TIL",color = "group_n",color_name = "Gene set CNV",color_labels =  color_labels,color_values =color_list$color,title = glue::glue('{search_surtype} infiltrates between\ngene set CNV groups in {search_cancertype}'),xlab = 'Groups', ylab = 'Immune infiltrates score\n(ImmuCellAI)',xangle = 0,comp_list=comp_list,ylimitfold=0.1)

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)