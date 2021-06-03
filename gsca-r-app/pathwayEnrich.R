# Library -----------------------------------------------------------------

library(magrittr)
library(doParallel)
library(clusterProfiler)
# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

search_str <- args[1]
apppath <- args[2]
tableuuid <- args[3]
tablecol <- args[4]

# search_str = 'A2M#ACE#ANGPT2#BPI#CD1B#CDR1#EGR2#EGR3#HBEGF#HERPUD1#MCM2#PCTP#PODXL#PPY#PTGS2#RCAN1#SLC4A7#THBD@KICH_all_expr_gene_set.rds.gz#KIRC_all_expr_gene_set.rds.gz#KIRP_all_expr_gene_set.rds.gz#LUAD_all_expr_gene_set.rds.gz#LUSC_all_expr_gene_set.rds.gz'
# apppath <- '/home/huff/github/GSCA'
# tableuuid <- '3dfee429-973b-4222-bb2b-ba8522b68540'
# tablecol <- 'preanalysised_enrichment'


search_str_split <- strsplit(x = search_str, split = '@')[[1]]
search_genes <- strsplit(x = search_str_split[1], split = '#')[[1]]
search_colls <- strsplit(x = search_str_split[[2]], split = '#')[[1]]
search_cancertypes <- list(strsplit(x = search_str_split[[2]], split = '#')[[1]] )%>%
  purrr::pmap(.f=function(.x){strsplit(x = .x, split = '_')[[1]][1]}) %>% unlist()

# Mongo -------------------------------------------------------------------

gsca_conf <- readr::read_lines(file = file.path(apppath, 'gsca-r-app/gsca.conf'))
pre_gsea_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)

fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"uuid": "<.xx>"}', .open = '<', .close = '>')
}
# fetch data --------------------------------------------------------------
source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))

fields <- '{"symbol": true, "fc": true,"entrez": true,"_id": false}'
fetched_data <- purrr::map(.x = paste(search_cancertypes[1],"deg",sep="_"), .f = fn_fetch_mongo_all, pattern="_deg",fields = fields) %>%
  dplyr::bind_rows() 



# kegg --------------------------------------------------------------------

fetched_data %>%
  dplyr::filter(symbol %in% search_genes) %>%
  .$entrez -> search_genes_entrez
enrichKEGG(gene = search_genes_entrez,
           organism = 'hsa',
           pvalueCutoff = 0.05) -> enKegg
enKegg@result %>%
  dplyr::as.tbl() %>%
  dplyr::filter(fdr <0.05) %>%
  dplyr::mutate(Method = "KEGG")-> enKegg.res.q005

# go ----------------------------------------------------------------------
egoBP <- enrichGO(gene = search_genes_entrez,
                ont           = "BP",
                pAdjustMethod = "BH",
                pvalueCutoff  = 1)
egoBP@result %>%
  dplyr::as.tbl() %>%
  dplyr::filter(fdr <0.05) %>%
  dplyr::mutate(Method = "GO:BP") -> egoBP.res.q005

egoCC <- enrichGO(gene = search_genes_entrez,
                  ont           = "CC",
                  pAdjustMethod = "BH",
                  pvalueCutoff  = 1)
egoCC@result %>%
  dplyr::as.tbl() %>%
  dplyr::filter(fdr <0.05) %>%
  dplyr::mutate(Method = "GO:CC") -> egoCC.res.q005

egoMF <- enrichGO(gene = search_genes_entrez,
                  ont           = "MF",
                  pAdjustMethod = "BH",
                  pvalueCutoff  = 1)
egoMF@result %>%
  dplyr::as.tbl() %>%
  dplyr::filter(fdr <0.05) %>%
  dplyr::mutate(Method = "GO:MF") -> egoMF.res.q005


rbind(egoBP.res.q005,egoCC.res.q005) %>%
  rbind(egoMF.res.q005) %>%
  rbind(enKegg.res.q005) %>%
  dplyr::rename("fdr"="p.adjust") %>%
  dplyr::mutate(Hits = purrr::map(geneID,.f=function(.x){
    .x <- as.character(.x)
    hits <- strsplit(.x,"/")[[1]]
    fetched_data %>%
      dplyr::filter(entrez %in% hits) %>%
      .$symbol -> hits.symbol
    paste0(hits.symbol,collapse="/")
  })) %>%
  tidyr::unnest()-> enrichALL

# Update mongo ------------------------------------------------------------

insert_data <- list(uuid = tableuuid, enrichment = enrichALL, gene_set = search_genes)

uuid_query <- pre_gsea_coll$find(
  query = fn_query_str(.x = tableuuid),
  fields = '{"uuid":true, "_id": false}'
)
# pre_gsea_coll$drop()
if (nrow(uuid_query) == 0) {
  pre_gsea_coll$insert(data = insert_data)
  pre_gsea_coll$index(add = '{"uuid": 1}')
  message("insert data into preanalysised_enrichment")
}
