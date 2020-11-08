
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str = 'A2M@KICH_all_expr'
# filepath = '/home/liucj/github/GSCA/gsca/resource/pngs/48c070a7-5daf-423b-ac35-838d550b624e.png'
# apppath <- '/home/liucj/github/GSCA'


search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]


# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca/rscripts/gsca.conf'))

# Function ----------------------------------------------------------------

fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"symbol": {"$in": ["<.xx>"]}}', .open = '<', .close = '>')
}

fn_fetch_mongo <- function(.x) {
  .coll <- mongolite::mongo(collection = .x, url = gsca_conf)
  .coll$find(
    query = fn_query_str(search_genes),
    fields = '{"type": true, "expr": true, "_id": false}'
  ) %>% 
    dplyr::mutate(cancertype = gsub(pattern = '_all_expr', replacement = '', x = .x)) %>% 
    tidyr::unnest(cols = c(type, expr)) %>% 
    dplyr::mutate(type = factor(x = type, levels = c('tumor', 'normal')), expr = log2(expr + 1))
}


# Query data --------------------------------------------------------------
fetched_data <- purrr::map(.x = search_cancertypes, .f = fn_fetch_mongo) %>% 
  dplyr::bind_rows()


# Plot --------------------------------------------------------------------
CPCOLS <- c("#000080", "#F8F8FF", "#CD0000")
fetched_data %>% 
  ggplot(aes(x = cancertype, y = expr, color = type)) +
  geom_boxplot(outlier.colour = NA) +
  scale_color_manual(name = "Type", labels = c("Tumor", "Normal"), values = c(CPCOLS[3], CPCOLS[1])) +
  theme(
    panel.background = element_rect(colour = "black", fill = "white"),
    panel.grid = element_line(colour = "grey", linetype = "dashed"),
    panel.grid.major = element_line(
      colour = "grey",
      linetype = "dashed",
      size = 0.2
    ),
    plot.title = element_text(hjust = 0.5),
    axis.ticks = element_line(color = "black"),
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, colour = "black"),
    axis.text.y = element_text(colour = "black"),
    legend.position = 'right',
    legend.text = element_text(size = 12),
    legend.title = element_text(size = 14),
    legend.key = element_rect(fill = "white")
  ) +
  labs(title = glue::glue("{search_genes} expression in TCGA-{gsub(pattern = '_all_expr', replacement = '', x = search_cancertypes)} cancer types"), x = 'Cancer type', y = 'Expression log2(RSEM)') ->
  singlegene_boxplot


# Save image --------------------------------------------------------------

ggsave(filename = filepath, plot = singlegene_boxplot, device = 'png', width = 5, height = 5)
