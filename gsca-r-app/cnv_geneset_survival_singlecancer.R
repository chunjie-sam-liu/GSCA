# cnv single gene survival---------------------------------------------------------
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

# tableuuid <-'fb7c8b98-6bb8-4577-8ed3-27bc8e25a7b4'
# tablecol <- 'preanalysised_cnvgeneset'
# search_cancertypes <- 'KICH'
# search_surtype <- 'os'
# apppath <- '/home/huff/github/GSCA'
# Mongo -------------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsva_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_survival"), url = gsca_conf)

# Functions ----------------------------------------------------------------
# source(file.path(apppath, "gsca-r-app/utils/fn_geneset_survival_cnv.R"))
# source(file.path(apppath, "gsca-r-app/utils/fn_geneset_cnv.R"))
# source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
# source(file.path(apppath, "gsca-r-app/utils/fn_survival.R"))

# Query data --------------------------------------------------------------

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
  dplyr::filter(cancertype == search_cancertypes) ->  gsva_score

# fetch survival data -----------------------------------------------------

fields <- '{"cancer_types": true, "sample_name": true, "os_months": true,"os_status": true, "pfs_months": true,"pfs_status": true,"dss_months": true,"dss_status": true,"dfi_months": true,"dfi_status": true,"_id": false}'
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
  dplyr::inner_join(fetched_survival_data, by=c("sample_name","cancertype")) -> combine_data

# fetch survival res ------------------------------------------------------
pre_ana_gsva_survival_col <- glue::glue("{tablecol}_survival")
uuid_query <- post_gsva_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"res_table": true, "_id": false}'
)

fields <- '{"res_table": true,"_id": false}'

fetched_cnv_survival <- purrr::map(.x = pre_ana_gsva_survival_col, .f = fn_fetch_mongo, pattern="_survival",fields = fields,.key=tableuuid,.keyindex="uuid")[[1]] %>%
  dplyr::filter(sur_type == tolower(search_surtype)) %>%
  dplyr::filter(cancertype == search_cancertypes)


source(file.path(apppath, "gsca-r-app/utils/fn_survival.R"))
survival_group  %>%
  dplyr::filter(type %in% search_surtype) -> survival_type_to_draw

combine_data %>%
  dplyr::select(sample_name,group,cancertype,time=survival_type_to_draw$time,status=survival_type_to_draw$status) -> combine_data_group


# draw --------------------------------------------------------------------
cnv_group <- tibble::tibble(cnv=c(-2,-1,0,1,2),
                            group_detail=c("Homo. dele.","Hete. dele.","WT","Hete. amp.","Homo. amp."),
                            group=c("Dele.","Dele.","WT","Amp.","Amp."),
                            color=c( "#00B2EE","#00B2EE","gold4","#CD2626","#CD2626"))
cnv_group %>%
  dplyr::select(group,color) %>%
  unique() -> cnv_group.color


title <- paste(toupper(search_surtype),"of gene set", "CNV in",search_cancertypes)
combine_data_group %>%
  dplyr::filter(!is.na(time)) %>%
  dplyr::filter(group !="Excluded") %>%
  fn_survival(title,cnv_group.color,logrankp=fetched_cnv_survival$logrankp,ylab=paste(toupper(search_surtype),"probability")) -> plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)

