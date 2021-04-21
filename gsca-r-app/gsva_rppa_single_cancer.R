# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
search_cancertype <-args[3]
search_surtype <- args[4]
filepath <- args[5]
apppath <- args[6]

# tableuuid <- "ba16c786-93ca-421e-a426-7a361f4c3e7a"
# tablecol <- "preanalysised_gsva"
# search_cancertype <- "KICH"
# search_surtype <- "Apoptosis"
# filepath <- "/home/huff/github/GSCA/gsca-r-plot/pngs/9c016f85-75e3-4959-8e29-9b220d5af2c7.png"
# apppath <- "/home/huff/github/GSCA"

# Mongo -------------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsva_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_rppa"), url = gsca_conf)

# fetch gsva score --------------------------------------------------------

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

fetched_data <- fn_fetch_data(.uuid = tableuuid)

fetched_data$gsva_score %>% 
  tibble::as_tibble() %>% 
  tidyr::gather(key = "cancertype", value = "gsva") %>% 
  dplyr::mutate(gsva = purrr::map(.x = gsva, .f = fn_reorg)) %>%
  dplyr::filter(cancertype == search_cancertype) %>%
  tidyr::unnest() %>%
  dplyr::filter(type=="tumor")->  gsva_score


# fetch rppa score data -----------------------------------------------------

fields <- '{"cancer_types": true, "barcode": true,"pathway": true,"score": true, "_id": false}'
fetched_rppa_data <- purrr::map(.x = "all_rppa_score", .f = fn_fetch_mongo, pattern="",fields = fields,.key=unique(gsva_score$cancertype),.keyindex="cancer_types") %>%
  dplyr::bind_rows() %>%
  dplyr::select(-cancertype) %>%
  dplyr::rename(cancertype=cancer_types,sample_name=barcode) 


fields <- '{"cancertype": true, "res_table": true,"_id": false}'
fetched_gsvarppacor_data <- purrr::map(.x = "preanalysised_gsva_rppa", .f = fn_fetch_mongo, pattern="preanalysised_gsva_",fields = fields,.key=tableuuid,.keyindex="uuid") %>%
  dplyr::bind_rows() %>%
  dplyr::filter(pathway %in% search_surtype)%>%
  dplyr::filter(cancertype == search_cancertype)
# combine -----------------------------------------------------------------

gsva_score %>%
  dplyr::filter(!is.na(gsva)) %>%
  dplyr::mutate(sample_name=substr(barcode,1,12)) %>%
  dplyr::inner_join(fetched_rppa_data, by=c("sample_name","cancertype")) %>%
  dplyr::filter(pathway == search_surtype)-> combine_data


# plot --------------------------------------------------------------------

source(file.path(apppath,"gsca-r-app/utils/fn_point_line.R"))

title <-  glue::glue('Spearman correlation between GSVA score and {search_surtype} \npathway activity in {search_cancertype}')
plot <- fn_point_fit(data=combine_data,aesx="score",aesy="gsva",
                     title=title,xlab=glue::glue('{search_surtype} pathway activity'),ylab="GSVA score",
                     label=paste("Cor. =",round(fetched_gsvarppacor_data$estimate,2),"\nFDR =", round(fetched_gsvarppacor_data$fdr,2)))

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)
