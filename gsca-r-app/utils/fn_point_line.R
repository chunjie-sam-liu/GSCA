library(ggplot2)
library(ggpubr)
# point and fitting line --------------------------------------------------

fn_point_fit <- function(data,aesx,aesy,title,xlab,ylab,label){
  data %>%
    ggplot(aes_string(x=aesx,y=aesy)) +
    geom_point() +
    geom_smooth(method = lm,se = TRUE, fullrange=TRUE, color = "#039BE5") +
    labs(title = title, x = xlab, y = ylab) +
    theme(
      # legend.position = "bottom",
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
      plot.title = element_text(size = 20)
    ) -> p
  # data %>%
  #   ggplot(aes_string(y=aesx)) +
  #   geom_boxplot( width = 0.1, fill = alpha("lightgray",0.1),outlier.colour = NA) +
  #   coord_flip() + theme_transparent() -> xbp
  # data %>%
  #   ggplot(aes_string(y=aesy)) +
  #   geom_boxplot( width = 0.1, fill = alpha("lightgray",0.1),outlier.colour = NA) +
  #   theme_transparent() -> ybp
  # xbp_grob <- ggplotGrob(xbp)
  # ybp_grob <- ggplotGrob(ybp) 
  data %>%
    dplyr::select(all_of(aesx)) %>%
    range() -> xmin_max
  data %>%
    dplyr::select(all_of(aesy)) %>%
    range() -> ymin_max
  xmin <- xmin_max[1]; xmax <- xmin_max[2]
  ymin <- ymin_max[1]; ymax <- ymin_max[2]
  
  yoffset <- (1/20)*ymax; xoffset <- (1/20)*xmax
  p +
    geom_label(x=xmax-xoffset,y=ymax,label=label)
  # sp + 
  #   annotation_custom(grob = xbp_grob, xmin = xmin, xmax = xmax, ymin =ymin, ymax = ymin+0.5*yoffset) + 
  #   annotation_custom(grob = ybp_grob, xmin = xmin, xmax = xmin+0.5*xoffset, ymin = ymin, ymax = ymax) -> p
   
  return(p)
}
