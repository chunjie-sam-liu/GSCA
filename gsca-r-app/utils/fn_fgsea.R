library(fgsea)

library(data.table)
library(ggplot2)

data(examplePathways)
data(exampleRanks)
set.seed(42)

fgseaRes <- fgsea(pathways = examplePathways, 
                  stats    = exampleRanks,
                  minSize  = 15,
                  maxSize  = 500,
                  eps=0)

head(fgseaRes[order(pval), ])

plotEnrichment(examplePathways[["5991130_Programmed_Cell_Death"]],
               exampleRanks) + labs(title="Programmed Cell Death")


topPathwaysUp <- fgseaRes[ES > 0][head(order(pval), n=10), pathway]
topPathwaysDown <- fgseaRes[ES < 0][head(order(pval), n=10), pathway]
topPathways <- c(topPathwaysUp, rev(topPathwaysDown))
plotGseaTable(examplePathways[topPathways], exampleRanks, fgseaRes, 
              gseaParam=0.5)

pathways <- reactomePathways(names(exampleRanks))
fgseaRes <- fgsea(pathways, exampleRanks, maxSize=500)
head(fgseaRes)