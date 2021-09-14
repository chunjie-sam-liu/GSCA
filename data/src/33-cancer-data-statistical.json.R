datapath <- "/home/huff/data/GSCA"


# clinical ----------------------------------------------------------------

clinical <- readr::read_rds(file.path(datapath,"clinical","pancan34_clinical_stage_survival_subtype.rds.gz"))

stage <- readr::read_rds(file.path(datapath,"clinical","Pancan.Merge.clinical-STAGE.rds.gz")) %>%
  dplyr::mutate(stage = purrr::map(stage, .f=function(.x){
    .x %>%
      dplyr::mutate(sample_name=toupper(barcode)) %>%
      dplyr::select(-barcode) %>%
      tidyr::gather(-sample_name,key="stage_type",value="stage")
  }))

survival <- readr::read_rds(file.path(datapath,"clinical","pancan33_survival_NEW.rds.gz"))

clinical %>%
  dplyr::select(cancer_types,subtype=n.x)-> subtype_statistical

stage %>%
  dplyr::mutate(count= purrr::map(stage,.f=function(.x){
    .x %>%
      dplyr::filter(!is.na(stage)) %>%
      dplyr::group_by(stage_type) %>%
      dplyr::mutate(stage=dplyr::n()) %>%
      dplyr::select(stage_type,stage) %>%
      unique()
  })) %>%
  dplyr::select(-stage) %>%
  tidyr::unnest() %>%
  dplyr::filter(stage_type %in% c("clinical_stage","igcccg_stage" ,"masaoka_stage","pathologic_stage")) %>%
  tidyr::spread(key=stage_type,value=stage) -> stage_statistical

survival %>%
  dplyr::mutate(count= purrr::map(combine,.f=function(.x){
    .x %>%
      dplyr::select(pfs_status, pfs_days) %>%
      dplyr::filter(!is.na(pfs_status) & !is.na(pfs_days)) %>%
      nrow() -> .n_pfs
    .x %>%
      dplyr::select(os_days, os_status) %>%
      dplyr::filter(!is.na(os_days) & !is.na(os_status)) %>%
      nrow() -> .n_os
    tibble::tibble(PFS=.n_pfs,OS=.n_os)
  })) %>%
  dplyr::select(-combine) %>%
  tidyr::unnest()  -> survival_statistical

# mRNA expre AND Immune--------------------------------------------------------------
all_expr <- readr::read_rds(file.path(datapath,"expr","pancan33_expr.IdTrans.rds.gz"))

all_expr %>%
  dplyr::mutate(expr = purrr::map(expr,.f=function(.x){
    ncol(.x)-2
  })) %>%
  tidyr::unnest() -> expr_statistical

all_immune <- readr::read_rds(file.path(datapath,"TIL","pan33_ImmuneCellAI.rds.gz"))

all_immune %>%
  dplyr::mutate(immune=purrr::map(ImmuneCellAI,.f=function(.x){
    nrow(.x)
  })) %>%
  dplyr::select(-ImmuneCellAI) %>%
  tidyr::unnest()-> immune_statistical


# cnv ---------------------------------------------------------------------

cnv <- readr::read_rds(file.path(datapath,"cnv","pancan34_cnv_threshold.IdTrans.rds.gz"))

cnv%>%
  dplyr::mutate(cnv = purrr::map(cnv,.f=function(.x){
    ncol(.x)-2
  })) %>%
  tidyr::unnest() -> cnv_statistical


# snv ---------------------------------------------------------------------

snv <- readr::read_rds(file.path(datapath,"TIL","pancan33_sample_with_snv.rds.gz"))
sample_with_snv <- readr::read_rds(file.path(datapath,"pancan33_sample_with_snv.rds.gz"))

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
  dplyr::full_join(subtype_statistical, by="cancer_types") %>%
  dplyr::full_join(stage_statistical, by="cancer_types") %>%
  dplyr::full_join(survival_statistical, by="cancer_types") %>%
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
