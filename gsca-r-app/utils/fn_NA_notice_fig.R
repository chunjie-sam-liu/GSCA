library(ggplot2)
fn_NA_notice_fig <- function(WARN_message){
  data<-tibble::tibble(x=c(1:10),y=c(1:10))
  data %>%
    ggplot(aes(x=x,y=y)) +
    annotate("text", label = WARN_message, x = 2, y = 2, size = 8, colour = "red") +
    theme(
      axis.text.x = element_blank(),
      axis.text = element_blank(),
      axis.title = element_blank(),
      plot.margin = rep(unit(0, "null"), 4),
      axis.ticks.length = unit(0, "cm"),
      panel.background = element_rect(fill = "white", color = "red"),
      
      panel.grid = element_blank(),
      panel.grid.major = element_blank()
    )
}
