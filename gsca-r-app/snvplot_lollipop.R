library(maftools)
library(magrittr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str="MCM2@KICH_snv_count"
# filepath='/home/huff/github/GSCA/gsca-r-plot/pngs/ed916e24-0de9-4350-8f8e-67c364a7ea67.png'
# apppath='/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_colls, split = '_')[[1]][1]

# mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

# Functions ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
# fetch data --------------------------------------------------------------
# fields <- '{"_id": false}'
# fetched_snv_maf <- purrr::map(.x = paste(search_cancertypes,"_snv_maf",sep=""), .f = fn_fetch_mongo, pattern="_snv_maf",fields = fields,.key=search_genes,.keyindex="symbol") %>%
#   dplyr::bind_rows() %>%
#   dplyr::rename(Hugo_Symbol=symbol)
# fetched_snv_maf %>%
#   dplyr::select(cancertype,Tumor_Sample_Barcode) -> clincial_info
# pan_maf <- read.maf(maf=fetched_snv_maf,clinicalData=clincial_info)

data_path <- file.path(apppath,'gsca-r-rds/maf')
filename <-  paste(search_cancertypes,"_maf_data.IdTrans.maf.rds.gz",sep="")
pan_maf <- readr::read_rds(file.path(data_path,filename))

snv_count <- fn_fetch_mongo_snv_count(.data=search_colls,.keyindex="symbol", .key=search_genes)
# pic size ----------------------------------------------------------------

fn_height <- function(.g){
  .lg <- length(.g)
  if(.lg<=5){
    .height <- 3
  } else{
    .height <- 3 + (.lg-5)*0.5
  }
  if(.height>=15){
    .height <- 15
  } else {
    .height <- .height
  }
  .height
}
# plot --------------------------------------------------------------------
# height <- fn_height(nrow(fetched_snv_maf))
height <- fn_height(snv_count$EffectiveMut)
png(filename = filepath,height = height,width = 4,units = "in",res=500)
lollipopPlot(maf = pan_maf,gene = search_genes, showMutationRate = TRUE)
dev.off()

pdf_name <- gsub("\\.png",".pdf",filepath)
pdf(file = pdf_name,height = height,width = 4)
lollipopPlot(maf = pan_maf,gene = search_genes, showMutationRate = TRUE)
dev.off()
