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

# fetch data --------------------------------------------------------------

data_path <- "/home/huff/data/GSCA/mutation/snv/sub_cancer_maf"
filename <-  paste(search_cancertypes,"_maf_data.IdTrans.maf.rds.gz",sep="")
pan_maf <- readr::read_rds(file.path(data_path,filename))


# plot --------------------------------------------------------------------
png(filename = filepath,height = 3,width = 4,units = "in",res=500)
lollipopPlot(maf = pan_maf,gene = search_genes, showMutationRate = TRUE)
dev.off()

pdf_name <- gsub("\\.png",".pdf",filepath)
pdf(file = pdf_name,height = 3,width = 4)
lollipopPlot(maf = pan_maf,gene = search_genes, showMutationRate = TRUE)
dev.off()
