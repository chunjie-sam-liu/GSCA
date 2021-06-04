# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]
# search_str<- "A2M@KIRC_methy_cor_expr"
# apppath='/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()

# Functions ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))

# Query data --------------------------------------------------------------
fields <- '{"symbol": true, "sample_name": true, "type": true,"expr": true, "_id": false}'
fetched_expr_data <-purrr::map(.x = paste(search_cancertypes,"_all_expr",sep=""), .f = fn_fetch_mongo, pattern="_all_expr",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows() %>%
  dplyr::filter(type=="tumor") %>%
  dplyr::mutate(expr=log2(expr+1))

fields <- '{"symbol": true, "barcode": true,"sample_name": true,"type": true,"methy": true,"_id": false}'
fetched_methy_data <- purrr::map(.x = paste(search_cancertypes,"_all_methy",sep=""), .f = fn_fetch_mongo, pattern="_methy_survival",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()%>%
  dplyr::filter(type=="tumor")

fetched_methy_data %>%
  dplyr::inner_join(fetched_expr_data,by=c("sample_name")) -> combine_data

fields <- '{"symbol": true, "spm": true,"fdr": true,"_id": false}'
fetched_methy_cor <- purrr::map(.x = paste(search_cancertypes,"_methy_cor_expr",sep=""), .f = fn_fetch_mongo, pattern="_methy_cor_expr",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()

# plot --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_point_line.R"))
source(file.path(apppath,"gsca-r-app/utils/fn_p_format.R"))

title <-  glue::glue('Spearman correlation between {search_genes} methylation and mRNA \nexpression in {search_cancertypes}')
plot <- fn_point_fit(data=combine_data,aesx="expr",aesy="methy",title=title,xlab="Expression log2(RSEM)",ylab="Methylation (Beta value)",label=paste("Cor. =",round(fetched_methy_cor$spm,2),"\nFDR =",fn_format(fetched_methy_cor$fdr)))

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)
