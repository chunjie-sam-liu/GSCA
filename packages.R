pkgs <- c(
  "ggplot2",
  "tidyverse",
  "mongolite",
  "fgsea",
  "trend",
  "ggpubr",
  "survminer",
  "maftools",
  "plyr",
  "ggthemes",
  "clusterProfiler"
)

install.packages('BiocManager')

pkgs <- unique(pkgs)
ap.db <- available.packages(contrib.url(BiocManager::repositories()))
ap <- rownames(ap.db)
pkgs_to_install <- pkgs[pkgs %in% ap]

BiocManager::install(pkgs_to_install, update=FALSE, ask=FALSE)
# From github

suppressWarnings(BiocManager::install(update=TRUE, ask=FALSE))
# Remove tmp directory

# just in case there were warnings, we want to see them
# without having to scroll up:
warnings()

if (!is.null(warnings()))
{
  w <- capture.output(warnings())
  if (length(grep("is not available|had non-zero exit status", w))) quit(save="no", status=0L, runLast = FALSE)
}