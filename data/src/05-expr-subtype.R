
# Library -----------------------------------------------------------------

library(magrittr)

# Load data ---------------------------------------------------------------
rda_path <- "/home/huff/github/GSCA/data"

expr_subtype <- readr::read_rds(file = '/home/huff/data/GSCA/expr/expr_subtype.NEW.IdTrans.rds.gz')
expr_subtype_mean <- readr::read_rds(file = '/home/huff/data/GSCA/expr/expr_in_subtypes.mean.NEW.IdTrans.rds.gz')
for (i in 1:length(expr_subtype_mean)) {
  if(i==1){
    expr_subtype_mean[[i]] -> expr_subtype_mean.arrange
  }else{
    if(nrow(expr_subtype_mean[[i]])>0){
      expr_subtype_mean[[i]] %>%
        rbind(expr_subtype_mean.arrange)-> expr_subtype_mean.arrange
    }else{
      expr_subtype_mean.arrange -> expr_subtype_mean.arrange
    }
  }
}
expr_subtype_mean.arrange %>%
  dplyr::mutate(subtype.mean.n = paste(subtype," (",paste(signif(meanExp,2),n,sep = "/"), ")", sep="")) %>%
  dplyr::select(-meanExp,-n) %>%
  dplyr::group_by(cancer_types,entrez_id) %>%
  dplyr::arrange(subtype) %>%
  dplyr::mutate(n = 1:dplyr::n())%>%
  dplyr::mutate(subtypename = paste("Subtype",n,sep=""))  %>%
  dplyr::select(-subtype,-n) %>%
  dplyr::ungroup() %>%
  tidyr::spread(key="subtypename",value="subtype.mean.n") %>%
  tidyr::nest(-cancer_types,.key="meanExp") -> expr_subtype_mean.process

load(file = file.path(rda_path,"rda",'01-gene-symbols.rda'))
gsca_conf <- readr::read_lines(file = file.path(rda_path,"src",'gsca.conf'))


search_symbol <- search_symbol

# Function ----------------------------------------------------------------
fn_transform_df <- function(cancer_types, combine) {
  .x <- combine
  .y <- cancer_types
  message(glue::glue('Handling DEG for {.y}'))
  .fdr <- p.adjust(.x$p.value,method = "fdr")
  .x %>% 
    dplyr::mutate(fdr=.fdr) %>%
    dplyr::rename(
      pval = p.value
    ) %>%
    dplyr::mutate(entrez_id = as.numeric(entrez_id)) %>%
    dplyr::filter(entrez_id %in% search_symbol$entrez) %>%
    dplyr::select(-entrez_id)->
    .d
  
  # collection
  .coll_name <- glue::glue('{.y}_expr_subtype')
  .coll_expr <- mongolite::mongo(collection = .coll_name, url = gsca_conf)
  # insert data
  .coll_expr$drop()
  .coll_expr$insert(data = .d)
  .coll_expr$index(add = '{"symbol": 1}')
  message(glue::glue('Insert data for {.y} into {.coll_name}.'))
  
  .d
}


# Tidy data ---------------------------------------------------------------
expr_subtype %>%
  dplyr::inner_join(expr_subtype_mean.process,by="cancer_types") %>%
  dplyr::mutate(combine=purrr::map2(data,meanExp,.f=function(.x,.y){
    .x %>%
      dplyr::inner_join(.y,by=c("entrez_id","symbol"))
  })) %>%
  dplyr::select(-data,-meanExp) -> expr_subtype.combine

expr_subtype.combine %>% 
  purrr::pmap(.f = fn_transform_df) ->
  expr_subtype_nest_mongo_data

# Save image --------------------------------------------------------------

save.image(file = file.path(rda_path,"rda",'05-expr-subtype.rda'))
