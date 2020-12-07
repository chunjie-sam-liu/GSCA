# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"
gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

cnv_symbol_search_symbol_final <- readr::read_rds(file = 'data/rda/cnv_symbol_search_symbol_final.rds.gz') %>% 
  dplyr::select(entrez, symbol)

# Load cnv ----------------------------------------------------------------
cnv_expr <- readr::read_rds(file = '/home/huff/data/GSCA/mutation/cnv/pancan34_all_exp-cor-cnv.NEW.IdTrans.rds.gz')

# Function ----------------------------------------------------------------

fn_gene_tcga_all_cor_cnv_expr <- function(cancer_types, spm) {
  .x <- spm
  .y <- cancer_types
  
  .fdr <- p.adjust(.x$fdr,method = "fdr")
  .x %>% 
    dplyr::left_join(cnv_symbol_search_symbol_final, by = 'symbol') %>% 
    dplyr::mutate(fdr = .fdr) %>%
    dplyr::mutate(logfdr = -log10(fdr)) %>% 
    dplyr::select(entrez, symbol, spm, fdr, logfdr) -> 
    .dd
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_cnv_cor_expr')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"symbol": 1}')
  
  message(glue::glue('Save all {.y} CNV cor expr into mongo'))
  
  .dd
}
# data --------------------------------------------------------------------



cnv_expr %>% 
  purrr::pmap(.f = fn_gene_tcga_all_cor_cnv_expr) ->
  cnv_expr_cor_mongo_data

# Save image --------------------------------------------------------------

save.image(file = 'data/rda/09-cnv-expr.rda')