
# Library -----------------------------------------------------------------

library(magrittr)


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
  
}



all_expr_colls <- collnames$name[grepl(pattern = "_all_expr", x = collnames$name)]


