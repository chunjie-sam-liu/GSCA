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

source(file.path(apppath,"gsca-r-app/utils/fn_pieplot.R"))
fetched_data %>%
  dplyr::group_by(cancertype) %>%
  dplyr::summarise(v = sum(a_total - d_total)) %>%
  dplyr::arrange(dplyr::desc(v)) -> cnv_cancer_rank

# gene rank ----
fetched_data %>%
  dplyr::group_by(symbol) %>%
  dplyr::summarise(v = sum(a_total - d_total)) %>%
  dplyr::arrange(v) -> cnv_gene_rank

fetched_data %>%
  dplyr::select(-a_total, -d_total) %>%
  tidyr::gather(key = type, value = per, -c(cancertype , symbol)) %>%
  dplyr::mutate(
    symbol = factor(x = symbol, levels = cnv_gene_rank$symbol),
    cancertype  = factor(x = cancertype , levels = cnv_cancer_rank$cancertype)
  ) -> pie_plot_ready

plot <- fn_pie_plot(data=pie_plot_ready, aesy= "per",fill="type",facet_grid= "symbol ~ cancertype",
                    fill_limits=c("a_hete", "a_homo", "d_hete", "d_homo", "other"),
                    fill_label=c("Hete. Amp.", "Homo. Amp.", "Hete. Del.", "Homo. Del.", "None"),
                    fill_value=c("brown1", "brown4", "aquamarine3", "aquamarine4", "grey"),
                    title = "CNV percentage in each cancer")

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = size$width-3, height = size$height)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = size$width-3, height = size$height)
