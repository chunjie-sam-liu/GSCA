data_path <- "/home/huff/data/GSCA/for_download"

dirs <- list.files(data_path)

data_summary <- tibble::tibble()
for (dir in dirs) {
  files <- list.files(file.path(data_path,dir))
  tmp <- tibble::tibble(File_name=files) %>%
    dplyr::mutate(Cancer_type=purrr::map(File_name,.f=function(.x){
      if(dir=="snv"){
        strsplit(.x,"_")[[1]][1]
      }else{
        strsplit(.x,"\\.")[[1]][1]
      }
    })) %>%
    dplyr::mutate(Data_type=purrr::map(File_name,.f=function(.x){
      if(dir=="snv"){
        "snv"
      }else{
        strsplit(.x,"\\.")[[1]][2]
      }
    })) %>%
    tidyr::unnest()
  rbind(data_summary,tmp)->data_summary
}


# sample count
datacount <- readr::read_tsv(file.path("/home/huff/data/GSCA","pancan33_alldatatype_sample_counts.tsv"))

datacount %>%
  tidyr::gather(-cancer_types,key="Data_type",value="Sample_size") -> datacount.gather

datacount.gather$Data_type %>% unique()

datacount.gather %>%
  dplyr::filter(Data_type %in% c("clinical_stage","igcccg_stage","masaoka_stage","pathologic_stage")) %>%
  dplyr::mutate(Sample_size=paste(Data_type,":",Sample_size,sep="")) %>%
  dplyr::mutate(Data_type="stage") %>%
  dplyr::group_by(cancer_types,Data_type) %>%
  tidyr::nest() %>%
  dplyr::mutate(Sample_size=purrr::map(data,.f=function(.x){
    paste0(.x$Sample_size,collapse = "; ")
  })) %>%
  dplyr::select(-data) %>%
  tidyr::unnest() -> Stage_count

datacount.gather %>%
  dplyr::filter(Data_type %in% c("DFI","DSS","OS","PFS")) %>%
  dplyr::mutate(Sample_size=paste(Data_type,":",Sample_size,sep="")) %>%
  dplyr::mutate(Data_type="survival") %>%
  dplyr::group_by(cancer_types,Data_type) %>%
  tidyr::nest() %>%
  dplyr::mutate(Sample_size=purrr::map(data,.f=function(.x){
    paste0(.x$Sample_size,collapse = "; ")
  })) %>%
  dplyr::select(-data) %>%
  tidyr::unnest() -> Survival_count

rppa_score <- readr::read_rds(file.path("/home/huff/data/GSCA","rppa/pancan32_rppa_score.rds.gz"))
rppa_score %>%
  dplyr::mutate(Sample_size=purrr::map(rppa,.f=function(.x){
    .x$barcode %>% unique() %>% length()
  })) %>%
  dplyr::select(-rppa) %>%
  tidyr::unnest() %>%
  dplyr::mutate(Data_type="PAS") -> rppa.count

datacount.gather %>% 
  dplyr::filter(Data_type %in% c("cnv","expr","immune","methy","snv","subtype")) %>%
  dplyr::mutate(Data_type=ifelse(Data_type=="expr","mRAN_expr",Data_type)) %>%
  dplyr::mutate(Data_type=ifelse(Data_type=="immune","ImmuneCellAI",Data_type)) %>%
  rbind(Stage_count) %>%
  rbind(Survival_count)%>%
  rbind(rppa.count) -> datacount.all

#  combine data count and info
datacount.all %>%
  dplyr::rename("Cancer_type"="cancer_types") %>%
  dplyr::inner_join(data_summary,by=c("Cancer_type","Data_type")) -> combine

# json
combine %>%
  dplyr::mutate(download="Download") %>%
  dplyr::group_by(Data_type) %>%
  tidyr::nest() %>%
  dplyr::mutate(json=purrr::map2(data,Data_type,.f=function(.x,.y){
    .x %>%
      jsonlite::toJSON(pretty = T, auto_unbox = T) %>%
      readr::write_file(file.path("/home/huff/data/GSCA/for_download.json",paste(.y,"json.txt",sep="_")))
  }))
  
