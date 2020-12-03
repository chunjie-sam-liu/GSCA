
fn_filter_pattern <- function(trend,value,trend1,trend2,p_cutoff) {
  if(!is.na(trend) && !is.na(value)){
    if ((trend == trend1) && (value < p_cutoff)) {
      return(1)
    } else if ((trend == trend2) && (value <p_cutoff)) {
      return(-1)
    } else {
      return(0)
    }
  } else {
    return(0)
  }
}

fn_get_pattern <- function(.x,trend1,trend2,p_cutoff,selections) {
  .x %>%
    dplyr::mutate(pattern = purrr::map2_dbl(trend,value, fn_filter_pattern,trend1=trend1,trend2=trend2,p_cutoff=p_cutoff)) %>%
    dplyr::select(all_of(selections), pattern ) %>%
    tidyr::spread(key = cancertype, value = pattern) %>%
    dplyr::mutate_if(.predicate = is.numeric, .funs = function(.) {ifelse(is.na(.), 0, .)})
}
fn_get_pattern_celltype <- function(.x,trend1,trend2,p_cutoff,selections) {
  .x %>%
    dplyr::mutate(pattern = purrr::map2_dbl(trend,value, fn_filter_pattern,trend1=trend1,trend2=trend2,p_cutoff=p_cutoff)) %>%
    dplyr::select(all_of(selections), pattern ) %>%
    tidyr::spread(key = cell_type, value = pattern) %>%
    dplyr::mutate_if(.predicate = is.numeric, .funs = function(.) {ifelse(is.na(.), 0, .)})
}
fn_get_cancer_types_rank <- function(.x) {
  .x %>%
    dplyr::summarise_if(.predicate = is.numeric, dplyr::funs(sum(abs(.)))) %>%
    tidyr::gather(key = cancertype, value = rank) %>%
    dplyr::arrange(dplyr::desc(rank))
}
fn_get_cell_types_rank <- function(.x) {
  .x %>%
    dplyr::summarise_if(.predicate = is.numeric, dplyr::funs(sum(.))) %>%
    tidyr::gather(key = cell_type, value = rank) %>%
    dplyr::arrange(dplyr::desc(rank))
}
fn_get_gene_rank <- function(.x) {
  .x %>%
    dplyr::rowwise() %>%
    dplyr::do(
      symbol = .$symbol,
      rank = unlist(.[-1][-1], use.names = F) %>% sum(),
      high = (unlist(.[-1][-1], use.names = F) == 1) %>% sum(),
      low = (unlist(.[-1][-1], use.names = F) == -1) %>% sum()
    ) %>%
    dplyr::ungroup() %>%
    tidyr::unnest(cols = c(symbol, rank, high, low)) %>%
    dplyr::arrange(rank)
}

fn_pval_class <- function(.p){
  if(.p>0.05){
    ""
  }else if(.p<=0.05 & .p>=0.01){
    "*"
  }else if(.p<0.01 & .p>=0.001){
    "**"
  } else{
    "***"
  }
}
fn_pval_label <- function(.x){
  .x %>%
    dplyr::mutate(p_label=purrr::map(value,fn_pval_class)) %>%
    tidyr::unnest(cols = c(p_label))
}
