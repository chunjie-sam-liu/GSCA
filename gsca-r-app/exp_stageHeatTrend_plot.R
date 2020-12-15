# stage profile plot ------------------------------------------------------

# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath_stageheat <- args[2]
filepath_stagetrend <- args[3]
apppath <- args[4]

# search_str = "A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_expr_stage#KIRC_expr_stage#KIRP_expr_stage#LUAD_expr_stage#LUSC_expr_stage#SKCM_expr_stage"
# filepath = "/home/huff/github/GSCA/gsca-r-plot/pngs/1c16fb64-8ef4-4789-a87a-589d140c5bbe.png"
# apppath = '/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(search_genes,search_cancertypes)

# functions ---------------------------------------------------------------
source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))


# Query data --------------------------------------------------------------
stages_included <- c("0","I","II","III","IV")
fields <- '{"cancer_types": true, "sample_name": true,"stage": true, "_id": false}'
fetched_stage_data <- purrr::map(.x = "all_stage", .f = fn_fetch_mongo, pattern="_stage",fields = fields,.key=search_cancertypes,.keyindex="cancer_types") %>%
  dplyr::bind_rows() %>%
  dplyr::select(-cancertype) %>%
  dplyr::rename(cancertype=cancer_types) %>%
  dplyr::mutate(stage = purrr::map(stage,.f=function(.x){
    sub1 <- gsub(pattern = "[a-cA-C1-9]$",replacement = "",.x)
    sub2 <- gsub(pattern = "[a-cA-C1-9]$",replacement = "",.x)
    sub3 <- gsub(pattern = "Stage ",replacement = "",.x)
    return(sub3)
  })) %>%
  tidyr::unnest() %>%
  dplyr::filter(stage %in% stages_included)

fields <- '{"symbol": true, "barcode": true,"sample_name": true,"type": true,"expr": true,"_id": false}'
fetched_expr_data <- purrr::map(.x = paste0(search_cancertypes,"_all_expr",sep=""), .f = fn_fetch_mongo, pattern="_all_expr",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows() %>%
  dplyr::filter(type=="tumor")

# combine -----------------------------------------------------------------
fetched_stage_data%>%
  dplyr::inner_join(fetched_expr_data,by=c("sample_name","cancertype")) -> combine

# mean exp ----------------------------------------------------------------

combine %>%
  dplyr::group_by(cancertype,symbol,stage) %>%
  dplyr::mutate(mean_exp= mean(expr)) %>%
  dplyr::select(mean_exp) %>%
  dplyr::ungroup() %>%
  unique() -> combine_mean

# trend analysis --------------------------------------------------------------------

stage_number <- tibble::tibble(stage=c("0","I","II","III","IV"),
                               rank=c(0,1,2,3,4))

combine_mean %>%
  dplyr::mutate(log2mean_exp = log2(mean_exp+1))%>%
  dplyr::inner_join(stage_number,by="stage") -> for_plot

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

# heatmap --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_gradient_heatmap.R"))
for_plot_trend %>%
  dplyr::filter(!is.na(log2mean_exp)) %>%
  .$log2mean_exp -> exp_value
min(exp_value) %>% floor() -> min_heat
max(exp_value) %>% ceiling() -> max_heat
fillbreaks_heat <- sort(unique(c(min_heat,max_heat,round(seq(min_heat,max_heat,length.out = 4)))))
CPCOLS <- c("red", "white", "blue")

heat_plot <- gradient_heatmap(data = for_plot_trend,
                              fill="log2mean_exp",
                              fillname="Log2(RSEM)",
                              aesx="stage",
                              aesy="symbol",
                              fillbreaks=fillbreaks_heat,
                              yrank=trend_symbol_rank$symbol,
                              xlab="Stages",
                              ylab="Symbol",
                              title="")

# Save --------------------------------------------------------------------
ggsave(filename = filepath_stageheat, plot = heat_plot, device = 'png', width = size$width, height = size$height)
filepath_stageheat_pdf_name <- gsub("\\.png",".pdf",filepath_stageheat)
ggsave(filename = filepath_stageheat_pdf_name, plot = heat_plot, device = 'pdf', width = size$width, height = size$height)


# TREND PLOT --------------------------------------------------------------

for_plot_trend %>%
  dplyr::filter(!is.na(statistic)) %>%
  .$statistic -> statistic_value
min(statistic_value) %>% floor() -> min_trend
max(statistic_value) %>% ceiling() -> max_trend
fillbreaks_trend <- sort(unique(c(0,min_trend,max_trend)))
CPCOLS_trend <- c("#ee0e27", "grey", "#1678f3")
n_cancers <- for_plot_trend$cancertype %>% unique() %>% length()

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