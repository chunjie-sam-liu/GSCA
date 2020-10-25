# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"
gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load cnv ----------------------------------------------------------------
cnv_percent <- readr::read_rds(file = '/home/huff/data/GSCA/mutation/cnv/pancan34_cnv_percent.IdTrans.rds.gz')


# Function ----------------------------------------------------------------

fn_gene_tcga_cnv_percent <- function(cancer_types, cnv) {
  .x <- cnv
  .y <- cancer_types
  
  
  .x 
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_cnv_percent')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .x )
  .coll$index(add = '{"symbol": 1}')
  
  message(glue::glue('Save all {.y} CNV percent into mongo'))
  
  .x
}


# data --------------------------------------------------------------------

cnv_percent %>% 
  purrr::pmap(.f = fn_gene_tcga_cnv_percent) ->
  cnv_percent_mongo_data

# Save image --------------------------------------------------------------

save.image(file = 'data/rda/10-cnv-percent.rda')
