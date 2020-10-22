
# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"
load(file = file.path(rda_path,"rda",'01-gene-symbols.rda'))
gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))


search_symbol <- search_symbol
ncbi_name <- 
  readr::read_tsv(file = '/home/huff/data/gene_info/homo_sapines/NCBI/Homo_sapiens.gene_info') %>% 
  dplyr::filter(`#tax_id` == 9606) %>% 
  dplyr::mutate(Synonyms = stringr::str_to_lower(string = Synonyms)) %>% 
  dplyr::rename(entrez = GeneID, symbol = Symbol, biotype = type_of_gene) %>% 
  dplyr::mutate(searchname = stringr::str_to_lower(string = symbol)) %>% 
  dplyr::mutate(ensembl = purrr::map_chr(.x = dbXrefs, .f = function(.x) {
    print(.x)
    if (!grepl(pattern = 'Ensembl', x = .x)) return(NA)
    
    .x %>% strsplit(split = '\\|') %>% .[[1]] -> .xx
    paste0(gsub(pattern = 'Ensembl:', replacement = '', x = .xx[stringr::str_detect(string = .xx, pattern = 'Ensembl:')]), collapse = '|')
  })) %>% 
  dplyr::select(entrez, symbol, description, biotype, ensembl, searchname, Synonyms) %>% 
  dplyr::mutate(Synonyms = purrr::map2(.x = searchname, .y = Synonyms, .f = function(.x, .y) {
    c(.x, strsplit(x = .y, split = '\\|')[[1]]) %>% unique()
  }))

readr::write_rds(x = ncbi_name, file = 'data/rda/ncbi_name.rds.gz', compress = 'gz')

cnv <- readr::read_rds(file = '/home/liucj/shiny-data/GSCALite/TCGA/cnv/pancan34_cnv.rds.gz')

# CNV symbol --------------------------------------------------------------


cnv_symbol <- cnv$cnv[[1]]$symbol %>% 
  tibble::enframe(value = 'cnvsymbol') %>% 
  dplyr::select(-name)

search_symbol %>% dplyr::filter(symbol %in% cnv_symbol$cnvsymbol) -> cnv_symbol_search_symbol
cnv_symbol %>% dplyr::filter(!cnvsymbol %in% search_symbol$symbol) -> cnv_symbol_no_search_symbol

# find search_symbol for cnv symbol from ncbi
cnv_symbol_no_search_symbol %>%
  dplyr::mutate(new_data = purrr::map(.x = cnvsymbol, .f = function(.x) {
    .x_lower <- stringr::str_to_lower(string = .x)
    ncbi_name %>% 
      dplyr::filter(purrr::map_lgl(.x = Synonyms, .f = function(.x) {
        .x_lower %in% .x
      }))
  })) ->
  cnv_symbol_no_search_symbol_ncbi
  
cnv_symbol_no_search_symbol_ncbi %>% 
  dplyr::filter(purrr::map_lgl(.x = new_data, .f = function(.x){nrow(.x) != 0})) -> 
  cnv_symbol_no_search_symbol_ncbi_filter


cnv_symbol_no_search_symbol_ncbi_filter %>% 
  dplyr::filter(purrr::map_lgl(.x = new_data, .f = function(.x){nrow(.x) > 1})) %>% 
  tidyr::unnest(cols = new_data) %>% 
  dplyr::filter(cnvsymbol == symbol) ->
  cnv_symbol_no_search_symbol_ncbi_filter_2unique


cnv_symbol_no_search_symbol_ncbi_filter %>% 
  dplyr::filter(purrr::map_lgl(.x = new_data, .f = function(.x){nrow(.x) == 1})) %>% 
  tidyr::unnest(cols = new_data) %>% 
  dplyr::bind_rows(cnv_symbol_no_search_symbol_ncbi_filter_2unique) %>% 
  dplyr::select(-Synonyms) ->
  cnv_symbol_no_search_symbol_ncbi_filter_retain

cnv_symbol_search_symbol %>% 
  tibble::add_column('cnvsymbol' = cnv_symbol_search_symbol$symbol, .before = 1) %>% 
  dplyr::bind_rows(cnv_symbol_no_search_symbol_ncbi_filter_retain) %>% 
  dplyr::distinct() ->
  cnv_symbol_search_symbol_final


# save cnv symbol ---------------------------------------------------------

readr::write_rds(x = cnv_symbol_search_symbol_final, file = 'data/rda/cnv_symbol_search_symbol_final.rds.gz', compress = 'gz')



# Save image --------------------------------------------------------------

save.image(file = 'data/rda/07-cnv-symbol.rda')
