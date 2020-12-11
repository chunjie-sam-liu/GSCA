library(ggplot2)
library(magrittr)
library(dplyr)
fn_boxplot <- function(data,title,colorkey,xlab,ylab){
  colorkey %>%
    dplyr::inner_join(data,by="group") %>%
    dplyr::group_by(group) %>%
    dplyr::mutate(n = n()) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(group = paste(group,", n=",n,sep="")) %>%
    dplyr::select(group,color) %>%
    unique() %>%
    sort() -> color_paired
  data %>%
    ggplot(aes(x=group,y=value)) +
    geom_boxplot(aes(color=group)) +
    geom_jitter(aes(color=group),width = 0.1) +
    scale_color_manual(
      values = color_paired$color,
      labels = color_paired$group,
      name = xlab
    ) +
    boxplot_theme_small_groups +
    labs(title = title, x = xlab, y = ylab) -> p
  return(p)
}
