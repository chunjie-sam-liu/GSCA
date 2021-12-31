
# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"
mongo_dump_path <- "/home/huff/data/GSCA/mongo_dump/2021-09-15_ClinicalRenew_dump"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load expr survival----------------------------------------------------------------
# data_path <- "/home/huff/data/GSCA/expr/cancer_gene_survival_separate"
# file_list <- grep("*_survival.exp.rds.gz",dir(file.path(data_path)),value = TRUE)
# expr_survival <- tibble::tibble()
# for (file in file_list) {
#   .expr_survival <- readr::read_rds(file.path(data_path,file)) %>%
#     dplyr::mutate(cancer_types= strsplit(file,split = "_")[[1]][1]) %>%
#     dplyr::mutate(symbol= strsplit(file,split = "_")[[1]][2]) 
#   if(nrow(expr_survival)<1){
#     expr_survival<-.expr_survival
#   } else {
#     rbind(expr_survival,.expr_survival) -> expr_survival
#   }
# }
# expr_survival %>%
# dplyr::mutate(`hr_categorical(H/L)`=1/hr_categorical) %>%
#   dplyr::rename(`hr_categorical(L/H)`=hr_categorical) %>%
#   readr::write_rds(file.path("/home/huff/data/GSCA/expr/pan33_expr_survival.rds.gz"))

# expr_survival <- readr::read_rds(file = '/home/huff/data/GSCA/expr/pan33_expr_survival.rds.gz')
expr_survival_OsPfs <- readr::read_rds(file = '/home/huff/data/GSCA/expr/pan33_expr_survival_NEW210812.rds.gz') %>%
  tidyr::unnest() %>%
  dplyr::mutate(`hr_categorical(H/L)`=1/hr_categorical) %>%
  dplyr::rename(`hr_categorical(L/H)`=hr_categorical)
expr_survival_DssDfi <- readr::read_rds(file = '/home/huff/data/GSCA/expr/pan33_expr_DSS-DFI_survival_210914.rds.gz') %>%
  tidyr::unnest() %>%
  dplyr::mutate(`hr_categorical(H/L)`=1/hr_categorical) %>%
  dplyr::rename(`hr_categorical(L/H)`=hr_categorical)

expr_survival_OsPfs %>%
  rbind(expr_survival_DssDfi) ->expr_survival
# load(file = file.path(rda_path,"rda",'01-gene-symbols.rda'))
# 
# search_symbol <- search_symbol %>%
#   dplyr::mutate(entrez=as.character(entrez))


# # # Function ----------------------------------------------------------------
fn_transform_df <- function(cancertype, data) {
  .d <- data%>%
    dplyr::select(-`hr_categorical(L/H)`,-coxp_continus,-hr_continus)
  .y <- cancertype
  message(glue::glue('Handling expr survival for {.y}'))


  # collection
  .coll_name <- glue::glue('{.y}_expr_survival')
  .coll_expr <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  # insert data
  .coll_expr$drop()
  .coll_expr$insert(data = .d)
  .coll_expr$index(add = '{"symbol": 1}')
  .coll_expr$export(file(file.path(mongo_dump_path,paste(.coll_name,"dump.json",sep="-"))))
  message(glue::glue('Insert data for {.y} into {.coll_name}.'))

  .d
}
# 
# 
# # Tidy data ---------------------------------------------------------------
# 
expr_survival %>%
  dplyr::rename("cancertype"="cancer_types") %>%
  dplyr::mutate(sur_type=toupper(sur_type)) %>%
  dplyr::mutate(higher_risk_of_death =ifelse(is.na(higher_risk_of_death),"Not applicable",higher_risk_of_death)) %>%
  dplyr::mutate(logrankp=ifelse(logrankp==1,NA,logrankp)) %>% 
  dplyr::filter(!is.na(coxp_categorical)|!is.na(logrankp)|!is.na(coxp_continus)|!is.na(hr_continus)|!is.na(`hr_categorical(H/L)`)) %>%
  dplyr::group_by(cancertype) %>%
  tidyr::nest() %>%
  dplyr::ungroup() ->
  expr_survival_nest
# 
# 
expr_survival_nest %>%
  purrr::pmap(.f = fn_transform_df) ->
  expr_survival_nest_mongo_data


# 
# # Save image --------------------------------------------------------------
# 
save.image(file = file.path(rda_path,"rda",'04-sexpr-survival.rda'))
