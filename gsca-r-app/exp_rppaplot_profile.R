
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

# search_str = "TP53@ACC_rppa_diff"
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
  dplyr::mutate(per=round(100*n/N_cancers)) %>%
  dplyr::select(symbol,pathway,class,per) %>%
  unique() %>%
  dplyr::ungroup() %>%
  dplyr::filter(!is.na(class)) %>%
  dplyr::filter(!is.na(per)) %>%
  tidyr::spread(key = "class",value="per") -> rppa_percent

false.match<-c()
for (i in c("Activation", "None", "Inhibition")) {
  colnames(rppa_percent)[3:5] %in% i -> .match
  if(!.match){
     c(false.match,i) -> false.match
  }
}
if(length(false.match)>0){
  for (x in false.match) {
    rppa_percent %>%
      dplyr::mutate(false.match=NA) %>%
      tidyr::gather(-symbol,-pathway,key="class",value = "value") %>%
      dplyr::mutate(class=ifelse(class=="false.match",x,class)) %>%
      dplyr::mutate(value=ifelse(is.na(value),0,value)) %>%
      tidyr::spread(key = "class",value="value") -> rppa_percent
  }
 
} else {
  rppa_percent %>%
    tidyr::gather(-symbol,-pathway,key="class",value = "value") %>%
    dplyr::mutate(value=ifelse(is.na(value),0,value)) %>%
    tidyr::spread(key = "class",value="value") -> rppa_percent
}
rppa_percent %>%
  dplyr::filter(Activation+Inhibition>=5) -> rppa_percent.filter
  
rppa_percent.filter %>%
  tidyr::gather(-symbol,-pathway,key=class,value="per") %>%
  dplyr::mutate(per=ifelse(class=="Inhibition",-per,per)) %>%
  dplyr::mutate(pathway = paste(pathway,substring(class,1,1),sep="_")) %>%
  dplyr::filter(class!="None") -> rppa_per_ready

# bubble_plot --------------------------------------------------------------------
source(file.path(apppath, "gsca-r-app/utils/fn_NA_notice_fig.R"))
if(nrow(rppa_per_ready)>0){
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
} else {
  fn_NA_notice_fig("Caution: no significant result for your search,\ninput more genes could help.") -> percent_plot
  # Save --------------------------------------------------------------------
  ggsave(filename = filepath_stagepoint, plot = percent_plot, device = 'png', width = size$width, height = 4)
  filepath_stagepoint_pdf_name <- gsub("\\.png",".pdf",filepath_stagepoint)
  ggsave(filename = filepath_stagepoint_pdf_name, plot = percent_plot, device = 'pdf', width = size$width, height = 4)
}



