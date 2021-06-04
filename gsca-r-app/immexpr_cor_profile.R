########### immune cnv correlation ################
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str <- 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_immune_cor_expr'
# apppath='/home/huff/github/GSCA'
# filepath <- "/home/huff/github/GSCA/gsca-r-plot/pngs/3d2e17d3-91b9-40ff-bf8f-d9dd70692a26.png"

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
fields <- '{"symbol": true, "cell_type": true,"cor": true,"fdr":true,"_id": false}'
fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_immune_cor_expr",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows() %>%
  dplyr::mutate(logfdr = -log10(fdr)) %>%
  dplyr::mutate(logfdr = ifelse(logfdr>10,10,logfdr))

# Sort ----------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/common_used_summary_plot_functions.R"))

fetched_data %>%
  dplyr::mutate(group = ifelse(logfdr>1.3,"<0.05",">0.05")) -> for_plot
fetched_data_clean_pattern <- fn_get_pattern_celltype(.x = for_plot %>%
                                                        dplyr::mutate(value=fdr) %>%
                                                        dplyr::mutate(trend=ifelse(cor>0,"Pos","Neg")),
                                                      trend1="Pos",
                                                      trend2="Neg",
                                                      p_cutoff=0.05,
                                                      selections = c("cell_type","symbol"))
celltype_rank <- fn_get_cell_types_rank(.x = fetched_data_clean_pattern %>%
                                          dplyr::select(-InfiltrationScore))
celltype_rank<-c("InfiltrationScore",celltype_rank$cell_type)
gene_rank <- fn_get_gene_rank(.x = fetched_data_clean_pattern)

# plot --------------------------------------------------------------------

source(file.path(apppath,"gsca-r-app/utils/fn_bubble_plot_immune.R"))
for_plot$cor %>% range() -> min_max
floor(min_max[1]*10)/10 -> min
ceiling(min_max[2]*10)/10 -> max
fillbreaks <- sort(unique(c(0,min,max)))
title <- glue::glue("Correlation between expression and immune infiltrates in ",{search_cancertypes})

plot <- bubble_plot(data=for_plot,
                    cancer="cell_type",
                    gene="symbol",
                    xlab="Cell type",
                    ylab="Symbol",
                    facet_exp=NA,
                    size="logfdr",
                    fill="cor",
                    fillmipoint =0,
                    fillbreaks =fillbreaks,
                    colorgroup="group",
                    cancer_rank=celltype_rank,
                    gene_rank=gene_rank$symbol,
                    sizename= "-Log10(FDR)",
                    colorvalue=c("black","grey"),
                    colorbreaks=c("<0.05",">0.05"),
                    colorname="FDR",
                    fillname="Correlation",
                    title=title)

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = size$width+3, height = size$height +2)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = size$width+3, height = size$height+2)