
# Library -----------------------------------------------------------------


library(magrittr)



# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = 'data/src/gsca.conf')


mongo <- mongolite::mongo(url=gsca_conf)
cursor <- mongo$run('{"listCollections":1}')

collnames <- cursor$cursor$firstBatch

collnames %>% 
  dplyr::select(name) %>% 
  tibble::as_tibble() ->
  collnames_tib

collnames_tib %>% 
  plyr::mutate(d = purrr::map(.x = name, .f = function(.x) {
    .xx <- stringr::str_split(string = .x, pattern = '_', simplify = T)
    .cancertype <- .xx[1,1]
    .suffix <- paste0(.xx[1,-1], collapse = '_')
    tibble::tibble(
      cancertype = .cancertype,
      suffix = .suffix
    )
  })) %>% 
  tidyr::unnest(cols = d) ->
  collnames_tib_unnest

collnames_tib_unnest %>% 
  dplyr::filter(grepl(pattern = '[^a-z]', x = cancertype)) ->
  collnames_tib_unnest_filter

collnames_tib_unnest_filter %>% 
  dplyr::group_by(suffix) %>% 
  tidyr::nest() %>% 
  dplyr::ungroup() %>% 
  dplyr::arrange(suffix) ->
  collnames_tib_unnest_filter_nest

collnames_tib_unnest_filter_nest %>%
  dplyr::mutate(new_data = purrr::map(.x = data, .f = function(.x) {
    .x %>% dplyr::arrange(cancertype) -> .x
    tibble::tibble(
      collnames = list(.x$name),
      cancertypes = list(.x$cancertype)
    )
  })) %>% 
  dplyr::select(-data) %>% 
  tidyr::spread(key = suffix, value = new_data) ->
  collnames_tib_unnest_filter_trans


collnames_tib_unnest_filter_trans %>% 
  jsonlite::toJSON(pretty = T, auto_unbox = T)
