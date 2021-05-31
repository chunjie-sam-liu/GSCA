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

# tableuuid <- "ba16c786-93ca-421e-a426-7a361f4c3e7a"
# tablecol <- "preanalysised_gsva"
# search_cancertype <- "KICH"
# search_surtype <- "DC"
# filepath <- "/home/huff/github/GSCA/gsca-r-plot/pngs/e1c5a5b9-5320-48d7-aeb8-5a5afd29c426.png"
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


# fetch immune score data -------------------------------------------------


fields <- '{"cell_type": true,"barcode": true,"sample_name":true, "TIL":true, "_id": false}'
fetched_immune <- purrr::map(.x = paste(search_cancertype,"_all_immune",sep=""), .f = fn_fetch_mongo, pattern="_all_immune",fields = fields,.key=search_surtype,.keyindex="cell_type") %>%
  dplyr::bind_rows()%>%
  dplyr::filter(substr(barcode,14,14)==0)

# fetch cor ---------------------------------------------------------------

fields <- '{"uuid": true, "res_table": true,"_id": false}'
fetched_gsvaimmucor_data <- purrr::map(.x = "preanalysised_gsva_immu", .f = fn_fetch_mongo, pattern="preanalysised_gsva_",fields = fields,.key=tableuuid,.keyindex="uuid") %>%
  dplyr::bind_rows() %>%
  dplyr::filter(celltype  %in% search_surtype)%>%
  dplyr::filter(cancertype == search_cancertype)
# combine -----------------------------------------------------------------

gsva_score %>%
  dplyr::filter(!is.na(gsva)) %>%
  dplyr::mutate(sample_name=substr(barcode,1,12)) %>%
  dplyr::inner_join(fetched_immune, by=c("barcode","cancertype","sample_name"))-> combine_data

# plot --------------------------------------------------------------------

source(file.path(apppath,"gsca-r-app/utils/fn_point_line.R"))

title <-  glue::glue('Spearman correlation between GSVA score and infiltrate of\n{search_surtype} cell in {search_cancertype}')
plot <- fn_point_fit(data=combine_data,aesx="TIL",aesy="gsva",
                     title=title,xlab=glue::glue('Infiltrate of {search_surtype}'),ylab="GSVA score",
                     label=paste("Cor. =",round(fetched_gsvaimmucor_data$estimate,2),
                                 "\nP value = ",format(signif(fetched_gsvaimmucor_data$p_value*1000)/1000, scientific = TRUE),
                                 "\nFDR =", format(signif(fetched_gsvaimmucor_data$fdr*1000)/1000,scientific = TRUE)))
# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)