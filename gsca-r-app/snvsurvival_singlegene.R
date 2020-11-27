
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

# search_str <-'A2M@KIRC_snv_survival@os'
# apppath <- '/home/huff/github/GSCA'
search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]
survival_type <- search_str_split[3]

# arguments need to be determined future ----------------------------------
color_list <- tibble::tibble(color=c( "#CD2626","#00B2EE"),
                             group=c("Mutated","Non-mutated"))
# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

# Functions ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_survival.R"))

# Query data --------------------------------------------------------------
# fetched_snv_data <- search_cancertypes %>%
#   as.data.frame() %>%
#   dplyr::as.tbl() %>%
#   dplyr::rename(cancer_types=".") %>%
#   dplyr::mutate(snv=purrr::map(cancer_types,fn_fetch_mongo_snv_maf, .keyindex="symbol", .key=search_genes))


data_path <- "/home/huff/data/GSCA/mutation/snv/sub_cancer_maf_tsv"
fetched_snv_data <- tibble::tibble()
for (cancer in search_cancertypes) {
  filename <- paste(cancer,"_maf_data.IdTrans.tsv.rds.gz",sep="") 
  maf_file <- readr::read_rds(file.path(data_path,filename)) %>%
    dplyr::filter(Hugo_Symbol %in% search_genes)
  if(nrow(fetched_snv_data)<1){
    fetched_snv_data<-maf_file
  } else {
    rbind(fetched_snv_data,maf_file) ->fetched_snv_data
  }
}


fetched_survival_data <- fn_fetch_mongo_all_survival(.data="all_survival",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows() %>%
  dplyr::filter(cancer_types %in% search_cancertypes)

# mutation group --------------------------------------------------------

fetched_snv_data %>%
  dplyr::rename(symbol=Hugo_Symbol) %>%
  dplyr::mutate(sample_name = substr(x = Tumor_Sample_Barcode, start = 1, stop = 12)) %>%
  dplyr::mutate(group = ifelse(Variant_Classification %in% c("Missense_Mutation","Nonsense_Mutation","Frame_Shift_Ins","Splice_Site","Frame_Shift_Del","In_Frame_Del","In_Frame_Ins"), "Mutated","Non-mutated"))%>%
  dplyr::select(sample_name,group)-> fetched_snv_data.bycancer

fetched_survival_data %>%
  dplyr::left_join(fetched_snv_data.bycancer,by=c("sample_name")) %>%
  dplyr::mutate(group=ifelse(is.na(group),"Non-mutated",group)) -> combine_group_data

survival_group  %>%
  dplyr::filter(type %in% survival_type) -> survival_type_to_draw

combine_group_data %>%
  dplyr::select(sample_name,group,cancer_types,time=survival_type_to_draw$time,status=survival_type_to_draw$status) -> combine_data_group

# draw survival plot ------------------------------------------------------
title <- paste(toupper(survival_type),"survival of",search_genes, "SNV in",search_cancertypes)
combine_data_group %>%
  dplyr::filter(!is.na(time)) %>%
  fn_survival(title,color_list) -> plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)
