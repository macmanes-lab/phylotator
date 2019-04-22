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
main: setup welcome assemblycheck transdecoder blast files align_files
blast:${DIR}/blast/${RUNOUT}.diamond
setup:${DIR}/blast ${DIR}/transdecoder ${DIR}/alignment/${RUNOUT}
files:${DIR}/blast/${RUNOUT}.files.done
align_files:${DIR}/alignment/${RUNOUT}/alignment.files.done
transdecoder:${DIR}/transdecoder/${RUNOUT}/longest_orfs.pep

.DELETE_ON_ERROR:
.PHONY:check assemblycheck

${DIR}/blast ${DIR}/transdecoder ${DIR}/alignment/${RUNOUT}:
	@mkdir -p ${DIR}/blast
	@mkdir -p ${DIR}/transdecoder/${RUNOUT}
	@mkdir -p ${DIR}/alignment/${RUNOUT}



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

${DIR}/transdecoder/${RUNOUT}/longest_orfs.pep:${ASSEMBLY}
	TransDecoder.LongOrfs -t ${ASSEMBLY} --output_dir ${DIR}/transdecoder/${RUNOUT}/

${DIR}/blast/${RUNOUT}.diamond:${DIR}/transdecoder/${RUNOUT}/longest_orfs.pep ${DB}
	printf "\n\n*****  I'm using DIAMOND to identify potential homologous sequences ***** \n\n"
	cat ${DIR}/transdecoder/${RUNOUT}/longest_orfs.pep | parallel  --block 200k --recstart '>' --pipe --round-robin --line-buffer -j $(CPU) "diamond blastp --outfmt 6 qseqid sseqid evalue -p $(CPU) -e ${EVALUE} --top ${DB} -q - -d ${DB}" > ${DIR}/blast/${RUNOUT}.diamond

${DIR}/blast/${RUNOUT}.files.done:${DIR}/blast/${RUNOUT}.diamond
	printf "\n\n*****  I'm making files for all the blast hits ***** \n\n"
	for i in  $$(cut -f1  ${DIR}/blast/${RUNOUT}.diamond | sort -u --parallel); do grep -Fw $$i ${DIR}/blast/${RUNOUT}.diamond | awk '{print $$1 "\n" $$2}' | sort -u --parallel $(CPU) > ${DIR}/blast/$$i.txt; done
	touch ${DIR}/blast/${RUNOUT}.files.done

${DIR}/alignment/${RUNOUT}/alignment.files.done:${DIR}/blast/${RUNOUT}.files.done
	find ${DIR}/blast/ -name '*txt' 2> /dev/null | parallel -j $(CPU) "python ${MAKEDIR}/scripts/filter.py <(cat ${DIR}/transdecoder/${RUNOUT}/longest_orfs.pep ${MAKEDIR}/software/diamond/uniprot_sprot.fasta) {} > ${DIR}/alignment/${RUNOUT}/{1}.fasta 2> /dev/null"
	touch ${DIR}/alignment/${RUNOUT}/alignment.files.done
