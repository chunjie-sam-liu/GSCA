# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)
# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]
# search_str <- 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_cnv_survival#KIRC_cnv_survival#KIRP_cnv_survival#LUAD_cnv_survival#LUSC_cnv_survival'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
# search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()


# load data ---------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/cnv_survival_geneset.R"))

# geneset_survival <-  readr::read_tsv(file.path(apppath,"gsca-r-plot/tables","geneset_survival_table.tsv"))

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(search_genes,search_cancertypes)

color_list <- tibble::tibble(cnv=c(-2,-1,0,1,2),
                             group_detail=c("Homo. dele.","Hete. dele.","WT","Hete. amp.","Homo. amp."),
                             group=c("Dele.","Dele.","WT","Amp.","Amp."),
                             color=c( "#00B2EE","#00B2EE","gold4","#CD2626","#CD2626"))

# rank --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/common_used_summary_plot_functions.R"))
fetched_data_clean_pattern <- fn_get_pattern(
  .x = geneset_survival %>% dplyr::mutate(value=logrankp,trend="higher_risk_of_death"),
  trend1="higher_risk_of_death",
  trend2="higher_risk_of_death",
  p_cutoff=0.05,selections = c("cancertype","sur_type"))
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern)

# plot --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_survival_summary_plot.R"))
geneset_survival %>%
  dplyr::mutate(sur_type=toupper(sur_type)) %>%
  dplyr::mutate(logp=ifelse(logrankp==0,10,-log10(logrankp))) %>%
  dplyr::mutate(logp=ifelse(logp>10,10,logp)) -> for_plot
CPCOLS <- c("blue", "white", "red")
title <- ""

heat_plot <- fn_survival_summary_plot_onlyP(data = for_plot,
                                            aesx = "sur_type", 
                                            aesy = "cancertype",
                                            fill = "logp",
                                            fill_low=CPCOLS[1],
                                            fill_high=CPCOLS[3],
                                            fill_mid=CPCOLS[2],
                                            fill_midpoint=1.3,
                                            y_rank = cancer_rank$cancertype,
                                            x_rank = c("OS","PFS"),
                                            min=0,
                                            max=10,
                                            fill_name = "-Log(10) P",title = "",xlab = "",ylab = "Cancer types")
# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = heat_plot, device = 'png', width = 4, height = size$height)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = heat_plot, device = 'pdf', width = 4, height = size$height)