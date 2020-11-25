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


# plot --------------------------------------------------------------------
fn_pval_class <- function(.p){
  if(.p>0.05){
    ""
  }else if(.p<=0.05 & .p>=0.01){
    "*"
  }else if(.p<0.01 & .p>=0.001){
    "**"
  } else{
    "***"
  }
}
fn_pval_label <- function(.x){
  .x %>%
    dplyr::mutate(p_label=purrr::map(pval,fn_pval_class)) %>%
    tidyr::unnest()
}
heat_plot <- geneset_survival %>%
  dplyr::mutate(p_label=purrr::map(logrankp,fn_pval_class))%>%
  tidyr::unnest() %>%
  ggplot(aes(x = sur_type, y = cancertype)) +
  geom_tile(aes(fill = higher_risk_of_death, color=hr),height=0.8,width=0.8,size=1.5) +
  geom_text(aes(label=p_label)) +
  scale_color_gradient2(
    low = "blue",
    mid = "white",
    high = "red",
    midpoint = 1,
    na.value = "white",
    breaks = seq(0, 3, length.out = 6),
    name = "Hazard ratio"
  ) +
  scale_fill_manual(values = c("tomato","lightskyblue"),
                    limits = c("Mutated","Non-mutated"),
                    name="Higher risk of death") +
  theme(
    panel.background = element_rect(colour = "black", fill = "white"),
    panel.grid = element_line(colour = "grey", linetype = "dashed"),
    panel.grid.major = element_line(
      colour = "grey",
      linetype = "dashed",
      size = 0.2
    ),
    axis.title = element_blank(),
    axis.ticks = element_line(color = "black"),
    # axis.text.y = element_text(color = gene_rank$color),
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, colour = "black"),
    axis.text.y = element_text(colour = "black"),
    
    legend.text = element_text(size = 12),
    legend.title = element_text(size = 14),
    legend.key = element_rect(fill = "white", colour = "black"),
    strip.background = element_rect(fill="white",color="black"),
    strip.text = element_text(size= 12)
  )

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = heat_plot, device = 'png', width = size$width, height = size$height)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = heat_plot, device = 'pdf', width = size$width, height = size$height)