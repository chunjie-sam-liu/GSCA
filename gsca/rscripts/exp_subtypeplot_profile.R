# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

search_str = 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KIRC_expr_subtype#LUAD_expr_subtype#LUSC_expr_subtype'
filepath = '/home/huff/github/GSCA/gsca/resource/pngs/5579084c-505e-4a23-832d-3b95ae50758a.png'
apppath = '/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca/rscripts/gsca.conf'))

# Query data --------------------------------------------------------------

fetched_data <- purrr::map(.x = search_cancertypes, .f = fn_fetch_mongo) %>% dplyr::bind_rows()

# Sort --------------------------------------------------------------------

fetched_data_clean_pattern <- fn_get_pattern(.x = fetched_data)
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern)
gene_rank <- fn_get_gene_rank(.x = fetched_data_clean_pattern)

for_plot <- fn_pval_label(fetched_data)