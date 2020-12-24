# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)
# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
filepath <- args[3]
apppath <- args[4]

# tableuuid <- 'd6fe01ae-b1fe-4f9b-ac92-60210edca6bc'
# tablecol <- 'preanalysised_snvgeneset'
# filepath <- "/home/liucj/github/GSCA/gsca-r-plot/pngs/688682d4-977f-432b-8338-f0c28730cbcb.png"
# apppath <- '/home/huff/github/GSCA'

# Mongo -------------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
source(file.path(apppath, "gsca-r-app/utils/fn_geneset_survival.R"))
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsva_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_survival"), url = gsca_conf)

# Function ----------------------------------------------------------------


fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"uuid": "<.xx>"}', .open = '<', .close = '>')
}

fn_fetch_data <- function(.uuid) {
  pre_gsva_coll$find(query = fn_query_str(.x = .uuid), fields = '{"_id": false}')
}

# fetch data --------------------------------------------------------------

fetched_data <- fn_fetch_data(.uuid = tableuuid)$snvgeneset[[1]] %>%
  dplyr::mutate(sample_name=substr(barcode,1,12)) %>%
  tidyr::nest(data = c(barcode, group , sample_name))

fields <- '{"cancer_types": true, "sample_name": true, "os_days": true,"os_status": true, "pfs_days": true,"pfs_status": true,"_id": false}'
fetched_survival_data <- purrr::map(.x = "all_survival", .f = fn_fetch_mongo, pattern="_survival",fields = fields,.key=fetched_data$cancertype,.keyindex="cancer_types") %>%
  dplyr::bind_rows() %>%
  dplyr::group_by(cancer_types) %>%
  tidyr::nest() %>%
  dplyr::rename(cancertype=cancer_types)


# combine data ------------------------------------------------------------

fetched_data %>%
  dplyr::mutate(combine = purrr::map2(cancertype,data,.f=function(.x,.y){
    fetched_survival_data %>%
      dplyr::filter(cancertype %in% .x) %>%
      tidyr::unnest() %>%
      dplyr::inner_join(.y,by=c("sample_name")) %>%
      dplyr::mutate(group=ifelse(is.na(group),"1WT",group))
  })) %>%
  dplyr::ungroup() %>%
  dplyr::select(-data) -> combine_data_group

# calculation -------------------------------------------------------------

combine_data_group %>%
  dplyr::mutate(surviva_res = purrr::map2(cancertype,combine,fn_survival_res)) %>%
  dplyr::select(-combine) %>%
  tidyr::unnest(cols = c(surviva_res)) %>%
  dplyr::filter(!is.na(higher_risk_of_death))-> geneset_survival

# Insert table ------------------------------------------------------------
insert_data <- list(uuid = tableuuid, res_table = geneset_survival)
#post_gsva_coll$drop()
uuid_query <- post_gsva_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"uuid": true, "_id": false}'
)

if (nrow(uuid_query) == 0) {
  post_gsva_coll$insert(data = insert_data)
  post_gsva_coll$index(add = '{"uuid": 1}')
  message("insert data into preanalysised_snvgeneset_survival")
}

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(unique(geneset_survival$cancertype),unique(geneset_survival$sur_type))

color_list <- tibble::tibble(color=c( "#CD2626","#00B2EE"),
                             group=c("Mutant","WT"))

# rank --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/common_used_summary_plot_functions.R"))
fetched_data_clean_pattern <- fn_get_pattern(
  .x = geneset_survival %>% dplyr::rename(value=logrankp,trend=higher_risk_of_death),
  trend1="Mutated",
  trend2="Non-mutated",
  p_cutoff=0.05,selections = c("cancertype","sur_type"))
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern)

# plot --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_bubble_plot_immune.R"))
geneset_survival %>%
  dplyr::mutate(sur_type=toupper(sur_type)) %>%
  dplyr::rename(value=logrankp) %>% fn_pval_label() %>%
  dplyr::mutate(group = ifelse(value>0.05,">0.05","<0.05")) %>%
  dplyr::mutate(logp = -log10(value))-> for_plot
CPCOLS <- c("blue", "white", "red")
color_color <-  c("tomato","lightskyblue")
color_group<- c("Mutated","Non-mutated")
for_plot %>%
  dplyr::filter(!is.na(hr)) %>%
  .$hr -> HR_value
min(HR_value) %>% trunc() -> min
max(HR_value) %>% ceiling() -> max
fillbreaks <- sort(unique(c(1,min,max,seq(min,max,length.out = 3))))
title <- "Survival difference between geneset\nmutant and WT."

heat_plot <- bubble_plot(data=for_plot, 
                         cancer="sur_type", 
                         gene="cancertype", 
                         xlab="", 
                         ylab="Cancer type", 
                         facet_exp = NA,
                         size="logp", 
                         fill="hr", 
                         fillmipoint =1,
                         fillbreaks =fillbreaks,
                         colorgroup="group",
                         cancer_rank=c("OS","PFS"), 
                         gene_rank=cancer_rank$cancertype, 
                         sizename= "-Log(P)", 
                         fillname="Hazard ratio", 
                         colorvalue=c("black","grey"), 
                         colorbreaks=c("<0.05",">0.05"),
                         colorname="Logrank P value",
                         title=title)
# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = heat_plot, device = 'png', width = 4, height = size$height-1)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = heat_plot, device = 'pdf', width = 4, height = size$height-1)
