################### imm snv cor singlegene####################

# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str <- 'A2M@KIRC_immune_cor_snv@CD4_naive'
# apppath='/home/huff/github/GSCA'
# filepath <- "/home/huff/github/GSCA/gsca-r-plot/pngs/3d2e17d3-91b9-40ff-bf8f-d9dd70692a26.png"

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()
celltype <- search_str_split[3]

# fetch data --------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
fields <- '{"symbol": true, "cell_type": true,"logfc": true,"fdr":true,"cell_type":true,"_id": false}'
fetched_snvcor_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_immune_cor_snv",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows() %>%
  dplyr::filter(cell_type %in% celltype)

effective_mut <- c("Missense_Mutation","Nonsense_Mutation","Frame_Shift_Ins","Splice_Site","Frame_Shift_Del","In_Frame_Del","In_Frame_Ins")
fields <- '{"symbol":true,"barcode":true,"Variant_Classification":true,"_id": false}'
fetched_snv <- purrr::map(.x = paste(search_cancertypes,"_snv_maf",sep=""), .f = fn_fetch_mongo, pattern="_snv_maf",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()%>%
  dplyr::rename(Hugo_Symbol=symbol)

fields <- '{"cell_type": true,"barcode": true,"sample_name":true, "TIL":true, "_id": false}'
fetched_immune <- purrr::map(.x = paste(search_cancertypes,"_all_immune",sep=""), .f = fn_fetch_mongo, pattern="_all_immune",fields = fields,.key=celltype,.keyindex="cell_type") %>%
  dplyr::bind_rows()%>%
  dplyr::filter(substr(barcode,14,14)==0)

fields <- '{"_id": false}'
fetched_snv_samples <- purrr::map(.x = "all_samples_with_snv", .f = fn_fetch_mongo, pattern="_samples_with_snv",fields = fields,.key=search_cancertypes,.keyindex="cancer_types") %>%
  dplyr::bind_rows()%>%
  dplyr::filter(substr(barcode,14,14)==0) %>%
  dplyr::mutate(cancertype=search_cancertypes)

# combine ----------------------------------------------------------------

fetched_immune %>%
  dplyr::filter(barcode %in% fetched_snv_samples$barcode) %>%
  dplyr::left_join(fetched_snv, by=c("barcode","cancertype")) -> combine

combine %>%
  dplyr::mutate(group = ifelse(Variant_Classification %in% effective_mut, "Mutated", "WT")) %>%
  dplyr::mutate(symbol=search_genes) %>%
  dplyr::group_by(group) %>%
  dplyr::mutate(n=n()) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(group_n = paste(group,", n=",n,sep="")) -> for_plot

# Plot --------------------------------------------------------------------
CPCOLS <- c("#000080", "#F8F8FF", "#CD0000")
source(file.path(apppath,"gsca-r-app/utils/fn_boxplot_single_gene_in_cancer.R"))

color_labels <- for_plot$group_n %>% unique() %>% sort()
combn_matrix <- combn(sort(unique(for_plot$group)),2)
comp_list <- list()
for(i in 1:ncol(combn_matrix)){
  comp_list[[i]] <- combn_matrix[,i]
}
plot <- box_plot_single_gene_single_cancer(data = for_plot,aesx = "group",aesy="TIL",color = "group_n",color_name = "Group",color_labels =  color_labels,color_values = c(CPCOLS[3], CPCOLS[1]),title = glue::glue('{celltype} infiltrates between {search_genes}\nmutatants and WT in {search_cancertypes}'),xlab = 'Group', ylab = 'Immune infiltrate score\n(ImmuCellAI)',xangle = 0,comp_list=comp_list)

# Save image --------------------------------------------------------------

ggsave(filename = filepath, plot = plot, device = 'png', width = 5, height = 3)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 5, height = 3)
