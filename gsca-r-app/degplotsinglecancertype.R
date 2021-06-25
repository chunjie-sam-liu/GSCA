
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str = 'HERPUD1@KICH_all_expr'
# filepath = '/home/liucj/github/GSCA/gsca-r-plot/pngs/48c070a7-5daf-423b-ac35-838d550b624e.png'
# apppath <- '/home/huff/github/GSCA'


search_str_split <- strsplit(x = search_str, split = "@")[[1]]
search_genes <- strsplit(x = search_str_split[1], split = "#")[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = "#")[[1]]
search_cancertypes <- strsplit(x = search_colls, split = "_")[[1]][1]


# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, "gsca-r-app/gsca.conf"))

# Function ----------------------------------------------------------------

fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"symbol": {"$in": ["<.xx>"]}}', .open = "<", .close = ">")
}

fn_fetch_mongo_all <- function(.x) {
  .coll <- mongolite::mongo(collection = .x, url = gsca_conf)
  .coll$find(
    query = fn_query_str(search_genes),
    fields = '{"type": true, "expr": true, "_id": false}'
  ) %>%
    dplyr::mutate(cancertype = gsub(pattern = "_all_expr", replacement = "", x = .x)) %>%
    tidyr::unnest(cols = c(type, expr)) %>%
    dplyr::mutate(type = factor(x = type, levels = c("tumor", "normal")), expr = log2(expr + 1))
}


# Query data --------------------------------------------------------------
fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo_all) %>%
  dplyr::bind_rows() %>%
  dplyr::mutate(type = ifelse(type == "tumor", "Tumor", "Normal"))

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
fields <- '{"symbol": true, "fdr": true,"_id": false}'
fetched_exprdiff_data <- purrr::map(.x = paste(search_cancertypes,"_deg",sep=""), .f = fn_fetch_mongo, pattern="_deg",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows() 

# Plot --------------------------------------------------------------------
CPCOLS <- c("#000080", "#F8F8FF", "#CD0000")
source(file.path(apppath, "gsca-r-app/utils/fn_boxplot_single_gene_in_cancer.R"))

combn_matrix <- combn(sort(unique(fetched_data$type)),2)
comp_list <- list()
for(i in 1:ncol(combn_matrix)){
  comp_list[[i]] <- combn_matrix[,i]
}

plot <- box_plot_single_gene_single_cancer_nocompare(
  data = fetched_data,
  aesx = "type", 
  aesy = "expr", 
  color = "type", 
  color_name = "Group",
  color_labels = c("Normal", "Tumor"),
  color_values = c(CPCOLS[1], CPCOLS[3]), 
  title = glue::glue("{search_genes} expression in {search_cancertypes} (tumor vs. normal)"),
  xlab = "Group",
  ylab = "Expression log2(RSEM)", 
  xangle = 0,
  fdr=fetched_exprdiff_data$fdr
)


# Save image --------------------------------------------------------------
width = 6
height = 4
ggsave(filename = filepath, plot = plot, device = "png", width = width, height = height)
pdf_name <- gsub("\\.png", ".pdf", filepath)
ggsave(filename = pdf_name, plot = plot, device = "pdf", width = width * 1.2, height = height * 1.2)
