re4 <- RaggedExperiment(GRangesList(
    GRanges(c(A = "chr1:1-10:-", B = "chr1:8-14:-", C = "chr2:15-18:+"),
        score = 3:5),
    GRanges(c(D = "chr1:1-10:-", E = "chr2:11-18:+"), score = 1:2)
), colData = DataFrame(id = 1:2))

query <- GRanges(c("chr1:1-14:-", "chr2:11-18:+"))

weightedmean <- function(scores, ranges, qranges)
{
    ## weighted average score per query range
    ## the weight corresponds to the size of the overlap of each 
    ## overlapping subject range with the corresponding query range  
    isects <- pintersect(ranges, qranges)
    sum(scores * width(isects)) / sum(width(isects))
}

qreduceAssay(re4, query, weightedmean)

\dontrun{
    ## Extended example: non-silent mutations, summarized by genic
    ## region

    suppressPackageStartupMessages({
        library(TxDb.Hsapiens.UCSC.hg19.knownGene)
        library(org.Hs.eg.db)
        library(GenomeInfoDb)
        library(MultiAssayExperiment)
    })

    ## TCGA Multi-assay experiment to RaggedExperiment

    url <- "http://s3.amazonaws.com/multiassayexperiments/accMAEO.rds"
    ## download.file(url, fl <- tempfile())
    ## fl <- "accMAEO.rds"
    mae <- readRDS(fl)[, , c("RNASeq2GeneNorm", "CNASNP", "Mutations")]

    ## genomic coordinates

    gn <- genes(TxDb.Hsapiens.UCSC.hg19.knownGene)
    gn <- keepStandardChromosomes(granges(gn), pruning.mode="coarse")
    seqlevelsStyle(gn) <- "NCBI"

    ## reduce mutations, marking any genomic range with non-silent
    ## mutation as FALSE

    nonsilent <- function(scores, ranges, qranges)
        any(scores != "Silent")
    re <- as(mae[["Mutations"]], "RaggedExperiment")
    mutations <- qreduceAssay(re, gn, nonsilent, "Variant_Classification")

    ## reduce copy number

    re <- as(mae[["CNASNP"]], "RaggedExperiment")
    cn <- qreduceAssay(re, gn, weightedmean, "Segment_Mean")
}
