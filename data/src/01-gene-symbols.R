
# Library -----------------------------------------------------------------


library(magrittr)


# Conf --------------------------------------------------------------------
gsca_conf <- readr::read_lines(file = 'data/src/gsca.conf')

# Gene Symbol ------------------------------------------------------------------
# gene_symbol <- readr::read_rds('/home/huff/data/GSCA/id/NCBI_id_in_TCGA-final.rds.gz')
#gene_symbol %>%
#  dplyr::filter(!is.na(symbol)) %>% 
#  dplyr::distinct() %>% 
#  dplyr::mutate(searchname = gsub(pattern = '[^a-z0-9]',replacement = '', x = stringr::str_to_lower(symbol))) %>% 
#  dplyr::mutate(entrez = as.numeric(entrez)) ->
#  search_symbol
gene_symbol <- readr::read_tsv(file.path("/home/huff/data/gene_info/homo_sapines/NCBI/Homo_sapiens.gene_info.simplify"))
gene_symbol %>%
  dplyr::filter(!is.na(Symbol)) %>% 
  dplyr::distinct() %>% 
  dplyr::mutate(searchname = gsub(pattern = '[^a-z0-9]',replacement = '', x = stringr::str_to_lower(Symbol))) %>% 
  dplyr::mutate(entrez = as.numeric(GeneID)) ->
  search_symbol

expr_symbol <- readr::read_rds(file = '/home/huff/data/GSCA/expr/pancan14_expr_fc_pval.IdTrans.rds.gz') %>%
  dplyr::select(entrez, symbol) %>%
  unique()

cnv_symbol <- readr::read_rds(file = '/home/huff/data/GSCA/cnv/pancan34_cnv.IdTrans.rds.gz') %>%
  .$cnv %>% .[[1]] %>%
  dplyr::select(entrez, symbol) %>%
  unique()

snv_symbol <- readr::read_rds(file = '/home/huff/data/GSCA/snv/all_maf.snv_count_per.rds.gz') %>%
  tidyr::unnest() %>%
  dplyr::ungroup() %>%
  dplyr::select(entrez, symbol) %>%
  unique()
methy_symbol <- readr::read_rds(file = '/home/huff/data/GSCA/methy/pan14_allgene_methy_diff.IdTrans.rds.gz') %>%
  tidyr::unnest() %>%
  dplyr::ungroup() %>%
  dplyr::select(entrez, symbol) %>%
  unique()
expr_symbol %>%
  dplyr::mutate(entrez=as.numeric(entrez)) %>%
  dplyr::full_join(cnv_symbol,by=c("entrez","symbol"))%>%
  dplyr::full_join(snv_symbol,by=c("entrez","symbol")) %>%
  dplyr::full_join(methy_symbol,by=c("entrez","symbol")) -> all_genes_symbol

# symbols_name <- all_genes_symbol %>% dplyr::select(symbol) %>% unique() %>%dplyr::filter(!is.na(symbol))

search_symbol %>%
  dplyr::inner_join(all_genes_symbol,by="entrez") -> symbols_name
paste0(symbols_name$symbol,collapse = ",")
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
