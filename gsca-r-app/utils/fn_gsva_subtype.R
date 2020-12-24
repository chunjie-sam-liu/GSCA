library(dplyr)

fn_subtype <- function(gsva,subtype){
  gsva %>%
    dplyr::filter(type=="tumor") %>%
    dplyr::mutate(sample_name = substr(barcode,1,12))->.gsva_t
  subtype %>%
    dplyr::inner_join(.gsva_t,by="sample_name") %>%
    dplyr::distinct() %>%
    dplyr::group_by(subtype) %>%
    dplyr::mutate(l = n()) %>%
    dplyr::ungroup() %>%
    dplyr::rename(expr=gsva)-> .combine
  
  #filter out subtypes with less than 5 samples in one of subtype.
  .combine %>%
    dplyr::filter(l>=5) %>%
    dplyr::select(subtype) %>%
    dplyr::distinct() -> .subtype_more5
  
  if(nrow(.subtype_more5)<2){ #filter out cancers with less than 2 subtypes
    return(tibble::tibble())
  } else {
    .combine %>% 
      dplyr::filter(subtype %in% .subtype_more5$subtype) %>%
      tidyr::drop_na(expr) %>%
      fn_oneway() %>%
      dplyr::select(p.value,method) %>%
      dplyr::rename(diff_p=p.value,diff_method=method)-> diff_test_res
  }
  .combine %>%
    dplyr::group_by(subtype) %>%
    dplyr::mutate(mean_exp= mean(expr)) %>%
    dplyr::mutate(n=n()) %>%
    dplyr::select(mean_exp,n) %>%
    dplyr::ungroup() %>%
    unique() -> combine_mean
  
  diff_test_res %>%
    tidyr::nest(test=everything()) -> test
  combine_mean%>%
    tidyr::nest(mean=everything()) -> mean
  cbind(test,mean)
}

fn_oneway <- function(.x) {
  .x$subtype %>% unique() %>% length() -> .n_subtype
  if(.n_subtype > 2){
    .res <- broom::tidy(oneway.test(log2(expr + 1) ~ subtype, data = .x))
  }else{
    .res <- broom::tidy(wilcox.test(log2(expr + 1) ~ subtype, data = .x))
  }
  
  .res 
}
