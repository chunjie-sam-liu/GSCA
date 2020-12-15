
library(trend)
fn_trend_analysis <- function(.x){
  .x %>%
    dplyr::arrange(stage) %>%
    .$mean_exp -> .y
  
  broom::tidy(mk.test(.y, continuity = TRUE))
}



