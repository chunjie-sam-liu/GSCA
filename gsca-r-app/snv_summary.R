library(maftools)
library(magrittr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath_snvsummary <- args[2]
filepath_snvoncoplot <- args[3]
filepath_snvtitvplot <- args[4]
apppath <- args[5]


# search_str = "A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_snv_count#KIRC_snv_count#KIRP_snv_count#LUAD_snv_count#LUSC_snv_count"
# filepath= "/home/huff/github/GSCA/gsca-r-plot/pngs/7aa843d9-6287-468e-9d52-47c44ea1fe21.png"
# apppath='/home/huff/github/GSCA'


search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()


# fetch data --------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
fields <- '{"_id": false}'
fetched_snv_maf <- purrr::map(.x = paste(search_cancertypes,"_snv_maf",sep=""), .f = fn_fetch_mongo, pattern="_snv_maf",fields = fields,.key=search_genes,.keyindex="symbol") %>%
  dplyr::bind_rows()


# judgment ---------------------------------------------------------------

effective_mut <- c("Missense_Mutation","Nonsense_Mutation","Frame_Shift_Ins","Splice_Site","Frame_Shift_Del","In_Frame_Del","In_Frame_Ins")


if(nrow(fetched_snv_maf)>0){
  fetched_snv_maf %>%
    dplyr::filter(Variant_Classification %in% effective_mut) -> fetched_snv_maf.non_synonymous
  if(nrow(fetched_snv_maf.non_synonymous)>0){
    fetched_snv_maf.non_synonymous %>%
      dplyr::rename(Hugo_Symbol=symbol) ->fetched_snv_maf.non_synonymous
    fetched_snv_maf.non_synonymous %>%
      dplyr::select(cancertype,Tumor_Sample_Barcode) %>%
      dplyr::rename("Cancer_type"="cancertype")-> clincial_info
    maf_project <- read.maf(maf=fetched_snv_maf.non_synonymous,clinicalData=clincial_info)
    # draw plot ---------------------------------------------------------------
    # summary plot
    png(filename = filepath_snvsummary,height = 4,width = 6,units = "in",res=500)
    plotmafSummary(maf = maf_project, rmOutlier = TRUE, addStat = 'median', dashboard = TRUE, titvRaw = FALSE)
    dev.off()

    pdf_name_snvsummary <- gsub("\\.png",".pdf",filepath_snvsummary)
    pdf(file = pdf_name_snvsummary,height = 4,width = 6)
    plotmafSummary(maf = maf_project, rmOutlier = TRUE, addStat = 'median', dashboard = TRUE, titvRaw = FALSE)
    dev.off()

    # titv plot
    maf.titv = titv(maf = maf_project, plot = FALSE, useSyn = TRUE)

    png(filename = filepath_snvtitvplot,height = 4,width = 6,units = "in",res=500)
    plotTiTv(res = maf.titv)
    dev.off()

    pdf_name_snvtitvplot <- gsub("\\.png",".pdf",filepath_snvtitvplot)
    pdf(file = pdf_name_snvtitvplot,height = 4,width = 6)
    plotTiTv(res = maf.titv)
    dev.off()

    if(length(unique(fetched_snv_maf.non_synonymous$entrez))>=2){
      # oncoplot
      png(filename = filepath_snvoncoplot,height = 6,width = 10,units = "in",res=500)
      oncoplot(
        maf = maf_project,
        clinicalFeatures = "Cancer_type", sortByMutation = TRUE, sortByAnnotation = TRUE,
        top = 10
      )
      dev.off()

      pdf_name_snvoncoplot <- gsub("\\.png",".pdf",filepath_snvoncoplot)
      pdf(file = pdf_name_snvoncoplot,height = 6,width = 10)
      oncoplot(
        maf = maf_project,
        clinicalFeatures = "Cancer_type", sortByMutation = TRUE, sortByAnnotation = TRUE,
        top = 10
      )
      dev.off()
    }else{
      source(file.path(apppath, "gsca-r-app/utils/fn_NA_notice_fig.R"))
      fn_NA_notice_fig("Caution: \nOncoplot requires at-least two genes with\n non-synonymous mutations for plotting.") -> p
      # Save --------------------------------------------------------------------
      ggsave(filename = filepath_snvoncoplot, plot = p, device = 'png', width = 6, height = 4)
      pdf_name_snvoncoplot <- gsub("\\.png",".pdf",filepath_snvoncoplot)
      ggsave(filename = pdf_name_snvoncoplot, plot = p, device = 'pdf', width = 6, height = 4)
    }
  }else{
    source(file.path(apppath, "gsca-r-app/utils/fn_NA_notice_fig.R"))
    fn_NA_notice_fig("Caution: \nNo non-synonymous mutations found\nin your search gene list.") -> p
    # Save --------------------------------------------------------------------
    ggsave(filename = filepath_snvsummary, plot = p, device = 'png', width = 6, height = 4)
    pdf_name <- gsub("\\.png",".pdf",filepath_snvsummary)
    ggsave(filename = pdf_name, plot = p, device = 'pdf', width = 6, height = 4)

    ggsave(filename = filepath_snvoncoplot, plot = p, device = 'png', width = 6, height = 4)
    ggsave(filename = filepath_snvtitvplot, plot = p, device = 'png', width = 6, height = 4)
    pdf_name_snvtitvplot <- gsub("\\.png",".pdf",filepath_snvtitvplot)
    pdf_name_snvoncoplot <- gsub("\\.png",".pdf",filepath_snvoncoplot)
    ggsave(filename = pdf_name_snvoncoplot, plot = p, device = 'pdf', width = 6, height = 4)
    ggsave(filename = pdf_name_snvtitvplot, plot = p, device = 'pdf', width = 6, height = 4)
  }

}else{
  source(file.path(apppath, "gsca-r-app/utils/fn_NA_notice_fig.R"))
  fn_NA_notice_fig("Caution: \nNo mutations found\nin your search gene list.") -> p
  # Save --------------------------------------------------------------------
  ggsave(filename = filepath_snvsummary, plot = p, device = 'png', width = 6, height = 4)
  pdf_name <- gsub("\\.png",".pdf",filepath_snvsummary)
  ggsave(filename = pdf_name, plot = p, device = 'pdf', width = 6, height = 4)

  ggsave(filename = filepath_snvoncoplot, plot = p, device = 'png', width = 6, height = 4)
  ggsave(filename = filepath_snvtitvplot, plot = p, device = 'png', width = 6, height = 4)
  pdf_name_snvtitvplot <- gsub("\\.png",".pdf",filepath_snvtitvplot)
  pdf_name_snvoncoplot <- gsub("\\.png",".pdf",filepath_snvoncoplot)
  ggsave(filename = pdf_name_snvoncoplot, plot = p, device = 'pdf', width = 6, height = 4)
  ggsave(filename = pdf_name_snvtitvplot, plot = p, device = 'pdf', width = 6, height = 4)
}



