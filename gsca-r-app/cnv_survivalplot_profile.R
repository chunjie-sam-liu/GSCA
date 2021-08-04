
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]
# search_str <- 'A2M#ACE#ANGPT2#CBX2#PDL1#EZH2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_cnv_survival#KIRC_cnv_survival#KIRP_cnv_survival#LUAD_cnv_survival#LUSC_cnv_survival'
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
fields <- '{"symbol": true, "log_rank_p": true,"sur_type": true, "_id": false}'
fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_cnv_survival",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()

# Sort ----------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/common_used_summary_plot_functions.R"))

fetched_data_clean_pattern <- fn_get_pattern(
  .x = fetched_data %>% dplyr::mutate(value=log_rank_p,trend="higher_risk_of_death") %>% dplyr::filter(sur_type=="OS"),
  trend1="higher_risk_of_death",
  trend2="higher_risk_of_death",
  p_cutoff=0.05,
  selections =c("cancertype","symbol"))
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern)
gene_rank <- fn_get_gene_rank(.x = fetched_data_clean_pattern)
for_plot <- fetched_data %>% 
  dplyr::rename(value=log_rank_p) %>%
  dplyr::mutate(logp=ifelse(value==0,10,-log10(value))) %>%
  dplyr::mutate(logp=ifelse(logp>10,10,logp)) %>%
  dplyr::mutate(group=ifelse(value>0.05,">0.05","<=0.05"))

# Plot --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_bubble_plot_immune.R"))
CPCOLS <- c("blue", "white", "red")
for_plot %>%
  dplyr::filter(!is.na(logp)) %>%
  .$logp -> logp_value
min(logp_value) %>% trunc() -> min
max(logp_value) %>% ceiling() -> max
fillbreaks <- sort(unique(c(1.3,min,max,seq(min,max,length.out = 3))))

heat_plot <- bubble_plot(data=for_plot, 
                         cancer="cancertype", 
                         gene="symbol", 
                         xlab="Cancer type", 
                         ylab="Symbol", 
                         facet_exp = ".~sur_type",
                         size="logp", 
                         fill="logp", 
                         fillmipoint =1.3,
                         fillbreaks =fillbreaks,
                         colorgroup="group",
                         cancer_rank=cancer_rank$cancertype, 
                         gene_rank=gene_rank$symbol, 
                         sizename= "-Log(10) Logrank P", 
                         fillname="-Log(10) Logrank P", 
                         colorvalue=c("black","grey"), 
                         colorbreaks=c("<=0.05",">0.05"),
                         colorname="Logrank P value",
                         title="Survival difference between CNV groups")
# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = heat_plot, device = 'png', width = size$width, height = size$height+2)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = heat_plot, device = 'pdf', width = size$width, height = size$height+2)


