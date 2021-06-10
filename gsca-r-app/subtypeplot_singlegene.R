
# subtype plot single gene -------------------------------------------------



# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]


# search_str='MCM2@LUSC_expr_subtype'
# filepath='/home/huff/github/GSCA/gsca-r-plot/pngs/9d59a758-8321-4619-bd54-5d0bfeea7d47.png'
# apppath='/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]


# Functions ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/plot_theme.R"))
source(file.path(apppath,"gsca-r-app/utils/fn_boxplot_single_gene_in_cancer.R"))
# Query data --------------------------------------------------------------
fetched_expr_data <- fn_fetch_mongo_all_expr_single_cancer(.cancer_types = search_cancertypes, .keyindex="symbol", .key=search_genes) %>%
  dplyr::bind_rows() %>%
  dplyr::group_by(sample_name) %>%
  dplyr::mutate(expr = mean(expr)) %>%
  dplyr::ungroup() %>%
  unique()

fetched_subtype_data <- fn_fetch_mongo_all_subtype(.data="all_subtype",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows()

fetched_expr_data %>%
  dplyr::filter(type=="tumor") %>%
  dplyr::inner_join(fetched_subtype_data,by=c("cancer_types", "sample_name"))  %>%
  dplyr::filter(!is.na(subtype)) %>%
  dplyr::filter(!is.na(expr)) -> combine_data

# draw survival plot ------------------------------------------------------
combine_data%>%
  dplyr::mutate(expr=log2(expr+1))  %>%
  dplyr::rename(group=subtype)%>%
  dplyr::group_by(group) %>%
  dplyr::mutate(n=n()) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(group_n = paste(group,", n=",n,sep="")) -> for_plot

title <- paste(search_genes, "mRNA expression \nin subtypes of",search_cancertypes, sep=" ")
color <- c("#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D", "#666666")
len_subtype <- length(unique(combine_data$subtype))

color_list <- tibble::tibble(color=color[1:len_subtype],
                             group=sort(unique(for_plot$group_n)))
for_plot$group %>% class() -> group_class
if(is.numeric(group_class)){
  angle <- 0
}else{
  angle <- 45
}
combn_matrix <- combn(sort(unique(for_plot$group)),2)
comp_list <- list()
for(i in 1:ncol(combn_matrix)){
  comp_list[[i]] <- combn_matrix[,i]
}

plot <- box_plot_single_gene_single_cancer(data = for_plot,aesx = "group",aesy="expr",color = "group_n",color_name = "Subtypes",color_labels =  color_list$group,color_values = color_list$color,title = title,xlab = 'Subtype', ylab = 'Expression log2(RSEM)',xangle = 0,comp_list=comp_list,ylimitfold=0.1)

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 3)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 3)
