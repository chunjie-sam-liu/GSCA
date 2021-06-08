############### immune cell expr cor mongo ###################

# Library -----------------------------------------------------------------

library(magrittr)

# data path---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/TIL"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load data ----------------------------------------------------------------
# immune_expr <- readr::read_rds(file.path(data_path,"pan33_ImmuneCellAI_cor_geneExp.rds.gz"))

# Function ----------------------------------------------------------------

fn_gene_tcga_all_cor_immune_expr <- function(cancer_types, cor) {
  .x <- cor
  .y <- cancer_types
  
  
  .x %>% 
    dplyr::mutate(entrez=as.numeric(entrez)) %>%
    dplyr::select(-statistic,-alternative) %>%
    dplyr::select(cell_type,entrez,symbol,cor,p.value,fdr,logfdr,method)-> .dd
  
  
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
filename <- dir(file.path(data_path,"expr_immune"))
immune_expr <- tibble::tibble()
for (file in filename) {
  data <- readr::read_rds(file.path(data_path,"expr_immune",file)) %>%
    dplyr::rename(entrez=entrez_id) %>% 
    dplyr::group_by(cell_type) %>%
    tidyr::nest() %>% 
    dplyr::mutate(data=purrr::map(data,.f=function(.x){
      .fdr=p.adjust(.x$p.value, method = "fdr")
      .x %>%
        dplyr::mutate(fdr=.fdr,logfdr=-log10(fdr))
    })) %>%
    tidyr::unnest() %>%
    dplyr::ungroup() 
  cancertype <- strsplit(file,split = "\\.")[[1]][1]
  .tmp <- fn_gene_tcga_all_cor_immune_expr(cancertype,data)
  # immune_expr <- rbind(data %>% dplyr::mutate(cancer_types=cancertype),immune_expr)
}
immune_expr %>%
  readr::write_rds(file.path(data_path,"pan33_ImmuneCellAI_spearmancor_geneExp.rds.gz"),compress = "gz")
# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/19-immune-expr-cor.rda'))
