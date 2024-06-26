library(Seurat)
cds <- readRDS("../ee_seurat2_yangfu/G101_PC20res04.rds")
cds <- SubsetData(cds,ident.use = c(1,4,3))
cds

cds <- NormalizeData(cds)
cds <- ScaleData(cds, vars.to.regress = c("nUMI", "percent.mito"))
cds <- FindVariableGenes(cds)
length(x = cds@var.genes)
write.csv(cds@var.genes,file = "var.genes.csv")
cds <- RunDiffusion(cds,genes.use = cds@var.genes)
DMPlot(cds)
pdf(file = "diffusionmap_by_seurat2_using_var.genes.pdf")
DMPlot(cds)
dev.off()



cds <- RunPCA(object = cds, pc.genes = cds@var.genes, do.print = TRUE, pcs.print = 1:5, 
               genes.print = 5)
PCAPlot(object = cds, dim.1 = 1, dim.2 = 2)
cds <- JackStraw(object = cds, num.replicate = 100, display.progress = FALSE)
JackStrawPlot(object = cds, PCs = 1:15)
PCElbowPlot(object = cds)
cds <- RunDiffusion(cds,dims.use = 1:15)
DMPlot(cds)
pdf(file = "diffusionmap_by_seurat2_using_dims1-15.pdf")
DMPlot(cds)
dev.off()



