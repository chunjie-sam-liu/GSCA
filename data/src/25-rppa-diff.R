############### rppa diff mongo ###################

# Library -----------------------------------------------------------------

library(magrittr)

# data path---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/rppa"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load data ----------------------------------------------------------------
pan32_gene_AIN_pval.IdTrans.rds.gz <- readr::read_rds(file.path(data_path,"pan32_gene_AIN_pval.IdTrans.rds.gz"))

# Function ----------------------------------------------------------------

fn_list_data <- function(.x){
  tibble::tibble(
    pathway = list(.x$pathway),
    diff = list(.x$diff),
    class = list(.x$class)
  )
}

fn_gene_tcga_all_cor_immune_methy <- function(cancer_types, diff_pval) {
  .x <- diff_pval
  .y <- cancer_types
  
  
  .x %>% 
    dplyr::mutate(entrez=as.numeric(entrez)) %>%
    dplyr::mutate(class = ifelse(fdr <= 0.05 & diff > 0, "Activation", "None")) %>% 
    dplyr::mutate(class = ifelse(fdr <= 0.05 & diff < 0, "Inhibition", class)) %>% 
    dplyr::select(entrez,symbol,pathway,diff,class) %>%
    dplyr::group_by(entrez,symbol) %>%
    tidyr::nest() %>%
    dplyr::mutate(data=purrr::map(data,.f=fn_list_data)) %>%
    tidyr::unnest() %>%
    dplyr::ungroup() -> .dd
  
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_rppa_diff')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"symbol": 1, "pathway": 1}')
  
  message(glue::glue('Save all {.y} all rppa diff into mongo'))
  
  .dd
}
# data --------------------------------------------------------------------
system.time(
  pan32_gene_AIN_pval.IdTrans.rds.gz %>% 
    purrr::pmap(.f = fn_gene_tcga_all_cor_immune_methy) ->
    rppa_diff_mongo_data
)
# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/25-rppa-diff.rda'))
