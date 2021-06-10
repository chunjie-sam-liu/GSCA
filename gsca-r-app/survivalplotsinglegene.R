# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]


# arguments need to be determined future ----------------------------------

break_point <- "median"
color_list <- tibble::tibble(color=c( "#CD2626","#00B2EE"),
                             group=c("Higher expr.","Lower expr."))

# search_str = 'A2M@BRCA_expr_survival@OS'
# filepath = '/home/huff/github/GSCA/gsca-r-plot/pngs/9624753a-1aae-4288-b610-9c9337f960c6.png'
# apppath <- '/home/huff/github/GSCA'


search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]
surtype <- search_str_split[3]
# Functions ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_survival.R"))

# Query data --------------------------------------------------------------
fetched_expr_data <- fn_fetch_mongo_all_expr_single_cancer(.cancer_types = search_cancertypes, .keyindex="symbol", .key=search_genes) %>%
  dplyr::bind_rows() %>%
  dplyr::group_by(sample_name,type) %>%
  dplyr::mutate(expr = mean(expr)) %>%
  dplyr::ungroup() %>%
  unique()

fetched_survival_data <- fn_fetch_mongo_all_survival(.data="all_survival",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows()

fetched_expr_data %>%
  dplyr::filter(type=="tumor") %>%
  dplyr::inner_join(fetched_survival_data,by=c("cancer_types", "sample_name")) -> combine_data

fields <- '{"symbol": true, "logrankp": true,"sur_type": true,"_id": false}'
fetched_expr_survival <- purrr::map(.x = paste(search_cancertypes,"_expr_survival",sep=""), .f = fn_fetch_mongo, pattern="_methy_cor_expr",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()%>%
  dplyr::filter(sur_type %in% surtype)

# expression group --------------------------------------------------------
expr_group %>%
  dplyr::filter(group %in% break_point) -> cutoff

survival_group  %>%
  dplyr::filter(type %in% surtype) -> survival_type_to_draw

combine_data %>%
  dplyr::filter(!is.na(expr)) %>%
  dplyr::select(symbol,sample_name,expr,cancer_types,time=survival_type_to_draw$time,status=survival_type_to_draw$status) %>%
  dplyr::filter(!is.na(time)) %>%
  dplyr::filter(!is.na(status)) %>%
  dplyr::mutate(group = ifelse(expr>quantile(expr,cutoff$cutoff),"Higher expr.","Lower expr.")) -> combine_data_group

# draw survival plot ------------------------------------------------------
title <- paste(surtype,"survival between",search_genes, "high and low mRNA \nexpression in",search_cancertypes)
combine_data_group %>%
  dplyr::filter(!is.na(group)) %>%
  fn_survival(title,color_list,logrankp=fetched_expr_survival$logrankp,ylab=paste(toupper(surtype),"probability")) -> plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)
