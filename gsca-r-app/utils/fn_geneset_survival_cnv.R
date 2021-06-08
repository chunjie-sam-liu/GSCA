###################################
# snv gene set survival calculation
####################################

survival_group <- tibble::tibble(type=c("os","pfs"),
                                 time=c("os_days","pfs_days"),
                                 status=c("os_status","pfs_status"))

fn_cox_logp <- function(.d){
  .d %>%
    dplyr::filter(!is.na(group)) %>%
    dplyr::filter(!is.na(time)) %>%
    dplyr::filter(!is.na(status)) %>%
    dplyr::group_by(group) %>%
    dplyr::mutate(n=dplyr::n()) %>%
    dplyr::select(group,n) %>%
    dplyr::ungroup() %>%
    dplyr::filter(n>=2) %>%
    .$group %>% unique() %>% length() -> len_group
  if(!is.na(len_group)){
    if(len_group>=2){
      kmp <- tryCatch(
        1 - pchisq(survival::survdiff(survival::Surv(time, status) ~ group, data = .d, na.action = na.exclude)$chisq, df = len_group - 1),
        error = function(e) {1}
      )
    } else {
      kmp<-NA
    }
    tibble::tibble(logrankp=kmp)
  } else {
    tibble::tibble(logrankp=NA)
  }
}

fn_survival <- function(.data,sur_type){

  survival_group %>%
    dplyr::filter(type==sur_type) -> sur_type_do

  .data %>%
    dplyr::select(sample_name,group,time=sur_type_do$time,status=sur_type_do$status) %>%
    fn_cox_logp()
}

fn_survival_res <- function(.cancer_types,.combine){
  # os survival ----
  fn_survival(.combine,sur_type="os") %>%
    dplyr::mutate(sur_type="os")-> os

  # pfs survival -----
  if (length(grep("pfs",colnames(.combine)))>0) {
    fn_survival(.combine,sur_type="pfs") %>%
      dplyr::mutate(sur_type="pfs")-> pfs

    os %>%
      rbind(pfs) -> tmp
  } else {
    os -> tmp
  }

  tmp
}
