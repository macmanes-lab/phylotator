#!/usr/bin/make -rRsf

SHELL=/bin/bash -o pipefail

#USAGE:
#
#	phylotate.mk ASSEMBLY= DB= RUNOUT=runname
#

MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))
DIR := ${CURDIR}
CPU=16
EVALUE=1e-10
TOP=0.01
MEM=110
RUNOUT =
ASSEMBLY=
DB=
VERSION := ${shell cat  ${MAKEDIR}/version.txt}

.DEFAULT_GOAL := main

help:
main: setup welcome assemblycheck blast
blast:${DIR}/blast/${RUNOUT}.diamond
setup:${DIR}/blast

.DELETE_ON_ERROR:
.PHONY:report check assemblycheck

${DIR}/blast:
	@mkdir -p ${DIR}/blast


help:
	printf "\n\n*****  Welcome to the Oyster River Prptocol ***** \n"
	printf "*****  This is version ${VERSION} *****\n\n"
	printf "Usage:\n\n"
	printf "/path/to/Oyster_River/Protocol/oyster.mk main CPU=24 \\n"
	printf "MEM=128 \\n"
	printf "STRAND=RF \\n"
	printf "READ1=1.subsamp_1.cor.fq \\n"
	printf "READ2=1.subsamp_2.cor.fq \\n"
	printf "RUNOUT=test\n\n"

assemblycheck:
	if [ -e ${ASSEMBLY} ]; then printf ""; else printf "\n\n\n\n ERROR: YOUR ASSEMBLY FILE DOES NOT EXIST AT THE LOCATION YOU SPECIFIED\n\n\n\n "; $$(shell exit); fi;
	if [ -e ${DB} ]; then printf ""; else printf "\n\n\n\n ERROR: YOUR ASSEMBLY FILE DOES NOT EXIST AT THE LOCATION YOU SPECIFIED\n\n\n\n "; $$(shell exit); fi;

welcome:
	printf "\n\n*****  Welcome to the Phylotate ***** \n"
	printf "*****  This is version ${VERSION} ***** \n\n "
	printf " \n\n"

${DIR}/blast/${RUNOUT}.diamond:${ASSEMBLY} ${DB}
	printf "\n\n*****  I'm using DIAMOND to identify potential homologous sequences ***** \n"
	cat ${ASSEMBLY} | parallel  --block 200k --recstart '>' --pipe --round-robin --line-buffer -j $(CPU) "diamond blastx --outfmt 6 qseqid sseqid evalue -p $(CPU) -e ${EVALUE} --top ${DB} -q - -d ${DB}" > ${DIR}/blast/${RUNOUT}.diamond
