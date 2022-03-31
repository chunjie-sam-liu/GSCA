library(ggplot2)
fn_cnv_oncoplot <- function(data,aesx,aesy,fill,fillname,fillcolor,filllimit,filllabel,xrank,yrank,title,xlab,ylab){
  data %>%
    ggplot(aes(x=barcode,y=symbol)) +
    geom_tile(aes(fill=cnv)) +
    scale_fill_manual(
      name=fillname,
      values = fillcolor,
      limits = filllimit,
      label = filllabel
    ) +
    scale_x_discrete(
      limits = xrank
    ) +
    scale_y_discrete(
      limits = yrank
    ) +
    theme(
      panel.background = element_rect(colour = "black", fill = "white"),
      panel.grid = element_line(colour = "grey", linetype = "dashed"),
      panel.grid.major = element_line(
        colour = "grey",
        linetype = "dashed",
        size = 0.2
      ),
      axis.text.x = element_blank(),
      axis.text.y = element_text(colour = "black",size = 10),
      axis.ticks = element_blank(),
      axis.title = element_blank(),
      legend.position = "bottom",
      legend.key.size = unit(0.25, "cm"),
      legend.text = element_text(size = 8),
      legend.title = element_text(size = 12),
      legend.key = element_rect(fill = "white", colour = "white")
    ) +
    labs(title = title, x = xlab, y = ylab) -> p
  return(p)
}
