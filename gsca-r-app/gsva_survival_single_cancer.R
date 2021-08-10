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
# search_surtype <- "OS"
# filepath <- "/home/huff/github/GSCA/gsca-r-plot/pngs/9c016f85-75e3-4959-8e29-9b220d5af2c7.png"
# apppath <- "/home/huff/github/GSCA"

# Mongo -------------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsva_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_survival"), url = gsca_conf)

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
    dplyr::mutate(type = factor(x = type, levels = c("tumor", "normal"))) ->
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


# fetch survival data -----------------------------------------------------

fields <- '{"cancer_types": true, "sample_name": true, "os_days": true,"os_status": true, "pfs_days": true,"pfs_status": true,"_id": false}'
fetched_survival_data <- purrr::map(.x = "all_survival", .f = fn_fetch_mongo, pattern="_survival",fields = fields,.key=unique(gsva_score$cancertype),.keyindex="cancer_types") %>%
  dplyr::bind_rows() %>%
  dplyr::group_by(cancer_types) %>%
  tidyr::nest() %>%
  dplyr::rename(cancertype=cancer_types) %>%
  dplyr::ungroup() %>%
  tidyr::unnest()

# combine -----------------------------------------------------------------

gsva_score %>%
  dplyr::filter(!is.na(gsva)) %>%
  dplyr::mutate(sample_name=substr(barcode,1,12)) %>%
  dplyr::inner_join(fetched_survival_data, by=c("sample_name","cancertype")) -> combine_data


# survival analysis -------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_survival.R"))

cutoff <- 0.5

survival_group  %>%
  dplyr::filter(type %in% search_surtype) -> survival_type_to_draw

combine_data %>%
  dplyr::rename(expr=gsva) %>%
  dplyr::select(cancertype,sample_name,expr,time=survival_type_to_draw$time,status=survival_type_to_draw$status) %>%
  dplyr::filter(!is.na(time)) %>%
  dplyr::filter(!is.na(status)) %>%
  dplyr::mutate(group = ifelse(expr>quantile(expr,cutoff),"Higher GSVA","Lower GSVA")) -> combine_data_group

# fetch survival res ------------------------------------------------------
pre_ana_gsva_survival_col <- glue::glue("{tablecol}_survival")
uuid_query <- post_gsva_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"res_table": true, "_id": false}'
)

fields <- '{"res_table": true,"_id": false}'

fetched_expr_survival <- purrr::map(.x = pre_ana_gsva_survival_col, .f = fn_fetch_mongo, pattern="_survival",fields = fields,.key=tableuuid,.keyindex="uuid") %>%
  bind_rows() %>%
  dplyr::filter(sur_type == search_surtype)%>%
  dplyr::filter(cancertype == search_cancertype)

# draw survival plot ------------------------------------------------------
color_list <- tibble::tibble(color=c( "#CD2626","#00B2EE"),
                             group=c("Higher GSVA","Lower GSVA"))

title <- paste(search_surtype,"survival","of GSVA score in",search_cancertype)
combine_data_group %>%
  dplyr::filter(!is.na(group)) %>%
  fn_survival(title,color_list,logrankp=fetched_expr_survival$logrankp,ylab=paste(toupper(search_surtype),"probability")) -> plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)
