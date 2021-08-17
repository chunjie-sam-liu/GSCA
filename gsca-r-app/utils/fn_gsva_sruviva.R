
fn_cox_logp <- function(.d,highgroup,lowgroup){
  .d %>%
    dplyr::filter(!is.na(group)) %>%
    dplyr::filter(!is.na(time)) %>%
    dplyr::filter(!is.na(status)) %>%
    dplyr::group_by(group) %>%
    dplyr::mutate(n=dplyr::n()) %>%
    dplyr::select(group,n) %>%
    dplyr::ungroup() %>%
    dplyr::filter(n>=1) %>%
    .$group %>% unique() %>% length() -> len_group
  if(len_group==2){
    kmp <- tryCatch(
      1 - pchisq(survival::survdiff(survival::Surv(time, status) ~ group, data = .d, na.action = na.exclude)$chisq, df = len_group - 1),
      error = function(e) {1}
    )
    
    cox_categorical <- tryCatch(
      broom::tidy(survival::coxph(survival::Surv(time, status) ~ group, data = .d, na.action = na.exclude)),
      error = function(e) {1}
    )
    if (!is.numeric(cox_categorical)) {
      coxp_categorical <- cox_categorical$p.value
      hr_categorical <- exp(cox_categorical$estimate)
    } else {
      coxp_categorical <- 1
      hr_categorical <- 1
    }
    
    cox_continus <- tryCatch(
      broom::tidy(survival::coxph(survival::Surv(time, status) ~ expr, data = .d, na.action = na.exclude)),
      error = function(e) {1}
    )
    if (!is.numeric(cox_continus)) {
      coxp_continus <- cox_continus$p.value
      hr_continus <- exp(cox_continus$estimate)
    } else {
      coxp_continus <- 1
      hr_continus <- 1
    }
    if(!is.na(hr_categorical)){
      if(hr_categorical>1){
        higher_risk_of_death <- highgroup
      }else if (hr_categorical<1){
        higher_risk_of_death <- lowgroup
      } else{
        higher_risk_of_death <- NA
      }
    } else{
      higher_risk_of_death <- NA
    }
    
    
  } else {
    kmp<-1
    coxp_categorical<-1
    coxp_continus<-1
    hr_continus <- 1
    hr_categorical<- 1
    higher_risk_of_death <- NA
  }
  tibble::tibble(logrankp=kmp,
                 coxp_categorical=coxp_categorical,
                 hr_categorical=hr_categorical,
                 coxp_continus=coxp_continus,
                 hr_continus=hr_continus,
                 higher_risk_of_death=higher_risk_of_death)
}

fn_survival <- function(gsva,survival){
  gsva %>%
    dplyr::filter(type=="tumor") %>%
    dplyr::filter(!is.na(gsva)) %>%
    dplyr::mutate(sample_name=substr(barcode,1,12)) %>%
    dplyr::inner_join(survival, by="sample_name") -> .combine
  .combine %>%
    dplyr::mutate(group=ifelse(gsva>quantile(gsva,0.5),"2Higher GSVA","1Lower GSVA")) -> .combine_group
  
  .combine_group %>%
    dplyr::rename(time=os_months,status=os_status,expr=gsva) %>%
    fn_cox_logp(highgroup="Higher GSVA",lowgroup="Lower GSVA") %>%
    dplyr::mutate(sur_type = "OS")-> os_res
  
  if (length(grep("pfs",colnames(survival)))>0) {
    .combine_group %>%
      dplyr::rename(time=pfs_months,status=pfs_status,expr=gsva) %>%
      fn_cox_logp(highgroup="Higher GSVA",lowgroup="Lower GSVA") %>%
      dplyr::mutate(sur_type = "PFS") -> pfs_res
    rbind(os_res,pfs_res) -> res
  } else {
    os_res -> res
  }
  res %>%
    dplyr::filter(!is.na(higher_risk_of_death))
}
