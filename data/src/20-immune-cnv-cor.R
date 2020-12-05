############### immune cell cnv cor mongo ###################

# Library -----------------------------------------------------------------

library(magrittr)

# data path---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/TIL"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load data ----------------------------------------------------------------
immune_cnv <- readr::read_rds(file.path(data_path,"pan33_ImmuneCellAI_cor_geneCNV.rds.gz"))

# Function ----------------------------------------------------------------
fn_gene_tcga_all_cor_immune_cnv <- function(cancer_types, data) {
  .x <- data
  .y <- cancer_types
  
  .x %>% 
    dplyr::filter(method=="Spearman's rank correlation rho") %>%
    dplyr::group_by(cell_type) %>%
    tidyr::nest() %>% 
    dplyr::mutate(data=purrr::map(data,.f=function(.x){
      .fdr=p.adjust(.x$p.value, method = "fdr")
      .x %>%
        dplyr::mutate(fdr=.fdr)
    })) %>%
    tidyr::unnest() %>%
    dplyr::ungroup() %>%
    dplyr::mutate(entrez=as.numeric(entrez)) %>%
    dplyr::select(-statistic) %>%
    dplyr::select(cell_type,entrez,symbol,cor,p.value,fdr,method) -> .dd
  
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_immune_cor_cnv')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"symbol": 1, "cell_type": 1}')
  
  message(glue::glue('Save all {.y} all immune cnv cor into mongo'))

}
# data --------------------------------------------------------------------
system.time(
  immune_cnv %>% 
    purrr::pmap(.f = fn_gene_tcga_all_cor_immune_cnv) ->
    immune_cnv_cor_mongo_data
)
# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/20-immune-cnv-cor.rda'))
