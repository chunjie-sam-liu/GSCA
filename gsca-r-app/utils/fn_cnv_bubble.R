fn_cnv_bubble <- function(data,aesx,aesy,size,color,xlab,ylab,sizename,min=0,max=100,colorname,labels,wrap){
  data %>%
    ggplot(aes_string(y = aesy, x = aesx)) +
    geom_point(aes_string(size = size, color = color)) +
    xlab(xlab) +
    ylab(ylab) +
    scale_size_continuous(
      name = sizename,
      breaks = trunc(seq(ceiling(min), floor(max), length.out = 3)),
      limits = c(floor(min),ceiling(max))
    ) +
    ggthemes::scale_color_gdocs(
      name = colorname,
      labels = labels #c("Deletion", "Amplification")
    ) +
    facet_wrap(as.formula(wrap)) +
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 10,colour = "black"),
          strip.text.x = element_text(size = 12),
          panel.background = element_rect(colour = "black", fill = "white"),
          panel.grid = element_line(colour = "grey", linetype = "dashed"),
          panel.grid.major = element_line(
            colour = "grey",
            linetype = "dashed",
            size = 0.2
          ),
          axis.text.y = element_text(size = 10,colour = "black"),
          legend.text = element_text(size = 10),
          axis.title = element_text(size=12),
          legend.title = element_text(size = 12),
          legend.key = element_rect(fill = "white", colour = "black"),
          plot.title = element_text(size = 20),
          strip.background = element_blank(),
          strip.text = element_text(color="black",size = 12)
          ) -> p
  return(p)
}
