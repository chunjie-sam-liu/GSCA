# Library -----------------------------------------------------------------

library(magrittr)
library(doParallel)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
apppath <- args[2]
tableuuid <- args[3]
tablecol <- args[4]

# search_str = 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL@KICH_all_expr_gene_set.rds.gz'
# apppath <- '/home/huff/github/GSCA'
# tableuuid <- '6326efd0-2f45-4fd1-8dff-8b32d64f5739'
# tablecol <- 'preanalysised_cnvgeneset'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()

# Function ----------------------------------------------------------------
source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_survival_cnv.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_cnv.R"))

cnv_group <- tibble::tibble(cnv=c(-2,-1,0,1,2),
                            group_detail=c("Homo. dele.","Hete. dele.","WT","Hete. amp.","Homo. amp."),
                            group=c("Dele.","Dele.","WT","Amp.","Amp."),
                            color=c( "#CD2626","#CD2626","#00B2EE","#F8F8FF","#F8F8FF"))

fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"uuid": "<.xx>"}', .open = '<', .close = '>')
}
# fetch data --------------------------------------------------------------

fields <- '{"symbol": true, "barcode": true,"sample_name": true,"type": true,"cnv": true,"_id": false}'
fetched_cnv_data <- purrr::map(.x = paste(search_cancertypes,"_cnv_threshold",sep=""), .f = fn_fetch_mongo, pattern="_cnv_threshold",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows() %>%
  dplyr::filter(type == "tumor")

# mutation group --------------------------------------------------------

fetched_cnv_data %>%
  dplyr::inner_join(cnv_group,by="cnv") -> combine_group_data

combine_group_data %>%
  tidyr::nest(data = c(sample_name, symbol, 
                       barcode, type, cnv, color,group_detail, group)) %>%
  dplyr::mutate(mutataion_group=purrr::map(data,fn_geneset_cnv)) %>%
  dplyr::select(-data) -> mutate_grouped

# Update mongo ------------------------------------------------------------
mutate_grouped %>%
  tidyr::unnest() %>%
  dplyr::ungroup()-> cnvgeneset
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)

insert_data <- list(uuid = tableuuid, cnvgeneset = cnvgeneset)

uuid_query <- pre_gsva_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"uuid": true, "_id": false}'
)

if (nrow(uuid_query) == 0) {
  pre_gsva_coll$insert(data = insert_data)
  pre_gsva_coll$index(add = '{"uuid": 1}')
  message("insert data into preanalysised_cnvgeneset")
}
