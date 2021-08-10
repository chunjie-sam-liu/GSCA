
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

# search_str <-'KRAS@LUAD_snv_survival@PFS'
# apppath <- '/home/huff/github/GSCA'
search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]
survival_type <- search_str_split[3]

# arguments need to be determined future ----------------------------------
# color_list <- tibble::tibble(color=c( "#CD2626","#00B2EE"),
#                              group=c("Mutated","Non-mutated"))

# Functions ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_survival.R"))

# Query data --------------------------------------------------------------

# data_path <- file.path(apppath,"gsca-r-rds")
# fetched_snv_data <- tibble::tibble()
# for (cancer in search_cancertypes) {
#   filename <- paste(cancer,"_maf_data.IdTrans.tsv.rds.gz",sep="") 
#   maf_file <- readr::read_rds(file.path(data_path,filename)) %>%
#     dplyr::filter(Hugo_Symbol %in% search_genes)
#   if(nrow(fetched_snv_data)<1){
#     fetched_snv_data<-maf_file
#   } else {
#     rbind(fetched_snv_data,maf_file) ->fetched_snv_data
#   }
# }
effective_mut <- c("Missense_Mutation","Nonsense_Mutation","Frame_Shift_Ins","Splice_Site","Frame_Shift_Del","In_Frame_Del","In_Frame_Ins")
fields <- '{"symbol":true,"barcode":true,"sample_name":true ,"Variant_Classification":true,"_id": false}'
fetched_snv <- purrr::map(.x = paste(search_cancertypes,"_snv_maf",sep=""), .f = fn_fetch_mongo, pattern="_snv_maf",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()%>%
  dplyr::rename(Hugo_Symbol=symbol)

fields <- '{"_id": false}'
fetched_snv_samples <- purrr::map(.x = "all_samples_with_snv", .f = fn_fetch_mongo, pattern="_samples_with_snv",fields = fields,.key=search_cancertypes,.keyindex="cancer_types") %>%
  dplyr::bind_rows()%>%
  dplyr::filter(substr(barcode,14,14)==0) %>%
  dplyr::mutate(cancertype=search_cancertypes)

fetched_survival_data <- fn_fetch_mongo_all_survival(.data="all_survival",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows() %>%
  dplyr::filter(cancer_types %in% search_cancertypes)

fields <- '{"symbol": true, "log_rank_p": true,"cox_p": true,"HR":true,"higher_risk_of_death":true,"sur_type":true,"_id": false}'
fetched_snvsurvival_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_immune_cor_snv",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows() %>%
  dplyr::filter(sur_type %in% survival_type)

# combine --------------------------------------------------------
fetched_snv %>%
  dplyr::group_by(sample_name) %>%
  tidyr::nest() %>%
  dplyr::mutate(group = purrr::map(data,.f=function(.x){
    .x %>%
      dplyr::filter(Variant_Classification %in% effective_mut) -> .tmp
    if(nrow(.tmp)>0){
      "Mutant"
    }else{
      "WT"
    }
  })) %>%
  tidyr::unnest() %>%
  dplyr::select(-Variant_Classification) %>%
  unique() %>%
  dplyr::ungroup() -> fetched_snv.grouped

fetched_snv.grouped %>%
  dplyr::right_join(fetched_snv_samples, by=c("barcode","cancertype")) %>%
  dplyr::mutate(sample_name = substr(barcode,1,12)) %>%
  dplyr::inner_join(fetched_survival_data, by=c("sample_name","cancer_types")) %>%
  dplyr::mutate(group = ifelse(is.na(group),"WT",group)) -> combine


survival_group  %>%
  dplyr::filter(type %in% survival_type) -> survival_type_to_draw

combine %>%
  dplyr::select(sample_name,group,cancer_types,time=survival_type_to_draw$time,status=survival_type_to_draw$status) -> combine_data_group


# draw survival plot ------------------------------------------------------
title <- paste(toupper(survival_type),"of",search_genes, "SNV in",search_cancertypes)
color_list <- tibble::tibble(color=c( "#CD2626","#00B2EE"),
                             group=sort(unique(combine_data_group$group)))
combine_data_group %>%
  dplyr::filter(!is.na(time)) %>%
  fn_survival(title,color_list,logrankp=fetched_snvsurvival_data$log_rank_p,ylab=paste(survival_type,"probability")) -> plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)
