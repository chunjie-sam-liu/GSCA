# snv single gene survival---------------------------------------------------------
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)
# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str <-'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@PRAD_snv_survival@pfs'
# apppath <- '/home/huff/github/GSCA'
search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]
survival_type <- search_str_split[3]

# arguments need to be determined future ----------------------------------
color_list <- tibble::tibble(color=c( "#CD2626","#00B2EE"),
                             group=c("Mutant","WT"))
# Functions ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_survival.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_snv.R"))

# Query data --------------------------------------------------------------
fetched_survival_data <- fn_fetch_mongo_all_survival(.data="all_survival",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows() %>%
  dplyr::filter(cancer_types %in% search_cancertypes)

fields <- '{"symbol": true, "Variant_Classification": true,"barcode": true ,"sample_name": true,"_id": false}'
fetched_snv_data <- purrr::map(.x = paste(search_cancertypes,"_snv_maf",sep=""), .f = fn_fetch_mongo, pattern="_snv_maf",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()

fields <- '{"_id": false}'
fetched_snv_samples <- purrr::map(.x = "all_samples_with_snv", .f = fn_fetch_mongo, pattern="_samples_with_snv",fields = fields,.key=search_cancertypes,.keyindex="cancer_types") %>%
  dplyr::bind_rows()%>%
  dplyr::filter(substr(barcode,14,14)==0) %>%
  dplyr::select(-cancertype) %>%
  dplyr::rename(cancertype=cancer_types)
# mutation group ----------------------------------------------------------

effective_mut <- c("Missense_Mutation","Nonsense_Mutation","Frame_Shift_Ins","Splice_Site","Frame_Shift_Del","In_Frame_Del","In_Frame_Ins")

fetched_snv_data %>%
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
  dplyr::select(-mutataion_group) %>%
  tidyr::unnest() -> combine_data

# combine data ------------------------------------------------------------

survival_group  %>%
  dplyr::filter(type %in% survival_type) -> survival_type_to_draw

combine_data %>%
  dplyr::select(sample_name,group,cancer_types,time=survival_type_to_draw$time,status=survival_type_to_draw$status) -> combine_data_group


# draw --------------------------------------------------------------------

title <- paste(toupper(survival_type),"survival of gene set", "SNV in",search_cancertypes)
combine_data_group %>%
  dplyr::mutate(group=ifelse(group=="1WT","WT","Mutant")) %>%
  dplyr::filter(!is.na(time)) %>%
  fn_survival(title,color_list) -> plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)

