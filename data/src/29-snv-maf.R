
# snv into mongo ----------------------------------------------------------


# Library -----------------------------------------------------------------

library(magrittr)

# data path ---------------------------------------------------------------

rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/methy"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))
# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"

maf_snv <- readr::read_rds(file = '/home/huff/data/GSCA/snv/all_maf_data.IdTrans.maf.tsv.rds.gz')

# Function ----------------------------------------------------------------
fn_transform_samples <- function(.x) {
  .x -> .y
  .y %>% 
    dplyr::rename(barcode = barcode16) %>% 
    dplyr::mutate(sample_name = substr(x = Tumor_Sample_Barcode, start = 1, stop = 12)) ->.yy
  y_names <- colnames(.yy)
  
  list_data <- tibble::tibble()
  for (i in 1:length(y_names)) {
    tibble::tibble(col=list(.yy %>% dplyr::select(y_names[i]) %>% as.data.frame() %>% array()%>% as.matrix() %>% .[,1])) -> .tmp
    if(i==1){
      .tmp -> list_data
    }else{
      rbind(list_data,.tmp)->list_data
    }
  }
  list_data %>%
    dplyr::mutate(colnames=y_names) %>%
    tidyr::spread(key="colnames",value="col")
}
fn_snv_mongo <-function(cancer_types,data){
  .y <- cancer_types 
  .d <- data %>% 
    dplyr::rename(symbol=Hugo_Symbol) %>%
    dplyr::group_by(entrez, symbol) %>% 
    tidyr::nest() %>% 
    dplyr::ungroup() 
  
  .df <- purrr::map_dfr(.x = .d$data, .f = fn_transform_samples)
  
  .d %>%
    dplyr::select(-data) %>%
    dplyr::ungroup() %>% 
    dplyr::bind_cols(.df) ->
    .dd
    
  # insert to collection
  .coll_name <- glue::glue('{.y}_snv_maf')
  .coll <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data=.dd)
  .coll$index(add='{"symbol": 1}')
  
  message(glue::glue('Save all {.y} SNV maf into mongo'))
  return(1)
}

# into mongo

maf_snv %>%
  tidyr::nest(-cancer_types) -> tmp

tmp %>% 
  dplyr::filter(!cancer_types %in% c("GBM","OV","LUAD","LUSC","PRAD","UCEC","BLCA","TGCT","ESCA","PAAD","KIRP","LIHC")) %>%
  purrr::pmap(.f = fn_snv_mongo) ->
  all_snv_mongo_data

# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,"rda",'29-snv-maf.rda'))
load(file.path(rda_path,"rda",'29-snv-maf.rda'))
