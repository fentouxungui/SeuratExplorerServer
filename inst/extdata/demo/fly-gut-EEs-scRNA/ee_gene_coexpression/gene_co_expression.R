library(Seurat)
cds <- readRDS("../../ee_seurat2_yangfu/G101_PC20res04.rds")

peptides_gene <- c("Tk","Dh31","NPF","Nplp2","Mip","Gpb5","CCAP","ITP","sNPF","CCHa2","AstA","CCHa1","CG13565","AstC")


total_TF <- read.delim("../ee_extract_TF_from_cluster_markers/all_candidates TFs.csv",stringsAsFactors = F)
head(total_TF)
TF <- total_TF$symbol
head(TF)  
TF <- TF[TF %in% rownames(cds@data)]

gene_list <- append(TF,peptides_gene)
head(gene_list)


cor.total_genes <- cor(t(as.matrix(cds@data)[gene_list,]))
head(cor.total_genes)
write.csv(cor.total_genes,"correlation_of_total_TFs_and_14_peptides.csv")

#matrix<-cds@data
#matrix_mod<-as.matrix(matrix)
#gene<-as.numeric(matrix_mod[gene,])
#correlations<-apply(matrix_mod,1,function(x){cor(gene,x)})
#correlations[abs(correlations) > 0.6]

chosen_TF <- c("pros","Fer1","sug","h","luna","drm","mamo","exex","mirr","emc","esg","tap","Ptx1")
gene_list_2 <- append(chosen_TF,peptides_gene)
cor.total_genes <- cor(t(as.matrix(cds@data)[gene_list_2,]))
head(cor.total_genes)
write.csv(cor.total_genes,"correlation_of_13_TFs_and_14_peptides.csv")

library(corrgram)
data <- as.matrix(t(cds@data[gene_list_2,]))
head(data)
corrgram(data, order=TRUE,
         main="correlation of chosen genes",
         lower.panel=panel.shade, upper.panel=panel.pie,
         diag.panel=panel.minmax, text.panel=panel.txt)
corrgram(data, order=TRUE,
         upper.panel=panel.cor, main="vote")
