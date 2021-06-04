library(ggplot2)

box_plot_single_gene_multi_cancers <- function(data,aesx,aesy,color,color_name,facets,color_labels,color_values,title,xlab,ylab){
  
  data %>%
    ggplot(aes_string(x = aesx, y = aesy, color = color)) +
    geom_boxplot(outlier.colour = NA) +
    geom_jitter(alpha=0.5,size=0.5,width = 0.2) +
    facet_wrap(facets = as.formula(facets),strip.position = "bottom",nrow=1) +
    scale_color_manual(name = color_name, labels = color_labels, values = color_values) +
    labs(title = title, x = xlab, y = ylab) +
    theme(
      panel.background = element_rect(colour = NA, fill = NA),
      panel.grid = element_line(colour = "grey", linetype = "dashed"),
      panel.grid.major = element_line(
        colour = "grey",
        linetype = "dashed",
        size = 0.2
      ),
      plot.title = element_text(size=14, hjust = 0.5),
      axis.title = element_text(size = 14, color = "black"),
      axis.ticks = element_line(color = "black"),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      axis.text.y = element_text(size = 12, colour = "black"),
      strip.background = element_blank(),
      strip.text = element_text(size = 12, color = "black"),
      legend.position = 'right',
      legend.text = element_text(size = 12),
      legend.title = element_text(size = 14),
      legend.key = element_rect(fill = "white")
    )  -> p
  return(p)
}

box_plot_single_gene_single_cancer <- function(data,aesx,aesy,color,color_name,color_labels,color_values,title,xlab,ylab,xangle,comp_list,ylimitfold=0.1){
  if(xangle==0){
    hjust=0.5
    vjust=0.5
  } else{
    hjust=1
    vjust=0.5
  }
  data %>%
    dplyr::select(aesy) %>%
    max() ->.max
  label.y <- c()
  for (i in 1:length(comp_list)) {
    .tmp <- .max*0.07*i+.max
    label.y <- c(label.y,.tmp)
  }
  
  data %>%
    ggplot(aes_string(x = aesx, y = aesy, color = color)) +
    geom_boxplot(outlier.colour = NA) +
    geom_jitter(alpha=0.5,size=0.5,width = 0.2) +
    scale_y_continuous(limits = c(0,max(label.y)+ylimitfold*.max)) +
    scale_color_manual(name = color_name, labels = color_labels, values = color_values)+
    labs(title = title, x = xlab, y = ylab)  +
    ggpubr::stat_compare_means(comparisons = comp_list, method = "wilcox.test",label = "p.signif",label.y=label.y, vjust = 10) +
    theme(
      panel.background = element_rect(colour = "black", fill = "white"),
      panel.grid = element_line(colour = "grey", linetype = "dashed"),
      panel.grid.major = element_line(
        colour = "grey",
        linetype = "dashed",
        size = 0.2
      ),
      plot.title = element_text(size = 18, hjust = 0.5),
      axis.title = element_text(size = 14, color = "black"),
      axis.ticks = element_line(color = "black"),
      axis.text.x = element_text(size = 12, angle = xangle, hjust = hjust, vjust = vjust, colour = "black"),
      axis.text.y = element_text(size = 12, colour = "black"),
      legend.position = 'right',
      legend.text = element_text(size = 12),
      legend.title = element_text(size = 14),
      legend.key = element_rect(fill = "white")
    ) -> p
  return(p)
}


