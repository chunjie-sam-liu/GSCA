library(ggplot2)

bubble_plot <- function(data, cancer, gene, size, color, ylab="Symbol",xlab="Cancer types",cancer_rank, gene_rank, sizename, colorname, title) {
    CPCOLS <- c("red", "white", "blue")
    data %>%
      ggplot(aes_string(y = gene, x = cancer)) +
      geom_point(aes_string(size = size, color = color)) +
      scale_y_discrete(limit = gene_rank) +
      scale_x_discrete(limit = cancer_rank) +
      labs(title = title, xlab=xlab, ylab = ylab) +
      scale_size_continuous(
        name = sizename, # "-Log10(FDR)"
        breaks = c(0,1.3,2,3,4),
        labels = c("1","0.05","0.01","0.001","≤0.0001")
      ) +
      guides(size=guide_legend(title.position="top")) +
      scale_color_gradient2(
        name = colorname, # "Methylation diff (T - N)",
        low = CPCOLS[3],
        mid = CPCOLS[2],
        high = CPCOLS[1]
      ) +
      guides(color=guide_colourbar(title.position="top",reverse=TRUE)) +
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
        plot.title = element_text(size = 12)
      ) -> p
    return(p)
}
