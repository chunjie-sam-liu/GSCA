
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str = 'A2M@ACC_all_expr#BLCA_all_expr#BRCA_all_expr#CESC_all_expr#CHOL_all_expr#COAD_all_expr#DLBC_all_expr#ESCA_all_expr#GBM_all_expr#HNSC_all_expr#KICH_all_expr#KIRC_all_expr#KIRP_all_expr#LAML_all_expr#LGG_all_expr#LIHC_all_expr#LUAD_all_expr#LUSC_all_expr#MESO_all_expr#OV_all_expr#PAAD_all_expr#PCPG_all_expr#PRAD_all_expr#READ_all_expr#SARC_all_expr#SKCM_all_expr#STAD_all_expr#TGCT_all_expr#THCA_all_expr#THYM_all_expr#UCEC_all_expr#UCS_all_expr#UVM_all_expr'
# filepath = '/home/liucj/github/GSCA/gsca-r-plot/pngs/a7b217d6-d881-47d7-8ad6-2fdf78cf5049.png'
# apppath <- '/home/liucj/github/GSCA'


search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]


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
source(file.path(apppath,"gsca-r-app/utils/fn_boxplot_single_gene_in_cancer.R"))
CPCOLS <- c("#000080", "#F8F8FF", "#CD0000")
plot <- box_plot_single_gene_multi_cancers(
  data = fetched_data,
  aesx = "type",
  aesy="expr",
  facets=".~cancertype",
  color = "type",
  color_name = "Group",
  color_labels = c("Tumor", "Normal"),
  color_values = c(CPCOLS[3], CPCOLS[1]),
  title = glue::glue('{search_genes} expression across TCGA cancer types'),
  xlab = 'Cancer type', 
  ylab = 'Expression log2(RSEM)'
)


# Save image --------------------------------------------------------------

ggsave(filename = filepath, plot = plot, device = 'png', width = 18, height = 5)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 20, height = 5)
