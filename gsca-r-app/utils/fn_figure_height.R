
# function to determine the width and height of saved figure --------------

fn_height_width <- function(.g,.c){
  .lg <- length(.g)
  .lc <- length(.c)
  if(.lg<=20){
    .height <- 7
  } else{
    .height <- 7 + (.lg-20)*0.5
  }
  if(.lc<=10){
    .width <- 7
  } else {
    .wdith <- 7 + (.lc-10)*0.5
  }
  tibble::tibble(width=.width,height=.height)
}
