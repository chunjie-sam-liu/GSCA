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
    tidyr::gather(key = 'aliquot', value = 'expr') ->
    .y
}
fn_methy_data_mongo <- function(cancer_types,methy){
  message(glue::glue('Handling {cancer_types} all methylation'))
  # transform data as mongo json format
  .x <- methy
  
  .x %>%
    tidyr::gather(-entrez, -symbol, -gene,key="barcode") %>% 
    dplyr::mutate(entrez = as.numeric(entrez)) %>% 
    tidyr::nest() -> 
    .d
  
  .df <- purrr::map_dfr(.x = .d$data, .f = fn_transform_samples)
}
