
library(survival)
library(dplyr)
library(ggplot2)

# expr group --------------------------------------------------------------

expr_group <- tibble::tibble(group=c("median","up_quantile","low_quantile"),
                             cutoff = c(0.5,0.75,0.25))


# survival type -----------------------------------------------------------

survival_group <- tibble::tibble(type=c("OS","PFS","os","pfs"),
                                 time=c("os_days","pfs_days","os_days","pfs_days"),
                                 status=c("os_status","pfs_status","os_status","pfs_status"))

# function to draw survival plot ------------------------------------------

library(survminer)
fn_survival <- function(data,title,color,logrankp=NA){
  if(is.na(logrankp)){
    data %>% 
      dplyr::filter(!is.na(time)) %>%
      dplyr::filter(!is.na(status)) %>%
      dplyr::filter(!is.na(group)) %>%
      dplyr::group_by(group) %>%
      dplyr::mutate(n=dplyr::n()) %>%
      dplyr::select(group,n) %>%
      dplyr::ungroup() %>%
      dplyr::filter(n>5) %>%
      .$group %>% unique() %>% length() -> len_group
    if(!is.na(len_group)){
      logrankp <- tryCatch(
        1 - pchisq(survival::survdiff(survival::Surv(time, status) ~ group, data = data, na.action = na.exclude)$chisq, df = len_group - 1),
        error = function(e) {1}
      )
    }else{
      logrankp<-1
    }
  } else {
    logrankp<-logrankp
  }
  fit <- survfit(survival::Surv(time, status) ~ group, data = data, na.action = na.exclude)
  x_lable <- max(data$time)/4
  color %>%
    dplyr::inner_join(data,by="group") %>%
    dplyr::group_by(group) %>%
    dplyr::mutate(n = n()) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(group_label = paste(group,", n=",n,sep="")) %>%
    dplyr::select(group,group_label,color) %>%
    unique() %>%
    dplyr::arrange(group) -> color_paired
  survminer::ggsurvplot(fit,pval=F, #pval.method = T,
                        data = data,
                        surv.median.line = "hv",
                        title = paste(title), # change it when doing diff data
                        ylab = 'Probability of survival',
                        xlab = 'Time (days)',
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
             label = paste("Log rank P =", round(logrankp,2))) +
    scale_color_manual(
      values = color_paired$color,
      labels = color_paired$group_label
    ) -> p
  return(p)
}
