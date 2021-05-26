############### methy diff mongo ###################

# library -----------------------------------------------------------------

library(magrittr)


# data path ---------------------------------------------------------------

rda_path <- "/home/huff/github/GSCA/data/"
data_path <- "/home/huff/data/GSCA/methy"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))


# load methy data ---------------------------------------------------------

methy_diff <- readr::read_rds(file.path(data_path,"pan14_allgene_methy_diff.IdTrans.rds.gz"))


# function ----------------------------------------------------------------

fn_methy_diff_mongo <-function(cancer_types,methy){
  .y <- cancer_types 
  .fdr <- p.adjust(methy$p_val,method = "fdr")
  .x <- methy %>%
    dplyr::rename(fc=diff,gene_tag=gene,trend=direction,pval=p_val) %>%
    dplyr::mutate(fdr=.fdr)
  
  # insert to collection
  .coll_name <- glue::glue('{.y}_methy_diff')
  .coll <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  
  .coll$drop()
  .coll$insert(data=.x)
  .coll$index(add='{"symbol": 1}')
  
  message(glue::glue('Save all {.y} methy diff into mongo'))
  
  .x
}

# data --------------------------------------------------------------------
methy_diff %>%
  purrr::pmap(.f=fn_methy_diff_mongo) -> methy_diff_mongo_data

# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,'rda/12-methy_diff.rda'))
