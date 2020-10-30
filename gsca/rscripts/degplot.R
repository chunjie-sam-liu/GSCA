
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
filepath <- args[2]
apppath <- args[3]

search_str = 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_deg#KIRC_deg#KIRP_deg#LUAD_deg#LUSC_deg'
filepath = '/home/liucj/github/GSCA/gsca/resource/pngs/A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_deg#KIRC_deg#KIRP_deg#LUAD_deg#LUSC_deg.png'
apppath <- '/home/liucj/github/GSCA'


search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_cancertypes <- strsplit(x = search_str_split[[2]], split = '#')[[1]]


# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca/rscripts/gsca.conf'))

# Function ----------------------------------------------------------------

fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"symbol": {"$in": ["<.xx>"]}}', .open = '<', .close = '>')
}

fn_fetch_mongo <- function(.x) {
  .coll <- mongolite::mongo(collection = .x, url = gsca_conf)
  .coll$find(
    query = fn_query_str(search_genes),
    fields = '{"symbol": true, "fc": true, "fdr": true, "_id": false}'
  ) %>% 
    dplyr::mutate(cancertype = gsub(pattern = '_deg', replacement = '', x = .x))
}


# Query data --------------------------------------------------------------

fetched_data <-  purrr::map(.x = search_cancertypes, .f = fn_fetch_mongo) %>% 
  dplyr::bind_rows() %>% 
  dplyr::mutate(fdr = -log10(fdr))

# Plot --------------------------------------------------------------------
CPCOLS <- c("#000080", "#F8F8FF", "#CD0000")
bubble_plot <- fetched_data %>% 
  ggplot(aes(x = cancertype, y = symbol)) +
  geom_point(aes(size = fdr, col = log2(fc))) +
  scale_color_gradient2(
    low = CPCOLS[1],
    mid = CPCOLS[2],
    high = CPCOLS[3],
    midpoint = 0,
    na.value = "white",
    breaks = seq(-3, 3, length.out = 5),
    labels = c("<= -3", "-1.5", "0", "1.5", ">= 3"),
    name = "log2 FC"
  ) 


# Save --------------------------------------------------------------------
ggsave(filename = filepath, plot = bubble_plot, device = 'png')

