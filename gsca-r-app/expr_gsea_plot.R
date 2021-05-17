
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
  dplyr::mutate(logpadj = -log10(padj)) %>%
  dplyr::mutate(group = ifelse(padj<=0.05,"<0.05",">0.05"))-> for_plot
for_plot %>%
  dplyr::filter(!is.na(logpadj)) %>%
  .$logpadj %>% range() -> min_max
floor(min_max[1]) -> min
ceiling(min_max[2]) -> max
fillbreaks <- sort(unique(c(1.3,min,max)))
fillname<-"-log10(p.adj.)"
# CPCOLS <- c("#ffffff", RColorBrewer::brewer.pal(9, "Set1"))
CPCOLS <- c("#000080", "#F8F8FF", "#CD0000")
#CPCOLS %>% scales::show_col()

fillmipoint <- 1.3
for_plot %>% 
  ggplot(aes(x = reorder(cancertype, NES), y = NES, fill = logpadj)) +
  geom_bar(stat = "identity") +
  scale_fill_gradient(
    name = fillname, 
    low = CPCOLS[2],
    high = CPCOLS[3],
    limits=c(min(fillbreaks),max(fillbreaks)),
    breaks=fillbreaks
  ) +
  coord_flip() +
  theme(
    panel.background = element_rect(colour = "black", fill = "white"),
    panel.grid = element_line(colour = "grey", linetype = "dashed"),
    panel.grid.major = element_line(
      colour = "grey",
      linetype = "dashed",
      size = 0.2
    ),
    plot.title = element_text(size = 18, hjust = 0.5),
    axis.title = element_text(size=16),
    axis.text.x = element_text(size = 12,colour = "black"),
    axis.text.y = element_text(size = 12,colour = "black"),
    legend.title = element_text(size = 16),
    legend.text = element_text(size = 14),
    legend.key = element_rect(fill = "white", colour = "black"),
    legend.key.size = unit(0.5, "cm"),
  ) +
  guides(
    fill = guide_colourbar(
      title = fillname, 
      title.position = "top",
      title.hjust = 0.5
    )
  )+
  labs(
    x = "Cancer type",
    y = "Normalized enrichment score (NES)",
    title = "Enrichment score of inputted gene set in selected cancer types"
  ) ->
  gsea_plot

# Save image --------------------------------------------------------------
width = 7
height = length(unique(for_plot$cancertype)) * 0.8

ggsave(filename = filepath, plot = gsea_plot, device = 'png', width = width, height = height)
pdf_name <- gsub("\\.png",".pdf", filepath)
ggsave(filename = pdf_name, plot = gsea_plot, device = 'pdf', width = width * 2, height = height * 2)
