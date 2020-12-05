# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str <- 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_cnv_percent#KIRC_cnv_percent#KIRP_cnv_percent#LUAD_cnv_percent#LUSC_cnv_percent'
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
fields <- '{"symbol": true, "a_total": true,"d_total": true,"a_hete": true,"d_hete": true,"a_homo": true,"d_homo": true,"other": true,"_id": false}'
fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_cnv_percent",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()

# plot --------------------------------------------------------------------
fetched_data %>%
  dplyr::select(cancertype, symbol, a_hete, d_hete) %>%
  tidyr::gather(key = type, value = per, -cancertype, -symbol) %>%
  dplyr::mutate(effect = plyr::revalue(type, replace = c("a_hete" = "Hetezygous amplification", "d_hete" = "Hetezygous deletion"))) %>%
  dplyr::mutate(color = plyr::revalue(type, replace = c("a_hete" = "brown4", "d_hete" = "aquamarine4"))) %>%
  dplyr::mutate(per=ifelse(per==0,NA,per*100)) -> plot_ready

source(file.path(apppath,"gsca-r-app/utils/fn_cnv_bubble.R"))

plot <- fn_cnv_bubble(data=plot_ready, aesx = "cancertype",aesy="symbol",size="per",color="color",xlab="Cancer type",ylab="Symbol",sizename="CNV (%)",colorname="SCNA type",labels=c("Deletion","Amplification"),wrap="~ effect")

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = size$width, height = size$height)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = size$width, height = size$height)
