############### tcga clinical info (survival stage subtype metastasis progression) process ###################

# Library -----------------------------------------------------------------

library(magrittr)

# data path---------------------------------------------------------------

gsca_path <- file.path("/home/huff/data/GSCA")
rda_path <- "/home/huff/github/GSCA/data/"
mongo_dump_path <- "/home/huff/data/GSCA/mongo_dump"

# load data ---------------------------------------------------------------

clinical <- readr::read_rds(file.path(gsca_path,"clinical","pancan34_clinical_stage_survival_subtype.rds.gz"))

stage <- readr::read_rds(file.path(gsca_path,"clinical","Pancan.Merge.clinical-STAGE.rds.gz")) %>%
  dplyr::mutate(stage = purrr::map(stage, .f=function(.x){
    .x %>%
      dplyr::mutate(sample_name=toupper(barcode)) %>%
      dplyr::select(-barcode) %>%
      tidyr::gather(-sample_name,key="stage_type",value="stage")
  }))

survival <- readr::read_rds(file.path(gsca_path,"clinical","pancan33_survival_NEW.rds.gz"))

  
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
  tibble::tibble(
    sample_name = list(.x$sample_name),
    os_months = list(.x$os_months ),
    os_days = list(.x$os_days),
    os_status = list(.x$os_status),
    pfs_months = list(.x$pfs_months ),
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
  .coll$export(file(file.path(mongo_dump_path,"2021-08-15_ClinicalRenew_dump",paste(.coll_name,"dump.json",sep="-"))))
  
  message(glue::glue('Save all {.y} all survival data into mongo'))
  
  .dd
}
# import --------------------------------------------------------------------
system.time(
  survival %>%
    tidyr::unnest() %>%
    dplyr::mutate(os_months = os_days/30, pfs_months =pfs_days/30) %>%
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
  .coll$export(file(file.path(mongo_dump_path,"2021-08-15_ClinicalRenew_dump",paste(.coll_name,"dump.json",sep="-"))))
  
  message(glue::glue('Save all {.y} all stage data into mongo'))
  
  .dd
}

# import --------------------------------------------------------------------
stages_included <- tibble::tibble(stage=c("Stage I","Stage I","Stage I","Stage I","Stage I","Stage I","Stage I","Stage I",
                                          "Stage II","Stage II","Stage II","Stage II","Stage II","Stage II","Stage II","Stage II",
                                          "Stage III", "Stage III", "Stage III", "Stage III","Stage III","Stage III","Stage III",
                                          "Stage IV","Stage IV","Stage IV","Stage IV","Stage IV","Stage IV",
                                          "intermediate","poor","good"),
                                  stage_raw=c("stage i","stage ia","stage ib","stage ia1","stage ia2","stage ib1","stage ib2","stage ic",
                                              "stage ii","stage iia","stage iia1","stage iia2","stage iib","stage iic","iia","iib",
                                              "stage iii","stage iiia","stage iiib","stage iiic","iii","stage iiic1","stage iiic2",
                                              "stage iv","stage iva","stage ivb","stage ivc","iva","ivb",
                                              "intermediate","poor","good"))
system.time(
  stage %>%
    tidyr::unnest() %>%
    dplyr::rename("barcode"="sample_name") %>%
    dplyr::filter(stage_type %in% c("clinical_stage","igcccg_stage" ,"masaoka_stage","pathologic_stage")) %>%
    dplyr::mutate(class="all") %>%
    dplyr::filter(!is.na(stage)) %>%
    dplyr::mutate(stage_raw=stage) %>%
    dplyr::select(-stage) %>%
    dplyr::inner_join(stages_included,by="stage_raw") %>%
    dplyr::select(-stage_raw) %>%
    tidyr::nest(-class) %>%
    purrr::pmap(.f = fn_stage) ->
    stage_mongo_data
)
# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/27-clinical-info.rda'))
