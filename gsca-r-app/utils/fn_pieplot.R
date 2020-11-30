library(ggplot2)

fn_pie_plot <- function(data,aesy,fill,facet_grid,fill_limits,fill_label,fill_value){
  data %>%
    ggplot(aes_string(x = factor(1), y = aesy, fill = fill)) +
    geom_bar(stat = "identity", position = "stack", color = NA) +
    # scale_y_continuous(limits = c(0,1))
    coord_polar("y") +
    facet_grid(as.formula(facet_grid)) + # cancer_types ~ symbol+
    scale_fill_manual(
      limits = fill_limits, # c("a_hete", "a_homo", "d_hete", "d_homo", "other"),
      label = fill_label, #c("Hete. Amp.", "Homo. Amp.", "Hete. Del.", "Homo. Del.", "None"),
      values = fill_value #c("brown1", "brown4", "aquamarine3", "aquamarine4", "grey")
    ) +
    theme(
      axis.text = element_blank(),
      axis.title = element_blank(),
      axis.ticks = element_blank(),
      
      strip.text.y = element_text(angle = 0, hjust = 0, size = 4),
      strip.text.x = element_text(size = 4, angle = 90, vjust = 0),
      strip.background = element_blank(),
      
      legend.title = element_blank(),
      legend.text = element_text(size = 4),
      legend.position = "right",
      legend.key.size = unit(0.25, "cm"),
      
      panel.background = element_blank(),
      panel.spacing = unit(0, "null"), # unit(0.01, "lines"),
      panel.spacing.x = unit(0, "null"),
      
      plot.margin = rep(unit(0, "null"), 4),
      axis.ticks.length = unit(0, "cm")
    ) -> p
  return(p)
}
