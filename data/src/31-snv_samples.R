############### samples with snv into mongo ###############

# library -----------------------------------------------------------------

library(magrittr)


# data path ---------------------------------------------------------------

rda_path <- "/home/huff/github/GSCA/data"
data_path <- "/home/huff/data/GSCA/TIL"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load data ----------------------------------------------------------------
sample_with_snv <- readr::read_rds(file.path(data_path,"pancan33_sample_with_snv.rds.gz"))

# subtype -----------------------------------------------------------------

fn_list_subtype <- function(.x){
  tibble::tibble(
    barcode = list(.x$sample_with_snv)
  )
}

fn_mongo <- function(class, data) {
  .x <- data
  .y <- class
  
  
  .x %>% 
    tidyr::nest(-cancer_types) %>%
    dplyr::mutate(data=purrr::map(data,.f=fn_list_subtype)) %>%
    tidyr::unnest() %>%
    dplyr::ungroup() -> .dd
  
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_samples_with_snv')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"cancer_types": 1}')
  
  message(glue::glue('Save all {.y} all subtype data into mongo'))
  
  .dd
}
# import --------------------------------------------------------------------
system.time(
  sample_with_snv %>%
    tidyr::unnest() %>%
    dplyr::mutate(class="all") %>%
    tidyr::nest(-class) %>%
    purrr::pmap(.f = fn_mongo) ->
    fn_subtype_mongo_data
)
