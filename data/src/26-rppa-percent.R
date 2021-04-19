############### rppa percentage mongo ###################

# Library -----------------------------------------------------------------

library(magrittr)

# data path---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/rppa"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load data ----------------------------------------------------------------
pan32_gene_activate.inhibit_pathway_percent.IdTrans.rds.gz <- readr::read_rds(file.path(data_path,"pan32_gene_activate.inhibit_pathway_percent.IdTrans.rds.gz"))

# Function ----------------------------------------------------------------

fn_list_data <- function(.x){
  tibble::tibble(
    pathway = list(.x$pathway),
    activated = list(.x$a),
    inhibited = list(.x$i),
    not_significant = list(.x$n)
  )
}

fn_gene_tcga_all_cor_immune_methy <- function(cancer_types, data) {
  .x <- data
  .y <- cancer_types
  
  
  .x %>% 
    tidyr::nest(-symbol,-entrez) %>%
    dplyr::mutate(data=purrr::map(data,.f=fn_list_data)) %>%
    tidyr::unnest() %>%
    dplyr::ungroup() -> .dd
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_rppa_percent')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"symbol": 1}')
  
  message(glue::glue('Save all {.y} all rppa percent into mongo'))
  
  .dd
}
# data --------------------------------------------------------------------
system.time(
  pan32_gene_activate.inhibit_pathway_percent.IdTrans.rds.gz %>% 
    dplyr::mutate(cancer_types="all") %>%
    tidyr::unnest() %>%
    dplyr::mutate(entrez=as.numeric(entrez)) %>%
    tidyr::nest(-cancer_types) %>%
    purrr::pmap(.f = fn_gene_tcga_all_cor_immune_methy) ->
    rppa_percent_mongo_data
)
# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/26-rppa-percent.rda'))
