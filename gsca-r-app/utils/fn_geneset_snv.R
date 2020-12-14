###################################
# snv gene set definition
####################################
fn_geneset_snv <- function(.x){
  .x %>%
    dplyr::select(symbol,sample_name,group) %>%
    dplyr::group_by(sample_name) %>%
    tidyr::nest() %>%
    dplyr::mutate(group = purrr::map(data,.f=function(.y){
      mutated_n <- length(grep("2Mutant",.y$group,value = T))
      if(mutated_n>0){
        "2Mutant"
      }else{
        "1WT"
      }
    })) %>%
    dplyr::ungroup() %>%
    dplyr::select(-data) %>%
    tidyr::unnest(group)
}
