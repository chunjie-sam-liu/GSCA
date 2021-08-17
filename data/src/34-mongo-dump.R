# Library -----------------------------------------------------------------


library(magrittr)

mongo_dump_path <- "/home/huff/data/GSCA/mongo_dump"

# Mongo -------------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"

gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))


mongo <- mongolite::mongo(url = gsca_conf)
cursor <- mongo$run('{"listCollections":1}')

collnames <- cursor$cursor$firstBatch

collnames %>%
  dplyr::select(name) %>%
  tibble::as_tibble() ->
  collnames_tib

collnames_tib %>%
  plyr::mutate(d = purrr::map(.x = name, .f = function(.x) {
    .collname <- .x
    print(.collname)
    .coll <- mongolite::mongo(collection = .collname, url = gsca_conf)
    .coll$export(file(file.path(mongo_dump_path,paste(.x,"dump.json",sep="-"))))
    return(1)
  })) %>%
  tidyr::unnest(cols = d) ->
  collnames_tib_unnest
