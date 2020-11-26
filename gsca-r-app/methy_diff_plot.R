# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str <- "A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KIRC_methy_diff#KIRP_methy_diff#LUAD_methy_diff#LUSC_methy_diff"
# apppath = '/home/huff/github/GSCA'
search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
#search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
#  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(search_genes,search_colls)

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

# Function ----------------------------------------------------------------

fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"symbol": {"$in": ["<.xx>"]}}', .open = '<', .close = '>')
}

fn_fetch_mongo <- function(.x) {
  .coll <- mongolite::mongo(collection = .x, url = gsca_conf)
  .coll$find(
    query = fn_query_str(search_genes),
    fields = '{"symbol": true, "fc": true,"trend": true,"gene_tag": true,"logfdr": true, "_id": false}'
  ) %>%
    dplyr::mutate(cancertype = gsub(pattern = '_methy_diff', replacement = '', x = .x))
}

fn_filter_pattern <- function(trend,logfdr) {
  if ((trend == "Up") && (logfdr > 1.3)) {
    return(1)
  } else if ((trend == "Down") && (logfdr >1.3)) {
    return(-1)
  } else {
    return(0)
  }
}

fn_get_pattern <- function(.x) {
  .x %>%
    dplyr::mutate(pattern = purrr::map2_dbl(trend,logfdr, fn_filter_pattern)) %>%
    dplyr::select(cancertype, symbol, pattern ) %>%
    tidyr::spread(key = cancertype, value = pattern) %>%
    dplyr::mutate_if(.predicate = is.numeric, .funs = function(.) {ifelse(is.na(.), 0, .)})
}

fn_get_cancer_types_rank <- function(.x) {
  .x %>%
    dplyr::summarise_if(.predicate = is.numeric, dplyr::funs(sum(abs(.)))) %>%
    tidyr::gather(key = cancertype, value = rank) %>%
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
    dplyr::mutate(p_label=purrr::map(log_rank_p,fn_pval_class)) %>%
    tidyr::unnest()
}

# Query data --------------------------------------------------------------

fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo) %>% dplyr::bind_rows()
fetched_data %>%
  dplyr::mutate(tag = purrr::map(gene_tag,.f=function(.x){strsplit(.x,"_")[[1]][1]})) %>%
  dplyr::select(-gene_tag) %>%
  tidyr::unnest(tag) -> fetched_data

# Sort --------------------------------------------------------------------

fetched_data_clean_pattern <- fn_get_pattern(.x = fetched_data)
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern)
gene_rank <- fn_get_gene_rank(.x = fetched_data_clean_pattern)

for_plot <- fetched_data

# Plot --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_bubble_plot.R"))
CPCOLS <- c("#000080", "#F8F8FF", "#CD0000")

plot <- bubble_plot(data=for_plot, cancer="cancertype", gene="symbol", size="logfdr", color="fc", cancer_rank=cancer_rank, gene_rank=gene_rank, sizename= "-Log10(FDR)", colorname="Methylation diff (T - N)", title="")

ggsave(filename = filepath,plot = plot, device = 'png', width = size$width, height = size$height)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = size$width, height = size$height)
