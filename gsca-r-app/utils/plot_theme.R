library(ggplot2)
boxplot_theme_small_groups <- theme(
  panel.background = element_rect(colour = "black", fill = "white"),
  panel.grid = element_line(colour = "grey", linetype = "dashed"),
  panel.grid.major = element_line(
    colour = "grey",
    linetype = "dashed",
    size = 0.2
  ),
  plot.title = element_text(hjust = 0.5),
  axis.ticks = element_line(color = "black"),
  axis.text.y = element_text(colour = "black"),
  legend.position = 'right',
  legend.text = element_text(size = 12),
  legend.title = element_text(size = 14),
  legend.key = element_rect(fill = "white")
)
