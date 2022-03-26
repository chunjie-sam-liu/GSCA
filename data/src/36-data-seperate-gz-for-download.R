# expression seperate

data_path <- "/home/huff/data/GSCA"
gsca_path <- file.path("/home/huff/data/GSCA")

expr <- readr::read_rds(file.path(data_path,"expr","pancan33_expr.IdTrans.rds.gz"))


expr %>%
  dplyr::mutate(seperate=purrr::map2(cancer_types,expr,.f=function(.x,.y){
    .y %>%
      dplyr::mutate(cancer_type=.x) %>%
      dplyr::select(cancer_type,matches(".")) %>%
      readr::write_tsv(file.path(data_path,"expr","download",paste(.x,"mRAN_expr.tsv",sep=".")))
  })) 

# survival data
survival_os <- readr::read_rds("/home/huff/project/TCGA_survival/data/Pancan.Merge.clinical-OS-Age-stage.rds.gz") %>%
  dplyr::rename("os"="clinical_data")
survival_pfs <- readr::read_rds("/home/huff/project/data/TCGA-survival-time/cell.2018.survival/TCGA_pancan_cancer_cell_survival_time.rds.gz") %>%
  dplyr::rename("cancer_types"="type","pfs"="data")

survival_os %>%
  dplyr::inner_join(survival_pfs,by="cancer_types") %>%
  dplyr::mutate(combine=purrr::map2(os,pfs,.f=function(.x,.y){
    .y %>%
      dplyr::rename("barcode"="bcr_patient_barcode","pfs_status"="PFS","pfs_days"="PFS.time") %>%
      dplyr::select(barcode,pfs_status,pfs_days) %>%
      dplyr::full_join(.x,by="barcode") %>%
      dplyr::mutate(os_days=as.numeric(OS), os_status=as.numeric(Status)) %>%
      dplyr::select(sample_name = barcode,os_days, os_status,pfs_status,pfs_days)
  })) %>%
  dplyr::select(cancer_types,combine) -> survival_os_pfs

survival_dss_dfi <- readr::read_rds(file.path(data_path,"clinical","pancan33_DSS-DFI_survival.rds.gz"))

survival_os_pfs %>%
  dplyr::inner_join(survival_dss_dfi,by="cancer_types") %>%
  dplyr::mutate(all=purrr::map2(combine,survival,.f=function(.x,.y){
    .x %>%
      dplyr::full_join(.y,by="sample_name")
  })) %>%
  dplyr::mutate(seperate=purrr::map2(cancer_types,all,.f=function(.x,.y){
    .y %>%
      dplyr::mutate(cancer_type=.x) %>%
      dplyr::select(cancer_type,matches(".")) %>%
      readr::write_tsv(file.path(data_path,"clinical","download",paste(.x,"survival.tsv",sep=".")))
  })) 

# subtype data
clinical <- readr::read_rds(file.path(data_path,"clinical","pancan34_clinical_stage_survival_subtype.rds.gz"))

clinical %>%
  dplyr::filter(n.x>0) %>%
  dplyr::select(cancer_types,subtype) %>%
  dplyr::mutate(seperate=purrr::map2(cancer_types,subtype,.f=function(.x,.y){
    .y %>%
      dplyr::mutate(cancer_type=.x) %>%
      dplyr::select(cancer_type,matches(".")) %>%
      readr::write_tsv(file.path(data_path,"clinical","download",paste(.x,"subtype.tsv",sep=".")))
  })) 

# stage data
stage <- readr::read_rds(file.path(gsca_path,"clinical","Pancan.Merge.clinical-STAGE.rds.gz")) 

stage %>%
  dplyr::mutate(seperate=purrr::map2(cancer_types,stage,.f=function(.x,.y){
    .y %>%
      dplyr::mutate(cancer_type=.x) %>%
      dplyr::select(cancer_type,matches(".")) %>%
      readr::write_tsv(file.path(data_path,"clinical","download","stage",paste(.x,"stage.tsv",sep=".")))
  })) 

# cnv
cnv <- readr::read_rds(file.path(data_path,"cnv","pancan34_cnv_threshold.IdTrans.rds.gz"))

cnv%>%
  dplyr::mutate(seperate=purrr::map2(cancer_types,cnv,.f=function(.x,.y){
    .y %>%
      dplyr::mutate(cancer_type=.x) %>%
      dplyr::select(cancer_type,matches(".")) %>%
      readr::write_tsv(file.path(data_path,"for_download","cnv",paste(.x,"cnv.tsv",sep=".")))
  })) 

# methylation
methy <- readr::read_rds(file.path(data_path,"methy","pancan33_meth.IdTrans.rds.gz"))

methy %>%
  dplyr::mutate(seperate=purrr::map2(cancer_types,methy,.f=function(.x,.y){
    .y %>%
      dplyr::mutate(cancer_type=.x) %>%
      dplyr::select(cancer_type,matches(".")) %>%
      readr::write_tsv(file.path(data_path,"for_download","methy",paste(.x,"methy.tsv",sep=".")))
  })) 

# immune
immune_cell_data <- readr::read_rds(file.path(data_path,"TIL","pan33_ImmuneCellAI.rds.gz"))

immune_cell_data %>%
  dplyr::mutate(seperate=purrr::map2(cancer_types,ImmuneCellAI,.f=function(.x,.y){
    .y %>%
      dplyr::mutate(cancer_type=.x) %>%
      dplyr::select(cancer_type,matches(".")) %>%
      readr::write_tsv(file.path(data_path,"for_download","TIL",paste(.x,"ImmuneCellAI.tsv",sep=".")))
  })) 

# rppa
rppa_score <- readr::read_rds(file.path(data_path,"rppa/pancan32_rppa_score.rds.gz"))

rppa_score %>%
  dplyr::mutate(seperate=purrr::map2(cancer_types,rppa,.f=function(.x,.y){
    .y %>%
      dplyr::mutate(cancer_type=.x) %>%
      dplyr::select(cancer_type,matches(".")) %>%
      readr::write_tsv(file.path(data_path,"for_download","pathwayactivity",paste(.x,"PAS.tsv",sep=".")))
  })) 
