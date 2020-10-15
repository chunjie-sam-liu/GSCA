
# Library -----------------------------------------------------------------


library(magrittr)


# Conf --------------------------------------------------------------------
gsca_conf <- readr::read_lines(file = 'data/src/gsca.conf')

# Gene Symbol ------------------------------------------------------------------
gene_symbol <- readr::read_rds('/home/liucj/shiny-data/GSCALite/01_gene_symbol.rds.gz')

gene_symbol %>%
  tibble::enframe() %>%
  dplyr::rename(searchname = name, symbol = value) ->
  search_symbol

gsca_gene_symbol <- mongolite::mongo(collection = 'gene_symbol', url = gsca_conf)


# Insert search symbol ----------------------------------------------------


gsca_gene_symbol$insert(search_symbol)


# Id conversion -----------------------------------------------------------

gene_symbol_id <- readr::read_rds(path = '/home/liucj/shiny-data/GSCALite/id_correspond_between_NCBI_TCGA.rds.gz')

# Save image --------------------------------------------------------------

save.image(file = 'data/rda/01-gene-symbols.rda')
