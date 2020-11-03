############### snv survival mongo ###############


# library -----------------------------------------------------------------

library(magrittr)


# data path ---------------------------------------------------------------

rda_path <- "/home/huff/github/GSCA/data"
data_path <- "/home/huff/data/GSCA/snv"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load snv survival----------------------------------------------------------------

snv_survival <- readr::read_rds(file.path(data_path,"pancan32_snv_survival_genelist_sig_pval.IdTrans.rds.gz"))


# Function ----------------------------------------------------------------

fn_snv_survival_mongo <-function(cancer_types,snv_survival){
  .y <- cancer_types 
  .x <- snv_survival %>%
    dplyr::rename(higher_risk_of_death=worse,cox_p=coxP,log_rank_p=logRankP) %>%
    dplyr::mutate(higher_risk_of_death=ifelse(higher_risk_of_death=="High","Mutated","Non-mutated")) %>%
    dplyr::mutate(HR = exp(estimate))
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_snv_survival')
  .coll <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data=.x)
  .coll$index(add='{"symbol": 1}')
  
  message(glue::glue('Save all {.y} SNV survival into mongo'))
  
  .x
}

# data --------------------------------------------------------------------
snv_survival %>%
  purrr::pmap(.f=fn_snv_survival_mongo) -> snv_survival_mongo_data

# Save image --------------------------------------------------------------

save.image(file = 'data/rda/12-snv-survival.rda')

