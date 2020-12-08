library(ggplot2)
fn_survival_summary_plot <- function(data,aesx,aesy,color,fill,label,y_rank,x_rank,facet_exp,fill_low,fill_high,fill_mid,midpoint,min, max,fill_name,color_color,color_group,color_name,title,xlab,ylab){
  data %>%
    ggplot(aes_string(x = aesx, y = aesy)) +
    geom_tile(aes_string(fill = fill, color=color),height=0.8,width=0.8,size=0.8) +
    geom_text(aes_string(label=label)) +
    scale_y_discrete(limit = y_rank) +
    scale_x_discrete(limit = x_rank) +
    facet_grid(as.formula(facet_exp)) +
    scale_fill_gradient2(
      low = fill_low,
      mid = fill_mid,
      high = fill_high,
      midpoint = midpoint,
      na.value = "white",
      breaks = seq(min, max, length.out = 6),
      name = fill_name
    ) +
    labs(title = title, x = xlab, y = ylab) +
    scale_color_manual(values = color_color,
                      limits = color_group,
                      name=color_name) +
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
      legend.title = element_text(size = 12),
      legend.key.size = unit(0.5, "cm"),
      legend.key = element_rect(fill = "white", colour = "black"),
      strip.background =  element_rect(fill="white",color="black"),
      strip.text = element_text(color="black",size = 12)
    )
}

fn_survival_summary_plot_onlyP <- function(data,aesx,aesy,fill,y_rank,x_rank,fill_low,fill_high,fill_mid,fill_midpoint,min, max,fill_name,title,xlab,ylab){
  data %>%
    ggplot(aes_string(x = aesx, y = aesy)) +
    geom_tile(aes_string(fill = fill),height=0.8,width=0.8,size=1.5) +
    scale_y_discrete(limit = y_rank) +
    scale_x_discrete(limit = x_rank) +
    labs(title = title, x = xlab, y = ylab) +
    scale_fill_gradient2(
      low = fill_low,
      mid = fill_mid,
      high = fill_high,
      midpoint = fill_midpoint,
      na.value = "white",
      breaks = sort(c(seq(min, max, length.out = 6),1.3)),
      labels = c("0","1.3","","4","6","8","10"),
      name = fill_name
    ) +
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
      axis.text.x = element_text(colour = "black",size = 12),
      axis.text.y = element_text(colour = "black",size = 12),
      
      legend.text = element_text(size = 12),
      legend.title = element_text(size = 14),
      legend.key = element_rect(fill = "white", colour = "black")
    )
}
