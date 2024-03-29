################### imm methy cor singlegene####################

# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str <- 'A2M@all_gdsc_cor_expr@(5Z)-7-Oxozeaenol'
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
fields <- '{"symbol": true, "cell_type": true,"cor": true,"fdr":true,"_id": false}'
fetched_methycor_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_immune_cor_methy",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows() %>%
  dplyr::filter(cell_type %in% celltype)

fields <- '{"symbol": true,"barcode": true,"sample_name":true, "type":true, "methy":true, "_id": false}'
fetched_methy <- purrr::map(.x = paste(search_cancertypes,"_all_methy",sep=""), .f = fn_fetch_mongo, pattern="_all_methy",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()%>%
  dplyr::filter(type=="tumor")

fields <- '{"cell_type": true,"barcode": true,"sample_name":true, "TIL":true, "_id": false}'
fetched_immune <- purrr::map(.x = paste(search_cancertypes,"_all_immune",sep=""), .f = fn_fetch_mongo, pattern="_all_immune",fields = fields,.key=celltype,.keyindex="cell_type") %>%
  dplyr::bind_rows()%>%
  dplyr::filter(substr(barcode,14,14)==0)

# Sort ----------------------------------------------------------------

fetched_immune %>%
  dplyr::inner_join(fetched_methy, by="sample_name") -> for_plot

# plot --------------------------------------------------------------------

source(file.path(apppath,"gsca-r-app/utils/fn_point_line.R"))

title <-  glue::glue('Spearman correlation between {search_genes} methylation and {celltype} \ninfiltrates in {search_cancertypes}')
plot <- fn_point_fit(data=for_plot,aesx="TIL",aesy="methy",
                     title=title,xlab=glue::glue('{celltype} infiltrates (ImmuCellAI)'),ylab="Methylation (Beta value)",
                     label=paste("Cor. =",round(fetched_methycor_data$cor,2),"\nFDR =", round(fetched_methycor_data$fdr,2)))

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)