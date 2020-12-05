
# cnv single gene plot ---------------------------------------------------------

# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str <- 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_cnv_threshold#KIRC_cnv_threshold#KIRP_cnv_threshold#LUAD_cnv_threshold#LUSC_cnv_threshold'
# apppath='/home/huff/github/GSCA'
# filepath <- "/home/huff/github/GSCA/gsca-r-plot/pngs/3d2e17d3-91b9-40ff-bf8f-d9dd70692a26.png"

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()

# fetch data --------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
fields <- '{"symbol": true, "aliquot": true,"barcode": true,"sample_name": true,"type": true,"cnv": true,"_id": false}'
fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo, pattern="_cnv_threshold",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()%>%
  dplyr::filter(type=="tumor") 


# plot --------------------------------------------------------------------
color_list <- tibble::tibble(color=c("brown4","aquamarine4","brown1","aquamarine3","grey"),
                             cnvtype=c("Homo. Amp.", "Homo. Del.", "Hete. Amp.", "Hete. Del.", "None"),
                             cnv=c(2,-2,1,-1,0),
                             rank = c(1,2,3,4,5))

fetched_data %>%
  dplyr::inner_join(color_list,by="cnv") %>%
  dplyr::group_by(symbol) %>%
  dplyr::mutate(symbol_cnv = sum(abs(cnv))) %>%
  dplyr::select(symbol,symbol_cnv) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(desc(symbol_cnv)) %>%
  unique() %>%
  top_n(10) %>%
  dplyr::mutate(symbolrank=1:10,
                symbol_n=paste("symbol",1:10,sep="_"))-> symbol_rank

fetched_data %>%
  dplyr::inner_join(color_list,by="cnv") %>%
  dplyr::group_by(cancertype) %>%
  dplyr::mutate(cancer_cnv = sum(abs(cnv))) %>%
  dplyr::select(cancertype,cancer_cnv) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(cancer_cnv) %>%
  unique()  -> cancer_rank

fetched_data %>%
  dplyr::group_by(barcode) %>%
  dplyr::mutate(cnv_sum = sum(abs(cnv))) %>%
  dplyr::filter(cnv_sum!=0) %>%
  dplyr::select(barcode) %>%
  unique() -> sample_with_atleast_one_cnv
# 
# fetched_data %>%
#   dplyr::inner_join(symbol_rank,by="symbol")%>%
#   dplyr::inner_join(cancer_rank,by="cancertype") %>%
#   dplyr::inner_join(color_list,by="cnv") %>%
#   dplyr::arrange(cancer_cnv,desc(symbol_cnv)) %>%
#   dplyr::select(barcode) %>%
#   unique() %>%
#   dplyr::filter(barcode %in% sample_with_atleast_one_cnv$barcode) -> sample_rank
# 
# fetched_data %>%
#   dplyr::filter(barcode %in% sample_with_atleast_one_cnv$barcode) %>%
#   dplyr::filter(symbol %in% symbol_rank$symbol)%>%
#   dplyr::inner_join(color_list,by="cnv") %>%
#   dplyr::inner_join(symbol_rank,by="symbol") %>%
#   dplyr::inner_join(cancer_rank,by="cancertype") %>%
#   dplyr::group_by(barcode) %>%
#   tidyr::nest() %>%
#   dplyr::mutate(sample_rank =  purrr::map(data,.f=function(.x){
#     .x %>%
#       dplyr::arrange(desc(symbol_cnv)) %>%
#       head(1) %>%
#       dplyr::select(cancertype,rank,symbol_cnv,cancer_cnv)
#   })) %>%
#   dplyr::select(-data) %>%
#   tidyr::unnest(cols = c(sample_rank)) -> forrank
# forrank %>%
#   dplyr::arrange(desc(cancer_cnv),desc(symbol_cnv),rank)-> sample_rank
# fetched_data %>%
#   dplyr::filter(barcode %in% sample_with_atleast_one_cnv$barcode) %>%
#   dplyr::filter(symbol %in% symbol_rank$symbol)%>%
#   dplyr::inner_join(color_list,by="cnv") %>%
#   dplyr::inner_join(symbol_rank,by="symbol") %>%
#   dplyr::inner_join(cancer_rank,by="cancertype") %>%
#   dplyr::group_by(barcode) %>%
#   dplyr::mutate(rank=max(rank))%>%
#   unique() %>%
#   dplyr::select(barcode,rank,symbol_n,symbolrank,cancer_cnv) %>%
#   tidyr::spread(key="symbol_n",value="symbolrank")  %>%
#   dplyr::arrange(desc(cancer_cnv),desc(symbol_1,symbol_2,symbol_3,symbol_4,symbol_5,symbol_6,symbol_7,symbol_8,symbol_9,symbol_10),rank) -> sample_rank
# 
# fetched_data %>%
#   dplyr::filter(barcode %in% sample_with_atleast_one_cnv$barcode) %>%
#   dplyr::filter(symbol %in% symbol_rank$symbol)%>%
#   dplyr::inner_join(color_list,by="cnv") %>%
#   dplyr::inner_join(symbol_rank,by="symbol") %>%
#   dplyr::inner_join(cancer_rank,by="cancertype") %>%
#   dplyr::group_by(barcode) %>%
#   dplyr::mutate(rank=max(rank))%>%
#   unique() %>%
#   dplyr::filter(cnv!=0) %>%
#   dplyr::select(barcode,symbol_n,symbolrank,cancer_cnv,cnv) %>%
#   tidyr::spread(key="symbol_n",value="symbolrank")  %>%
#   dplyr::arrange(desc(cancer_cnv),desc(symbol_1,symbol_2,symbol_3,symbol_4,symbol_5,symbol_6,symbol_7,symbol_8,symbol_9,symbol_10),cnv) -> sample_rank

fetched_data %>%
  dplyr::filter(symbol %in% symbol_rank$symbol) %>%
  dplyr::filter(barcode %in% sample_with_atleast_one_cnv$barcode) %>%
  dplyr::mutate(cnv=as.factor(cnv)) -> plot_ready

color_list %>%
  dplyr::filter(cnv %in%  c(fetched_data$cnv %>% unique())) -> color

source(file.path(apppath,"gsca-r-app/utils/fn_cnv_oncoplot.R"))

fn_cnv_oncoplot(data=plot_ready,
                aesx="barcode",
                aesy="symbol",
                fill="cnv",
                fillname="CNV type",
                fillcolor=color$color,
                filllimit=factor(color$cnv),
                filllabel=color$cnvtype,
                xrank=sample_rank$barcode,
                yrank=symbol_rank$symbol,
                title=glue::glue("CNV ditribution of gene set (top 10) in specific cancer types"),
                xlab="",ylab="") -> plot;plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 5, height = 2)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 5, height = 2)

