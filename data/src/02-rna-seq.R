
# Library -----------------------------------------------------------------

library(magrittr)


# Load data ---------------------------------------------------------------

all_expr <- readr::read_rds(file = '/home/huff/data/GSCA/expr/pancan33_expr.IdTrans.rds.gz')
load(file = 'data/rda/01-gene-symbols.rda')
gsca_conf <- readr::read_lines(file = 'data/src/gsca.conf')


search_symbol <- search_symbol
# Function ----------------------------------------------------------------

fn_transform_samples <- function(.x) {
  .x %>% 
    tidyr::gather(key = 'aliquot', value = 'expr') ->
    .y
  
  .y %>% 
    dplyr::mutate(tmp = substr(x = aliquot, start = 14, stop = 15)) %>% 
    dplyr::mutate(type = ifelse(tmp == '01', 'tumor', 'normal')) %>% 
    dplyr::mutate(barcode = substr(x = aliquot, start = 1, stop = 16)) %>% 
    dplyr::mutate(sample_name = substr(x = barcode, start = 1, stop = 12)) -> 
    .yy
  
  tibble::tibble(
    aliquot = list(.yy$aliquot),
    barcode = list(.yy$barcode),
    sample_name = list(.yy$sample_name),
    type = list(.yy$type),
    expr = list(.yy$expr)
  )
}

fn_gene_tcga_all_expr <- function(cancer_types, expr){
  # transform data as mongo json format
  .x <- expr
  
  .x %>% dplyr::filter(symbol %in% search_symbol$symbol) -> .xx
  
  .xx %>% 
    dplyr::group_by(entrez_id, symbol) %>% 
    tidyr::nest() -> 
    .d
  
  .df <- purrr::map_dfr(.x = .d$data, .f = fn_transform_samples)
  
  .d %>% 
    dplyr::select(-data) %>%
    dplyr::ungroup() %>% 
    dplyr::bind_cols(.df) ->
    .dd
  
  # insert to collection
  .y <- cancer_types
  .coll_name <- glue::glue('{.y}_all_expr')
  # collection
  .coll_expr <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  # insert data
  .coll_expr$drop()
  .coll_expr$insert(data = .dd)
  
  # save the result
  .dd
}
# Change the name ---------------------------------------------------------

# collection name TCGAname_all_expr
all_expr %>% 
  purrr::pmap(.f = fn_gene_tcga_all_expr) ->
  all_expr_mongo_data


# Save image --------------------------------------------------------------

save.image(file = 'data/rda/02-rna-seq.rda')
