############### CTRP drug mongo ###################

# Library -----------------------------------------------------------------

library(magrittr)

# data path---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/drug"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load data ----------------------------------------------------------------
ctrp_exp <- readr::read_rds(file.path(data_path,"ctrp_exp_spearman.IdTrans.rds.gz"))

# Function ----------------------------------------------------------------

fn_gene_tcga_all_cor_immune_methy <- function(cancer_types,data) {
  .x <- data
  .y <- cancer_types
  
  
  .x %>% 
    dplyr::rename(entrez=entrez_id,drug=drug_name,cor=cor_sprm,) %>%
    dplyr::mutate(entrez=as.numeric(entrez)) -> .dd
  
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_ctrp_cor_expr')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"symbol": 1, "drug":1}')
  
  message(glue::glue('Save all {.y} all ctrp expr cor into mongo'))
  
  .dd
}
# data --------------------------------------------------------------------
system.time(
  ctrp_exp %>% 
    tidyr::unnest() %>%
    dplyr::mutate(cancer_types="all") %>%
    dplyr::group_by(drug_name) %>%
    tidyr::nest() %>%
    dplyr::mutate(fdr = purrr::map(data,.f=function(.x){
      p.adjust(.x$p_val,method = "fdr")
    })) %>%
    tidyr::unnest() %>%
    tidyr::nest(-cancer_types) %>%
    purrr::pmap(.f = fn_gene_tcga_all_cor_immune_methy) ->
    ctrp_exp_cor_mongo_data
)
# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/23-ctrp-expr-cor.rda'))
