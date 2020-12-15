
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
filepath <- args[3]
apppath <- args[4]


# tableuuid <- 'ba16c786-93ca-421e-a426-7a361f4c3e7a'
# tablecol <- 'preanalysised_gsva'
# filepath <- "/home/liucj/github/GSCA/gsca-r-plot/pngs/688682d4-977f-432b-8338-f0c28730cbcb.png"
# apppath <- '/home/huff/github/GSCA'

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsva_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_survival"), url = gsca_conf)

# Function ----------------------------------------------------------------
source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))


fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"uuid": "<.xx>"}', .open = '<', .close = '>')
}

fn_fetch_data <- function(.uuid) {
  pre_gsva_coll$find(query = fn_query_str(.x = .uuid), fields = '{"_id": false}')
}

fn_reorg <- function(.x) {
  
  .x %>%
    tibble::as_tibble() %>%
    tidyr::gather(key = "barcode", value = "gsva") %>%
    tidyr::separate(col = "barcode", into = c("barcode", "type"), sep = "#") %>%
    dplyr::mutate(type = factor(x = type, levels = c("tumor", "normal"))) ->
    .xx
  .xx
}

# Process -----------------------------------------------------------------

fetched_data <- fn_fetch_data(.uuid = tableuuid)

fetched_data$gsva_score %>% 
  tibble::as_tibble() %>% 
  tidyr::gather(key = "cancertype", value = "gsva") %>% 
  dplyr::mutate(gsva = purrr::map(.x = gsva, .f = fn_reorg)) ->
  gsva_score_nest


fields <- '{"cancer_types": true, "sample_name": true, "os_days": true,"os_status": true, "pfs_days": true,"pfs_status": true,"_id": false}'
fetched_survival_data <- purrr::map(.x = "all_survival", .f = fn_fetch_mongo, pattern="_survival",fields = fields,.key=gsva_score_nest$cancertype,.keyindex="cancer_types") %>%
  dplyr::bind_rows() %>%
  dplyr::group_by(cancer_types) %>%
  tidyr::nest() %>%
  dplyr::rename(cancertype=cancer_types)

# survival analysis -------------------------------------------------------
gsva_score_nest %>%
  dplyr::inner_join(fetched_survival_data, by="cancertype") -> combine_data

source(file.path(apppath,"gsca-r-app/utils/fn_gsva_sruviva.R"))
combine_data %>%
  dplyr::mutate(sur_res = purrr::map2(gsva,data,fn_survival)) %>%
  dplyr::select(cancertype,sur_res) %>%
  tidyr::unnest() -> gsva_score_survival

# Insert table ------------------------------------------------------------
insert_data <- list(uuid = tableuuid, res_table = gsva_score_survival)
#post_gsva_coll$drop()
uuid_query <- post_gsva_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"uuid": true, "_id": false}'
)

if (nrow(uuid_query) == 0) {
  post_gsva_coll$insert(data = insert_data)
  post_gsva_coll$index(add = '{"uuid": 1}')
  message("insert data into preanalysised_gsva_survival")
}

# Plot --------------------------------------------------------------------
gsva_score_survival %>%
  dplyr::mutate(group=ifelse(logrankp>0.05,">0.05","<0.05")) %>%
  dplyr::rename(HR=hr_categorical) %>%
  dplyr::mutate(logp = -log10(logrankp))-> for_plot

# Sort -------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/common_used_summary_plot_functions.R"))

fetched_data_clean_pattern <- fn_get_pattern(
  .x = for_plot %>% dplyr::rename(value=logrankp,trend=higher_risk_of_death) %>% dplyr::filter(sur_type=="OS"),
  trend1="Higher GSVA",
  trend2="Lower GSVA",
  p_cutoff=0.05,
  selections =c("cancertype"))
cancer_rank <- fn_get_cancer_types_rank_v2(.x = fetched_data_clean_pattern)

source(file.path(apppath,"gsca-r-app/utils/fn_bubble_plot_immune.R"))
CPCOLS <- c("blue", "white", "red")
color_color <-  c("tomato","lightskyblue")
color_group<- c("Higher GSVA","Lower GSVA")
for_plot %>%
  dplyr::filter(!is.na(HR)) %>%
  .$HR -> HR_value
min(HR_value) %>% floor() -> min
max(HR_value) %>% ceiling() -> max
fillbreaks <- sort(unique(c(1,min,max,seq(min,max,length.out = 3))))
title <- ""

heat_plot <- bubble_plot(data=for_plot, 
                         cancer="sur_type",
                         gene="cancertype", 
                         ylab="Cancer types", 
                         xlab="", 
                         facet_exp = NA,
                         size="logp", 
                         fill="HR", 
                         fillmipoint =1,
                         fillbreaks =fillbreaks,
                         colorgroup="group",
                         gene_rank=cancer_rank$cancertype, 
                         cancer_rank=c("OS","PFS"), 
                         sizename= "-Log(P)", 
                         fillname="Hazard ratio", 
                         colorvalue=c("black","grey"), 
                         colorbreaks=c("<0.05",">0.05"),
                         colorname="Logrank P",
                         title=title)

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(unique(for_plot$cancertype),unique(for_plot$sur_type))

# Save image --------------------------------------------------------------

ggsave(filename = filepath, plot = heat_plot, device = 'png', width = size$width, height =  size$height)
pdf_name <- gsub("\\.png",".pdf", filepath)
ggsave(filename = pdf_name, plot = heat_plot, device = 'pdf', width = size$width, height = size$height)