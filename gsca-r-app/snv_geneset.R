# Library -----------------------------------------------------------------

library(magrittr)
library(doParallel)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
apppath <- args[2]
tableuuid <- args[3]
tablecol <- args[4]

# search_str = 'ACE@LUAD_all_expr_gene_set.rds.gz'
# apppath <- '/home/huff/github/GSCA'
# tableuuid <- 'd6fe01ae-b1fe-4f9b-ac92-60210edca6bc'
# tablecol <- 'preanalysised_snvgeneset'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()

# Function ----------------------------------------------------------------
source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_survival.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_snv.R"))

fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"uuid": "<.xx>"}', .open = '<', .close = '>')
}
# fetch data --------------------------------------------------------------

effective_mut <- c("Missense_Mutation","Nonsense_Mutation","Frame_Shift_Ins","Splice_Site","Frame_Shift_Del","In_Frame_Del","In_Frame_Ins")
fields <- '{"symbol":true,"barcode":true,"sample_name":true ,"Variant_Classification":true,"_id": false}'
fetched_snv <- purrr::map(.x = paste(search_cancertypes,"_snv_maf",sep=""), .f = fn_fetch_mongo, pattern="_snv_maf",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()

fields <- '{"_id": false}'
fetched_snv_samples <- purrr::map(.x = "all_samples_with_snv", .f = fn_fetch_mongo, pattern="_samples_with_snv",fields = fields,.key=search_cancertypes,.keyindex="cancer_types") %>%
  dplyr::bind_rows()%>%
  dplyr::filter(substr(barcode,14,14)==0) %>%
  dplyr::select(-cancertype) %>%
  dplyr::rename(cancertype=cancer_types)

# mutation group --------------------------------------------------------
if(nrow(fetched_snv)>0){
  fetched_snv %>%
    dplyr::group_by(sample_name) %>%
    tidyr::nest() %>%
    dplyr::mutate(group = purrr::map(data,.f=function(.x){
      .x %>%
        dplyr::filter(Variant_Classification %in% effective_mut) -> .tmp
      if(nrow(.tmp)>0){
        "2Mutant"
      }else{
        "1WT"
      }
    })) %>%
    tidyr::unnest() %>%
    dplyr::select(-Variant_Classification) %>%
    unique() %>%
    dplyr::ungroup() -> fetched_snv.grouped
  
  fetched_snv.grouped %>%
    dplyr::right_join(fetched_snv_samples, by=c("barcode","cancertype")) %>%
    dplyr::mutate(sample_name = substr(barcode,1,12)) %>%
    dplyr::mutate(group = ifelse(is.na(group),"1WT",group)) %>%
    dplyr::group_by(cancertype) %>%
    tidyr::nest() -> fetched_snv_data.bycancer
  
  
  fetched_snv_data.bycancer %>%
    dplyr::mutate(mutataion_group=purrr::map(data,fn_geneset_snv)) %>%
    dplyr::select(-data) -> mutate_grouped
  mutate_grouped %>%
    tidyr::unnest() %>%
    dplyr::ungroup()-> snvgeneset
}else{
  tibble::tibble(cancertyp=NA, barcode=NA,group=NA)-> snvgeneset
}

# Update mongo ------------------------------------------------------------

pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)

insert_data <- list(uuid = tableuuid, snvgeneset = snvgeneset)

uuid_query <- pre_gsva_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"uuid": true, "_id": false}'
)

if (nrow(uuid_query) == 0) {
  pre_gsva_coll$insert(data = insert_data)
  pre_gsva_coll$index(add = '{"uuid": 1}')
  message("insert data into preanalysised_snvgeneset")
}
