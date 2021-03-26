clinical %>%
  dplyr::select(cancer_types,subtype=n.x, survival= n.y, stage=n) -> clinical_statistical

all_expr %>%
  dplyr::mutate(expr = purrr::map(expr,.f=function(.x){
    ncol(.x)
  })) %>%
  tidyr::unnest() -> expr_statistical
expr_statistical %>%
  dplyr::mutate(immune=expr) %>%
  dplyr::select(-expr)-> immune_statistical
cnv%>%
  dplyr::mutate(cnv = purrr::map(cnv,.f=function(.x){
    ncol(.x)
  })) %>%
  tidyr::unnest() -> cnv_statistical
snv %>%
  dplyr::mutate(snv = purrr::map(sample_with_snv,.f=function(.x){
    length(.x)
  })) %>%
  dplyr::select(-sample_with_snv) %>%
  tidyr::unnest()-> snv_statistical
methy_data %>%
  dplyr::mutate(methy = purrr::map(methy,.f=function(.x){
    ncol(.x)
  })) %>%
  tidyr::unnest()-> methy_statistical

expr_statistical %>%
  dplyr::full_join(clinical_statistical, by="cancer_types") %>%
  dplyr::full_join(immune_statistical, by="cancer_types") %>%
  dplyr::full_join(cnv_statistical, by="cancer_types") %>%
  dplyr::full_join(snv_statistical, by="cancer_types") %>%
  dplyr::full_join(methy_statistical, by="cancer_types") -> statistical_data

statistical_data %>%
  jsonlite::toJSON(pretty = T, auto_unbox = T)

save.image(file.path("./data/rda/33-cancer-data-statictical.rda"))
