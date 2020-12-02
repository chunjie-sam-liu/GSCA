
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


# args <- commandArgs(TRUE)
# 
# search_str <- args[1]
# filepath <- args[2]
# apppath <- args[3]

# arguments need to be determined future ----------------------------------

# survival_type <- c("os")

# search_str<-  'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_cnv_survival#KIRC_cnv_survival#KIRP_cnv_survival#LUAD_cnv_survival#LUSC_cnv_survival'
# apppath='/home/huff/github/GSCA'

# search_str_split <- strsplit(x = search_str, split = '@')[[1]]
# search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
# # search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
# search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
# search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
#   purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()


# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

# Function ----------------------------------------------------------------
source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_survival_cnv.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_cnv.R"))

cnv_group <- tibble::tibble(cnv=c(-2,-1,0,1,2),
                            group_detail=c("Homo. dele.","Hete. dele.","WT","Hete. amp.","Homo. amp."),
                            group=c("Dele.","Dele.","WT","Amp.","Amp."),
                            color=c( "#CD2626","#CD2626","#00B2EE","#F8F8FF","#F8F8FF"))

# Query data --------------------------------------------------------------
fetched_survival_data <- fn_fetch_mongo_all_survival(.data="all_survival",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows() %>%
  dplyr::filter(cancer_types %in% search_cancertypes)

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

# calculation -------------------------------------------------------------

mutate_grouped %>%
  tidyr::unnest(cols = c(mutataion_group)) %>%
  dplyr::inner_join(fetched_survival_data,by="sample_name") %>%
  tidyr::nest(combine=c(sample_name, os_days, os_status, pfs_days, pfs_status, group)) %>%
  dplyr::mutate(surviva_res = purrr::map2(cancer_types,combine,fn_survival_res)) %>%
  dplyr::select(-combine) %>%
  tidyr::unnest(cols = c(surviva_res)) %>%
  dplyr::select(-cancer_types)-> geneset_survival

# results into mongo database ---------------------------------------------
uuid <- gsub("\\.png","",gsub("\\/home/huff/github/GSCA/gsca-r-plot/pngs/","",filepath))

# insert to collection
tibble::tibble(uuid=uuid,search=search_str_split[1],coll=search_str_split[2],purpose="cnv_geneset_survival",res=list(geneset_survival)) -> for_mongo

.coll_name <- 'cnv_geneset_survival'
.coll <- mongolite::mongo(collection = .coll_name, url = gsca_conf)

.coll$insert(data=for_mongo)
message(glue::glue('Refresh cnv geneset mongo res'))