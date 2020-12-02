
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str = 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_expr_survival#KIRC_expr_survival#KIRP_expr_survival#LUAD_expr_survival#LUSC_expr_survival'
# filepath = 'home/huff/github/GSCA/gsca-r-plot/pngs/b47556d1-e6ee-4b8b-aae0-2a7db026cebf.png'
# apppath <- '/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(search_genes,search_cancertypes)

# fetch data --------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
fields <- '{"symbol": true, "pval": true, "higher_risk_of_death": true,"HR": true, "_id": false}'
fetched_data <- purrr::map(.x = search_cancertypes, .f = fn_fetch_mongo, pattern="_expr_survival",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()


# Sort -------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/common_used_summary_plot_functions.R"))

fetched_data_clean_pattern <- fn_get_pattern(
  .x = fetched_data %>% dplyr::rename(value=pval,trend=higher_risk_of_death),
  trend1="Higher expr.",
  trend2="Lower expr.",
  p_cutoff=0.05,
  selections =c("cancertype","symbol"))
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern)
gene_rank <- fn_get_gene_rank(.x = fetched_data_clean_pattern)
for_plot <- fn_pval_label(.x = fetched_data %>% dplyr::rename(value=pval))

# Plot --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_survival_summary_plot.R"))
CPCOLS <- c("blue", "white", "red")
color_color <-  c("tomato","lightskyblue")
color_group<- c("Higher expr.","Lower expr.")
for_plot %>%
  dplyr::filter(!is.na(HR)) %>%
  .$HR -> HR_value
min(HR_value) %>% trunc() -> min
max(HR_value) %>% ceiling() -> max
title <- ""

heat_plot <- fn_survival_summary_plot(data = for_plot,
                                      aesx = "cancertype", 
                                      aesy = "symbol",
                                      color = "higher_risk_of_death",
                                      fill = "HR",
                                      label = "p_label",
                                      y_rank = gene_rank$symbol,
                                      x_rank = cancer_rank$cancertype,
                                      fill_low = CPCOLS[1],
                                      fill_high = CPCOLS[3],
                                      fill_mid = CPCOLS[2],
                                      midpoint = 1,
                                      min = min,
                                      max = max,
                                      fill_name ="Hazard ratio",
                                      color_color = color_color,
                                      color_group = color_group,
                                      color_name = "Higher risk of death",
                                      title = title,
                                      ylab = "Gene symbol",
                                      xlab = "Cancer types")
# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = heat_plot, device = 'png', width = size$width, height = size$height)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = heat_plot, device = 'pdf', width = size$width, height = size$height)