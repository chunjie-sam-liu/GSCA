#####################################
###### filter the files that renewed
#####################################

apppath <- '/home/huff/github/GSCA'
gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

.coll <- mongolite::mongo(collection = "preanalysised", url = gsca_conf)

fn_query_str_utils <- function(.key,.keyindex) {
  .xx <- paste0(.key, collapse = '","')
  glue::glue('{"<.keyindex>": {"$in": ["<.xx>"]}}', .open = '<', .close = '>')
}

.coll$find(
  query = fn_query_str_utils(c("methysurvivalplot","methysurvivalsinglegene"),"purpose"),
    fields = '{"uuid": true, "coll": true, "purpose": true, "search":true, "_id": false}'
) %>%
  dplyr::as.tbl() -> filtered_uuids
filtered_uuids$uuid

filtered_uuids %>%
  readr::write_tsv(file.path("/home/huff/github/GSCA/gsca-r-plot/FilesWithNewRes_NeedToRemove.tsv"))
