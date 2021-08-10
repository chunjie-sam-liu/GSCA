
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

# search_str <-'MED30@ACC_cnv_threshold@OS'
# apppath <- '/home/huff/github/GSCA'
search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]
survival_type <- search_str_split[3]

# arguments need to be determined future ----------------------------------
cnv_group <- tibble::tibble(cnv=c(-2,-1,0,1,2),
                            group_detail=c("Homo. dele.","Hete. dele.","WT","Hete. amp.","Homo. amp."),
                            group=c("Dele.","Dele.","WT","Amp.","Amp."),
                            color=c( "#00B2EE","#00B2EE","gold4","#CD2626","#CD2626"))
cnv_group %>%
  dplyr::select(group,color) %>%
  unique() -> cnv_group.color

# Functions ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))

source(file.path(apppath, "gsca-r-app/utils/fn_survival.R"))
# Query data --------------------------------------------------------------

fetched_survival_data <- fn_fetch_mongo_all_survival(.data="all_survival",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows() %>%
  dplyr::filter(cancer_types %in% search_cancertypes)

fields <- '{"symbol": true, "barcode": true,"sample_name": true,"type": true,"cnv": true,"_id": false}'
fetched_cnv_data <- purrr::map(.x = paste(search_cancertypes,"_cnv_threshold",sep=""), .f = fn_fetch_mongo, pattern="_cnv_threshold",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows() %>%
  dplyr::filter(substr(barcode,14,14)=="0")

# mutation group --------------------------------------------------------

fetched_survival_data %>%
  dplyr::left_join(fetched_cnv_data,by=c("sample_name")) %>%
  dplyr::inner_join(cnv_group,by="cnv") -> combine_group_data

survival_group  %>%
  dplyr::filter(type %in% survival_type) -> survival_type_to_draw

combine_group_data %>%
  dplyr::select(sample_name,group,cancer_types,time=survival_type_to_draw$time,status=survival_type_to_draw$status) -> combine_data_group

fields <- '{"symbol": true, "log_rank_p": true,"sur_type": true,"_id": false}'
fetched_cnv_survival <- purrr::map(.x = paste(search_cancertypes,"_cnv_survival",sep=""), .f = fn_fetch_mongo, pattern="_cnv_survival",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows() %>%
  dplyr::filter(sur_type %in% toupper(survival_type))

# draw survival plot ------------------------------------------------------
title <- paste(toupper(survival_type),"of",search_genes, "CNV in",search_cancertypes)
combine_data_group %>%
  dplyr::filter(!is.na(time)) %>%
  fn_survival(title,cnv_group.color,logrankp=fetched_cnv_survival$log_rank_p,ylab=paste(toupper(survival_type),"probability")) -> plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)
