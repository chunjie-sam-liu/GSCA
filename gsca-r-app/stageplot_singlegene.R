
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


# search_str="A2M@KICH_expr_stage@pathologic_stage"
# filepath='/home/huff/github/GSCA/gsca-r-plot/pngs/2f81a610-a51b-4c6d-816d-a35a2e1ecb26.png'
# apppath='/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
stagetype <- search_str_split[3]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

# Functions ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/plot_theme.R"))
source(file.path(apppath,"gsca-r-app/utils/fn_boxplot_single_gene_in_cancer.R"))
# Query data --------------------------------------------------------------
fetched_expr_data <- fn_fetch_mongo_all_expr_single_cancer(.cancer_types = search_cancertypes, .keyindex="symbol", .key=search_genes) %>%
  dplyr::bind_rows()%>%
  dplyr::group_by(sample_name,type) %>%
  dplyr::mutate(expr = mean(expr)) %>%
  dplyr::ungroup() %>%
  unique()

fetched_stage_data <- fn_fetch_mongo_all_stage(.data="all_stage",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows() %>%
  dplyr::filter(stage_type==stagetype)

fetched_expr_data %>%
  dplyr::filter(type=="tumor") %>%
  dplyr::inner_join(fetched_stage_data,by=c("cancer_types", "sample_name"))%>%
  dplyr::filter(!is.na(stage)) %>%
  dplyr::filter(!is.na(expr)) -> combine_data

# draw survival plot ------------------------------------------------------
stages_included <- tibble::tibble(stage=c("Stage I","Stage II","Stage III","Stage IV","intermediate","poor","good"),
                                  rank=c(1,2,3,4,2,3,1))
combine_data%>%
  dplyr::mutate(expr=log2(expr+1))  %>%
  dplyr::inner_join(stages_included) %>%
  dplyr::group_by(stage) %>%
  dplyr::mutate(n=n()) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(group_n = paste(stage,", n=",n,sep="")) -> for_plot

title <- paste(search_genes, "mRNA expression\nin",stagetype,"of",search_cancertypes, sep=" ")
color <- c("#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D", "#666666")
len_stage <- length(unique(for_plot$group_n))

color_list <- for_plot %>%
  dplyr::select(group_n,rank) %>%
  unique() %>%
  dplyr::arrange(rank) %>%
  dplyr::mutate(color=color[1:len_stage])

combn_matrix <- combn(sort(unique(for_plot$stage)),2)
comp_list <- list()
for(i in 1:ncol(combn_matrix)){
  comp_list[[i]] <- combn_matrix[,i]
}

plot <- box_plot_single_gene_single_cancer(data = for_plot,aesx = "stage",aesy="expr",color = "group_n",color_name = "Stage",color_labels =  color_list$group_n,color_values = color_list$color,title = title,xlab = 'Stage', ylab = 'Expression log2(RSEM)',xangle = 0,comp_list=comp_list,ylimitfold=0.1)
# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 3)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 3)
