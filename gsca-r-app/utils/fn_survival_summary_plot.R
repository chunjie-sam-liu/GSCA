library(ggplot2)
fn_survival_summary_plot <- function(data,aesx,aesy,color,fill,label,y_rank,x_rank,color_low,color_high,color_mid,midpoint,min, max,color_name,fill_color,fill_group,fill_name,title,xlab,ylab){
  data %>%
    ggplot(aes_string(x = aesx, y = aesy)) +
    geom_tile(aes_string(fill = fill, color=color),height=0.8,width=0.8,size=1.5) +
    geom_text(aes_string(label=label)) +
    scale_y_discrete(limit = y_rank) +
    scale_x_discrete(limit = x_rank) +
    scale_color_gradient2(
      low = color_low,
      mid = color_mid,
      high = color_high,
      midpoint = midpoint,
      na.value = "white",
      breaks = seq(min, max, length.out = 6),
      name = color_name
    ) +
    labs(title = title, x = xlab, y = ylab) +
    scale_fill_manual(values = fill_color,
                      limits = fill_group,
                      name=fill_name) +
    theme(
      panel.background = element_rect(colour = "black", fill = "white"),
      panel.grid = element_line(colour = "grey", linetype = "dashed"),
      panel.grid.major = element_line(
        colour = "grey",
        linetype = "dashed",
        size = 0.2
      ),
      axis.title = element_text(colour = "black",size = 14),
      axis.ticks = element_line(color = "black"),
      # axis.text.y = element_text(color = gene_rank$color),
      axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, colour = "black"),
      axis.text.y = element_text(colour = "black"),
      
      legend.text = element_text(size = 12),
      legend.title = element_text(size = 14),
      legend.key = element_rect(fill = "white", colour = "black")
    )
}
