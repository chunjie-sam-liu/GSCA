############### methy survival mongo ###################

# library -----------------------------------------------------------------

library(magrittr)


# data path ---------------------------------------------------------------

rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/methy"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))


# load methy data ---------------------------------------------------------

methy_survival <- readr::read_rds(file.path(data_path,"pancan32_meth_survival.IdTrans.rds.gz"))


# function ----------------------------------------------------------------

fn_methy_survival_mongo <-function(cancer_types,methy){
  .y <- cancer_types 
  .x <- methy %>%
    dplyr::rename(higher_risk_of_death=Hyper_worse,cox_p=coxP,log_rank_p=logRankP) %>%
    dplyr::mutate(higher_risk_of_death=ifelse(higher_risk_of_death=="High","Hypermethylation","Hypomethylation")) 
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_methy_survival')
  .coll <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data=.x)
  .coll$index(add='{"symbol": 1}')
  
  message(glue::glue('Save all {.y} methy survival into mongo'))
  
  .x
}

# data --------------------------------------------------------------------
methy_survival %>%
  purrr::pmap(.f=fn_methy_survival_mongo) -> methy_survival_mongo_data

# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/16-methy_survival.rda'))

