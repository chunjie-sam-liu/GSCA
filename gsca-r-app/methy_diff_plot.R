# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str <- "A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KIRC_methy_diff#KIRP_methy_diff#LUAD_methy_diff#LUSC_methy_diff"
# apppath = '/home/huff/github/GSCA'
search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
#search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
#  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(search_genes,search_colls)

# fetch data --------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
fields <- '{"symbol": true, "fc": true,"trend": true,"gene_tag": true,"fdr": true, "_id": false}'
fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_methy_diff",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()
fetched_data %>%
  dplyr::mutate(tag = purrr::map(gene_tag,.f=function(.x){strsplit(.x,"_")[[1]][1]})) %>%
  dplyr::select(-gene_tag) %>%
  tidyr::unnest(tag) -> fetched_data

# Sort ----------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/common_used_summary_plot_functions.R"))

fetched_data_clean_pattern <- fn_get_pattern(.x = fetched_data %>% dplyr::mutate(value=10^(-log10(fdr))),
                                             trend1="Up",
                                             trend2="Down",
                                             p_cutoff=1.3,
                                             selections = c("cancertype","symbol"))
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern)
gene_rank <- fn_get_gene_rank(.x = fetched_data_clean_pattern)

for_plot <- fetched_data %>%
  dplyr::mutate(group = ifelse(fdr<=0.05,"<=0.05",">0.05")) %>%
  dplyr::mutate(logfdr=-log10(fdr))

# Plot --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_bubble_plot_immune.R"))
for_plot %>%
  dplyr::filter(!is.na(fc)) %>%
  .$fc %>% range() -> min_max
floor(min_max[1]) -> min
ceiling(min_max[2]) -> max
fillbreaks <- sort(unique(c(0,min,max)))
title <- "Methylation difference in each cancer"
plot <- bubble_plot(data=for_plot, 
                    cancer="cancertype", 
                    gene="symbol", 
                    xlab="Cancer type", 
                    ylab="Symbol",
                    facet_exp=NA,
                    size="logfdr",
                    fill="fc",
                    fillmipoint =0,
                    fillbreaks =fillbreaks,
                    colorgroup="group",
                    cancer_rank=cancer_rank$cancertype, 
                    gene_rank=gene_rank$symbol, 
                    sizename= "-Log10(FDR)", 
                    colorvalue=c("black","grey"),
                    colorbreaks=c("<=0.05",">0.05"),
                    colorname="FDR", 
                    fillname="Methy. diff(T-N)", 
                    title=title) +
  guides(fill=guide_colourbar(title.position="top", reverse = TRUE))

# save --------------------------------------------------------------------
ggsave(filename = filepath,plot = plot, device = 'png', width = size$width, height = size$height)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = size$width, height = size$height)
