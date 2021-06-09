datapath <- "/home/huff/data/GSCA"


# clinical ----------------------------------------------------------------

clinical <- readr::read_rds(file.path(datapath,"clinical","pancan34_clinical_stage_survival_subtype.rds.gz"))
clinical %>%
  dplyr::select(cancer_types,subtype=n.x, survival= n.y, stage=n)-> clinical_statistical


# mRNA expre AND Immune--------------------------------------------------------------
all_expr <- readr::read_rds(file.path(datapath,"expr","pancan33_expr.IdTrans.rds.gz"))

all_expr %>%
  dplyr::mutate(expr = purrr::map(expr,.f=function(.x){
    ncol(.x)-2
  })) %>%
  tidyr::unnest() -> expr_statistical
expr_statistical %>%
  dplyr::mutate(immune=expr) %>%
  dplyr::select(-expr)-> immune_statistical


# cnv ---------------------------------------------------------------------

cnv <- readr::read_rds(file.path(datapath,"cnv","pancan34_cnv_threshold.IdTrans.rds.gz"))

cnv%>%
  dplyr::mutate(cnv = purrr::map(cnv,.f=function(.x){
    ncol(.x)-2
  })) %>%
  tidyr::unnest() -> cnv_statistical


# snv ---------------------------------------------------------------------

snv <- readr::read_rds(file.path(datapath,"TIL","pancan33_sample_with_snv.rds.gz"))
sample_with_snv <- readr::read_rds(file.path(data_path,"pancan33_sample_with_snv.rds.gz"))

snv %>%
  dplyr::mutate(snv = purrr::map(sample_with_snv,.f=function(.x){
    length(.x)
  })) %>%
  dplyr::select(-sample_with_snv) %>%
  tidyr::unnest()-> snv_statistical


# methylation -------------------------------------------------------------

methy_data <- readr::read_rds(file.path(datapath,"methy","pancan33_meth.IdTrans.rds.gz"))
methy_data %>%
  dplyr::mutate(methy = purrr::map(methy,.f=function(.x){
    ncol(.x)-3
  })) %>%
  tidyr::unnest()-> methy_statistical


# combine -----------------------------------------------------------------


expr_statistical %>%
  dplyr::full_join(clinical_statistical, by="cancer_types") %>%
  dplyr::full_join(immune_statistical, by="cancer_types") %>%
  dplyr::full_join(cnv_statistical, by="cancer_types") %>%
  dplyr::full_join(snv_statistical, by="cancer_types") %>%
  dplyr::full_join(methy_statistical, by="cancer_types") %>%
  tidyr::gather(-cancer_types,key="class",value="value") %>%
  dplyr::mutate(value=ifelse(is.na(value),"--",value)) %>%
  tidyr::spread(key="class",value="value")-> statistical_data

statistical_data %>%
  readr::write_tsv(file.path(datapath,"pancan33_alldatatype_sample_counts.tsv"))

# json --------------------------------------------------------------------

statistical_data %>%
  jsonlite::toJSON(pretty = T, auto_unbox = T)

# overlapping -------------------------------------------------------------
clinical %>%
  dplyr::inner_join(all_expr, by="cancer_types") -> clinical_exp

clinical_exp %>%
  dplyr::mutate(subtype_exp = purrr::map2(subtype,expr,.f=function(.x,.y){
    tibble::tibble(samplename=colnames(.y))%>%
      dplyr::filter(substr(samplename,14,14)==0) %>%
      dplyr::mutate(barcode=substr(samplename,1,12)) %>%
      dplyr::inner_join(.x,by="barcode") %>%
      .$subtype %>% table() %>% as_data_frame()
  })) %>%
  dplyr::select(cancer_types,subtype_exp) %>%
  tidyr::unnest()

# save image --------------------------------------------------------------


save.image(file.path(datapath,"33-cancer-data-statictical.rda"))
