
# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)


# Arguments ---------------------------------------------------------------


args <- commandArgs(TRUE)

tableuuid <- args[1]
tablecol <- args[2]
filepath <- args[3]
apppath <- args[4]


# tableuuid <- 'e0a1b16f-eea4-4261-9e7f-4768f3281240'
# tablecol <- 'preanalysised_cnvgeneset'
# filepath <- "/home/huff/github/GSCA/gsca-r-plot/pngs/5b9339bf-b9a8-4fdb-8c7a-2fd535f841ee.png"
# apppath <- '/home/huff/github/GSCA'

# Mongo -------------------------------------------------------------------

source(file.path(apppath, "gsca-r-app/utils/fn_fetch_mongo_data.R"))
pre_gsva_coll <- mongolite::mongo(collection = tablecol, url = gsca_conf)
post_gsva_coll <- mongolite::mongo(collection = glue::glue("{tablecol}_immu"), url = gsca_conf)

# Function ----------------------------------------------------------------


fn_query_str <- function(.x) {
  .xx <- paste0(.x, collapse = '","')
  glue::glue('{"uuid": "<.xx>"}', .open = '<', .close = '>')
}

fn_fetch_data <- function(.uuid) {
  pre_gsva_coll$find(query = fn_query_str(.x = .uuid), fields = '{"_id": false}')
}

# Process -----------------------------------------------------------------

fetched_data <- fn_fetch_data(.uuid = tableuuid)$cnvgeneset[[1]]
if(ncol(fetched_data)>0){
  fetched_data %>% 
    tibble::as_tibble() %>% 
    tidyr::nest(-cancertype) -> gsva_score_nest
  
  fields <- '{"_id": false}'
  fetched_immu_data <- purrr::map(.x =paste(gsva_score_nest$cancertype,"all_immune",sep="_"), .f = fn_fetch_mongo_all, pattern="_all_immune",fields = fields) %>%
    dplyr::bind_rows() %>%
    dplyr::group_by(cancertype) %>%
    tidyr::nest() %>%
    dplyr::ungroup() %>%
    dplyr::rename("ImmuneCellAI"="data")
  
  # stage analysis -------------------------------------------------------
  gsva_score_nest %>%
    dplyr::inner_join(fetched_immu_data, by="cancertype") -> combine_data
  
  
  # function to get correlation ---------------------------------------------
  
  fn_gsva_immu_cor <- function(genesetcnv,data){
    
    data %>%
      dplyr::filter(substr(aliquot,14,14)=="0") %>%
      dplyr::select(-barcode)  -> .combined_immu
    
    genesetcnv %>%
      dplyr::inner_join(.combined_immu,by="sample_name") -> .combined_gsva_rppa
    
    .combined_gsva_rppa %>%
      dplyr::filter(group != "Excluded") %>%
      dplyr::filter(!is.na(TIL)) %>%
      dplyr::group_by(cell_type) %>%
      tidyr::nest() -> .combined_gsva_rppa_nested
    
    .combined_gsva_rppa_nested %>%
      dplyr::mutate(cor = purrr::map(data,.f=function(.x){
        if(length(unique(.x$group)) == 2){
          broom::tidy(wilcox.test(TIL~group,data=.x))
        }else if(length(unique(.x$group)) > 2){
          broom::tidy(oneway.test(TIL~group,data=.x))
        }else{
          tibble::tibble()
        }
      })) %>%
      dplyr::select(-data) %>%
      tidyr::unnest() %>%
      dplyr::ungroup() -> .cor_res
    
    
    
    .fdr <- p.adjust(.cor_res$p.value)
    
    .cor_res %>%
      dplyr::mutate(fdr = .fdr)
  }
  
  fn_gsva_immu_fc <- function(genesetcnv,data){
    data %>%
      dplyr::filter(substr(aliquot,14,14)=="0") %>%
      dplyr::select(-barcode)  -> .combined_immu
    
    genesetcnv %>%
      dplyr::inner_join(.combined_immu,by="sample_name") -> .combined_gsva_rppa
    
    .combined_gsva_rppa %>%
      dplyr::filter(group != "Excluded") %>%
      dplyr::filter(!is.na(TIL)) %>%
      dplyr::group_by(cell_type) %>%
      tidyr::nest() -> .combined_gsva_rppa_nested
    .f_fc <- function(.y, .com){
      if(length(unique(.y$group)) == 2){
        
        .y %>%
          dplyr::filter(group=="WT") %>%
          .$TIL %>%
          mean -> .wt
        .y %>%
          dplyr::filter(group!="WT") %>%
          .$TIL %>%
          mean -> .mut
        broom::tidy(wilcox.test(TIL~group,data=.y)) %>%
          dplyr::mutate(fc = .mut/.wt, compare = .com)
      }else{
        tibble::tibble()
      }
    }
    .combined_gsva_rppa_nested %>%
      dplyr::mutate(cor = purrr::map(data,.f=function(.x){
        .x %>%
          dplyr::filter(group %in% c("WT","Dele.")) -> dele_WT
        .x %>%
          dplyr::filter(group %in% c("WT","Amp.")) -> amp_WT
        
        .f_fc(dele_WT,"Dele. vs. WT") %>%
          rbind(.f_fc(amp_WT,"Amp. vs. WT"))
      })) %>%
      dplyr::select(-data) %>%
      tidyr::unnest() %>%
      dplyr::ungroup() -> .fc
    .fc
  }
  # calculation -------------------------------------------------------------
  suppressWarnings(
    combine_data %>%
      dplyr::mutate(res = purrr::map2(data,ImmuneCellAI,fn_gsva_immu_cor)) %>%
      dplyr::select(cancertype,res) %>%
      tidyr::unnest()  %>%
      dplyr::rename("celltype"="cell_type") -> gsva_score_rppa_test_res
  )
  gsva_score_rppa_test_res %>%
    dplyr::mutate(method_short=strsplit(method,split = " ")[[1]][1]) -> gsva_score_rppa_test_res
  
  suppressWarnings(
    combine_data %>%
      dplyr::mutate(res = purrr::map2(data,ImmuneCellAI,fn_gsva_immu_fc)) %>%
      dplyr::select(cancertype,res) %>%
      tidyr::unnest()  %>%
      dplyr::rename("celltype"="cell_type") -> gsva_score_rppa_test_fc
  )
  # Insert table ------------------------------------------------------------
  insert_data <- list(uuid = tableuuid, res_table = gsva_score_rppa_test_res)
  #post_gsva_coll$drop()
  uuid_query <- post_gsva_coll$find(
    query = fn_query_str(.x = tableuuid),
    fields = '{"uuid": true, "_id": false}'
  )
  
  if (nrow(uuid_query) == 0) {
    post_gsva_coll$insert(data = insert_data)
    post_gsva_coll$index(add = '{"uuid": 1}')
    message("insert data into preanalysised_cnvgeneset_immu")
  }
  
  # Plot --------------------------------------------------------------------
  gsva_score_rppa_test_fc %>%
    dplyr::mutate(label=ifelse(p.value<=0.05, "*","")) %>%
    dplyr::mutate(logP=-log10(p.value))-> gsva_score_rppa_test_res.label
  
  gsva_score_rppa_test_res.label %>%
    dplyr::filter(!is.na(logP)) %>%
    dplyr::mutate(celltypecor=ifelse(p.value<=0.05&fc>1,"Higher in CNV","Not significant")) %>%
    dplyr::mutate(celltypecor=ifelse(p.value<=0.05&fc<1,"Lower in CNV",celltypecor)) %>%
    dplyr::mutate(labelcor=ifelse(celltypecor=="Not significant",NA,celltypecor)) %>%
    ggplot(aes(x=log2(fc),y=logP)) +
    geom_point(aes(color=celltypecor)) +
    facet_grid(cancertype~compare, scale="free_y") +
    ggrepel::geom_text_repel(aes(label=celltype,color=labelcor)) +
    scale_color_manual(values = c("Higher in CNV"="#d0021b",
                                  "Not significant"="black",
                                  "Lower in CNV"="green"),
                       name="Significance") +
    theme(
      axis.text = element_text(colour = "black",size = 10),
      axis.title = element_text(size = 13),
      # legend.key.size = unit(0.25, "cm"),
      legend.position = "bottom",
      plot.margin = rep(unit(0, "null"), 4),
      axis.ticks.length = unit(0, "cm"),
      # legend.text = element_text(size = 5),
      # axis.title.x = element_text(size = 6),
      # axis.title.y = element_text(size = 6),
      # legend.title = element_text(size = 6),
      panel.background = element_rect(fill = "white", color = NA),
      panel.grid = element_line(colour = "grey", linetype = "dashed"),
      panel.grid.major = element_line(
        colour = "grey",
        linetype = "dashed",
        size = 0.2
      )
    ) +
    ylab("-log10 (P value)") +
    xlab("log2 fold change of immune cell abundance (CNV vs. WT)") + 
    geom_vline(xintercept = 0,col="grey",lwd=0.5) + 
    geom_hline(yintercept = 1.3,col="grey",lwd=0.5) -> plot
  # pic size ----------------------------------------------------------------
  
  source(file.path(apppath, "gsca-r-app/utils/fn_figure_height.R"))
  size_width <- 4+length(unique(gsva_score_rppa_test_res.label$cancertype))*0.5
  
  
  ggsave(filename = filepath, plot = plot, device = 'png', width = 8, height = size_width)
  pdf_name <- gsub("\\.png",".pdf", filepath)
  ggsave(filename = pdf_name, plot = plot, device = 'pdf', width = 8, height = size_width)
  
}else{
  source(file.path(apppath, "gsca-r-app/utils/fn_NA_notice_fig.R"))
  fn_NA_notice_fig("Caution: \nnot applicable for your search.\nPlease check if there are no CNVs\n in your search?") -> p
  # Save --------------------------------------------------------------------
  ggsave(filename = filepath, plot = p, device = 'png', width = 6, height = 4)
  pdf_name <- gsub("\\.png",".pdf",filepath)
  ggsave(filename = pdf_name, plot = p, device = 'pdf', width = 6, height = 4)
}


