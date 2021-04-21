############### rppa diff mongo ###################

# Library -----------------------------------------------------------------

library(magrittr)

# data path---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCALite/TCGA/rppa"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load data ----------------------------------------------------------------
rppa_score <- readr::read_rds(file.path(data_path,"pancan32-rppa-score.rds.gz"))

# Function ----------------------------------------------------------------

fn_list_data <- function(.x){
  tibble::tibble(
    barcode = list(.x$barcode),
    pathway = list(.x$pathway),
    score = list(.x$score)
  )
}

fn_gene_tcga_all_cor_immune_methy <- function(class, data) {
  .x <- data
  .y <- class
  
  
  .x %>% 
    tidyr::nest(-cancer_types) %>%
    dplyr::mutate(data=purrr::map(data,.f=fn_list_data)) %>%
    tidyr::unnest()-> .dd
  
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_rppa_score')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"cancer_types": 1}')
  
  message(glue::glue('Save all {.y} all rppa score into mongo'))
  
  .dd
}
# data --------------------------------------------------------------------
system.time(
  rppa_score %>% 
    tidyr::unnest() %>%
    dplyr::mutate(class="all") %>%
    tidyr::nest(-class) %>%
    purrr::pmap(.f = fn_gene_tcga_all_cor_immune_methy) ->
    rppa_score_mongo_data
)
# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/25-rppa-diff.rda'))
