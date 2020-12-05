library(ggplot2)

bubble_plot <- function(data, cancer, gene, size, color, colorgroup, ylab="Symbol",xlab="Cancer types",cancer_rank, gene_rank, sizename, colorname, title) {
  CPCOLS <- c("red", "white", "blue")
  data %>%
    ggplot(aes_string(y = gene, x = cancer)) +
    geom_point(aes_string(size = size, fill = color, colour=colorgroup), shape = 21,stroke = 1) +
    scale_y_discrete(limit = gene_rank) +
    scale_x_discrete(limit = cancer_rank) +
    labs(title = title) +
    ylab(ylab) +
    xlab(xlab) +
    scale_size_continuous(
      name = sizename, # "-Log10(FDR)"
      guide=FALSE
    ) +
    scale_fill_gradient2(
      name = colorname, # "Methylation diff (T - N)",
      low = CPCOLS[3],
      mid = CPCOLS[2],
      high = CPCOLS[1]
    ) +
    guides(fill=guide_colourbar(title.position="top",reverse=TRUE)) +
    scale_color_manual(values = c("black","grey"),
                       breaks = c("FDR<0.05","FDR>0.05"),
                       name="FDR") +
    guides(color=guide_legend(title.position="top")) +
    theme(
      legend.position = "bottom",
      panel.background = element_rect(colour = "black", fill = "white"),
      panel.grid = element_line(colour = "grey", linetype = "dashed"),
      panel.grid.major = element_line(
        colour = "grey",
        linetype = "dashed",
        size = 0.2
      ),
      axis.text.y = element_text(size = 10,colour = "black"),
      axis.text.x = element_text(vjust = 1, hjust = 1, angle = 40, size = 10,colour = "black"),
      legend.text = element_text(size = 10),
      axis.title = element_text(size=12),
      legend.title = element_text(size = 12),
      legend.key = element_rect(fill = "white", colour = "black"),
      legend.key.size = unit(0.5, "cm"),
      plot.title = element_text(size = 20)
    ) -> p
  return(p)
}
