
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
fields <- '{"symbol": true, "log_rank_p": true,"cox_p": true,"sur_type": true,"higher_risk_of_death": true,"HR": true, "_id": false}'
fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_snv_survival",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()

if(nrow(fetched_data)>0){
  # Sort ----------------------------------------------------------------
  source(file.path(apppath,"gsca-r-app/utils/common_used_summary_plot_functions.R"))
  
  fetched_data_clean_pattern <- fn_get_pattern(
    .x = fetched_data %>% 
      dplyr::filter(!is.na(cox_p)) %>%
      dplyr::rename(value=cox_p,trend=higher_risk_of_death) %>% 
      dplyr::filter(sur_type=="OS"),
    trend1="WT",
    trend2="Mutant",
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
  for_plot %>%
    .$HR -> HR_value
  min(HR_value) %>% trunc() -> min
  max(HR_value) %>% ceiling() -> max
  fillbreaks <- sort(unique(c(1,seq(min,max,length.out = 3))))
  
  title <- "Survival difference between mutant and WT"
  
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
                           sizename= "Cox P value", 
                           fillname="Hazard ratio", 
                           colorvalue=c("black","grey"), 
                           colorbreaks=c("<=0.05",">0.05"),
                           colorname="Cox P value",
                           title=title)
  
  # Save --------------------------------------------------------------------
  ggsave(filename = filepath, plot = heat_plot, device = 'png', width = (size$width)*2.5, height = size$height)
  pdf_name <- gsub("\\.png",".pdf",filepath)
  ggsave(filename = pdf_name, plot = heat_plot, device = 'pdf', width = (size$width)*2.5, height = size$height)
}else{
  source(file.path(apppath, "gsca-r-app/utils/fn_NA_notice_fig.R"))
  fn_NA_notice_fig("Caution: \nsurvival analysis is not applicable\nfor your search.\nPlease check if there are no mutations\n found in your search gene list?") -> p
  # Save --------------------------------------------------------------------
  ggsave(filename = filepath, plot = p, device = 'png', width = 6, height = 4)
  pdf_name <- gsub("\\.png",".pdf",filepath)
  ggsave(filename = pdf_name, plot = p, device = 'pdf', width = 6, height = 4)
}



