
# function to determine the width and height of saved figure --------------

fn_height_width <- function(.g,.c){
  .lg <- length(.g)
  .lc <- length(.c)
  if(.lg<=20){
    .height <- 4
  } else{
    .height <- 4 + (.lg-20)*0.5
  }
  if(.lc<=10){
    .width <- 6
  } else {
    .wdith <- 6 + (.lc-10)*0.5
  }
  tibble::tibble(width=.width,height=.height)
}
