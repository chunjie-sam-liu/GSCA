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
survival_type <- c("os")
color_list <- tibble::tibble(color=c( "#CD2626","#00B2EE"),
                             group=c("High expr.","Low expr."))

# search_str = 'CDR1@KICH_expr_survival'
# filepath = '/home/huff/github/GSCA/gsca-r-plot/pngs/89bdb2f8-912a-4b89-9b43-1603e6db17cd.png'
# apppath <- '/home/huff/github/GSCA'


search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

# Functions ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_survival.R"))

# Query data --------------------------------------------------------------
fetched_expr_data <- fn_fetch_mongo_all_expr_single_cancer(.cancer_types = search_cancertypes, .keyindex="symbol", .key=search_genes) %>%
  dplyr::bind_rows()

fetched_survival_data <- fn_fetch_mongo_all_survival(.data="all_survival",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows()

fetched_expr_data %>%
  dplyr::filter(type=="tumor") %>%
  dplyr::inner_join(fetched_survival_data,by=c("cancer_types", "sample_name")) -> combine_data


# expression group --------------------------------------------------------
expr_group %>%
  dplyr::filter(group %in% break_point) -> cutoff

survival_group  %>%
  dplyr::filter(type %in% survival_type) -> survival_type_to_draw

combine_data %>%
  dplyr::filter(!is.na(expr)) %>%
  dplyr::select(symbol,sample_name,expr,cancer_types,time=survival_type_to_draw$time,status=survival_type_to_draw$status) %>%
  dplyr::mutate(group = ifelse(expr>quantile(expr,cutoff$cutoff),"High expr.","Low expr.")) -> combine_data_group

# draw survival plot ------------------------------------------------------
title <- paste(search_cancertypes, search_genes, sep=", ")
combine_data_group %>%
  dplyr::filter(!is.na(group)) %>%
  fn_survival(title,color_list) -> plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)
