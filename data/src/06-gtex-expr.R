
# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"

gtex_expr <- readr::read_rds(file = '/home/huff/data/GSCA/expr/gtex_gene_mean_exp.IdTrans.rds.gz')
load(file = file.path(rda_path,"rda",'01-gene-symbols.rda'))
gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))


search_symbol <- search_symbol

# Function ----------------------------------------------------------------
fn_transform_df <- function(.x) {
  tibble::tibble(
    expr = list(.x$expr),
    tissue = list(.x$tissue)
  )
}
# Tidy data ---------------------------------------------------------------


gtex_expr %>% 
  tidyr::unnest(cols = Mean_trans) %>% 
  dplyr::left_join(search_symbol, by = 'symbol') %>% 
  dplyr::select(entrez, symbol, expr = RPKM, tissue = SMTS) %>% 
  dplyr::mutate(entrez = as.numeric(entrez)) %>% 
  dplyr::group_by(entrez, symbol) %>% 
  tidyr::nest() %>% 
  dplyr::ungroup() ->
  gtex_expr_nest

gtex_expr_nest$data %>% 
  purrr::map_dfr(.f = fn_transform_df) ->
  gtex_expr_nest_df

gtex_expr_nest %>% 
  dplyr::bind_cols(gtex_expr_nest_df) %>% 
  dplyr::select(-data) ->
  gtex_expr_nest_mongo_data


# mongo db ----------------------------------------------------------------


.coll_name <- glue::glue('gtex_expr')
.coll_expr <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
# insert data
.coll_expr$drop()
.coll_expr$insert(data = gtex_expr_nest_mongo_data)
.coll_expr$index(add = '{"symbol": 1}')

# eQTL --------------------------------------------------------------------


gtex_eqtl <- readr::read_rds(file = '/home/huff/data/GSCA/expr/GTEx_egene.merged.tissue.IdTrans.rds.gz')


gtex_eqtl %>% 
  dplyr::left_join(search_symbol, by = 'symbol') %>% 
  dplyr::select(entrez, symbol, gene_chr, gene_start, gene_end, chr, pos, rs_id, qval, tissue) %>% 
  dplyr::mutate(entrez = as.numeric(entrez)) %>% 
  dplyr::group_by(entrez, symbol, gene_chr, gene_start, gene_end, chr) %>% 
  tidyr::nest() %>% 
  dplyr::ungroup() %>% 
  dplyr::rename(eqtl = data) ->
  gtex_eqtl_nest

# mongo db
.coll_name <- glue::glue('gtex_eqtl')
.coll_expr <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
# insert data
.coll_expr$drop()
.coll_expr$insert(data = gtex_eqtl_nest)
.coll_expr$index(add = '{"symbol": 1}')

# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,"rda",'06-gtex-expr.rda'))
