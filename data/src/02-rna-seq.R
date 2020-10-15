
# Library -----------------------------------------------------------------

library(magrittr)

d <- readr::read_rds('/home/liucj/shiny-data/GSCALite/id_correspond_between_NCBI_TCGA.rds.gz')

dd <- readr::read_rds('/home/liucj/shiny-data/GSCALite/TCGA/expr/pancan33_expr.rds.gz')


ddd <- readr::read_rds('/home/liucj/shiny-data/GSCALite/TCGA/expr/pancan33_expr_filtered.rds.gz')

dddd <- readr::read_rds('/home/liucj/shiny-data/GSCALite/TCGA/expr/pancan14_expr_fc_pval.rds.gz')

dddd %>% 
  dplyr::filter(symbol != '?')
