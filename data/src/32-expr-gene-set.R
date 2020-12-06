
# Library -----------------------------------------------------------------

library(magrittr)
library(doParallel)


# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = "data/src/gsca.conf")


mongo <- mongolite::mongo(url = gsca_conf)
cursor <- mongo$run('{"listCollections":1}')

collnames <- cursor$cursor$firstBatch


# Function ----------------------------------------------------------------

fn_fetch_all <- function(.x) {
  .coll <- mongolite::mongo(collection = .x, url = gsca_conf)
  .data <- .coll$find(fields = '{"symbol": true, "barcode": true, "type": true, "expr": true, "_id": false}')
  .data %>% 
    tibble::as_tibble() %>% 
    tidyr::unnest(cols = c(barcode, type, expr)) %>% 
    dplyr::mutate(barcode = paste(barcode, type, sep = '#')) %>% 
    dplyr::select(-type) %>% 
    tidyr::spread(key = barcode, value = expr) ->
    .data_matrix
  
  .new_coll_name <- glue::glue("{.x}_gene_set")
  .new_coll <- mongolite::mongo(collection = .new_coll_name, url = gsca_conf)
  # insert data
  .new_coll$drop()
  .new_coll$insert(data = .data_matrix)
  .new_coll$index(add = '{"symbol": 1}')
  message(glue::glue('Insert data for {.new_coll_name} into {.x}.'))
  
  .rds_filename <- glue::glue("~/tmp/gene-set/{.new_coll_name}.rds.gz")
  readr::write_rds(x = .data_matrix, file = .rds_filename, compress = 'gz')
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


# Update data -------------------------------------------------------------


all_expr_colls <- collnames$name[grepl(pattern = "_all_expr", x = collnames$name)]

fn_parallel_start(n_cores = length(all_expr_colls))
foreach(i = all_expr_colls, .packages = c('magrittr')) %dopar% {
  fn_fetch_all(.x = i)
}
fn_parallel_stop()
