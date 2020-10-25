# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"
gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load cnv ----------------------------------------------------------------
cnv_threshold <- readr::read_rds(file = '/home/huff/data/GSCA/mutation/cnv/pancan34_cnv_threshold.IdTrans.rds.gz')

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
    cnv = list(.yy$expr)
  )
}

fn_gene_tcga_cnv_threshold <- function(cancer_types, cnv) {
  .x <- cnv
  .y <- cancer_types
  message(glue::glue('{.y} CNV threshold processing.'))
  
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
  .coll_name <- glue::glue('{.y}_cnv_threshold')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"symbol": 1}')
  
  message(glue::glue('Save all {.y} CNV threshold into mongo'))
  
  .dd
}



# Change name -------------------------------------------------------------

cnv_threshold %>% 
  purrr::pmap(.f = fn_gene_tcga_cnv_threshold) ->
  cnv_threshold_mongo_data

# Save image --------------------------------------------------------------

save.image(file = 'data/rda/11-cnv-threshold.rda')
