############### methy data mongo ###################

# library -----------------------------------------------------------------

library(magrittr)


# data path ---------------------------------------------------------------

rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/methy"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))


# load methy data ---------------------------------------------------------

methy_data <- readr::read_rds(file.path(data_path,"pancan33_meth.IdTrans.rds.gz"))


# function ----------------------------------------------------------------

fn_transform_samples <- function(.x){
  .x %>% 
    tidyr::gather(key = 'aliquot', value = 'methylation') ->
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
    methy = list(.yy$methylation)
  )
}
fn_methy_data_mongo <- function(cancer_types,methy){
  message(glue::glue('Handling {cancer_types} all methylation'))
  # transform data as mongo json format
  .x <- methy
  
  .x %>%
    dplyr::mutate(entrez = as.numeric(entrez)) %>% 
    dplyr::rename(gene_tag=gene) %>%
    dplyr::group_by(symbol,entrez,gene_tag) %>%
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
  .coll_name <- glue::glue('{.y}_all_methy')
  # collection
  .coll_methy <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  # insert data
  .coll_methy$drop()
  .coll_methy$insert(data = .dd)
  .coll_methy$index(add = '{"symbol": 1}')
  message(glue::glue('Insert methy data for {cancer_types} into {.coll_name}.'))
  
  # save the result
  .dd
}

# collection name TCGAname_all_expr
methy_data %>% 
  purrr::pmap(.f = fn_methy_data_mongo) ->
  all_methy_mongo_data

# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,"rda",'14-methy.rda'))
load(file.path(rda_path,"rda",'14-methy.rda'))