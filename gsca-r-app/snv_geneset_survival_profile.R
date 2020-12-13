# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)
# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]
# search_str <- 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_snv_survival#KIRC_snv_survival#KIRP_snv_survival#LUAD_snv_survival#LUSC_snv_survival'
# apppath <- '/home/huff/github/GSCA'
# filepath <- '/home/huff/github/GSCA/gsca-r-plot/pngs/0b7ebc57-c2bd-4fd0-8775-5458e514cdb1.png'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
# search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()


# load data ---------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/snv_survival_geneset.R"))

# geneset_survival <-  readr::read_tsv(file.path(apppath,"gsca-r-plot/tables","geneset_survival_table.tsv"))

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(search_genes,search_cancertypes)

color_list <- tibble::tibble(color=c( "#CD2626","#00B2EE"),
                             group=c("Mutated","Non-mutated"))

# rank --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/common_used_summary_plot_functions.R"))
fetched_data_clean_pattern <- fn_get_pattern(
  .x = geneset_survival %>% dplyr::rename(value=logrankp,trend=higher_risk_of_death),
  trend1="Mutated",
  trend2="Non-mutated",
  p_cutoff=0.05,selections = c("cancertype","sur_type"))
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern)

# plot --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_bubble_plot_immune.R"))
geneset_survival %>%
  dplyr::mutate(sur_type=toupper(sur_type)) %>%
  dplyr::rename(value=logrankp) %>% fn_pval_label() %>%
  dplyr::mutate(group = ifelse(value>0.05,">0.05","<0.05")) %>%
  dplyr::mutate(logp = -log10(value))-> for_plot
CPCOLS <- c("blue", "white", "red")
color_color <-  c("tomato","lightskyblue")
color_group<- c("Mutated","Non-mutated")
for_plot %>%
  dplyr::filter(!is.na(hr)) %>%
  .$hr -> HR_value
min(HR_value) %>% trunc() -> min
max(HR_value) %>% ceiling() -> max
fillbreaks <- sort(unique(c(1,min,max,seq(min,max,length.out = 3))))
title <- ""

heat_plot <- bubble_plot(data=for_plot, 
                         cancer="sur_type", 
                         gene="cancertype", 
                         xlab="", 
                         ylab="Cancer type", 
                         facet_exp = NA,
                         size="logp", 
                         fill="hr", 
                         fillmipoint =1,
                         fillbreaks =fillbreaks,
                         colorgroup="group",
                         cancer_rank=c("OS","PFS"), 
                         gene_rank=cancer_rank$cancertype, 
                         sizename= "-Log(P)", 
                         fillname="Hazard ratio", 
                         colorvalue=c("black","grey"), 
                         colorbreaks=c("<0.05",">0.05"),
                         colorname="Logrank P",
                         title=title)
# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = heat_plot, device = 'png', width = 4, height = size$height)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = heat_plot, device = 'pdf', width = 4, height = size$height)