
############### # cnv survival into mongo - ###############

# library -----------------------------------------------------------------

library(magrittr)


# data path ---------------------------------------------------------------

rda_path <- "/home/huff/github/GSCA/data"
data_path <- "/home/huff/data/GSCA/cnv"
mongo_dump_path <- "/home/huff/data/GSCA/mongo_dump/2021-09-15_ClinicalRenew_dump"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load cnv survival----------------------------------------------------------------
#### Old
# file_list <- grep("*_survival.cnv.rds.gz",dir(file.path(data_path,"cancer_cnv_survival_201201")),value = TRUE)
# cnv_survival <- tibble::tibble()
# for (file in file_list) {
#   .cnv_survival <- readr::read_rds(file.path(data_path,"cancer_cnv_survival",file)) %>%
#     dplyr::mutate(cancer_types= strsplit(file,split = "_")[[1]][1])
#   if(nrow(cnv_survival)<1){
#     cnv_survival<-.cnv_survival
#   } else {
#     rbind(cnv_survival,.cnv_survival) ->cnv_survival
#   }
# }
### New
cnv_survival_OsPfs <- readr::read_rds(file.path(data_path,"pan33_cnv_survival_NEW210813.rds.gz")) %>%
  dplyr::mutate(data = purrr::map(data,.f=function(.x){
    .x %>%
      dplyr::select(-coxp)
  })) %>%
  tidyr::unnest()
cnv_survival_DssDfi <- readr::read_rds(file.path(data_path,"pan33_cnv_DSS-DFI_survival_210914.rds.gz"))%>%
  dplyr::mutate(data = purrr::map(data,.f=function(.x){
    .x %>%
      dplyr::select(-coxp)
  })) %>%
  tidyr::unnest()
cnv_survival_OsPfs %>%
  rbind(cnv_survival_DssDfi) %>%
  tidyr::nest(-cancer_types) -> cnv_survival    

# Function ----------------------------------------------------------------
fn_cnv_survival_mongo <-function(cancer_types,data){
  .y <- cancer_types 
  .x <- data %>%
    dplyr::mutate(entrez =as.numeric(entrez))%>%
    dplyr::rename(log_rank_p=logrankp) %>%
    dplyr::mutate(sur_type=toupper(sur_type))
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_cnv_survival')
  .coll <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data=.x)
  .coll$index(add='{"symbol": 1}')
  .coll$export(file(file.path(mongo_dump_path,paste(.coll_name,"dump.json",sep="-"))))
  
  message(glue::glue('Save all {.y} cnv survival into mongo'))
}

# data --------------------------------------------------------------------
cnv_survival %>%
  purrr::pmap(.f=fn_cnv_survival_mongo) -> cnv_survival_mongo_data

# Save image --------------------------------------------------------------

save.image(file = 'data/rda/12-cnv-survival.rda')

