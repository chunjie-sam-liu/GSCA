
# Library -----------------------------------------------------------------


library(magrittr)


# Conf --------------------------------------------------------------------
gsca_conf <- readr::read_lines(file = 'data/src/gsca.conf')

# Gene Symbol ------------------------------------------------------------------
gene_symbol <- readr::read_rds('/home/huff/data/GSCA/id/NCBI_id_in_TCGA-final.rds.gz')

gene_symbol %>%
  dplyr::filter(!is.na(symbol)) %>% 
  dplyr::distinct() %>% 
  dplyr::mutate(searchname = gsub(pattern = '[^a-z0-9]',replacement = '', x = stringr::str_to_lower(symbol))) %>% 
  dplyr::mutate(entrez = as.numeric(entrez)) ->
  search_symbol

gsca_gene_symbol <- mongolite::mongo(collection = 'gene_symbol', url = gsca_conf)



# Insert search symbol ----------------------------------------------------

gsca_gene_symbol$drop()
gsca_gene_symbol$insert(search_symbol)
gsca_gene_symbol$count()
gsca_gene_symbol$find(limit = 5)


# Index searchname --------------------------------------------------------

system.time(gsca_gene_symbol$find(query = '{"searchname":"pten"}'))
gsca_gene_symbol$index(add = '{"searchname": 1}')
system.time(gsca_gene_symbol$find(query = '{"searchname":"pten"}'))

# Save image --------------------------------------------------------------

save.image(file = 'data/rda/01-gene-symbols.rda')
