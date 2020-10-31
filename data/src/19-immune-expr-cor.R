############### immune cell expr cor mongo ###################

# Library -----------------------------------------------------------------

library(magrittr)

# data path---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/TIL"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load data ----------------------------------------------------------------
immune_expr <- readr::read_rds(file.path(data_path,"pan33_ImmuneCellAI_cor_geneExp.rds.gz"))

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

fn_gene_tcga_all_cor_immune_expr <- function(cancer_types, cor) {
  .x <- cor
  .y <- cancer_types
  
  
  .x %>% 
    dplyr::rename(entrez=entrez_id,cor=estimate) %>% 
    dplyr::mutate(fdr=p.adjust(p.value, method = "fdr")) %>%
    dplyr::mutate(logfdr=-log10(fdr))%>%
    dplyr::mutate(logfdr=ifelse(logfdr>50,50,logfdr)) %>%
    dplyr::mutate(entrez=as.numeric(entrez)) %>%
    dplyr::select(-statistic,-alternative,-p.value) %>%
    dplyr::select(cell_type,entrez,symbol,cor,fdr,logfdr,method) %>%
    dplyr::group_by(entrez,symbol) %>%
    tidyr::nest() %>%
    dplyr::mutate(data = purrr::map(data,.f = fn_list_data)) %>%
    tidyr::unnest() %>%
    dplyr::ungroup() -> .dd
  
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_immune_cor_expr')
  .coll <-  mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data = .dd)
  .coll$index(add = '{"symbol": 1, "cell_type": 1}')
  
  message(glue::glue('Save all {.y} all immune expr cor into mongo'))
  
  .dd
}
# data --------------------------------------------------------------------
system.time(
immune_expr %>% 
  purrr::pmap(.f = fn_gene_tcga_all_cor_immune_expr) ->
  immune_expr_cor_mongo_data
)
# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/19-immune-expr-cor.rda'))
