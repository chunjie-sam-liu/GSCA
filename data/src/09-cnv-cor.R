
# save cnv correlation with gene expression data into mongo ---------------


# library -----------------------------------------------------------------

library(magrittr)


# load darta --------------------------------------------------------------

rda_path <- "/home/huff/github/GSCA/data"
# load(file = file.path(rda_path,"rda",'01-gene-symbols.rda'))
gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))
cnv_symbol_search_symbol_final <- readr::read_rds(file = 'data/rda/cnv_symbol_search_symbol_final.rds.gz') %>% 
  dplyr::select(cnvsymbol, entrez, symbol)


# load cor between exp ----------------------------------------------------

cnv_cor <- readr::read_rds("/home/huff/data/GSCALite/TCGA/cnv/pancan34_all_gene_exp-cor-cnv.rds.gz")


# symbol filter -----------------------------------------------------------


