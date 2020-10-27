########### SNV count ##############
# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"
data_path <- "/home/huff/data/GSCA/snv"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load snv count----------------------------------------------------------------

snv <- readr::read_rds(file.path(data_path,"gene_list_snv_count.IdTrans.rds.gz"))

# Function ----------------------------------------------------------------

fn_gene_tcga_snv_count <- function(cancer_types, n, snv) {
  .x <- snv
  .y <- cancer_types
  .z <- n
  
  .x %>%
    dplyr::rename(mutated_sample_size=sm_count,percentage=per) %>%
    dplyr::mutate(sample_size = .z) -> .d
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_snv_count')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .d )
  .coll$index(add = '{"symbol": 1}')
  
  message(glue::glue('Save all {.y} SNV count into mongo'))
  
  .x
}

# data --------------------------------------------------------------------

snv %>% head(1) %>%
  purrr::pmap(.f = fn_gene_tcga_snv_count) ->
  snv_count_mongo_data

# Save image --------------------------------------------------------------

save.image(file = 'data/rda/12-snv-count.rda')
