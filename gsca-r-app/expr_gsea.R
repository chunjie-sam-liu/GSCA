
# Library -----------------------------------------------------------------

library(magrittr)
library(doParallel)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
apppath <- args[2]
tableuuid <- args[3]
tablecol <- args[4]

# search_str = 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_all_expr_gene_set.rds.gz#KIRC_all_expr_gene_set.rds.gz#KIRP_all_expr_gene_set.rds.gz#LUAD_all_expr_gene_set.rds.gz#LUSC_all_expr_gene_set.rds.gz'
# apppath <- '/home/liucj/github/GSCA'
# tableuuid <- '3dfee429-973b-4222-bb2b-ba8522b68540'
# tablecol <- 'preanalysised_gsea'


search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))
pre_gsea_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)

# Function ----------------------------------------------------------------
fn_load_data <- function(.x) {
  .d <- readr::read_rds(file = file.path(apppath, 'gsca-r-rds/gene-set', .x))
  
  .dnames <- colnames(.d)[-1]
  .tumor_ind <- which(grepl(pattern = 'tumor', x = .dnames))
  .normal_ind <- which(grepl(pattern = 'normal', x = .dnames))
  
  .d %>% 
    dplyr::rowwise(symbol) %>% 
    dplyr::summarize(
      tumor_mean = mean(dplyr::c_across(cols = .tumor_ind)),
      normal_mean = mean(dplyr::c_across(cols = .normal_ind))
      ) %>% 
    dplyr::ungroup() ->
    .dd
  
  .dd %>% 
    dplyr::filter(!(tumor_mean == 0 | normal_mean == 0)) %>% 
    dplyr::mutate(log2fc = log2(tumor_mean/normal_mean)) %>% 
    dplyr::select(-c(tumor_mean, normal_mean)) %>% 
    dplyr::arrange(log2fc) ->
    .gene_ranks
  
  tibble::tibble(
    symbol = list(.gene_ranks$symbol),
    log2fc = list(.gene_ranks$log2fc)
  )
}

fn_parallel_start <- function(n_cores = 10) {
  n_detected_cores <- parallel::detectCores()
  global_cluster <<- parallel::makeForkCluster(nnodes = n_cores)
  doParallel::registerDoParallel(cl = global_cluster)
}

fn_parallel_stop <- function() {
  parallel::stopCluster(cl = global_cluster)
  foreach::registerDoSEQ()
}

fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"uuid": "<.xx>"}', .open = '<', .close = '>')
}


# Load data ---------------------------------------------------------------


fn_parallel_start(n_cores = length(search_cancertypes))
gsea_score <- foreach(i = search_cancertypes, .packages = c('magrittr')) %dopar% {
  fn_load_data(i)
}
fn_parallel_stop()

names(gsea_score) <- gsub(pattern = "_all_expr_gene_set.rds.gz", replacement = "", x = search_cancertypes)


# Update mongo ------------------------------------------------------------

insert_data <- list(uuid = tableuuid, gsea_score = gsea_score)

uuid_query <- pre_gsea_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{ "_id": false}'
)
# pre_gsea_coll$drop()
if (nrow(uuid_query) == 0) {
  pre_gsea_coll$insert(data = insert_data)
  pre_gsea_coll$index(add = '{"uuid": 1}')
  message("insert data into preanalysised_gsea")
}
