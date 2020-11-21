library(maftools)
library(magrittr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str = "A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_snv_count#KIRC_snv_count#KIRP_snv_count#LUAD_snv_count#LUSC_snv_count"
# filepath= "/home/huff/github/GSCA/gsca-r-plot/pngs/6dcd096a-bdc9-4bee-988d-f946a79a91f6.png"
# apppath='/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()

# fetch data --------------------------------------------------------------

maf_project <- readr::read_rds(file.path(apppath,"gsca-r-plot","maf_project.rds.gz"))

# draw plot ---------------------------------------------------------------
maf.titv = titv(maf = maf_project, plot = FALSE, useSyn = TRUE)
#plot titv summary
png(filename = filepath,height = 4,width = 6,units = "in",res=500)
plotTiTv(res = maf.titv)
dev.off()

pdf_name <- gsub("\\.png",".pdf",filepath)
pdf(file = pdf_name,height = 4,width = 6)
plotTiTv(res = maf.titv)
dev.off()