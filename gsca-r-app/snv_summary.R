library(maftools)
library(magrittr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]


# search_str = "A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_snv_count#KIRC_snv_count#KIRP_snv_count#LUAD_snv_count#LUSC_snv_count"
# filepath= "/home/huff/github/GSCA/gsca-r-plot/pngs/7aa843d9-6287-468e-9d52-47c44ea1fe21.png"
# apppath='/home/huff/github/GSCA'


search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()


# fetch data --------------------------------------------------------------

data_path <- "/home/huff/data/GSCA/mutation/snv/sub_cancer_maf_tsv"
pan_maf <- tibble::tibble()
for (cancer in search_cancertypes) {
  filename <- paste(cancer,"_maf_data.IdTrans.tsv.rds.gz",sep="") 
  maf_file <- readr::read_rds(file.path(data_path,filename)) %>%
    dplyr::filter(Hugo_Symbol %in% search_genes)
  if(nrow(pan_maf)<1){
    pan_maf<-maf_file
  } else {
    rbind(pan_maf,maf_file) ->pan_maf
  }
}
pan_maf %>%
  dplyr::select(cancer_types,Tumor_Sample_Barcode) -> clincial_info
maf_project <- read.maf(maf=pan_maf,clinicalData=clincial_info)


# save maf ----------------------------------------------------------------

maf_project %>% 
  readr::write_rds(file.path(apppath,"gsca-r-plot","maf_project.rds.gz"),compress = "gz")


# draw plot ---------------------------------------------------------------
png(filename = filepath,height = 4,width = 6,units = "in",res=500)
plotmafSummary(maf = maf_project, rmOutlier = TRUE, addStat = 'median', dashboard = TRUE, titvRaw = FALSE)
dev.off()

pdf_name <- gsub("\\.png",".pdf",filepath)
pdf(file = pdf_name,height = 4,width = 6)
plotmafSummary(maf = maf_project, rmOutlier = TRUE, addStat = 'median', dashboard = TRUE, titvRaw = FALSE)
dev.off()
