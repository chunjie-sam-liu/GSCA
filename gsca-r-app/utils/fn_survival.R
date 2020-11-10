
library(survival)
library(dplyr)

# expr group --------------------------------------------------------------

expr_group <- tibble::tibble(group=c("median","up_quantile","low_quantile"),
                             cutoff = c(0.5,0.75,0.25))


# survival type -----------------------------------------------------------

survival_group <- tibble::tibble(type=c("os","pfs"),
                                 time=c("os_days","pfs_days"),
                                 status=c("os_status","pfs_status"))

# function to draw survival plot ------------------------------------------

fn_survival <- function(data,title,color){
  library(survival)
  library(survminer)
  fit <- survfit(survival::Surv(time, status) ~ group, data = data, na.action = na.exclude)
  diff <- survdiff(survival::Surv(time, status) ~ group, data = data, na.action = na.exclude)
  kmp <- 1 - pchisq(diff$chisq, df = length(levels(as.factor(data$group))) - 1)
  # legend <- data.frame(group=paste("C",sort(unique(data$group)),sep=""),n=fit$n)
  # legend %>%
  #   dplyr::mutate(
  #     label = purrr::map2(
  #       .x = group,
  #       .y = n,
  #       .f = function(.x,.y){
  #         latex2exp::TeX(glue::glue("<<.x>>, n = <<.y>>", .open = "<<", .close = ">>"))
  #       }
  #     )
  #   ) -> legend
  color %>%
    dplyr::inner_join(data,by="group") %>%
    dplyr::group_by(group) %>%
    dplyr::mutate(n = n()) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(group = paste(group,", n=",n,sep="")) %>%
    dplyr::select(group,color) %>%
    unique() -> color_paired
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
    scale_color_manual(
      values = color_paired$color,
      labels = color_paired$group
    ) -> p
  return(p)
}
