
# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"


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

expr_survival <- readr::read_rds(file = '/home/huff/data/GSCA/expr/pan33_expr_survival.rds.gz')

# load(file = file.path(rda_path,"rda",'01-gene-symbols.rda'))
# 
# search_symbol <- search_symbol
# 
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
