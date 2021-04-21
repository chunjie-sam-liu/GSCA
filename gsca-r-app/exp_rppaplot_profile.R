
# stage profile plot ------------------------------------------------------

# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath_stagepoint <- args[2]
apppath <- args[3]

# search_str = "A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@ESCA_rppa_diff#HNSC_rppa_diff#KICH_rppa_diff#KIRC_rppa_diff#KIRP_rppa_diff#LUAD_rppa_diff#LUSC_rppa_diff"
# filepath = "/home/huff/github/GSCA/gsca-r-plot/pngs/1c16fb64-8ef4-4789-a87a-589d140c5bbe.png"
# apppath = '/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()
# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(search_genes,search_cancertypes)
size$width <- 6 
# fetch data --------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
fields <- '{"symbol": true, "pathway": true,"fdr": true,"diff": true, "_id": false}'
fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_rppa_diff",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()


# data process ------------------------------------------------------------

fetched_data  %>%
  dplyr::mutate(class = ifelse(fdr <= 0.05 & diff > 0, "Activation", "None")) %>%
  dplyr::mutate(class = ifelse(fdr <= 0.05 & diff < 0, "Inhibition", class)) -> rppa_class

N_cancers <- length(search_cancertypes)
rppa_class %>%
  dplyr::group_by(symbol,pathway,class) %>%
  dplyr::mutate(n=dplyr::n()) %>%
  dplyr::select(symbol,pathway,class,n) %>%
  unique() %>%
  dplyr::ungroup() %>%
  dplyr::filter(!is.na(class)) %>%
  dplyr::filter(!is.na(n)) %>%
  tidyr::spread(key = "class",value="n") %>%
  dplyr::mutate(Activation=ifelse(is.na(Activation),0,round(100*Activation/N_cancers))) %>%
  dplyr::mutate(Inhibition=ifelse(is.na(Inhibition),0,round(100*Inhibition/N_cancers))) %>%
  dplyr::mutate(None=100-Activation-Inhibition) %>%
  dplyr::filter(Activation+Inhibition>=5)-> rppa_percent
  
rppa_percent %>%
  tidyr::gather(-symbol,-pathway,key=class,value="per") %>%
  dplyr::mutate(per=ifelse(class=="Inhibition",-per,per)) %>%
  dplyr::mutate(pathway = paste(pathway,substring(class,1,1),sep="_")) %>%
  dplyr::filter(class!="None") -> rppa_per_ready

# bubble_plot --------------------------------------------------------------------
rppa_per_ready %>%
  ggplot(aes(x = pathway, y = symbol)) +
  xlab("Pathway") + ylab("Symbol") +
  guides(fill = guide_colorbar("Percent")) +
  geom_tile(aes(fill = per), col = "white") +
  geom_text(
    label = ceiling(rppa_per_ready$per)
    # size = 1
  ) +
  scale_fill_gradient2(
    high = "red",
    mid = "white",
    low = "blue"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
    axis.text = element_text(colour = "black",size = 10),
    axis.title = element_text(size = 13),
    # legend.key.size = unit(0.25, "cm"),
    legend.position = "bottom",
    plot.margin = rep(unit(0, "null"), 4),
    axis.ticks.length = unit(0, "cm"),
    # legend.text = element_text(size = 5),
    # axis.title.x = element_text(size = 6),
    # axis.title.y = element_text(size = 6),
    # legend.title = element_text(size = 6),
    panel.background = element_rect(fill = "white", color = NA),
    panel.grid = element_line(colour = "grey", linetype = "dashed"),
    panel.grid.major = element_line(
      colour = "grey",
      linetype = "dashed",
      size = 0.2
    )
  ) +
  xlab("Pathway (A:Activate; I:Inhibit)") -> percent_plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath_stagepoint, plot = percent_plot, device = 'png', width = size$width, height = size$height)
filepath_stagepoint_pdf_name <- gsub("\\.png",".pdf",filepath_stagepoint)
ggsave(filename = filepath_stagepoint_pdf_name, plot = percent_plot, device = 'pdf', width = size$width, height = size$height)
