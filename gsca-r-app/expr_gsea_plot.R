
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
filepath <- args[3]
apppath <- args[4]


# tableuuid <- 'cf7c811d-3626-4a28-b050-57cd6521e9b2'
# tablecol <- 'preanalysised_gsea'
# filepath <- "/home/liucj/github/GSCA/gsca-r-plot/pngs/217c27f6-c12a-413d-8625-b9748fc1ff65.png"
# apppath <- '/home/liucj/github/GSCA'

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))
pre_gsea_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsea_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_expr"), url = gsca_conf)
# Function ----------------------------------------------------------------
fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"uuid": "<.xx>"}', .open = '<', .close = '>')
}


fn_fetch_data <- function(.uuid) {
  pre_gsea_coll$find(query = fn_query_str(.x = tableuuid), fields = '{"_id": false}')
}

fn_reorg <- function(.x) {
  .x %>%
    tidyr::unnest(cols = c(symbol, log2fc)) %>%
    tibble::deframe() %>% 
    sort() -> 
    .xx
  
  .fgseares <- fgsea::fgsea(list("Gene set" = gene_set), .xx)
  
  .fgseares %>% 
    as.data.frame() %>% 
    tibble::as_tibble() %>% 
    dplyr::select(-c(pathway, leadingEdge, size))
  
}

# Process -----------------------------------------------------------------

fetched_data <- fn_fetch_data(.uuid = tableuuid)

gene_set <- fetched_data$gene_set[[1]]

fetched_data$gsea_score %>%
  tibble::as_tibble() %>%
  tidyr::gather(key = "cancertype", value = "gsea") %>% 
  dplyr::mutate(gsea = purrr::map(.x = gsea, .f = fn_reorg)) %>% 
  tidyr::unnest(cols = gsea) %>% 
  dplyr::arrange(NES) ->
  gsea_score_test

# Insert table ------------------------------------------------------------
insert_data <- list(uuid = tableuuid, res_table = gsea_score_test)
# post_gsva_coll$drop()
uuid_query <- post_gsea_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"uuid": true, "_id": false}'
)

if (nrow(uuid_query) == 0) {
  post_gsea_coll$insert(data = insert_data)
  post_gsea_coll$index(add = '{"uuid": 1}')
  message("insert data into preanalysised_gsea")
}


# Plot --------------------------------------------------------------------
gsea_score_test %>% 
  dplyr::mutate(padj = -log10(padj)) %>% 
  ggplot(aes(x = reorder(cancertype, NES), y = NES, fill = padj)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  theme_bw() +
  theme(
    legend.position = "bottom",
  ) +
  guides(
    fill = guide_colourbar(
      title = "-log10(Padj)", 
      title.position = "top",
      title.hjust = 0.5,
    )
  )+
  labs(
    x = "Cancer type",
    y = "NES",
    title = "Enrichment score in selected cancer types"
  ) ->
  gsea_plot

# Save image --------------------------------------------------------------

ggsave(filename = filepath, plot = gsea_plot, device = 'png', width = 5, height = 8)
pdf_name <- gsub("\\.png",".pdf", filepath)
ggsave(filename = pdf_name, plot = gsea_plot, device = 'pdf', width = 5, height = 8)
