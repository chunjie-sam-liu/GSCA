


fn_query_str <- function(.key,.keyindex) {
  .xx <- paste0(.key, collapse = '","')
  glue::glue('{"<.keyindex>": {"$in": ["<.xx>"]}}', .open = '<', .close = '>')
}

# function fetch all_expr of a single_cancer from mongo-----------------------------------

fn_fetch_mongo_all_expr_single_cancer <- function(.cancer_types,.key,.keyindex) {
  exp_coll <- paste(.cancer_types,"all_expr",sep = "_")
  .coll_exp <- mongolite::mongo(collection = exp_coll, url = gsca_conf)
  .coll_exp$find(
    query = fn_query_str(.key,.keyindex),
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
    query = fn_query_str(.key,.keyindex),
    fields = '{"cancer_types": true, "sample_name": true, "os_days": true,"os_status": true, "pfs_days": true,"pfs_status": true,"_id": false}'
  ) %>%
    tidyr::unnest(cols = c(cancer_types, sample_name, os_days, os_status, pfs_days, pfs_status)) 
}
