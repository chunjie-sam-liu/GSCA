
# methy single gene survival---------------------------------------------------------
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)
# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]
# arguments need to be determined future ----------------------------------

break_point <- "median"

# search_str <-'A2M@KICH_methy_survival@OS'
# search_str <-'GSDMD@KIRC_methy_survival@OS'
# apppath <- '/home/huff/github/GSCA'
search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]
survival_type <- search_str_split[3]
# survival_type <- "os"
# arguments need to be determined future ----------------------------------
color_list <- tibble::tibble(color=c( "#CD2626","#00B2EE"),
                             group=c("Higher meth.","Lower meth."))

# Functions ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_survival.R"))

# Query data --------------------------------------------------------------

fetched_survival_data <- fn_fetch_mongo_all_survival(.data="all_survival",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows()

fields <- '{"symbol": true, "barcode": true,"sample_name": true,"type": true,"methy": true,"_id": false}'
fetched_methy_data <- purrr::map(.x = paste(search_cancertypes,"_all_methy",sep=""), .f = fn_fetch_mongo, pattern="_methy_survival",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()

fetched_methy_data %>%
  dplyr::filter(type=="tumor") %>%
  dplyr::filter(!is.na(methy)) %>%
  unique() %>%
  dplyr::inner_join(fetched_survival_data,by=c("sample_name")) -> combine_data

fields <- '{"symbol": true, "log_rank_p": true,"sur_type": true,"_id": false}'
fetched_methy_survival <- purrr::map(.x = paste(search_cancertypes,"_methy_survival",sep=""), .f = fn_fetch_mongo, pattern="_methy_cor_expr",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()%>%
  dplyr::filter(sur_type %in% survival_type)
# grouped --------------------------------------------------------
expr_group %>%
  dplyr::filter(group %in% break_point) -> cutoff

survival_group  %>%
  dplyr::filter(type %in% survival_type) -> survival_type_to_draw

combine_data %>%
  dplyr::select(symbol,sample_name,methy,cancer_types,time=survival_type_to_draw$time,status=survival_type_to_draw$status) %>%
  dplyr::filter(!is.na(time)) %>%
  dplyr::filter(!is.na(status)) %>%
  dplyr::mutate(group = ifelse(methy>quantile(methy,cutoff$cutoff),"Higher meth.","Lower meth.")) -> combine_data_group


# draw survival plot ------------------------------------------------------
title <- paste(toupper(survival_type),"of",search_genes, "methylation in",search_cancertypes)
combine_data_group %>%
  dplyr::filter(!is.na(time), time > 0, !is.na(status)) %>%
  fn_survival(title,color_list,logrankp=fetched_methy_survival$log_rank_p,ylab=paste(toupper(survival_type),"probability")) -> plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)
