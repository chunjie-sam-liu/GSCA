
# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"
data_path <- "/home/huff/data/GSCA/expr"
mongo_dump_path <- "/home/huff/data/GSCA/mongo_dump"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))


# Load data ----------------------------------------------------------------
pathologic_stage <- readr::read_rds(file.path(data_path,"pan21_expr_with_stage-210813.rds.gz")) %>%
  tidyr::unnest() %>%
  dplyr::mutate(stage_type="pathologic_stage")
clinical_stage <- readr::read_rds(file.path(data_path,"pan10_expr_with_ClinicalStage-210813.rds.gz")) %>%
  tidyr::unnest()%>%
  dplyr::mutate(stage_type="clinical_stage")
igcccg_stage <- readr::read_rds(file.path(data_path,"TGCT_expr_with_igcccgStage-210813.rds.gz")) %>%
  tidyr::unnest() %>%
  dplyr::rename(`Stage I (mean/n)`=`good (mean/n)`,`Stage II (mean/n)`=`intermediate (mean/n)`) %>%
  dplyr::mutate(`Stage I (mean/n)`=paste(`Stage I (mean/n)`,"(stage good)"),
                `Stage II (mean/n)`=paste(`Stage II (mean/n)`,"(stage intermediate)"),
                `Stage III (mean/n)`=NA,`Stage IV (mean/n)`=NA) %>%
  dplyr::mutate(stage_type="igcccg_stage")
masaoka_stage <- readr::read_rds(file.path(data_path,"TGCT_expr_with_masaokaStage-210813.rds.gz")) %>%
  tidyr::unnest()%>%
  dplyr::mutate(`Stage I (mean/n)`=NA) %>%
  dplyr::mutate(stage_type="masaoka_stage")

pathologic_stage %>%
  rbind(clinical_stage)%>%
  rbind(igcccg_stage)%>%
  rbind(masaoka_stage) %>%
  dplyr::group_by(cancer_types) %>%
  tidyr::nest() -> stage_expr

# Function ----------------------------------------------------------------
fn_transform_df <- function(cancer_types, data) {
  .x <- data
  .y <- cancer_types
  message(glue::glue('Handling stage for {.y}'))
  
  .x %>%
    dplyr::select(-method) %>%
    dplyr::mutate(entrez=as.numeric(entrez)) -> .d
  # collection
  .coll_name <- glue::glue('{.y}_expr_stage')
  .coll_expr <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  # insert data
  .coll_expr$drop()
  .coll_expr$insert(data = .d)
  .coll_expr$index(add = '{"symbol": 1}')
  .coll_expr$export(file(file.path(mongo_dump_path,"2021-08-15_ClinicalRenew_dump",paste(.coll_name,"dump.json",sep="-"))))
  
  message(glue::glue('Insert data for {.y} into {.coll_name}.'))
  
  .d
}


# Tidy data ---------------------------------------------------------------

stage_expr %>% 
  purrr::pmap(.f = fn_transform_df)->
  expr_stage_nest_mongo_data

# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,"rda",'28-expr-stage.rda'))
