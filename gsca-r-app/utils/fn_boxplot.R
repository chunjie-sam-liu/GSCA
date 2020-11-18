library(ggplot2)
library(magrittr)

fn_boxplot <- function(data,title,colorkey,xlab,ylab){
  data %>%
    ggplot(aes(x=group,y=value)) +
    geom_boxplot(aes(color=group)) +
    geom_jitter(aes(color=group),width = 0.1) +
    scale_color_manual(values = colorkey$color,
                       breaks = colorkey$group,
                       name = xlab) +
    boxplot_theme_small_groups +
    theme(
      axis.title.x = element_blank()
    ) +
    labs(title = title, x = xlab, y = ylab) -> p
  return(p)
}
