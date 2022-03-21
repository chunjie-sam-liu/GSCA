############### methy survival mongo ###################

# library -----------------------------------------------------------------

library(magrittr)


# data path ---------------------------------------------------------------

rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/methy"
mongo_dump_path <- "/home/huff/data/GSCA/mongo_dump/2021-09-15_ClinicalRenew_dump"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))


# load methy data ---------------------------------------------------------

methy_survival_OsPfs <- readr::read_rds(file.path(data_path,"pan33_methy_survival_NEW211108.rds.gz")) %>%
  dplyr::mutate(data = purrr::map(data,.f=function(.x){
    .x %>%
      dplyr::mutate(tag = strsplit(as.character(gene),"_")[[1]][1], 
                    sur_type=toupper(sur_type), 
                    coxP=coxp_categorical,
                    logRankP=logrankp,
                    HR=1/hr_categorical
                    ) %>%
      dplyr::ungroup() %>%
      dplyr::select(entrez, symbol,tag,logRankP,coxP,HR,sur_type,higher_risk_of_death)
  })) %>%
  tidyr::unnest()

methy_survival_DssDfi <- readr::read_rds(file.path(data_path,"pan33_methy_DSS-DFI_survival_211108.rds.gz")) %>%
  dplyr::mutate(data = purrr::map(data,.f=function(.x){
    .x %>%
      dplyr::mutate(tag = strsplit(as.character(gene),"_")[[1]][1], 
                    sur_type=toupper(sur_type), 
                    coxP=coxp_categorical,
                    logRankP=logrankp,
                    HR=1/hr_categorical
      ) %>%
      dplyr::ungroup() %>%
      dplyr::select(entrez, symbol,tag,logRankP,coxP,HR,sur_type,higher_risk_of_death)
  }))%>%
  tidyr::unnest()
methy_survival_OsPfs %>%
  rbind(methy_survival_DssDfi) ->methy_survival
# function ----------------------------------------------------------------

fn_methy_survival_mongo <-function(cancer_types,data){
  .y <- cancer_types 
  .x <- data %>%
    dplyr::rename(cox_p=coxP,log_rank_p=logRankP)
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_methy_survival')
  .coll <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data=.x)
  .coll$index(add='{"symbol": 1}')
  .coll$export(file(file.path(mongo_dump_path,paste(.coll_name,"dump.json",sep="-"))))
  
  message(glue::glue('Save all {.y} methy survival into mongo'))
  
  .x
}

# data --------------------------------------------------------------------
methy_survival %>%
  dplyr::filter(!is.na(logRankP)) %>%
  tidyr::nest(-cancer_types) %>%
  purrr::pmap(.f=fn_methy_survival_mongo) -> methy_survival_mongo_data

# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/16-methy_survival.rda'))

