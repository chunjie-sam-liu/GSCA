############### immune cell methy cor mongo ###################

# Library -----------------------------------------------------------------

library(magrittr)

# data path---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/TIL"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load data ----------------------------------------------------------------
immune_methy <- readr::read_rds(file.path(data_path,"pan33_ImmuneCellAI_cor_genemethy.rds.gz"))

# Function ----------------------------------------------------------------

fn_list_data <- function(.x){
  tibble::tibble(
    cell_type = list(.x$cell_type),
    cor = list(.x$cor),
    fdr = list(.x$fdr),
    logfdr = list(.x$logfdr),
    method = list(.x$method)
  )
}

fn_gene_tcga_all_cor_immune_methy <- function(cancer_types, cor) {
  .x <- cor
  .y <- cancer_types
  
  
  .x %>% 
    dplyr::select(-statistic,-alternative,-p.value) %>%
    dplyr::mutate(entrez=as.numeric(entrez)) %>%
    dplyr::select(cell_type,entrez,symbol,gene_tag=gene,cor,fdr,logfdr,method) %>%
    dplyr::group_by(entrez,symbol) %>%
    tidyr::nest() %>%
    dplyr::mutate(data=purrr::map(data,.f=fn_list_data)) %>%
    tidyr::unnest() %>%
    dplyr::ungroup() -> .dd
  
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_immune_cor_methy')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"symbol": 1, "cell_type": 1}')
  
  message(glue::glue('Save all {.y} all immune methy cor into mongo'))
  
  .dd
}
# data --------------------------------------------------------------------
system.time(
  immune_methy %>% 
    purrr::pmap(.f = fn_gene_tcga_all_cor_immune_methy) ->
    immune_methy_cor_mongo_data
)
# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/21-immune-methy-cor.rda'))
