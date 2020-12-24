
# snvplot profile ---------------------------------------------------------


# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str = 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_snv_count#KIRC_snv_count#KIRP_snv_count#LUAD_snv_count#LUSC_snv_count'
# filepath = '/home/huff/github/GSCA/gsca-r-plot/pngs/af3526dd-4f45-4e56-8f85-c1de4c8439e3.png'
# apppath = '/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]



# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(search_genes,search_cancertypes)

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

# Function ----------------------------------------------------------------

fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"symbol": {"$in": ["<.xx>"]}}', .open = '<', .close = '>')
}

fn_fetch_mongo <- function(.x) {
  .coll <- mongolite::mongo(collection = .x, url = gsca_conf)
  .coll$find(
    query = fn_query_str(search_genes),
    fields = '{"symbol": true, "percentage": true,"sample_size": true, "EffectiveMut": true ,"_id": false}'
  ) %>%
    dplyr::mutate(cancertype = gsub(pattern = '_snv_count', replacement = '', x = .x))
}

fn_heatmap <- function( data, cancer, gene, fill, label, cancer_rank, gene_rank){
  limit_high <- data$percentage %>% max()
  if(limit_high<=10){
    limit_high <- 10
    seq <- 2
  } else{
    seq <- 5
  }
  data %>%
    ggplot(aes_string(x = cancer, y = gene, fill = fill)) +
    geom_tile() +
    geom_text(aes_string(label = label)) +
    scale_x_discrete(position = "top", limits = cancer_rank$x_label) +
    scale_y_discrete(limits = gene_rank$symbol) +
    scale_fill_gradient2(
      name = "Mutation freq. (%)",
      limit = c(0, limit_high),
      breaks = seq(0, limit_high, seq),
      high = "red",
      na.value = "white"
    ) +
    theme_bw() +
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
      axis.text.x = element_text(colour = "black",angle = 45, hjust = -0.05),
      axis.text.y = element_text(colour = "black"),
      
      legend.text = element_text(size = 12),
      legend.title = element_text(size = 14),
      legend.key = element_rect(fill = "white", colour = "black")
    )+
    guides(fill = guide_legend(
      title = "Mutation freq. (%)",
      title.position = "left",
      title.theme = element_text(angle = 90, vjust = 2),
      reverse = T,
      keywidth = 0.6,
      keyheight = 0.8
    )) +
    labs(x = "", y = "", title = "SNV percentage heatmap") -> p
  return(p)
}
# Query data --------------------------------------------------------------

fetched_data <- purrr::map(.x = search_cancertypes, .f = fn_fetch_mongo) %>% dplyr::bind_rows() 


# data process ------------------------------------------------------------

fetched_data %>%
  tidyr::drop_na() %>%
  dplyr::mutate(x_label = paste(cancertype, " (n=", sample_size , ")", sep = "")) %>%
  # dplyr::mutate(sm_count = ifelse(sm_count > 0, sm_count, NA)) %>%
  dplyr::mutate(percentage = ifelse(is.na(percentage) , 0, percentage)) %>%
  dplyr::mutate(percentage =percentage) -> snv_per_plot_ready
snv_per_plot_ready %>%
  dplyr::group_by(x_label) %>%
  dplyr::summarise(s = sum(percentage)) %>%
  dplyr::arrange(dplyr::desc(s)) -> snv_per_cancer_rank
snv_per_plot_ready %>%
  dplyr::group_by(symbol) %>%
  dplyr::summarise(s = sum(percentage)) %>%
  dplyr::arrange(s) -> snv_per_gene_rank

# plot --------------------------------------------------------------------

p <- fn_heatmap(data = snv_per_plot_ready,
           cancer = "x_label", gene = "symbol", fill = "percentage", label = "EffectiveMut",
           cancer_rank = snv_per_cancer_rank, gene_rank = snv_per_gene_rank)

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = p, device = 'png', width = size$width, height = size$height)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = p, device = 'pdf', width = size$width, height = size$height)