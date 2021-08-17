############### snv survival mongo ###############


# library -----------------------------------------------------------------

library(magrittr)


# data path ---------------------------------------------------------------

rda_path <- "/home/huff/github/GSCA/data"
data_path <- "/home/huff/data/GSCA/snv"
mongo_dump_path <- "/home/huff/data/GSCA/mongo_dump/2021-08-15_ClinicalRenew_dump"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load snv survival----------------------------------------------------------------
# file_list <- grep("*_survival.snv.rds.gz",dir(file.path(data_path,"cancer_snv_survival_v1")),value = TRUE)
# snv_survival <- tibble::tibble()
# for (file in file_list) {
#   .snv_survival <- readr::read_rds(file.path(data_path,"cancer_snv_survival_v1",file)) %>%
#     dplyr::mutate(cancer_types= strsplit(file,split = "_")[[1]][1]) 
#   if(nrow(snv_survival)<1){
#     snv_survival<-.snv_survival
#   } else {
#     rbind(snv_survival,.snv_survival) ->snv_survival
#   }
# }

# Function ----------------------------------------------------------------

fn_snv_survival_mongo <-function(cancer_types,data){
  .y <- cancer_types 
  .x <- data %>%
    dplyr::rename(symbol=Hugo_Symbol ,log_rank_p=logrankp,HR=hr) %>%
    dplyr::mutate(sur_type=toupper(sur_type))
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_snv_survival')
  .coll <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data=.x)
  .coll$index(add='{"symbol": 1}')
  .coll$export(file(file.path(mongo_dump_path,paste(.coll_name,"dump.json",sep="-"))))
  
  message(glue::glue('Save all {.y} SNV survival into mongo'))
  
  .x
}

# data --------------------------------------------------------------------
snv_survival <- readr::read_rds(file.path(data_path,"pan33_snv_survival_NEW_210813.rds.gz"))
groups <- tibble::tibble(higher_risk_of_death=c("Mutated","Non-mutated","Not applicable"),
               higher_risk_of_death_rename = c("Mutant","WT","Not applicable"))
snv_survival %>%
  dplyr::ungroup() %>%
  tidyr::unnest() %>%
  dplyr::mutate(higher_risk_of_death=ifelse(!is.na(higher_risk_of_death),higher_risk_of_death,"Not applicable")) %>%
  # dplyr::mutate(higher_risk_of_death=ifelse(`2_mutated`<2 ,"Not applicable(# of mutant < 2)",higher_risk_of_death)) %>%
  dplyr::inner_join(groups, by="higher_risk_of_death") %>%
  dplyr::select(-higher_risk_of_death,higher_risk_of_death=higher_risk_of_death_rename,WT=`1_nonmutated`,Mutant=`2_mutated`) %>%
  tidyr::nest(data = c(Hugo_Symbol, entrez, logrankp, cox_p, hr, higher_risk_of_death,Mutant,WT,sur_type)) %>%
  dplyr::arrange(cancer_types) %>%
  purrr::pmap(.f=fn_snv_survival_mongo) -> snv_survival_mongo_data

# Save image --------------------------------------------------------------

save.image(file = 'data/rda/12-snv-survival.rda')

