# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"
load(file = file.path(rda_path,"rda",'01-gene-symbols.rda'))
gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))
cnv_symbol_search_symbol_final <- readr::read_rds(file = '/home/huff/github/GSCA/data/rda/cnv_symbol_search_symbol_final.rds.gz') %>% 
  dplyr::select(cnvsymbol, entrez, symbol)

# Load cnv ----------------------------------------------------------------

# cnv_old <- readr::read_rds(file = '/home/huff/data/GSCALite/TCGA/cnv/pancan34_cnv.rds.gz')
cnv <- readr::read_rds(file = '/home/huff/data/GSCA/cnv/pancan34_cnv.IdTrans.rds.gz')

# Function ----------------------------------------------------------------

fn_transform_samples <- function(.x) {
  .x %>% 
    tidyr::gather(key = 'aliquot', value = 'expr') ->
    .y
  
  .y %>% 
    dplyr::mutate(tmp = substr(x = aliquot, start = 14, stop = 14)) %>% 
    dplyr::mutate(type = ifelse(tmp == '0', 'tumor', 'normal')) %>% 
    dplyr::mutate(barcode = substr(x = aliquot, start = 1, stop = 16)) %>% 
    dplyr::mutate(sample_name = substr(x = barcode, start = 1, stop = 12)) -> 
    .yy
  
  tibble::tibble(
    aliquot = list(.yy$aliquot),
    barcode = list(.yy$barcode),
    sample_name = list(.yy$sample_name),
    type = list(.yy$type),
    cnv = list(.yy$expr)
  )
}

fn_gene_tcga_all_cnv <- function(cancer_types, cnv) {
  .y <- cancer_types
  .x <- cnv
  message(glue::glue('{.y} CNV data processing.'))
  
  # cnv_symbol_search_symbol_final %>% 
  #  dplyr::inner_join(
  #    .x %>% dplyr::rename(cnvsymbol = symbol),
  #    by = 'cnvsymbol'
  #  ) %>% 
  #  dplyr::select(-cnvsymbol) %>% 
  .x %>%
    dplyr::group_by(entrez, symbol) %>% 
    tidyr::nest() %>% 
    dplyr::ungroup() -> 
    .d
  
  .df <- purrr::map_dfr(.x = .d$data, .f = fn_transform_samples)
  
  .d %>% 
    dplyr::select(-data) %>% 
    dplyr::bind_cols(.df) ->
    .dd
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_all_cnv')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"symbol": 1}')
  
  message(glue::glue('Save all {.y} CNV into mongo'))
  
  .dd
  
}

# Change name -------------------------------------------------------------


cnv %>% 
  purrr::pmap(.f = fn_gene_tcga_all_cnv) ->
  all_cnv_mongo_data


# Save image --------------------------------------------------------------

save.image(file = 'data/rda/08-cnv-data.rda')
