###################################
# cnv gene set definition
####################################
fn_geneset_cnv <- function(.x){
  .x %>%
    dplyr::select(symbol,sample_name,group) %>%
    dplyr::group_by(sample_name) %>%
    tidyr::nest() %>%
    dplyr::mutate(group = purrr::map(data,.f=function(.y){
      Dele_n <- length(grep("Dele.",.y$group,value = T))
      Amp_n <- length(grep("Amp.",.y$group,value = T))
      if(Dele_n>0 && Amp_n>0){
        "Excluded"
      } else if(Dele_n>0 && Amp_n==0){
        "Dele."
      } else if(Amp_n>0 && Dele_n==0){
        "Amp."
      } else {
        "WT"
      }
    })) %>%
    dplyr::ungroup() %>%
    dplyr::select(-data) %>%
    tidyr::unnest(group)
}
