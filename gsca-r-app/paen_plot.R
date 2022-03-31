
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
filepath <- args[3]
apppath <- args[4]


# tableuuid <- 'fc3f2449-a0a7-4053-b6fc-18781d882fdc'
# tableuuid <- '4e16895f-a343-4542-bcaf-453953013f00'
# tablecol <- 'preanalysised_enrichment'
# filepath <- "/home/huff/github/GSCA/gsca-r-plot/pngs/217c27f6-c12a-413d-8625-b9748fc1ff65.png"
# apppath <- '/home/huff/github/GSCA'

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))
pre_gsea_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)

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

enrichRes <- fetched_data$enrichment[[1]]
if (ncol(enrichRes)>0) {
  enrichRes %>%
    tibble::as_tibble() %>%
    dplyr::arrange(fdr) -> enrichRes
  # Plot --------------------------------------------------------------------
    enrichRes %>%
      dplyr::group_by(Method) %>%
      tidyr::nest() %>%
      dplyr::mutate(filter = purrr::map(data,.f=function(.x){
        .x %>%
          head(10)
      })) %>%
      dplyr::select(-data) %>%
      tidyr::unnest() -> for_plot
    for_plot %>%
      dplyr::arrange(Count) %>%
      .$Description -> yrank
    for_plot <- within(for_plot,Description<-factor(Description,levels=yrank))

    for_plot %>%
      ggplot(aes(x = Count, y = Description)) +
      geom_point(aes(size=Count, color = fdr)) +
      scale_color_gradient(
        name = "FDR",
        low = "#a91627",
        high = "#fadadd"
      ) +
      facet_grid(Method~., scales = "free", space = "free")+
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
        legend.key = element_rect(fill = "white", colour = "white"),
        legend.key.size = unit(0.5, "cm"),
      ) +
      labs(
        y = "Pathway",
        title = "Enrichment result of inputs gene set\n(Top 10 terms for each source)"
      ) ->
      plot

    # Save image --------------------------------------------------------------
    width = 7
    height = nrow(for_plot) * 0.6

    ggsave(filename = filepath, plot = plot, device = 'png', width = 7, height = height)
    pdf_name <- gsub("\\.png",".pdf", filepath)
    ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 7+2, height = height+2)

}else{
    source(file.path(apppath, "gsca-r-app/utils/fn_NA_notice_fig.R"))
    fn_NA_notice_fig("Caution: \nthe size of the inputted gene set\nis too small to do pathway enrichment.\nInput at least 10 genes could be help.") -> p
    # Save --------------------------------------------------------------------
    ggsave(filename = filepath, plot = p, device = 'png', width = 7, height = 4)
    pdf_name <- gsub("\\.png",".pdf",filepath)
    ggsave(filename = pdf_name, plot = p, device = 'pdf', width = 7, height = 4)
}


