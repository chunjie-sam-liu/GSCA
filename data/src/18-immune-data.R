############### immune cell data mongo ###################

# Library -----------------------------------------------------------------

library(magrittr)

# data path---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/TIL"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load data ----------------------------------------------------------------
immune_data <- readr::read_rds(file.path(data_path,"pan33_ImmuneCellAI.rds.gz"))

# Function ----------------------------------------------------------------

fn_transform_samples <- function(.x) {
  tibble::tibble(
    aliquot = list(.x$aliquot),
    barcode = list(.x$barcode),
    sample_name = list(.x$sample_name),
    TIL = list(.x$TIL)
  )
}

fn_gene_tcga_all_cor_methy_expr <- function(cancer_types, ImmuneCellAI) {
  .x <- ImmuneCellAI
  .y <- cancer_types
  
  
  .x %>% 
    tidyr::gather(-aliquot,-barcode, -sample_name,key="cell_type",value="TIL") %>%
    dplyr::group_by(cell_type) %>%
    tidyr::nest() %>%
    dplyr::mutate(data = purrr::map(data,fn_transform_samples)) %>%
    tidyr::unnest(data) %>%
    dplyr::ungroup() -> .dd
  
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_all_immune')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"cell_type": 1}')
  
  message(glue::glue('Save all {.y} all immune into mongo'))
  
  .dd
}
# data --------------------------------------------------------------------

immune_data %>% 
  purrr::pmap(.f = fn_gene_tcga_all_cor_methy_expr) ->
  immune_mongo_data

# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/18-immune-data.rda'))
