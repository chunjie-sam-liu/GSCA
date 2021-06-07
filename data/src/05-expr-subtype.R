
# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"

expr_subtype <- readr::read_rds(file = '/home/huff/data/GSCA/expr/expr_subtype.NEW.IdTrans.rds.gz')
load(file = file.path(rda_path,"rda",'01-gene-symbols.rda'))
gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))


search_symbol <- search_symbol

# Function ----------------------------------------------------------------
fn_transform_df <- function(cancer_types, data) {
  .x <- data
  .y <- cancer_types
  message(glue::glue('Handling DEG for {.y}'))
  .fdr <- p.adjust(.x$p.value,method = "fdr")
  .x %>% 
    dplyr::mutate(fdr=.fdr) %>%
    dplyr::rename(
      pval = p.value
    ) %>%
    dplyr::filter(symbol %in% search_symbol$symbol) %>%
    dplyr::mutate(entrez = as.numeric(entrez_id)) %>%
    dplyr::select(-entrez_id)->
    .d
  
  # collection
  .coll_name <- glue::glue('{.y}_expr_subtype')
  .coll_expr <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  # insert data
  .coll_expr$drop()
  .coll_expr$insert(data = .d)
  .coll_expr$index(add = '{"symbol": 1}')
  message(glue::glue('Insert data for {.y} into {.coll_name}.'))
  
  .d
}


# Tidy data ---------------------------------------------------------------

expr_subtype %>% 
  purrr::pmap(.f = fn_transform_df) ->
  expr_subtype_nest_mongo_data

# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,"rda",'05-expr-subtype.rda'))
