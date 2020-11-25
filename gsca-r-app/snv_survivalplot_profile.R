
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(dplyr)

# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]
# search_str <- 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_snv_survival#KIRC_snv_survival#KIRP_snv_survival#LUAD_snv_survival#LUSC_snv_survival'
# apppath='/home/huff/github/GSCA'

search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()

# pic size ----------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
size <- fn_height_width(search_genes,search_cancertypes)

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))

# Function ----------------------------------------------------------------

fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"symbol": {"$in": ["<.xx>"]}}', .open = '<', .close = '>')
}

fn_fetch_mongo <- function(.x) {
  .coll <- mongolite::mongo(collection = .x, url = gsca_conf)
  .coll$find(
    query = fn_query_str(search_genes),
    fields = '{"symbol": true, "log_rank_p": true,"cox_p": true,"sur_type": true,"higher_risk_of_death": true,"HR": true, "_id": false}'
  ) %>%
    dplyr::mutate(cancertype = gsub(pattern = '_snv_survival', replacement = '', x = .x))
}

fn_filter_pattern <- function(risk, pval) {
  if ((risk == "Mutated") && (pval < 0.05)) {
    return(1)
  } else if ((risk == "Non-mutated") && (pval < 0.05)) {
    return(-1)
  } else {
    return(0)
  }
}

fn_get_pattern <- function(.x) {
  .x %>%
    dplyr::mutate(pattern = purrr::map2_dbl(higher_risk_of_death, log_rank_p, fn_filter_pattern)) %>%
    dplyr::select(cancertype, symbol, pattern,sur_type ) %>%
    tidyr::spread(key = cancertype, value = pattern) %>%
    dplyr::mutate_if(.predicate = is.numeric, .funs = function(.) {ifelse(is.na(.), 0, .)})
}

fn_get_cancer_types_rank <- function(.x) {
  .x %>%
    dplyr::summarise_if(.predicate = is.numeric, dplyr::funs(sum(abs(.)))) %>%
    tidyr::gather(key = cancertype, value = rank) %>%
    dplyr::arrange(dplyr::desc(rank))
}

fn_get_gene_rank <- function(.x) {
  .x %>%
    dplyr::rowwise() %>%
    dplyr::do(
      symbol = .$symbol,
      rank = unlist(.[-1][-1], use.names = F) %>% sum(),
      high = (unlist(.[-1][-1], use.names = F) == 1) %>% sum(),
      low = (unlist(.[-1][-1], use.names = F) == -1) %>% sum()
    ) %>%
    dplyr::ungroup() %>%
    tidyr::unnest(cols = c(symbol, rank, high, low)) %>%
    dplyr::arrange(rank)
}

fn_pval_class <- function(.p){
  if(.p>0.05){
    ""
  }else if(.p<=0.05 & .p>=0.01){
    "*"
  }else if(.p<0.01 & .p>=0.001){
    "**"
  } else{
    "***"
  }
}
fn_pval_label <- function(.x){
  .x %>%
    dplyr::mutate(p_label=purrr::map(log_rank_p,fn_pval_class)) %>%
    tidyr::unnest()
}

# Query data --------------------------------------------------------------

fetched_data <- purrr::map(.x = search_colls, .f = fn_fetch_mongo) %>% dplyr::bind_rows()

# Sort --------------------------------------------------------------------

fetched_data_clean_pattern <- fn_get_pattern(.x = fetched_data)
cancer_rank <- fn_get_cancer_types_rank(.x = fetched_data_clean_pattern %>% dplyr::filter(sur_type=="os"))
gene_rank <- fn_get_gene_rank(.x = fetched_data_clean_pattern %>% dplyr::filter(sur_type=="os"))

for_plot <- fn_pval_label(fetched_data)

# Plot --------------------------------------------------------------------
CPCOLS <- c("#000080", "#F8F8FF", "#CD0000")
heat_plot <- for_plot %>%
  ggplot(aes(x = cancertype, y = symbol)) +
  geom_tile(aes(fill = higher_risk_of_death, color=HR),height=0.8,width=0.8,size=1.5) +
  geom_text(aes(label=p_label)) +
  scale_y_discrete(limit = gene_rank$symbol) +
  scale_x_discrete(limit = cancer_rank$cancer_types) +
  facet_grid(.~sur_type) +
  scale_color_gradient2(
    low = "blue",
    mid = "white",
    high = "red",
    midpoint = 1,
    na.value = "white",
    breaks = seq(0, 3, length.out = 6),
    name = "Hazard ratio"
  ) +
  scale_fill_manual(values = c("tomato","lightskyblue"),
                    limits = c("Mutated","Non-mutated"),
                    name="Higher risk of death") +
  theme(
    panel.background = element_rect(colour = "black", fill = "white"),
    panel.grid = element_line(colour = "grey", linetype = "dashed"),
    panel.grid.major = element_line(
      colour = "grey",
      linetype = "dashed",
      size = 0.2
    ),
    axis.title = element_blank(),
    axis.ticks = element_line(color = "black"),
    # axis.text.y = element_text(color = gene_rank$color),
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, colour = "black"),
    axis.text.y = element_text(colour = "black"),
    
    legend.text = element_text(size = 12),
    legend.title = element_text(size = 14),
    legend.key = element_rect(fill = "white", colour = "black"),
    strip.background = element_rect(fill="white",color="black"),
    strip.text = element_text(size= 12)
  )


# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = heat_plot, device = 'png', width = size$width, height = size$height)
pdf_name <- gsub("\\.png",".pdf",filepath)
ggsave(filename = pdf_name, plot = heat_plot, device = 'pdf', width = size$width, height = size$height)


