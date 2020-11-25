
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

# search_str<-  'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_snv_survival#KIRC_snv_survival#KIRP_snv_survival#LUAD_snv_survival#LUSC_snv_survival'
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
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_survival.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_snv.R"))

# Query data --------------------------------------------------------------
# fetched_snv_data <- search_cancertypes %>%
#   as.data.frame() %>%
#   dplyr::as.tbl() %>%
#   dplyr::rename(cancer_types=".") %>%
#   dplyr::mutate(snv=purrr::map(cancer_types,fn_fetch_mongo_snv_maf, .keyindex="symbol", .key=search_genes))


data_path <- "/home/huff/data/GSCA/mutation/snv/sub_cancer_maf_tsv"
pan_maf <- tibble::tibble()
for (cancer in search_cancertypes) {
  filename <- paste(cancer,"_maf_data.IdTrans.tsv.rds.gz",sep="") 
  maf_file <- readr::read_rds(file.path(data_path,filename)) %>%
    dplyr::filter(Hugo_Symbol %in% search_genes)
  if(nrow(pan_maf)<1){
    pan_maf<-maf_file
  } else {
    rbind(pan_maf,maf_file) ->pan_maf
  }
}
fetched_snv_data <- pan_maf


fetched_survival_data <- fn_fetch_mongo_all_survival(.data="all_survival",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows()

# mutation group --------------------------------------------------------


fetched_snv_data %>%
  dplyr::rename(symbol=Hugo_Symbol) %>%
  dplyr::mutate(sample_name = substr(x = Tumor_Sample_Barcode, start = 1, stop = 12)) %>%
  dplyr::mutate(group = ifelse(Variant_Classification %in% c("Missense_Mutation","Nonsense_Mutation","Frame_Shift_Ins","Splice_Site","Frame_Shift_Del","In_Frame_Del","In_Frame_Ins"), "Mutated","Non-mutated"))%>%
  dplyr::group_by(cancer_types) %>%
  tidyr::nest() -> fetched_snv_data.bycancer

fetched_snv_data.bycancer %>%
  dplyr::mutate(mutataion_group=purrr::map(data,fn_geneset_snv)) %>%
  dplyr::select(-data) -> mutate_grouped

mutate_grouped %>%
  dplyr::mutate(combine = purrr::map2(cancer_types,mutataion_group,.f=function(.x,.y){
    print(.x)
    fetched_survival_data %>%
      dplyr::filter(cancer_types %in% .x) %>%
      dplyr::left_join(.y,by=c("sample_name")) %>%
      dplyr::mutate(group=ifelse(is.na(group),"Non-mutated",group))
  })) %>%
  dplyr::ungroup() %>%
  dplyr::select(-mutataion_group) -> combine_data_group

combine_data_group %>%
  readr::write_rds(file.path(apppath,"gsca-r-plot/tables","geneset_survival_data.rds.gz"))
# calculation -------------------------------------------------------------

combine_data_group %>%
  dplyr::mutate(surviva_res = purrr::map2(cancer_types,combine,fn_survival_res)) %>%
  dplyr::select(-combine) %>%
  tidyr::unnest(cols = c(surviva_res)) %>%
  dplyr::rename(cancertype=cancer_types)-> geneset_survival
geneset_survival %>%
  readr::write_tsv(file.path(apppath,"gsca-r-plot/tables","geneset_survival_table.tsv"))

# results into mongo database ---------------------------------------------
uuid <- gsub("\\.png","",gsub("\\/home/huff/github/GSCA/gsca-r-plot/pngs/","",filepath))

# insert to collection
tibble::tibble(uuid=uuid,search=search_str_split[1],coll=search_str_split[2],purpose="snv_geneset_survival",res=list(geneset_survival)) -> for_mongo

.coll_name <- 'snv_geneset_survival'
.coll <- mongolite::mongo(collection = .coll_name, url = gsca_conf)

.coll$drop()
.coll$insert(data=for_mongo)
message(glue::glue('Refresh snv geneset mongo res'))