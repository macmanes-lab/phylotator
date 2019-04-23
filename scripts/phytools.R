#!/usr/bin/env Rscript

library(phytools)

args = commandArgs(trailingOnly=TRUE)

tree <-read.tree(file = "TRINITY_DN8_c0_g1_i2.p1.txt.fasta.aligned.treefile")

tree = read.table(file = "args[1]")

getSisters(tree, node, mode=c("label"))
