library(dplyr)

source(file.path(apppath,"gsca-r-app/utils/trend_analysis.R"))

fn_stage <- function(gsva,stage){
  gsva %>%
    dplyr::filter(type=="tumor") %>%
    dplyr::mutate(sample_name = substr(barcode,1,12))->.gsva_t
  stage %>%
    dplyr::inner_join(.gsva_t,by="sample_name") %>%
    dplyr::distinct() %>%
    dplyr::group_by(stage) %>%
    dplyr::mutate(l = n()) %>%
    dplyr::ungroup() %>%
    dplyr::rename(expr=gsva)-> .combine
  
  #filter out stages with less than 5 samples in one of stage.
  .combine %>%
    dplyr::filter(l>=5) %>%
    dplyr::select(stage) %>%
    dplyr::distinct() -> .stage_more5
  
  if(nrow(.stage_more5)<2){ #filter out cancers with less than 2 stages
    return(tibble::tibble())
  } else {
    .combine %>% 
      dplyr::filter(stage %in% .stage_more5$stage) %>%
      tidyr::drop_na(expr) %>%
      fn_oneway() %>%
      dplyr::select(p.value,method) %>%
      dplyr::rename(diff_p=p.value,diff_method=method)-> diff_test_res
  }
  .combine %>%
    dplyr::group_by(stage) %>%
    dplyr::mutate(mean_exp= mean(expr)) %>%
    dplyr::mutate(n=n()) %>%
    dplyr::select(mean_exp,n) %>%
    dplyr::ungroup() %>%
    unique() -> combine_mean
  
  if(nrow(combine_mean)<3){ #filter out cancers with less than 2 stages
    trend_test_res <- tibble::tibble()
  } else {
    trend_test_res <- fn_trend_analysis(combine_mean) %>%
      dplyr::select(p.value,method,statistic) %>%
      dplyr::rename(trend_p=p.value,trend_method=method,trend_score=statistic)
  }
  diff_test_res %>%
    cbind(trend_test_res) %>%
    tidyr::nest(test=everything()) -> test
  combine_mean%>%
    tidyr::nest(mean=everything()) -> mean
  cbind(test,mean)
}

fn_oneway <- function(.x) {
  .x$stage %>% unique() %>% length() -> .n_stage
  if(.n_stage > 2){
    .res <- broom::tidy(oneway.test(log2(expr + 1) ~ stage, data = .x))
  }else{
    .res <- broom::tidy(wilcox.test(log2(expr + 1) ~ stage, data = .x))
  }
  
  .res 
}


