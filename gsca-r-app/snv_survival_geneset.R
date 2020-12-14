
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

# search_str<-  'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@PRAD_snv_survival'
# apppath='/home/huff/github/GSCA'

# search_str_split <- strsplit(x = search_str, split = '@')[[1]]
# search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
# # search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
# search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
# search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
#   purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()

uuid <- gsub("\\.png","",gsub("\\/home/huff/github/GSCA/gsca-r-plot/pngs/","",filepath))

# Function ----------------------------------------------------------------
source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_survival.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_snv.R"))

# Query data --------------------------------------------------------------

# data_path <-  file.path(apppath,"gsca-r-rds")
# pan_maf <- tibble::tibble()
# for (cancer in search_cancertypes) {
#   filename <- paste(cancer,"_maf_data.IdTrans.tsv.rds.gz",sep="") 
#   maf_file <- readr::read_rds(file.path(data_path,filename)) %>%
#     dplyr::filter(Hugo_Symbol %in% search_genes)
#   if(nrow(pan_maf)<1){
#     pan_maf<-maf_file
#   } else {
#     rbind(pan_maf,maf_file) ->pan_maf
#   }
# }
# fetched_snv_data <- pan_maf

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

fetched_survival_data <- fn_fetch_mongo_all_survival(.data="all_survival",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows() %>%
  dplyr::filter(cancer_types %in% search_cancertypes) %>%
  dplyr::rename(cancertype=cancer_types)
  


# mutation group --------------------------------------------------------

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
  dplyr::mutate(combine = purrr::map2(cancertype,mutataion_group,.f=function(.x,.y){
    print(.x)
    fetched_survival_data %>%
      dplyr::filter(cancertype %in% .x) %>%
      dplyr::inner_join(.y,by=c("sample_name")) %>%
      dplyr::mutate(group=ifelse(is.na(group),"1WT",group))
  })) %>%
  dplyr::ungroup() %>%
  dplyr::select(-mutataion_group) -> combine_data_group

combine_data_group %>%
  readr::write_rds(file.path(apppath,"gsca-r-plot/tables",paste(uuid,"geneset_survival_data.rds.gz",sep = "_")))
# calculation -------------------------------------------------------------

combine_data_group %>%
  dplyr::mutate(surviva_res = purrr::map2(cancertype,combine,fn_survival_res)) %>%
  dplyr::select(-combine) %>%
  tidyr::unnest(cols = c(surviva_res)) %>%
  dplyr::filter(!is.na(higher_risk_of_death))-> geneset_survival
geneset_survival %>%
  readr::write_tsv(file.path(apppath,"gsca-r-plot/tables","geneset_survival_table.tsv"))

# results into mongo database ---------------------------------------------

# insert to collection
tibble::tibble(uuid=uuid,search=search_str_split[1],coll=search_str_split[2],purpose="snv_geneset_survival",res=list(geneset_survival)) -> for_mongo

.coll_name <- 'snv_geneset_survival'
.coll <- mongolite::mongo(collection = .coll_name, url = gsca_conf)

.coll$insert(data=for_mongo)
message(glue::glue('Refresh snv geneset mongo res'))