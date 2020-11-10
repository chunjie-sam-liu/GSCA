############### tcga clinical info (survival stage subtype metastasis progression) process ###################

# Library -----------------------------------------------------------------

library(magrittr)

# data path---------------------------------------------------------------

gsca_path <- file.path("/home/huff/data/GSCA")
rda_path <- "/home/huff/github/GSCA/data/"

# load data ---------------------------------------------------------------

clinical <- readr::read_rds(file.path(gsca_path,"clinical","pancan34_clinical_stage_survival_subtype.rds.gz"))

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Function ----------------------------------------------------------------

# subtype -----------------------------------------------------------------

fn_list_subtype <- function(.x){
  tibble::tibble(
    sample_name = list(.x$barcode),
    subtype = list(.x$subtype)
  )
}

fn_subtype <- function(class, data) {
  .x <- data
  .y <- class
  
  
  .x %>% 
    tidyr::nest(-cancer_types) %>%
    dplyr::mutate(data=purrr::map(data,.f=fn_list_subtype)) %>%
    tidyr::unnest() %>%
    dplyr::ungroup() -> .dd
  
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_subtype')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"cancer_types": 1}')
  
  message(glue::glue('Save all {.y} all subtype data into mongo'))
  
  .dd
}
# import --------------------------------------------------------------------
system.time(
  clinical %>%
    dplyr::select(cancer_types,subtype,n.x) %>%
    tidyr::unnest() %>%
    dplyr::mutate(class="all") %>%
    tidyr::nest(-class) %>%
    purrr::pmap(.f = fn_subtype) ->
    fn_subtype_mongo_data
)

# survival ----------------------------------------------------------------

fn_list_survival <- function(.x){
  .x %>%
    dplyr::mutate(os_status=purrr::map(os_status,.f=function(.x){
      if(!is.na(.x)){
        ifelse(.x=="Dead",1,0)
      } else {
        NA
      }
    })) %>%
    dplyr::mutate(pfs_status =purrr::map(pfs_status,.f=function(.x){
      if(!is.na(.x)){
        ifelse(.x=="progression",1,0)
      } else {
        NA
      }
    })) %>%
    tidyr::unnest() -> .x
  tibble::tibble(
    sample_name = list(.x$barcode),
    os_days = list(.x$os_days),
    os_status = list(.x$os_status),
    pfs_days = list(.x$pfs_days),
    pfs_status = list(.x$pfs_status)
  )
}

fn_survival <- function(class, data) {
  .x <- data
  .y <- class
  
  
  .x %>% 
    tidyr::nest(-cancer_types) %>%
    dplyr::mutate(data=purrr::map(data,.f=fn_list_survival)) %>%
    tidyr::unnest() %>%
    dplyr::ungroup() -> .dd
  
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_survival')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"cancer_types": 1}')
  
  message(glue::glue('Save all {.y} all survival data into mongo'))
  
  .dd
}
# import --------------------------------------------------------------------
system.time(
  clinical %>%
    dplyr::select(cancer_types,survival,n.y) %>%
    tidyr::unnest() %>%
    dplyr::mutate(class="all") %>%
    tidyr::nest(-class) %>%
    purrr::pmap(.f = fn_survival) ->
    survival_mongo_data
)

# stage ----------------------------------------------------------------

fn_list_stage <- function(.x){
  tibble::tibble(
    sample_name = list(.x$barcode),
    stage = list(.x$stage),
    stage_type = list(.x$stage_type)
  )
}

fn_stage <- function(class, data) {
  .x <- data
  .y <- class
  
  
  .x %>% 
    tidyr::nest(-cancer_types) %>%
    dplyr::mutate(data=purrr::map(data,.f=fn_list_stage)) %>%
    tidyr::unnest() %>%
    dplyr::ungroup() -> .dd
  
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_stage')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"cancer_types": 1}')
  
  message(glue::glue('Save all {.y} all stage data into mongo'))
  
  .dd
}
# import --------------------------------------------------------------------
system.time(
  clinical %>%
    dplyr::select(cancer_types,stage) %>%
    tidyr::unnest() %>%
    dplyr::mutate(class="all") %>%
    tidyr::nest(-class) %>%
    purrr::pmap(.f = fn_stage) ->
    stage_mongo_data
)
# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/27-clinical-info.rda'))
