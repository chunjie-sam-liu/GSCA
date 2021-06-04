

# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str <- "A2M@KIRC_all_methy"
# apppath <- '/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]

# fetch data --------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
fields <- '{"symbol": true, "gene_tag": true,"aliquot": true,"type": true,"methy": true, "_id": false}'
fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_all_methy",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows() %>%
  dplyr::mutate(type=ifelse(type=="tumor","Tumor","Normal"))


# plot --------------------------------------------------------------------

source(file.path(apppath,"gsca-r-app/utils/fn_boxplot_single_gene_in_cancer.R"))
CPCOLS <- c("#000080", "#F8F8FF", "#CD0000")

combn_matrix <- combn(sort(unique(for_plot$type)),2)
comp_list <- list()
for(i in 1:ncol(combn_matrix)){
  comp_list[[i]] <- combn_matrix[,i]
}

plot <- box_plot_single_gene_single_cancer(data = fetched_data,aesx = "type",aesy="methy",color = "type",color_name = "Types",color_labels =  c("Normal", "Tumor"),color_values = c(CPCOLS[1], CPCOLS[3]),title = glue::glue('{search_genes} methylation in {search_cancertypes}'),xlab = 'Type', ylab = 'Methylation (Beta value)',xangle = 0,comp_list=comp_list)

ggsave(filename = filepath, plot = plot, device = 'png', width = 5, height = 3)

pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 5, height = 3)