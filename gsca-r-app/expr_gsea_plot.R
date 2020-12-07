
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
filepath <- args[3]
apppath <- args[4]


tableuuid <- 'cf7c811d-3626-4a28-b050-57cd6521e9b2'
tablecol <- 'preanalysised_gsea'
filepath <- "/home/liucj/github/GSCA/gsca-r-plot/pngs/217c27f6-c12a-413d-8625-b9748fc1ff65.png"
apppath <- '/home/liucj/github/GSCA'

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))
pre_gsea_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsea_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_expr"), url = gsca_conf)
# Function ----------------------------------------------------------------
fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"uuid": "<.xx>"}', .open = '<', .close = '>')
}


fn_fetch_data <- function(.uuid) {
  pre_gsea_coll$find(query = fn_query_str(.x = tableuuid), fields = '{"_id": false}')
}

fn_reorg <- function(.x) {
  .x %>%
    tidyr::unnest(cols = c(symbol, log2fc)) %>%
    tibble::deframe()
}

# Process -----------------------------------------------------------------

fetched_data <- fn_fetch_data(.uuid = tableuuid)


fetched_data$gsea_score %>%
  tibble::as_tibble() %>%
  tidyr::gather(key = "cancertype", value = "gsea") %>% 
  dplyr::mutate(gsea = purrr::map(.x = gsea, .f = fn_reorg))