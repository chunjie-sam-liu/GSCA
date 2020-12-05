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

fn_gene_tcga_all_cor_immune_methy <- function(cancer_types, cor) {
  .x <- cor
  .y <- cancer_types
  
  
  .x %>% 
    dplyr::mutate(entrez=as.numeric(entrez)) %>%
    dplyr::select(-statistic,-alternative) %>%
    dplyr::select(cell_type,entrez,symbol,cor,p.value,fdr,logfdr,method)-> .dd
  
  
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
filename <- dir(file.path(data_path,"methy_immune"))
immune_methy <- tibble::tibble()
for (file in filename) {
  data <- readr::read_rds(file.path(data_path,"methy_immune",file)) %>%
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
  .tmp <- fn_gene_tcga_all_cor_immune_methy(cancertype,data)
  immune_methy <- rbind(data %>% dplyr::mutate(cancer_types=cancertype),immune_methy)
}
immune_methy %>%
  readr::write_rds(file.path(data_path,"pan33_ImmuneCellAI_spearmancor_geneMethy.rds.gz"),compress = "gz")
# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/21-immune-methy-cor.rda'))
