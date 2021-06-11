
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

# search_str <- 'MED30@SKCM_cnv_threshold'
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
  dplyr::bind_rows()


# plot --------------------------------------------------------------------
color_list <- tibble::tibble(color=c("brown4","aquamarine4","brown1","aquamarine3","grey"),
                             type=c("Homo. Amp.", "Homo. Del.", "Hete. Amp.", "Hete. Del.", "None"),
                             value=c(2,-2,1,-1,0))
fetched_data %>%
  dplyr::filter(substr(barcode,14,14)=="0") %>%
  dplyr::mutate(cnv=as.factor(cnv)) -> plot_ready

fetched_data %>%
  dplyr::mutate(cnv_ab = abs(cnv)) %>%
  dplyr::arrange(desc(cnv_ab),desc(cnv)) -> sample_rank

color_list %>%
  dplyr::filter(value %in%  c(fetched_data$cnv %>% unique())) -> color

source(file.path(apppath,"gsca-r-app/utils/fn_cnv_oncoplot.R"))

fn_cnv_oncoplot(data=plot_ready,
                aesx="barcode",
                aesy="symbol",
                fill="cnv",
                fillname="CNV type",
                fillcolor=color$color,
                filllimit=factor(color$value),
                filllabel=color$type,
                xrank=sample_rank$barcode,
                yrank=search_genes,
                title=glue::glue("CNV distribution of ",{search_genes}," in ",{search_cancertypes}," tumor samples"),
                xlab="",ylab="") -> plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 5, height = 2)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 5, height = 2)

