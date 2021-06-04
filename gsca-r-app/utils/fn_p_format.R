
# signif + scientic format ------------------------------------------------

fn_format <- function(.x){
  if(.x<0.01){
    format(signif(.x,2), scientific = TRUE)
  }else{
    signif(.x,2)
  }
}
