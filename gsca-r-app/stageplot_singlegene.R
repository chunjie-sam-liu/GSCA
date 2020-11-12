
# stage single gene -------------------------------------------------------


# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]


# search_str="A2M@KICH_expr_stage"
# filepath='/home/huff/github/GSCA/gsca-r-plot/pngs/2f81a610-a51b-4c6d-816d-a35a2e1ecb26.png'
# apppath='/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

# Functions ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_boxplot.R"))
# Query data --------------------------------------------------------------
fetched_expr_data <- fn_fetch_mongo_all_expr_single_cancer(.cancer_types = search_cancertypes, .keyindex="symbol", .key=search_genes) %>%
  dplyr::bind_rows()

fetched_subtype_data <- fn_fetch_mongo_all_stage(.data="all_stage",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows()

fetched_expr_data %>%
  dplyr::filter(type=="tumor") %>%
  dplyr::inner_join(fetched_subtype_data,by=c("cancer_types", "sample_name"))%>%
  dplyr::filter(!is.na(stage)) %>%
  dplyr::filter(!is.na(expr)) -> combine_data

# draw survival plot ------------------------------------------------------
title <- paste(search_genes, "expression in stages of TCGA",search_cancertypes,"cancer type", sep=" ")
color <- c("#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D", "#666666")
len_stage <- length(unique(combine_data$stage))
color_list <- tibble::tibble(color=color[1:len_stage],
                             group=unique(combine_data$stage))
combine_data  %>%
  dplyr::mutate(expr=log2(expr+1)) %>%
  dplyr::rename(group=stage, value=expr) %>%
  fn_boxplot(title=title,colorkey=color_list,xlab="Stage",ylab="Expression log2(RSEM)") -> plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)
