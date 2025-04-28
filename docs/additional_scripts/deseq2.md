# SARTools DESeq2
SARTools is a wrapper script that performs DESeq2 analysis on RNASeq read counts. There is also an [EdgeR](https://github.com/PF2-pasteur-fr/SARTools) script available.

## variables
These variables are mostly self expanded
```
rm(list=ls())                                        # remove all the objects from the R session
workDir <- "counts"                                  # working directory for the R session
projectName <- "RNA Experiment"                      # name of the project
author <- "Iain Perry"                               #  author of the statistical analysis/report
targetFile <- "counts/metadata.txt"                  # path to the design/target file
rawDir <- "counts"                                   # path to the directory containing raw counts files
featuresToRemove <- c("alignment_not_unique", "ambiguous", "no_feature", "not_aligned", "too_low_aQual") # names of the features to be removed NULL if no feature to remove
varInt <- "Condition"                                # factor of interest
condRef <- "WildType"                                # reference biological condition
batch <- "Individual"                                # blocking factor: NULL (default) or "batch" for example
fitType <- "parametric"                              # mean-variance relationship: "parametric" (default), "local" or "mean"
cooksCutoff <- TRUE                                  # TRUE/FALSE to perform the outliers detection (default is TRUE)
independentFiltering <- TRUE                         # TRUE/FALSE to perform independent filtering (default is TRUE)
alpha <- 0.05                                        # threshold of statistical significance
pAdjustMethod <- "BH"                                # p-value adjustment method: "BH" (default) or "BY"
typeTrans <- "VST"                                   # transformation for PCA/clustering: "VST" or "rlog"
locfunc <- "median"                                  # "median" (default) or "shorth" to estimate the size factors
colors <- c("#f3c300", "#875692", "#f38400", "#a1caf1", "#be0032", "#c2b280", "#848482", "#008856", "#e68fac", "#0067a5", "#f99379", "#604e97") # vector of colors of each biological condition on the plots
forceCairoGraph <- FALSE
IDtoGene <- read.delim("GRCh38gencodeV39-202201/gencode.v39.primary_assembly.annotation.txt", header=TRUE)  # *** BESPOKE For using common gene names
```
If you haven't already installed it locally to R then run the below
```
install.packages("devtools") 
devtools::install_github("PF2-pasteur-fr/SARTools", build_opts="--no-resave-data")
```
## Main script
Set the working direcotry and load the package
```
setwd(workDir)
library(SARTools)
if (forceCairoGraph) options(bitmapType="cairo")
```
### checking parameters
This is a step to make sure all parameters are set
```
checkParameters.DESeq2(projectName=projectName,author=author,targetFile=targetFile,
                       rawDir=rawDir,featuresToRemove=featuresToRemove,varInt=varInt,
                       condRef=condRef,batch=batch,fitType=fitType,cooksCutoff=cooksCutoff,
                       independentFiltering=independentFiltering,alpha=alpha,pAdjustMethod=pAdjustMethod,
                       typeTrans=typeTrans,locfunc=locfunc,colors=colors)
```
### loading target file
This defines the data as a target file to perform the analysis on.
```
target <- loadTargetFile(targetFile=targetFile, varInt=varInt, condRef=condRef, batch=batch)
```

### loading counts
This loads the counts data 
```
counts <- loadCountData(target=target, rawDir=rawDir, featuresToRemove=featuresToRemove)
```

### description plots
This performs some basic description plots. e.g. the number of reads per sample, how many reads account for the highest transcript (measure of RNA quality).
```
majSequences <- descriptionPlots(counts=counts, group=target[,varInt], col=colors)
```

### analysis with DESeq2
The main running of DESeq2 is performed here. It is the core statistical analysis.
```
out.DESeq2 <- run.DESeq2(counts=counts, target=target, varInt=varInt, batch=batch,
                         locfunc=locfunc, fitType=fitType, pAdjustMethod=pAdjustMethod,
                         cooksCutoff=cooksCutoff, independentFiltering=independentFiltering, alpha=alpha)
```

### PCA + clustering
This performs useful diagnostics like PCA plotting and sample clustering. It gives an good idea of how similar samples are.
```
exploreCounts(object=out.DESeq2$dds, group=target[,varInt], typeTrans=typeTrans, col=colors)
```

### summary of the analysis 
This is a final genration of sample analysis including: boxplots, dispersions, diag size factors, export table, nDiffTotal, histograms, MA plot
```
summaryResults <- summarizeResults.DESeq2(out.DESeq2, group=target[,varInt], col=colors,
                                          independentFiltering=independentFiltering,
                                          cooksCutoff=cooksCutoff, alpha=alpha)
```

### generating HTML report
Combine all the plots into a nice well described report
```
writeReport.DESeq2(target=target, counts=counts, out.DESeq2=out.DESeq2, summaryResults=summaryResults,
                   majSequences=majSequences, workDir=workDir, projectName=projectName, author=author,
                   targetFile=targetFile, rawDir=rawDir, featuresToRemove=featuresToRemove, varInt=varInt,
                   condRef=condRef, batch=batch, fitType=fitType, cooksCutoff=cooksCutoff,
                   independentFiltering=independentFiltering, alpha=alpha, pAdjustMethod=pAdjustMethod,
                   typeTrans=typeTrans, locfunc=locfunc, colors=colors)
```

### Additional mods
This has been added to filter down the main tab output to the critical info.
The main tab output can be very large. and this foucses on gene ID, Log2FC, Pval and Padj.

```
tables <- list.files(path="tables", pattern="*complete.txt", full.names=TRUE, recursive=FALSE)

library(dplyr)
lapply(tables, function(x) {
  t <-read.table(x, header=TRUE)
  #t.cols <- select(t, Id, log2FoldChange, pvalue, padj)
  t.annot <- merge(t, IDtoGene, by='Id')
  write.table(t.annot, file=paste(x, ".annot.csv", sep=""), sep="\t", quote=FALSE, row.names=FALSE, col.names=TRUE)
  })
```
### save R image
You may additionally want to save your data for quick access
```
save.image(file=paste0(projectName, ".RData"))
```
