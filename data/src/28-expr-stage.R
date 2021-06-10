
# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"
data_path <- "/home/huff/data/GSCA/expr"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))


# Load data ----------------------------------------------------------------
pan25_expr_with_stage.rds.gz <- readr::read_rds(file.path(data_path,"pan25_expr_with_stage.rds.gz"))

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
  message(glue::glue('Insert data for {.y} into {.coll_name}.'))
  
  .d
}


# Tidy data ---------------------------------------------------------------

pan25_expr_with_stage.rds.gz %>% 
  purrr::pmap(.f = fn_transform_df)->
  expr_stage_nest_mongo_data

# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,"rda",'28-expr-stage.rda'))
