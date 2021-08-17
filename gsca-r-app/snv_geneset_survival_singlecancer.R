# snv single gene survival---------------------------------------------------------
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)
# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
search_cancertypes <- args[3]
search_surtype <- args[4]
filepath <- args[5]
apppath <- args[6]

# tableuuid <- "4cd96df0-cc8f-4373-a7eb-c8160dc5e967"
# tablecol <- "preanalysised_snvgeneset"
# search_cancertypes <- "LUAD"
# search_surtype <- "os"
# filepath <- "/home/huff/github/GSCA/gsca-r-plot/pngs/055e0f75-7bb9-4261-924f-185493594a4d.png"
# apppath <- "/home/huff/github/GSCA"

# arguments need to be determined future ----------------------------------
color_list <- tibble::tibble(color=c( "#CD2626","#00B2EE"),
                             group=c("Mutant","WT"))
# Functions ----------------------------------------------------------------

# Mongo -------------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsva_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_survival"), url = gsca_conf)

# Query data --------------------------------------------------------------
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

fetched_data$snvgeneset[[1]] %>% 
  tibble::as_tibble() %>%
  dplyr::filter(cancertype == search_cancertypes) ->  gsva_score

# fetch survival data -----------------------------------------------------

fields <- '{"cancer_types": true, "sample_name": true, "os_months": true,"os_status": true, "pfs_months": true,"pfs_status": true,"_id": false}'
fetched_survival_data <- purrr::map(.x = "all_survival", .f = fn_fetch_mongo, pattern="_survival",fields = fields,.key=unique(gsva_score$cancertype),.keyindex="cancer_types") %>%
  dplyr::bind_rows() %>%
  dplyr::group_by(cancer_types) %>%
  tidyr::nest() %>%
  dplyr::rename(cancertype=cancer_types) %>%
  dplyr::ungroup() %>%
  tidyr::unnest()

# combine -----------------------------------------------------------------

gsva_score %>%
  dplyr::filter(!is.na(group)) %>%
  dplyr::mutate(sample_name=substr(barcode,1,12)) %>%
  dplyr::inner_join(fetched_survival_data, by=c("sample_name","cancertype")) -> combine_data

# fetch survival res ------------------------------------------------------
pre_ana_gsva_survival_col <- glue::glue("{tablecol}_survival")
uuid_query <- post_gsva_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"res_table": true, "_id": false}'
)

fields <- '{"res_table": true,"_id": false}'

fetched_snv_survival <- purrr::map(.x = pre_ana_gsva_survival_col, .f = fn_fetch_mongo, pattern="_survival",fields = fields,.key=tableuuid,.keyindex="uuid")[[1]] %>%
  dplyr::filter(sur_type == tolower(search_surtype)) %>%
  dplyr::filter(cancertype == search_cancertypes)

# survival data ------------------------------------------------------------
source(file.path(apppath, "gsca-r-app/utils/fn_survival.R"))

survival_group  %>%
  dplyr::filter(type %in% search_surtype) -> survival_type_to_draw

combine_data %>%
  dplyr::select(sample_name,group,cancertype,time=survival_type_to_draw$time,status=survival_type_to_draw$status) -> combine_data_group

# draw --------------------------------------------------------------------

title <- paste(toupper(search_surtype),"of gene set", "SNV in",search_cancertypes)
combine_data_group %>%
  dplyr::mutate(group=ifelse(group=="1WT","WT","Mutant")) %>%
  dplyr::filter(!is.na(time)) %>%
  fn_survival(title,color_list,logrankp=fetched_snv_survival$logrankp,ylab=paste(toupper(search_surtype),"probability")) -> plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)

