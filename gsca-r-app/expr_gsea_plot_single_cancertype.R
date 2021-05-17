
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
cancertype <- args[3]
filepath <- args[4]
apppath <- args[5]


# tableuuid <- "3dfee429-973b-4222-bb2b-ba8522b68540"
# tablecol <- "preanalysised_gsea"
# cancertype <- "LUSC"
# filepath <- "/home/liucj/github/GSCA/gsca-r-plot/pngs/1ffb5e8f-38ff-4c4d-aa23-29b39e07edc5.png"
# apppath <- "/home/liucj/github/GSCA"

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, "gsca-r-app/gsca.conf"))
pre_gsea_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)

# Function ----------------------------------------------------------------
fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"uuid": "<.xx>"}', .open = "<", .close = ">")
}

fn_output_str <- function(.x) {
  glue::glue('{"gsea_score.<.x>": true, "gene_set": true, "_id": false}', .open = "<", .close = ">")
}

fn_fetch_data <- function(.uuid) {
  pre_gsea_coll$find(query = fn_query_str(.x = tableuuid), fields = fn_output_str(.x = cancertype))
}

fn_gsea_running_score <- function(pathway, stats, gseaParam = 1) {
  rnk <- rank(-stats)
  ord <- order(rnk)
  statsAdj <- stats[ord]
  statsAdj <- sign(statsAdj) * (abs(statsAdj)^gseaParam)
  statsAdj <- statsAdj / max(abs(statsAdj))
  pathway <- unname(as.vector(na.omit(match(pathway, names(statsAdj)))))
  pathway <- sort(pathway)
  gseaRes <- fgsea::calcGseaStat(statsAdj, selectedStats = pathway, returnAllExtremes = TRUE)
  bottoms <- gseaRes$bottoms
  tops <- gseaRes$tops
  n <- length(statsAdj)
  xs <- as.vector(rbind(pathway - 1, pathway))
  ys <- as.vector(rbind(bottoms, tops))
  toPlot <- tibble::tibble(x = c(0, xs, n + 1), y = c(0, ys, 0))
  
  ggplot(toPlot, aes(x = x, y = y)) +
    geom_point(
      color = "green",
      size = 0.1
    )+
    geom_hline(
      yintercept = max(tops), colour = "red",
      linetype = "dashed"
    )+
    geom_hline(
      yintercept = min(bottoms),
      colour = "red", linetype = "dashed"
    ) +
    geom_line(color = "green") +
    theme_bw() +
    geom_segment(data = data.frame(x = pathway), mapping = aes(
      x = x,
      y = -diff / 2, xend = x, yend = diff / 2
    ), size = 0.2) +
    theme(panel.border = element_blank(), panel.grid.minor = element_blank()) +
    labs(x = "rank", y = "enrichment score")
  
  list(es = toPlot, pos = tibble::tibble(x = pathway))
}

fn_gseaplot <- function(es, pos) {
  CPCOLS <- c("#ffffff", RColorBrewer::brewer.pal(9, "Set1"))
  ggplot() +
    scale_x_continuous(expand = c(0, 0)) +
    theme_classic(11) +
    theme(
      panel.grid = element_line(colour = "grey", linetype = "dashed"),
      panel.grid.major = element_line(
        colour = "grey",
        linetype = "dashed",
        size = 0.2
      ),
      legend.position = c(0.8, 0.8),
      legend.title = element_blank(),
      legend.background = element_rect(fill = "transparent"),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(), 
      axis.text.y = element_text(size = 12,colour = "black"),
      axis.title = element_text(size=16),
      plot.margin = margin(
        t = 0.2, r = 0.2, b = 0, l = 0.2,
        unit = "cm"
      )
    ) + 
    labs(x = NULL, y = NULL) ->
    pproto
  
  pproto + 
    geom_line(data = es, aes(x = x, y = y), color = CPCOLS[4]) +
    theme(
      plot.title = element_text(size = 18, hjust = 0.5)
    ) +
    labs(x = NULL, y = "Enrichment score", title = glue::glue("Enrichment plot of inputted gene set in {cancertype}")) ->
    pup
  
  pos %>% dplyr::mutate(ymin = 0, ymax = 1) -> pos
  pos %>% 
    ggplot(aes(x = x)) +
    geom_linerange(aes(ymin = ymin, ymax = ymax)) +
    scale_x_continuous(expand = c(0, 0)) +
    scale_y_continuous(expand = c(0,0)) +
    theme_classic(11) +
    theme(
      legend.position = "none",
      plot.margin = margin(t = -0.1, b = 0, unit = "cm"),
      axis.ticks = element_blank(),
      axis.text = element_blank(),
      axis.line.x = element_blank(),
    ) +
    labs(x = NULL, y = NULL) ->
    pmiddle
  
  v <- seq(1, nrow(pos), length.out = 9)
  vt <- ifelse(is.na(match(seq_along(rank_genes), pos$x) ), 0, 1)
  inv <- findInterval(rev(cumsum(vt)), v)
  if (min(inv) == 0) {
    inv <- inv + 1
  }
  col <- c(rev(RColorBrewer::brewer.pal(5, "Blues")), RColorBrewer::brewer.pal(5, "Reds"))
  ymin <- min(pmiddle$data$ymin)
  yy <- max(pmiddle$data$ymax - pmiddle$data$ymin) * 0.5
  xmin <- which(!duplicated(inv))
  xmax <- xmin + as.numeric(table(inv)[as.character(unique(inv))])
  
  d <- data.frame(
    ymin = ymin, ymax = yy, xmin = xmin,
    xmax = xmax, col = col[unique(inv)]
  )
  
  pmiddle +
    geom_rect(
      data = d,
      aes(xmin = xmin, xmax = xmax, ymin =ymin, ymax = ymax, fill = I(col)),
      alpha = 0.9, inherit.aes = FALSE
    ) ->
    pmid
  
  df <- rank_genes %>% 
    tibble::enframe(name = 'x', value = 'y') %>% 
    dplyr::arrange(-y) %>% 
    dplyr::mutate(x = seq_along(y))
  
  pproto +
    geom_segment(data = df, aes(x = x, xend = x, y = y, yend = 0), color = 'grey') +
    theme(
      plot.margin = margin(
        t = -0.1, r = 0.2, b = 0.2,
        l = 0.2, unit = "cm"
      ),
      axis.line.x = element_line(),
      axis.text.x = element_text(size = 12,colour = "black"),
      axis.ticks.x = element_line(),
    ) +
    labs(
      x = "Rank in Ordered Dataset",
      y = "Ranked List Metric"
    ) ->
    pdown
  
  plotlist <- list(pup, pmid, pdown)
  
  cowplot::plot_grid(
    plotlist = plotlist,
    ncol = 1,
    align = 'v',
    rel_heights = c(1.5, 0.2, 1)
  )
}
# Process -----------------------------------------------------------------

fetched_data <- fn_fetch_data(.uuid = tableuuid)

gene_set <- fetched_data$gene_set[[1]]


fetched_data$gsea_score %>%
  tibble::as_tibble() %>%
  tidyr::gather(key = "cancertype", value = "gsea") %>%
  dplyr::select(-1) %>%
  tidyr::unnest(cols = gsea) %>%
  tidyr::unnest(cols = c(symbol, log2fc)) %>%
  tibble::deframe() %>%
  sort() ->
  rank_genes

running_score <- fn_gsea_running_score(pathway = gene_set, stats = rank_genes)

gsea_plot <- fn_gseaplot(es = running_score$es, pos = running_score$pos)

# Save image --------------------------------------------------------------
width = 7
height = 6
ggsave(filename = filepath, plot = gsea_plot, device = 'png', width = width, height = height)
pdf_name <- gsub("\\.png",".pdf", filepath)
ggsave(filename = pdf_name, plot = gsea_plot, device = 'pdf', width = width * 2, height = height * 2)
