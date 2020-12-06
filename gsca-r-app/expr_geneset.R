
# Library -----------------------------------------------------------------

library(magrittr)
library(doParallel)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]
tableuuid <- args[4]
tablecol <- args[5]

# search_str = 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_all_expr_gene_set.rds.gz#KIRC_all_expr_gene_set.rds.gz#KIRP_all_expr_gene_set.rds.gz#LUAD_all_expr_gene_set.rds.gz#LUSC_all_expr_gene_set.rds.gz'
# apppath <- '/home/liucj/github/GSCA'
# tableuuid <- 'ba16c786-93ca-421e-a426-7a361f4c3e7a'
# tablecol <- 'preanalysised_gsva'


search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)

# Function ----------------------------------------------------------------
fn_load_data <- function(.x) {
  .d <- readr::read_rds(file = file.path(apppath, 'gsca-r-rds/gene-set', .x))
  .d_mat <- as.matrix(.d[,-1])
  rownames(.d_mat) <- .d$symbol
  
  .es <- GSVA::gsva(expr = .d_mat, gset.idx.list = list("geneset" = search_genes), method = "ssgsea", parallel.sz = 10, verbose=FALSE)
  
  .es %>% 
    as.data.frame() 
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
gsva_score <- foreach(i = search_cancertypes, .packages = c('magrittr')) %dopar% {
  fn_load_data(i)
}
fn_parallel_stop()

names(gsva_score) <- gsub(pattern = "_all_expr_gene_set.rds.gz", replacement = "", x = search_cancertypes)

# Update mongo ------------------------------------------------------------

insert_data <- list(uuid = tableuuid, gsva_score = gsva_score)

uuid_query <- pre_gsva_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"uuid": true, "_id": false}'
)

if (nrow(uuid_query) == 0) {
  pre_gsva_coll$insert(data = insert_data)
  pre_gsva_coll$index(add = '{"uuid": 1}')
  message("insert data into preanalysised_gsva")
}

