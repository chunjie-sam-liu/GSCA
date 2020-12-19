# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str = 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KIRC_expr_subtype#LUAD_expr_subtype#LUSC_expr_subtype'
# filepath = '/home/huff/github/GSCA/gsca-r-plot/pngs/5579084c-505e-4a23-832d-3b95ae50758a.png'
# apppath = '/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(search_genes,search_cancertypes)

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
    fields = '{"symbol": true, "pval": true, "fdr": true, "_id": false}'
  ) %>%
    dplyr::mutate(cancertype = gsub(pattern = '_expr_subtype', replacement = '', x = .x))
}

fn_filter_pattern <- function(fdr) {
  if ((fdr <= 0.05)) {
    return(1)
  } else {
    return(0)
  }
}

fn_get_pattern <- function(.x) {
  .x %>%
    dplyr::as.tbl() %>%
    dplyr::mutate(pattern = purrr::map(fdr, fn_filter_pattern)) %>%
    tidyr::unnest() %>%
    dplyr::select(cancertype, symbol, pattern) %>%
    tidyr::spread(key = cancertype, value = pattern) %>%
    dplyr::mutate_if(is.numeric, .funs = function(.) {ifelse(is.na(.), 0, .)})
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
      rank = unlist(.[-1], use.names = F) %>% sum(),
      high = (unlist(.[-1], use.names = F) == 1) %>% sum(),
      low = (unlist(.[-1], use.names = F) == -1) %>% sum()
    ) %>%
    dplyr::ungroup() %>%
    tidyr::unnest(cols = c(symbol, rank, high, low)) %>%
    dplyr::arrange(rank)
}

# Query data --------------------------------------------------------------

fetched_data <- purrr::map(.x = search_cancertypes, .f = fn_fetch_mongo) %>% dplyr::bind_rows()
# Sort --------------------------------------------------------------------

fetched_data_clean_pattern <- fn_get_pattern(.x = fetched_data)
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern)
gene_rank <- fn_get_gene_rank(.x = fetched_data_clean_pattern)

for_plot <- fetched_data %>%
  dplyr::mutate(logFDR = -log10(fdr)) %>%
  dplyr::mutate(logFDR = ifelse(logFDR>10,10,logFDR)) %>%
  dplyr::mutate(group=ifelse(fdr>0.05,">0.05","<0.05"))

# bubble_plot --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_bubble_plot_immune.R"))
for_plot -> for_plot_bubble
for_plot_bubble %>%
  dplyr::filter(!is.na(logFDR)) %>%
  .$logFDR -> logp_value
min(logp_value) %>% floor() -> min
max(logp_value) %>% ceiling() -> max
fillbreaks <- sort(unique(c(1.3,round(c(min,max,seq(min,max,length.out = 3))))))

p <- bubble_plot(data=for_plot_bubble, 
                          cancer="cancertype", 
                          gene="symbol", 
                          xlab="Cancer types", 
                          ylab="Symbol", 
                          facet_exp = NA,
                          size="logFDR", 
                          fill="logFDR", 
                          fillmipoint =1.3,
                          fillbreaks =fillbreaks,
                          colorgroup="group",
                          cancer_rank=cancer_rank$cancertype, 
                          gene_rank=gene_rank$symbol, 
                          sizename= "-Log(10) FDR", 
                          fillname="-Log(10) FDR", 
                          colorvalue=c("black","grey"), 
                          colorbreaks=c("<0.05",">0.05"),
                          colorname="FDR",
                          title="Subtype difference between high and\nlow gene expression")

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = p, device = 'png', width = size$width, height = size$height)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = p, device = 'pdf', width = size$width, height = size$height)
