############### snv immune association into mongo ###############

# library -----------------------------------------------------------------

library(magrittr)


# data path ---------------------------------------------------------------

rda_path <- "/home/huff/github/GSCA/data"
data_path <- "/home/huff/data/GSCA/TIL"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))

# Load snv survival----------------------------------------------------------------
# immune_snv <- readr::read_rds(file.path(data_path,"pan33_ImmuneCellAI_cor_geneSNV.rds.gz"))

# Function ----------------------------------------------------------------

fn_snv_immune_mongo <-function(cancer_types,wilcox_res){
  .y <- cancer_types 
  .x <- data 
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_immune_cor_snv')
  .coll <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data=.x)
  .coll$index(add='{"symbol": 1}')
  
  message(glue::glue('Save all {.y} SNV immune cor into mongo'))

}

# data --------------------------------------------------------------------
filename <- dir(file.path(data_path,"snv_immune"))
immune_snv <- tibble::tibble()
for (file in filename) {
  data <- readr::read_rds(file.path(data_path,"snv_immune",file)) %>%
    dplyr::rename(symbol=Hugo_Symbol) %>%
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
  .tmp <- fn_snv_immune_mongo(cancertype,data)
  immune_snv <- rbind(data %>% dplyr::mutate(cancer_types=cancertype),immune_snv)
}
immune_snv %>%
  readr::write_rds(file.path(data_path,"pan33_ImmuneCellAI_wilcoxn_geneSNV.rds.gz"),compress = "gz")


# Save image --------------------------------------------------------------

save.image(file = 'data/rda/12-snv-survival.rda')