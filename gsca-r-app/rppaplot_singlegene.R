
# stage single gene -------------------------------------------------------


# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]


# search_str="A2M@KICH_rppa_diff@RASMAPK"
# filepath='/home/huff/github/GSCA/gsca-r-plot/pngs/2f81a610-a51b-4c6d-816d-a35a2e1ecb26.png'
# apppath='/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]
search_pathway <- search_str_split[3]
# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

# Functions ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/plot_theme.R"))
source(file.path(apppath,"gsca-r-app/utils/fn_boxplot_single_gene_in_cancer.R"))

# Query data --------------------------------------------------------------
fetched_expr_data <- fn_fetch_mongo_all_expr_single_cancer(.cancer_types = search_cancertypes, .keyindex="symbol", .key=search_genes) %>%
  dplyr::bind_rows()

fetched_rppa_data <- fn_fetch_mongo_all_rppascore(.data="all_rppa_score",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows() %>%
  dplyr::rename("sample_name"="barcode") %>%
  dplyr::filter(pathway == search_pathway)

fields <- '{"symbol": true, "pathway": true,"fdr": true,"_id": false}'
fetched_exprrppa_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_rppa_diff",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows() %>%
  dplyr::filter(pathway  == search_pathway)


fetched_expr_data %>%
  dplyr::filter(type=="tumor") %>%
  dplyr::inner_join(fetched_rppa_data,by=c("cancer_types", "sample_name"))%>%
  dplyr::filter(!is.na(score)) %>%
  dplyr::filter(!is.na(expr)) -> combine_data

# draw survival plot ------------------------------------------------------
combine_data %>%
  dplyr::mutate(group=ifelse(expr>quantile(expr,0.5),"Higher expr.","Lower expr.")) -> for_plot

title <- paste("Activity of",search_pathway,"pathway between\nhigh and low",search_genes,"expression groups in",search_cancertypes, sep=" ")
color <- c("#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D", "#666666")
len_stage <- length(unique(for_plot$group))

color_list <- for_plot %>%
  dplyr::select(group) %>%
  unique() %>%
  dplyr::mutate(color=color[1:len_stage]) %>%
  dplyr::arrange(group)

combn_matrix <- combn(sort(unique(for_plot$group)),2)
comp_list <- list()
for(i in 1:ncol(combn_matrix)){
  comp_list[[i]] <- combn_matrix[,i]
}

plot <- box_plot_single_gene_single_cancer_nocompare(data = for_plot,aesx = "group",aesy="score",color = "group",color_name = "Expr. group",color_labels =  color_list$group,color_values = color_list$color,title = title,xlab = 'Expr. group', ylab = 'Pathway activity\n score',xangle = 0,fdr=fetched_exprrppa_data$fdr)

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 3)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 3)
