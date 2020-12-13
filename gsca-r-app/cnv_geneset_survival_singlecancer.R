# snv single gene survival---------------------------------------------------------
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)
# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str <-'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@LUAD_cnv_threshold@OS'
# apppath <- '/home/huff/github/GSCA'
search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]
survival_type <- search_str_split[3]

# Functions ----------------------------------------------------------------
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_survival_cnv.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_cnv.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_survival.R"))
cnv_group <- tibble::tibble(cnv=c(-2,-1,0,1,2),
                            group_detail=c("Homo. dele.","Hete. dele.","WT","Hete. amp.","Homo. amp."),
                            group=c("Dele.","Dele.","WT","Amp.","Amp."),
                            color=c( "#00B2EE","#00B2EE","gold4","#CD2626","#CD2626"))
# Query data --------------------------------------------------------------
fetched_survival_data <- fn_fetch_mongo_all_survival(.data="all_survival",.keyindex="cancer_types", .key=search_cancertypes) %>%
  dplyr::bind_rows() %>%
  dplyr::filter(cancer_types %in% search_cancertypes)

fields <- '{"symbol": true, "barcode": true,"sample_name": true,"type": true,"cnv": true,"_id": false}'
fetched_cnv_data <- purrr::map(.x = paste(search_cancertypes,"_cnv_threshold",sep=""), .f = fn_fetch_mongo, pattern="_cnv_threshold",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows() %>%
  dplyr::filter(type == "tumor")


# mutation group ----------------------------------------------------------

fetched_cnv_data %>%
  dplyr::inner_join(cnv_group,by="cnv") -> combine_group_data

combine_group_data %>%
  tidyr::nest(data = c(sample_name, symbol, 
                       barcode, type, cnv, color,group_detail, group)) %>%
  dplyr::mutate(mutataion_group=purrr::map(data,fn_geneset_cnv)) %>%
  dplyr::select(-data) %>%
  tidyr::unnest() -> mutate_grouped

# combine data ------------------------------------------------------------

fetched_survival_data %>%
  dplyr::inner_join(mutate_grouped,by=c("sample_name")) %>%
  dplyr::mutate(group=ifelse(is.na(group),"WT",group)) %>%
  dplyr::filter(group != "Excluded")-> combine_data

survival_group  %>%
  dplyr::filter(type %in% survival_type) -> survival_type_to_draw

combine_data %>%
  dplyr::select(sample_name,group,cancer_types,time=survival_type_to_draw$time,status=survival_type_to_draw$status) -> combine_data_group


# draw --------------------------------------------------------------------

title <- paste(toupper(survival_type),"survival of gene set", "CNV in",search_cancertypes)
combine_data_group %>%
  dplyr::filter(!is.na(time)) %>%
  fn_survival(title,cnv_group) -> plot

# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = plot, device = 'png', width = 6, height = 4)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 6, height = 4)

