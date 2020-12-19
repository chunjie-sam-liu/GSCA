# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]
# search_str<- "A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_methy_cor_expr#KIRC_methy_cor_expr#KIRP_methy_cor_expr#LUAD_methy_cor_expr#LUSC_methy_cor_expr"
# apppath='/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()


# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(search_genes,search_cancertypes)

# fetch data --------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
fields <- '{"symbol": true, "spm": true,"fdr": true,"logfdr": true,"_id": false}'
fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_methy_cor_expr",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()

# Sort ----------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/common_used_summary_plot_functions.R"))

fetched_data_clean_pattern <- fn_get_pattern(
  .x = fetched_data %>% dplyr::mutate(value=fdr,trend="trend",trend1="trend",trend1="trend"),
  trend1="trend",
  trend2="trend",
  p_cutoff=0.05,
  selections =c("cancertype","symbol"))
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern)
gene_rank <- fn_get_gene_rank(.x = fetched_data_clean_pattern)
for_plot <- fn_pval_label(.x = fetched_data %>% dplyr::rename(value=fdr))  %>%
  dplyr::mutate(group = ifelse(value<=0.05,"<0.05",">0.05"))

# Plot --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_bubble_plot_immune.R"))
for_plot %>%
  dplyr::filter(!is.na(spm)) %>%
  .$spm %>% range() -> min_max
floor(min_max[1]) -> min
ceiling(min_max[2]) -> max
fillbreaks <- sort(unique(c(0,min,max)))
title <- "Correlation between methylation and\nmRNA expression"
heat_plot <- bubble_plot(data=for_plot, 
                    cancer="cancertype", 
                    gene="symbol", 
                    xlab="Cancer type", 
                    ylab="Symbol",
                    facet_exp=NA,
                    size="logfdr",
                    fill="spm",
                    fillmipoint =0,
                    fillbreaks =fillbreaks,
                    colorgroup="group",
                    cancer_rank=cancer_rank$cancertype, 
                    gene_rank=gene_rank$symbol, 
                    sizename= "-Log10(FDR)", 
                    colorvalue=c("black","grey"),
                    colorbreaks=c("<0.05",">0.05"),
                    colorname="FDR", 
                    fillname="Spearman cor.", 
                    title=title) +
  guides(fill=guide_colourbar(title.position="top", reverse = F))

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = heat_plot, device = 'png', width = size$width, height = size$height)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = heat_plot, device = 'pdf', width = size$width, height = size$height)
