
# stage profile plot ------------------------------------------------------

# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath_stagepoint <- args[2]
filepath_stageheat <- args[3]
filepath_stagetrend <- args[4]
apppath <- args[5]

# search_str = "A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_expr_stage#KIRC_expr_stage#KIRP_expr_stage#LUAD_expr_stage#LUSC_expr_stage"
# filepath = "/home/huff/github/GSCA/gsca-r-plot/pngs/1c16fb64-8ef4-4789-a87a-589d140c5bbe.png"
# apppath = '/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(search_genes,search_cancertypes)

# Function ----------------------------------------------------------------

fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"symbol": {"$in": ["<.xx>"]}}', .open = '<', .close = '>')
}

fn_fetch_mongo <- function(.x) {
  .coll <- mongolite::mongo(collection = .x, url = gsca_conf)
  .coll$find(
    query = fn_query_str(search_genes),
    fields = '{"symbol": true, "pval": true, "fdr": true,"Stage I (mean/n)": true,"Stage II (mean/n)": true,"Stage III (mean/n)": true,"Stage IV (mean/n)": true, "_id": false}'
  ) %>%
    dplyr::mutate(cancertype = gsub(pattern = '_expr_stage', replacement = '', x = .x))
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
    dplyr::mutate(p_label=purrr::map(fdr,fn_pval_class)) %>%
    tidyr::unnest()
}

# Query data --------------------------------------------------------------

fetched_data <- purrr::map(.x = search_cancertypes, .f = fn_fetch_mongo) %>% dplyr::bind_rows() %>%
  dplyr::filter(!is.na(pval))

# Sort --------------------------------------------------------------------

fetched_data_clean_pattern <- fn_get_pattern(.x = fetched_data)
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern)
gene_rank <- fn_get_gene_rank(.x = fetched_data_clean_pattern)

for_plot <- fn_pval_label(fetched_data) %>%
  dplyr::mutate(logFDR = -log10(fdr)) %>%
  dplyr::mutate(logFDR = ifelse(logFDR>10,10,logFDR)) %>%
  dplyr::mutate(group = ifelse(fdr>0.05,">0.05","<0.05")) %>%
  tidyr::gather(-symbol,-pval,-fdr,-cancertype,-group,-p_label,-logFDR,key="stage",value="mean") 

list(for_plot$mean) %>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '/')[[1]][1]}) %>% unlist() %>% as.numeric() -> mean_exp

list(for_plot$stage) %>%
  purrr::pmap(.f=function(.x){gsub(pattern = " \\(mean\\/n\\)", replacement = "",gsub(pattern = "Stage ", replacement = "",.x)[[1]])}) %>% unlist()  -> stages

stage_number <- tibble::tibble(stage=c("I","II","III","IV"),
                               rank=c(1,2,3,4))

for_plot %>%
  dplyr::mutate(mean_exp = log2(mean_exp+0.01))%>%
  dplyr::mutate(stage = stages) %>%
  dplyr::inner_join(stage_number,by="stage") -> for_plot

# bubble_plot --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_bubble_plot_immune.R"))
for_plot %>%
  dplyr::select(-mean_exp,-mean,-stage) %>%
  unique() -> for_plot_bubble
for_plot_bubble %>%
  dplyr::filter(!is.na(logFDR)) %>%
  .$logFDR -> logp_value
min(logp_value) %>% floor() -> min
max(logp_value) %>% ceiling() -> max
fillbreaks <- sort(unique(c(1.3,min,max,seq(min,max,length.out = 3))))

bubbleplot <- bubble_plot(data=for_plot_bubble, 
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
                         colorname="-Log(10) FDR",
                         title="")

# Save --------------------------------------------------------------------
ggsave(filename = filepath_stagepoint, plot = bubbleplot, device = 'png', width = size$width, height = size$height)
filepath_stagepoint_pdf_name <- gsub("\\.png",".pdf",filepath_stagepoint)
ggsave(filename = filepath_stagepoint_pdf_name, plot = bubbleplot, device = 'pdf', width = size$width, height = size$height)


# heatmap --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_gradient_heatmap.R"))
for_plot %>%
  dplyr::filter(!is.na(mean_exp)) %>%
  .$mean_exp -> exp_value
min(exp_value) %>% floor() -> min_heat
max(exp_value) %>% ceiling() -> max_heat
fillbreaks_heat <- sort(unique(c(min_heat,max_heat,round(seq(min_heat,max_heat,length.out = 4)))))
CPCOLS <- c("red", "white", "blue")

heat_plot <- gradient_heatmap(data = for_plot,
                                fill="mean_exp",
                                fillname="Log2(RSEM)",
                                aesx="stage",
                                aesy="symbol",
                                fillbreaks=fillbreaks_heat,
                                yrank=gene_rank$symbol,
                                xlab="Stages",
                                ylab="Symbol",
                                title="")

# Save --------------------------------------------------------------------
ggsave(filename = filepath_stageheat, plot = heat_plot, device = 'png', width = size$width, height = size$height)
filepath_stageheat_pdf_name <- gsub("\\.png",".pdf",filepath_stageheat)
ggsave(filename = filepath_stageheat_pdf_name, plot = heat_plot, device = 'pdf', width = size$width, height = size$height)


# TREND PLOT --------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/trend_analysis.R"))

for_plot %>%
  dplyr::group_by(symbol,cancertype) %>%
  tidyr::nest() %>%
  dplyr::mutate(trend_analysis = purrr::map(data,fn_trend_analysis)) %>%
  dplyr::select(-data) %>%
  tidyr::unnest() %>%
  dplyr::ungroup() -> trend_res

trend_res %>%
  dplyr::group_by(symbol) %>%
  dplyr::mutate(rank=sum(statistic)) %>%
  dplyr::select(symbol,rank) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(rank) %>%
  unique() -> trend_symbol_rank

trend_res %>%
  dplyr::group_by(cancertype) %>%
  dplyr::mutate(rank=sum(statistic)) %>%
  dplyr::select(cancertype,rank) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(rank) %>%
  unique() -> trend_cancertype_rank

for_plot %>%
  dplyr::inner_join(trend_res,by=c("symbol","cancertype")) %>%
  dplyr::mutate(`Trend P` = ifelse(p.value>0.05,">0.05","<0.05")) -> for_plot_trend

for_plot_trend <- within(for_plot_trend,symbol<-factor(symbol,levels=unique(trend_symbol_rank$symbol)))
for_plot_trend <- within(for_plot_trend,cancertype<-factor(cancertype,levels=unique(trend_cancertype_rank$cancertype)))

for_plot_trend %>%
  dplyr::filter(!is.na(statistic)) %>%
  .$statistic -> statistic_value
min(statistic_value) %>% floor() -> min_trend
max(statistic_value) %>% ceiling() -> max_trend
fillbreaks_trend <- sort(unique(c(0,min_trend,max_trend)))
CPCOLS_trend <- c("#ee0e27", "grey", "#1678f3")

source(file.path(apppath,"gsca-r-app/utils/fn_trend_plot.R"))
trendplot <- trend_plot(data = for_plot_trend,
           aesx="rank",
           aesy="mean_exp",
           linecolor="statistic",
           linetype="`Trend P`",
           colorname="Trend",
           color_list = CPCOLS_trend,
           fillbreaks=fillbreaks_trend,
           color_lables=c("Down","Equal","Up"),
           title="",
           xlab="Stages",
           ylab="Symbol")

# Save --------------------------------------------------------------------
ggsave(filename = filepath_stagetrend, plot = trendplot, device = 'png', width = size$width, height = size$height)
filepath_stagetrend_pdf_name <- gsub("\\.png",".pdf",filepath_stagetrend)
ggsave(filename = filepath_stagetrend_pdf_name, plot = trendplot, device = 'pdf', width = size$width, height = size$height)