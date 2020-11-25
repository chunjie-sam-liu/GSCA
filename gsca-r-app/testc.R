
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath_testaparallelplot <- args[2]
filepath_testbparallelplot <- args[3]
apppath <- args[4]

# search_str = 'TP53@ACC_all_expr#BLCA_all_expr#BRCA_all_expr#CESC_all_expr#CHOL_all_expr#COAD_all_expr#DLBC_all_expr#ESCA_all_expr#GBM_all_expr#HNSC_all_expr#KICH_all_expr#KIRC_all_expr#KIRP_all_expr#LAML_all_expr#LGG_all_expr#LIHC_all_expr#LUAD_all_expr#LUSC_all_expr#MESO_all_expr#OV_all_expr#PAAD_all_expr#PCPG_all_expr#PRAD_all_expr#READ_all_expr#SARC_all_expr#SKCM_all_expr#STAD_all_expr#TGCT_all_expr#THCA_all_expr#THYM_all_expr#UCEC_all_expr#UCS_all_expr#UVM_all_expr
# '
# filepath_testaparallelplot = '/home/liucj/github/GSCA/gsca-r-plot/pngs/06dbe8a1-096a-4d88-ab36-af3161e5141d.png'
# filepath_testbparallelplot = '/home/liucj/github/GSCA/gsca-r-plot/pngs/8e721e52-60a8-4852-9ada-73ef1b13aeeb.png'
# apppath <- '/home/liucj/github/GSCA'


search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]


# pic size ----------------------------------------------------------------
testaparallelplot<-ggplot(mtcars, aes(mpg, as.factor(cyl))) + geom_boxplot()
testbparallelplot<-ggplot(mtcars, aes(mpg, as.factor(cyl))) + geom_boxplot()
ggsave(filename = filepath_testaparallelplot, plot = testaparallelplot, device = 'png')
ggsave(filename = filepath_testbparallelplot, plot = testbparallelplot, device = 'png')