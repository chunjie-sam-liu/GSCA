
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]
tableuuid <- args[4]
tablecol <- args[5]

search_str = 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_deg#KIRC_deg#KIRP_deg#LUAD_deg#LUSC_deg'
filepath = '/home/liucj/github/GSCA/gsca-r-plot/pngs/b56ab504-13d1-41d9-a8e7-2bf5d54cda27.png'
apppath <- '/home/liucj/github/GSCA'
tableuuid <- 'ca0b3549-3ac5-4111-a0c8-1706b929f703'
tablecol <- 'preanalysised_expr_geneset'


search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]] %>%
  gsub(pattern = "_deg", replacement = "_all_expr", x = .)
# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(search_genes,search_cancertypes)

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

# Function ----------------------------------------------------------------

fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"symbol": {"$in": ["<.xx>"]}}', .open = '<', .close = '>')
}

fn_fetch_mongo <- function(.x) {
  .coll <- mongolite::mongo(collection = .x, url = gsca_conf)
  .coll$find(
    query = fn_query_str(search_genes),
    fields = '{"symbol": true, "barcode": true, "type": true, "expr": true, "_id": false}'
  ) %>%
    tibble::as_tibble() %>%
    tidyr::unnest(cols = c(barcode, type, expr)) %>%
    tidyr::spread(key = "symbol", value = "expr")
}

fn_fetch_mongo_all_expr <- function(.x) {
  .coll <- mongolite::mongo(collection = .x, url = gsca_conf)
  .coll$find(fields = '{"symbol": true, "barcode": true, "type": true, "expr": true, "_id": false}')
}


# Query data --------------------------------------------------------------
fetched_data <- search_cancertypes %>%
  purrr::map(.f = fn_fetch_mongo) %>%
  tibble::enframe(name = "cancertype", value = "expr") %>%
  dplyr::mutate(cancertype = gsub(pattern = "_all_expr", replacement = "", x = search_cancertypes))
