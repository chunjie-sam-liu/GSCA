
############### # cnv survival into mongo - ###############

# library -----------------------------------------------------------------

library(magrittr)


# data path ---------------------------------------------------------------

rda_path <- "/home/huff/github/GSCA/data"
data_path <- "/home/huff/data/GSCA/cnv"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load cnv survival----------------------------------------------------------------
file_list <- grep("*_survival.cnv.rds.gz",dir(file.path(data_path,"cancer_cnv_survival")),value = TRUE)
cnv_survival <- tibble::tibble()
for (file in file_list) {
  .cnv_survival <- readr::read_rds(file.path(data_path,"cancer_cnv_survival",file)) %>%
    dplyr::mutate(cancer_types= strsplit(file,split = "_")[[1]][1])
  if(nrow(cnv_survival)<1){
    cnv_survival<-.cnv_survival
  } else {
    rbind(cnv_survival,.cnv_survival) ->cnv_survival
  }
}

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
  
  message(glue::glue('Save all {.y} cnv survival into mongo'))
}

# data --------------------------------------------------------------------
cnv_survival %>%
  tidyr::nest(-cancer_types) %>%
  purrr::pmap(.f=fn_cnv_survival_mongo) -> cnv_survival_mongo_data

# Save image --------------------------------------------------------------

save.image(file = 'data/rda/12-cnv-survival.rda')

