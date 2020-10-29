
# Library -----------------------------------------------------------------

library(magrittr)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

# search_str = 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_deg#KIRC_deg#KIRP_deg#LUAD_deg#LUSC_deg'
# filepath = '/home/liucj/github/GSCA/gsca/resource/pngs/A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_deg#KIRC_deg#KIRP_deg#LUAD_deg#LUSC_deg.png'
apppath <- '/home/liucj/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]


# Mongo -------------------------------------------------------------------

# gsca_conf <- readr::read_lines(file = here::here('gsca/rscripts/gsca.conf'))


print(search_str)
print(filepath)

readr::write_tsv(tibble::tibble(search_str = search_str, here = file.path(apppath, 'gsca/rscripts/gsca.conf')), file = filepath)
