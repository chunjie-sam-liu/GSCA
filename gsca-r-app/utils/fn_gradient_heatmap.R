##############
# usage: 
# load(file.path("/home/huff/github/GSCA/gsca-r-app/utils/fn_gradient_heatmap.R"))
gradient_heatmap <- function(data,aesx,aesy,fill,fillname,fillbreaks,yrank,title,xlab,ylab){
  data %>%
    ggplot(aes_string(x=aesx,y=aesy)) +
    geom_tile(aes_string(fill=fill),height=0.9) +
    facet_grid("~cancertype") +
    scale_fill_gradient(
      name = fillname, # "Methylation diff (T - N)",
      low = CPCOLS[2],
      high = CPCOLS[1],
      limits=c(min(fillbreaks),max(fillbreaks)),
      breaks=fillbreaks
    ) +
    scale_y_discrete(limit = yrank) +
    labs(title = title) +
    xlab(xlab) +
    ylab(ylab) + 
    theme(
      panel.background = element_rect(colour = "black", fill = "white"),
      panel.grid = element_line(colour = "grey", linetype = "dashed"),
      panel.grid.major = element_line(
        colour = "grey",
        linetype = "dashed",
        size = 0.2
      ),
      axis.text.y = element_text(size = 10,colour = "black"),
      axis.text.x = element_text(size = 10,colour = "black"),
      legend.text = element_text(size = 10),
      axis.title = element_text(size=12),
      legend.title = element_text(size = 12),
      legend.key = element_rect(fill = "white", colour = "white"),
      legend.key.size = unit(0.5, "cm"),
      plot.title = element_text(size = 14),
      strip.background =  element_rect(fill="white",color="black"),
      strip.text = element_text(color="black",size = 12)
    ) -> p
  return(p)
}
