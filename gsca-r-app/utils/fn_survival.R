
library(survival)
library(dplyr)
library(ggplot2)

# expr group --------------------------------------------------------------

expr_group <- tibble::tibble(group=c("median","up_quantile","low_quantile"),
                             cutoff = c(0.5,0.75,0.25))


# survival type -----------------------------------------------------------

survival_group <- tibble::tibble(type=c("OS","PFS","os","pfs","DSS","DFI","dss","dfi"),
                                 time=c("os_months","pfs_months","os_months","pfs_months","dss_months","dfi_months","dss_months","dfi_months"),
                                 status=c("os_status","pfs_status","os_status","pfs_status","dss_status","dfi_status","dss_status","dfi_status"))

# function to draw survival plot ------------------------------------------

library(survminer)
fn_survival <- function(data,title,color,logrankp=NA,ylab){
  data %>% 
    dplyr::filter(!is.na(time)) %>%
    dplyr::filter(!is.na(status)) %>%
    dplyr::filter(!is.na(group)) %>%
    dplyr::filter(!is.na(methy)) %>%
    dplyr::mutate(status=as.numeric(status),time=as.numeric(time)) %>%
    dplyr::filter(status %in% c(0,1)) %>%
    dplyr::filter(!is.na(group)) -> .data_f
  .data_f %>%
    dplyr::group_by(group) %>%
    dplyr::mutate(n=dplyr::n()) %>%
    dplyr::select(group,n) %>%
    dplyr::ungroup() %>%
    dplyr::filter(n>2) %>%
    .$group %>% unique() -> .group
  .group %>% length() -> len_group
  .data_f %>%
    dplyr::filter(group %in% .group) -> .data_f
  if(is.na(logrankp)){
    if(!is.na(len_group)){
      logrankp <- tryCatch(
        1 - pchisq(survival::survdiff(survival::Surv(time, status) ~ group, data = .data_f, na.action = na.exclude)$chisq, df = len_group - 1),
        error = function(e) {1}
      )
    }else{
      logrankp<-1
    }
  } else {
    logrankp<-logrankp
  }
  fit <- survfit(survival::Surv(time, status) ~ group, data = .data_f, na.action = na.exclude)
  x_lable <- max(.data_f$time)/4
  color %>%
    dplyr::inner_join(.data_f,by="group") %>%
    dplyr::group_by(group) %>%
    dplyr::mutate(n = n()) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(group_label = paste(group,", n=",n,sep="")) %>%
    dplyr::select(group,group_label,color) %>%
    unique() %>%
    dplyr::arrange(group) -> color_paired
  survminer::ggsurvplot(fit,pval=F, #pval.method = T,
                        data = .data_f,
                        surv.median.line = "hv",
                        title = paste(title), # change it when doing diff data
                        ylab = ylab,
                        xlab = 'Time (month)',
                        legend = "right",
                        # legend.title = "Methyla group:",
                        # ggtheme = theme_survminer(),
                        ggtheme = theme(
                          panel.border = element_blank(), panel.grid.major = element_blank(), 
                          panel.grid.minor = element_blank(), axis.line = element_line(colour = "black", 
                                                                                       size = 0.5), 
                          panel.background = element_rect(fill = "white"),
                          legend.key = element_blank(),
                          legend.background = element_blank(),
                          legend.text = element_text(size = 8),
                          axis.text = element_text(size = 12,color = "black"),
                          legend.title = element_blank(),
                          axis.title = element_text(size = 12,color = "black"),
                          text = element_text(color = "black")
                        )
  )[[1]] +
    annotate("text", 
             x = x_lable, y = 0.2, # x and y coordinates of the text
             label = paste("Logrank P value =", signif(logrankp,2))) +
    scale_color_manual(
      values = color_paired$color,
      labels = color_paired$group_label
    ) -> p
  return(p)
}
