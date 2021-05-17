
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str = 'ALKBH1@BLCA_deg#BRCA_deg#KICH_deg#KIRC_deg#KIRP_deg#LIHC_deg'
# filepath = '/home/liucj/github/GSCA/gsca-r-plot/pngs/156d3e34-0500-40f5-b8ed-58d2512f3918.png'
# apppath <- '/home/huff/github/GSCA'


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
    fields = '{"symbol": true, "fc": true, "fdr": true, "_id": false}'
  ) %>%
    dplyr::mutate(cancertype = gsub(pattern = '_deg', replacement = '', x = .x))
}

fn_filter_fc_pval <- function(.x) {
  .x %>%
    dplyr::filter(abs(log2(fc)) >= log2(3 / 2), fdr <= 0.05) %>%
    dplyr::mutate(fdr = -log10(fdr)) %>%
    dplyr::mutate(fdr = ifelse(fdr > 15, 15, fdr)) %>%
    dplyr::mutate(fc = ifelse(fc < 1 / 8, 1 / 8, ifelse(fc > 8, 8, fc)))
}

fn_filter_pattern <- function(fc, fdr) {
  if ((fc > 3 / 2) && (fdr < 0.05)) {
    return(1)
  } else if ((fc < 2 / 3) && (fdr < 0.05)) {
    return(-1)
  } else {
    return(0)
  }
}

fn_get_pattern <- function(.x) {
  .x %>%
    dplyr::mutate(expr_pattern = purrr::map2_dbl(fc, fdr, fn_filter_pattern)) %>%
    dplyr::select(cancertype, symbol, expr_pattern) %>%
    tidyr::spread(key = cancertype, value = expr_pattern) %>%
    dplyr::mutate_if(.predicate = is.numeric, .funs = function(.) {ifelse(is.na(.), 0, .)})
}

fn_get_cancer_types_rank <- function(.x) {
  .x %>%
    dplyr::summarise_if(.predicate = is.numeric, dplyr::funs(sum(abs(.)))) %>%
    tidyr::gather(key = cancertype, value = rank) %>%
    dplyr::arrange(dplyr::desc(rank))
}

fn_get_gene_rank <- function(.x) {
  .x %>%
    dplyr::rowwise() %>%
    dplyr::do(
      symbol = .$symbol,
      rank = unlist(.[-1], use.names = F) %>% sum(),
      up = (unlist(.[-1], use.names = F) == 1) %>% sum(),
      down = (unlist(.[-1], use.names = F) == -1) %>% sum()
    ) %>%
    dplyr::ungroup() %>%
    tidyr::unnest(cols = c(symbol, rank, up, down)) %>%
    dplyr::mutate(up_p = up / 14, down_p = down / 14, none = 1 - up_p - down_p) %>%
    dplyr::arrange(rank)
}

# Query data --------------------------------------------------------------
fetched_data <- purrr::map(.x = search_cancertypes, .f = fn_fetch_mongo) %>% dplyr::bind_rows()%>%
  dplyr::mutate(group=ifelse(fdr>0.05,">0.05","<0.05"))

# Sort --------------------------------------------------------------------

fetched_data_clean_pattern <- fn_get_pattern(.x = fetched_data)
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern)
gene_rank <- fn_get_gene_rank(.x = fetched_data_clean_pattern)

# fetched_data_filter <- fn_filter_fc_pval(.x = fetched_data)

# Plot --------------------------------------------------------------------
CPCOLS <- c("#000080", "#F8F8FF", "#CD0000")
# CPCOLS <- c("#ffffff", RColorBrewer::brewer.pal(9, "Set1"))
# CPCOLS <- c("#ffffff", ggsci::pal_lancet()(9))
# CPCOLS %>% scales::show_col()
fetched_data$fc %>% log2() %>% range() -> fc_range

min(fc_range) %>% floor() -> fc_min
max(fc_range) %>% ceiling() -> cc
fillbreaks <- sort(unique(c(0,round(c(fc_min,fc_max,seq(fc_min,fc_max,length.out = 3))))))

fetched_data %>%
  ggplot(aes(x = cancertype, y = symbol)) +
  geom_point(aes(size = -log2(fdr), fill = log2(fc), colour=group), shape = 21,stroke = 1) +
  scale_fill_gradient2(
    low = CPCOLS[1],
    mid = CPCOLS[2],
    high = CPCOLS[3],
    midpoint = 0,
    na.value = "white",
    limits=c(min(fillbreaks),max(fillbreaks)),
    breaks =fillbreaks,
    name = "log2(FC)"
  ) +
  scale_size_continuous(
    guide=FALSE
  ) +
  scale_color_manual(values = c("black","grey"),
                     breaks = c("<0.05",">0.05"),
                     name="FDR")+
  scale_y_discrete(limit = gene_rank$symbol) +
  scale_x_discrete(limit = cancer_rank$cancer_types) +
  theme(
    panel.background = element_rect(colour = "black", fill = "white"),
    panel.grid = element_line(colour = "grey", linetype = "dashed"),
    panel.grid.major = element_line(
      colour = "grey",
      linetype = "dashed",
      size = 0.2
    ),
    plot.title = element_text(size = 18, hjust = 0.5),
    axis.title = element_text(color = "black", size = 14),
    axis.ticks = element_line(color = "black"),
    axis.text.x = element_text(size = 12, angle = 90, hjust = 1, vjust = 0.5, colour = "black"),
    axis.text.y = element_text(colour = "black", size = 12),
    legend.text = element_text(size = 12),
    legend.title = element_text(size = 14),
    legend.key = element_rect(fill = "white", colour = "black")
  ) +
  labs(
    x = "Cancer types",
    y = "Gene symbols",
    title = "DEGs in each cancer types"
  ) -> bubble_plot


# Save --------------------------------------------------------------------

width = 7 / 5 * length(search_cancertypes)
height = 8 / 18 * length(search_genes)

width <- max(c(7, width))
height <- max(c(7, height))

ggsave(filename = filepath, plot = bubble_plot, device = 'png', width = width, height = height)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = bubble_plot, device = 'pdf', width = width,  height = height)

