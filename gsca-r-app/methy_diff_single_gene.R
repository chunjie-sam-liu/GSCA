# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str <- "A2M@ACC_all_methy#BLCA_all_methy#BRCA_all_methy#CESC_all_methy#CHOL_all_methy#COAD_all_methy#DLBC_all_methy#ESCA_all_methy#GBM_all_methy#HNSC_all_methy#KICH_all_methy#KIRC_all_methy#KIRP_all_methy#LAML_all_methy#LGG_all_methy#LIHC_all_methy#LUAD_all_methy#LUSC_all_methy#MESO_all_methy#OV_all_methy#PAAD_all_methy#PCPG_all_methy#PRAD_all_methy#READ_all_methy#SARC_all_methy#SKCM_all_methy#STAD_all_methy#TGCT_all_methy#THCA_all_methy#THYM_all_methy#UCEC_all_methy#UCS_all_methy#UVM_all_methy"
# apppath <- '/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]

# fetch data --------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
fields <- '{"symbol": true, "gene_tag": true,"aliquot": true,"type": true,"methy": true, "_id": false}'
fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_all_methy",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()%>%
  dplyr::mutate(type=ifelse(type=="tumor","Tumor","Normal"))


# plot --------------------------------------------------------------------

source(file.path(apppath,"gsca-r-app/utils/fn_boxplot_single_gene_in_cancer.R"))
CPCOLS <- c("#000080", "#F8F8FF", "#CD0000")
plot <- box_plot_single_gene_multi_cancers(data = fetched_data,aesx = "type",aesy="methy",facets=".~cancertype",color = "type",color_name = "Types",color_labels =  c("Normal", "Tumor"),color_values = c(CPCOLS[1], CPCOLS[3]),title = glue::glue('{search_genes} methylation across TCGA cancer types'),xlab = '', ylab = 'Methylation (Beta value)')

ggsave(filename = filepath, plot = plot, device = 'png', width = 15, height = 5)

pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 15, height = 5)