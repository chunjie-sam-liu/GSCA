
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
filepath <- args[3]
apppath <- args[4]


# tableuuid <- '292dda97-0c17-479c-a41d-34d366e22918'
# tablecol <- 'preanalysised_gsva'
# filepath <- "/home/liucj/github/GSCA/gsca-r-plot/pngs/688682d4-977f-432b-8338-f0c28730cbcb.png"
# apppath <- '/home/liucj/github/GSCA'

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsva_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_expr"), url = gsca_conf)

# Function ----------------------------------------------------------------
fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"uuid": "<.xx>"}', .open = '<', .close = '>')
}

fn_fetch_data <- function(.uuid) {
  pre_gsva_coll$find(query = fn_query_str(.x = tableuuid), fields = '{"_id": false}')
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

fn_test <- function(.x) {
  .x$type %>% table() %>%
    as.data.frame() %>%
    dplyr::as.tbl() %>%
    dplyr::filter(Freq>=10) -> .sample_count
  if(nrow(.sample_count)>1){
    t.test(formula = gsva ~ type, data = .x) %>%
      broom::tidy() %>%
      dplyr::select(diff_gsva = estimate, tumor_gsva = estimate1, normal_gsva = estimate2, pval = p.value) %>%
      dplyr::mutate(log2fc = log2(tumor_gsva/normal_gsva))
  }else{
    tibble::tibble()
  }
  
}



# Process -----------------------------------------------------------------

fetched_data <- fn_fetch_data(.uuid = tableuuid)

fetched_data$gsva_score %>% 
  tibble::as_tibble() %>% 
  tidyr::gather(key = "cancertype", value = "gsva") %>% 
  dplyr::mutate(gsva = purrr::map(.x = gsva, .f = fn_reorg)) ->
  gsva_score_nest

gsva_score_nest %>% 
  dplyr::mutate(test = purrr::map(.x = gsva, .f = fn_test)) %>% 
  dplyr::select(-gsva) %>% 
  tidyr::unnest(cols = test) ->
  gsva_score_test

# Insert table ------------------------------------------------------------
insert_data <- list(uuid = tableuuid, res_table = gsva_score_test)
#post_gsva_coll$drop()
uuid_query <- post_gsva_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"uuid": true, "_id": false}'
)

if (nrow(uuid_query) == 0) {
  post_gsva_coll$insert(data = insert_data)
  post_gsva_coll$index(add = '{"uuid": 1}')
  message("insert data into preanalysised_gsva")
}

# Plot --------------------------------------------------------------------
source(file.path(apppath,"gsca-r-app/utils/fn_boxplot_single_gene_in_cancer.R"))
gsva_score_nest %>% tidyr::unnest(cols = gsva) -> for_plot
CPCOLS <- c("#000080", "#F8F8FF", "#CD0000")

plot <- box_plot_single_gene_multi_cancers(data = for_plot,aesx = "type",aesy="gsva",facets=".~cancertype",color = "type",color_name = "Group",color_labels = c("Tumor", "Normal"),color_values = c(CPCOLS[3], CPCOLS[1]),title = "GSVA score in selected cancer types", xlab = 'Cancer type', ylab = 'GSVA score')

# Save image --------------------------------------------------------------
width = 7 / 5 * length(unique(for_plot$cancertype))
height = 5

width <- max(c(7, width))
if (width > 20) width <- 20
height <- max(c(5, height))

ggsave(filename = filepath, plot = plot, device = 'png', width = width, height = height)
pdf_name <- gsub("\\.png",".pdf", filepath)
ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = width, height = height)
