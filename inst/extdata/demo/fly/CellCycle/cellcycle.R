library(Seurat)
cds <- readRDS("../../ee_seurat2_By_yangfu/G101_PC20res04.rds")
cds <- UpdateSeuratObject(cds)
DimPlot(cds,label = TRUE)

s.list <- read.delim("mitotic-DNA-replication-during-S-phase.txt",stringsAsFactors = FALSE)
s.genes <- rownames(cds)[rownames(cds) %in% s.list$SYMBOL | rownames(cds) %in% s.list$ANNOTATION_SYMBOL]
s.genes

g2m.list <- read.delim("G22M-transition-of-mitotic-cell-cycle.txt",stringsAsFactors = FALSE)
g2m.genes <- rownames(cds)[rownames(cds) %in% g2m.list$ANNOTATION_SYMBOL | rownames(cds) %in% g2m.list$SYMBOL ]
g2m.genes 


## remove genes with low counts may contribute to the performance: Filter had bad effects!
# markers <- c(s.genes,g2m.genes)
# pdf(file = "counts.info.pdf")
# for (marker in markers) {
#   hist(cds@assays$RNA@counts[marker,],breaks = 100,main = NULL,xlab = paste("Raw counts value of",marker,sep = " "))
# }
# dev.off()
# 
# countsinfos <- data.frame(marker = character(0),TotalCounts = numeric(0),NonZeroCells = numeric(0),
#                           NonZeroCellsPCT = numeric(0),NonZeroCellsMean = numeric(0))
# for (marker in markers) {
#   markerCounts <- cds@assays$RNA@counts[marker,]
#   countsSum <- sum(markerCounts)
#   NonZero <- sum(markerCounts > 0)
#   NonZeroPCT <- NonZero/length(names(markerCounts))
#   NonZeroMean <- countsSum/NonZero
#   tmp <- data.frame(marker = as.character(marker),TotalCounts = as.numeric(countsSum),NonZeroCells = as.numeric(NonZero),
#                     NonZeroCellsPCT = as.numeric(NonZeroPCT),NonZeroCellsMean = as.numeric(NonZeroMean),stringsAsFactors = F)
#   countsinfos <- rbind(countsinfos,tmp)
# }
# library(DT)
# datatable(countsinfos)
# markers.filtered <- countsinfos[countsinfos$TotalCounts > 50,]$marker
# s.genes <- s.genes[s.genes %in% markers.filtered]
# g2m.genes <- g2m.genes[g2m.genes %in% markers.filtered]
# s.genes
# g2m.genes

cds <- CellCycleScoring(cds, s.features = s.genes, g2m.features = g2m.genes, set.ident = TRUE)
DimPlot(cds)
table(cds@meta.data$res.0.4,cds@meta.data$Phase)

#cds <- RunTSNE(cds, features = c(s.genes, g2m.genes))
DimPlot(cds,reduction = "umap")

write.csv(table(cds@meta.data$seurat_clusters,cds@meta.data$Phase),file = "cellcycle-counts-in-each-cluster.csv")

head(cds@meta.data)

library(dplyr)
pdf(file = "statics-of-score.pdf",width = 4,height = 22)
par(mfrow=c(11,2))
meta.info <- as.data.frame(cds@meta.data)
for (cluster in unique(meta.info$res.0.4)) {
  data.ex <- filter(meta.info, res.0.4 == cluster)
  print(hist(data.ex$S.Score,breaks =  seq(-0.3,0.7,by=0.01),main = cluster))
  print(hist(data.ex$G2M.Score, breaks =  seq(-0.3,0.7,by=0.01),main = cluster))
}
dev.off()



# correlation between these markers
markers <- c(s.genes,g2m.genes)
data <- as.matrix(cds@assays$RNA@data[markers,])
data[1:5,1:5]
library(corrgram)
corrgram(data, order=FALSE,
         main="correlation of chosen genes",
         lower.panel=panel.shade, upper.panel=panel.pie,
         diag.panel=panel.minmax, text.panel=panel.txt)
corrgram(data, order=TRUE,
         upper.panel=panel.cor, main="vote")