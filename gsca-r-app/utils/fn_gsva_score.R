
library(GSVA)

# function to get gsva ----------------------------------------------------

fn_gsva <- function(.genelist,.expr){
  if (length(.genelist)>0) {
    # expr: a matrix of expression values where rows correspond to genes and columns correspond to samples.
    # genelist:  a list object
    .genelist <- list(geneSet=.genelist)
    res.gsva <- gsva(.expr,.genelist, mx.diff = FALSE,
                     method = c("gsva"),
                     kcdf = c("Gaussian"),
                     verbose = FALSE, parallel.sz = 1)
    res.gsva %>%
      as.data.frame() %>%
      dplyr::as.tbl() %>%
      dplyr::mutate(feature = rownames(res.gsva)) %>%
      tidyr::gather(-feature, key = "Run",value = "GSVA_score") %>%
      tidyr::spread(key = "feature", value = "GSVA_score") -> gsva.score
  } else{
    gsva.score <- tibble::tibble()
  }
  
}