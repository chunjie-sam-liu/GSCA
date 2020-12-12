
# function to determine the width and height of saved figure --------------

fn_height_width <- function(.g,.c){
  .lg <- length(.g)
  .lc <- length(.c)
  if(.lg<=20){
    .height <- 4
  } else{
    .height <- 4 + (.lg-20)*0.2
  }
  if(.lc<=10){
    .width <- 6
  } else {
    .width <- 6 + (.lc-10)*0.2
  }
  tibble::tibble(width=.width,height=.height)
}
