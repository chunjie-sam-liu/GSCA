############### methy exp cor mongo ###################

# Library -----------------------------------------------------------------

library(magrittr)

# data path---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/methy"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load data ----------------------------------------------------------------
methy_expr <- readr::read_rds(file.path(data_path,"pancan34_all_gene_exp_cor_meth.IdTrans.rds.gz"))

# Function ----------------------------------------------------------------

fn_gene_tcga_all_cor_methy_expr <- function(cancer_types, methy) {
  .x <- methy
  .y <- cancer_types
  
  
  .x %>% 
    dplyr::mutate(fdr = 1/10^logfdr) %>% 
    dplyr::select(entrez, symbol, spm, fdr, logfdr) -> 
    .dd
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_methy_cor_expr')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"symbol": 1}')
  
  message(glue::glue('Save all {.y} methy cor expr into mongo'))
  
  .dd
}
# data --------------------------------------------------------------------

methy_expr %>% 
  purrr::pmap(.f = fn_gene_tcga_all_cor_methy_expr) ->
  methy_expr_cor_mongo_data

# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/17-methy_expr_cor.rda'))
