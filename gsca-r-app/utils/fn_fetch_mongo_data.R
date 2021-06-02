
library(magrittr)

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

fn_query_str_utils <- function(.key,.keyindex) {
  .xx <- paste0(.key, collapse = '","')
  glue::glue('{"<.keyindex>": {"$in": ["<.xx>"]}}', .open = '<', .close = '>')
}

# function fetch all_expr of a single_cancer from mongo-----------------------------------

fn_fetch_mongo_all_expr_single_cancer <- function(.cancer_types,.key,.keyindex) {
  exp_coll <- paste(.cancer_types,"all_expr",sep = "_")
  .coll_exp <- mongolite::mongo(collection = exp_coll, url = gsca_conf)
  .coll_exp$find(
    query = fn_query_str_utils(.key,.keyindex),
    fields = '{"symbol": true, "sample_name": true, "type": true,"expr": true, "_id": false}'
  ) %>%
    dplyr::mutate(cancer_types = .cancer_types) %>%
    tidyr::unnest(cols = c(type, expr, sample_name)) 
}


# function to fectch all_survival of a cancer type from mongo -------------


fn_fetch_mongo_all_survival <- function(.data, .key, .keyindex) {
  coll <- .data
  .coll <- mongolite::mongo(collection = coll, url = gsca_conf)
  .coll$find(
    query = fn_query_str_utils(.key,.keyindex),
    fields = '{"cancer_types": true, "sample_name": true, "os_days": true,"os_status": true, "pfs_days": true,"pfs_status": true,"_id": false}'
  ) %>%
    tidyr::unnest(cols = c(cancer_types, sample_name, os_days, os_status, pfs_days, pfs_status)) 
}

# function to fectch all_subtype of a cancer type from mongo -------------


fn_fetch_mongo_all_subtype <- function(.data, .key, .keyindex) {
  coll <- .data
  .coll <- mongolite::mongo(collection = coll, url = gsca_conf)
  .coll$find(
    query = fn_query_str_utils(.key,.keyindex),
    fields = '{"cancer_types": true, "sample_name": true, "subtype": true,"_id": false}'
  ) %>%
    tidyr::unnest(cols = c(cancer_types, sample_name, subtype)) 
}

# function to fectch all_subtype of a cancer type from mongo -------------


fn_fetch_mongo_all_stage <- function(.data, .key, .keyindex) {
  coll <- .data
  .coll <- mongolite::mongo(collection = coll, url = gsca_conf)
  .coll$find(
    query = fn_query_str_utils(.key,.keyindex),
    fields = '{"cancer_types": true, "sample_name": true, "stage": true,"_id": false}'
  ) %>%
    tidyr::unnest(cols = c(cancer_types, sample_name, stage)) 
}

# function to fetch snv_count ------------------------------------------

fn_fetch_mongo_snv_count <- function(.data, .key, .keyindex) {
  coll <- .data
  .coll <- mongolite::mongo(collection = coll, url = gsca_conf)
  .coll$find(
    query = fn_query_str_utils(.key,.keyindex),
    fields = '{"EffectiveMut": true, "_id": false}'
  ) %>%
    tidyr::unnest(cols = c(EffectiveMut)) 
}

fn_fetch_mongo_all_rppascore <- function(.data, .key, .keyindex) {
  coll <- .data
  .coll <- mongolite::mongo(collection = coll, url = gsca_conf)
  .coll$find(
    query = fn_query_str_utils(.key,.keyindex),
    fields = '{"cancer_types": true, "barcode": true, "pathway": true,"score": true,"_id": false}'
  ) %>%
    tidyr::unnest(cols = c(cancer_types, barcode, pathway,score)) 
}# function to fetch snv_maf ------------------------------------------

fn_fetch_mongo_snv_maf <-  function(.data, .key, .keyindex) {
  coll <- .data
  .coll <- mongolite::mongo(collection = coll, url = gsca_conf)
  .coll$find(
    query = fn_query_str_utils(.key,.keyindex),
    fields = '{"_id": false}'
  ) %>%
    tidyr::unnest() 
}


# function to fetch data [common use]--------------------------------------------------
fn_fetch_mongo <- function(.x,pattern,fields,.key,.keyindex) {
  .coll <- mongolite::mongo(collection = .x, url = gsca_conf)
  .coll$find(
    query = fn_query_str_utils(.key,.keyindex),
    fields =fields #'{"symbol": true, "fc": true,"trend": true,"gene_tag": true,"logfdr": true, "_id": false}'
  ) %>%
    dplyr::mutate(cancertype = gsub(pattern = pattern, replacement = '', x = .x)) %>%
    tidyr::unnest() 
}

fn_fetch_mongo_all <- function(.x,pattern,fields) {
  .coll <- mongolite::mongo(collection = .x, url = gsca_conf)
  .coll$find(fields =fields) %>%
    dplyr::mutate(cancertype = gsub(pattern = pattern, replacement = '', x = .x)) %>%
    tidyr::unnest() 
}
