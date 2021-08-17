
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]
# search_str <- "A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_methy_survival#KIRC_methy_survival#KIRP_methy_survival#LUAD_methy_survival#LUSC_methy_survival"
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
fields <- '{"symbol": true, "log_rank_p": true,"cox_p": true,"higher_risk_of_death": true,"HR": true,"sur_type": true,"_id": false}'
fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_methy_survival",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()

# Sort ----------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/common_used_summary_plot_functions.R"))

fetched_data_clean_pattern <- fn_get_pattern(
  .x = fetched_data %>% dplyr::rename(value=cox_p,trend=higher_risk_of_death),
  trend1="Hypermethylation",
  trend2="Hypomethylation",
  p_cutoff=0.05,
  selections =c("cancertype","symbol"))
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern)
gene_rank <- fn_get_gene_rank_v2(.x = fetched_data_clean_pattern)
for_plot <- fn_pval_label(.x = fetched_data %>% dplyr::rename(value=cox_p)) %>%
  dplyr::filter(!is.na(HR)) %>%
  dplyr::mutate(HR = ifelse(HR>10,10,HR)) %>%
  dplyr::mutate(logp = -log10(value),
                group = ifelse(value>0.05,">0.05","<=0.05"))

# Plot --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_bubble_plot_immune.R"))
CPCOLS <- c("blue", "white", "red")
color_color <-  c("tomato","lightskyblue")
color_group<- c("Hypermethylation","Hypomethylation")
for_plot %>%
  .$HR -> HR_value
min(HR_value) %>% trunc() -> min
max(HR_value) %>% ceiling() -> max
fillbreaks <- sort(unique(c(1,min,max,seq(min,max,length.out = 3))))

title <- "Survival difference between high and low\nmethylation in each cancer"
heat_plot <- bubble_plot(data=for_plot, 
                         cancer="cancertype", 
                         gene="symbol", 
                         xlab="Cancer type", 
                         ylab="Symbol", 
                         facet_exp = ".~sur_type",
                         size="logp", 
                         fill="HR", 
                         fillmipoint =1,
                         fillbreaks =fillbreaks,
                         colorgroup="group",
                         cancer_rank=cancer_rank$cancertype, 
                         gene_rank=gene_rank$symbol, 
                         sizename= "-Log(Cox P)", 
                         fillname="Hazard ratio", 
                         colorvalue=c("black","grey"), 
                         colorbreaks=c("<=0.05",">0.05"),
                         colorname="Cox P value",
                         title=title)


# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = heat_plot, device = 'png', width = size$width, height = size$height+2)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = heat_plot, device = 'pdf', width = size$width, height = size$height+2)


