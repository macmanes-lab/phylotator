#!/usr/bin/make -rRsf

SHELL=/bin/bash -o pipefail

#USAGE:
#
#	make
#

MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))
DIR := ${CURDIR}
CONDAROOT = ${DIR}/software/anaconda/install/
diamond_data := $(shell ls ${DIR}/software/diamond/uniprot_sprot.fasta 2>/dev/null)
conda := $(shell ${DIR}/software/anaconda/install/bin/conda info 2>/dev/null)
phylotate := $(shell ${DIR}/software/anaconda/install/bin/conda info --envs | grep phylotate 2>/dev/null)
VERSION := ${shell cat  ${MAKEDIR}/version.txt}

all: setup conda orp orthofuser transrate transabyss diamond_data busco_data postscript

.DELETE_ON_ERROR:

setup:
	@mkdir -p ${DIR}/shared
	@mkdir -p ${DIR}/software/anaconda
	@mkdir -p ${DIR}/software/diamond

conda:setup
ifdef conda
else
	cd ${DIR}/software/anaconda && curl -LO https://repo.anaconda.com/archive/Anaconda3-2018.12-Linux-x86_64.sh
	cd ${DIR}/software/anaconda && bash Anaconda3-2018.12-Linux-x86_64.sh -b -p install/
endif

phylotate:phylotate.yml conda setup
ifdef phylotate
else
	( \
				source ${DIR}/software/anaconda/install/bin/activate; \
				${DIR}/software/anaconda/install/bin/conda update -y -n base conda; \
				echo ". ${DIR}/software/anaconda/install/etc/profile.d/conda.sh" >> ~/.bashrc; \
				source ~/.bashrc; \
				source ${DIR}/software/anaconda/install/bin/deactivate; \
	 )
	 ( \
				${DIR}/software/anaconda/install/bin/conda install -y pycryptosat; \
				${DIR}/software/anaconda/install/bin/conda config --set sat_solver pycryptosat; \
				${DIR}/software/anaconda/install/bin/conda env create -f phylotate.yml python=3.7; \
  )
	@echo PATH=\$$PATH:${DIR}/software/anaconda/install/bin > pathfile;
endif

diamond_data:conda
ifdef diamond_data
	@echo "diamond_data is already installed"
else
	 cd ${DIR}/software/diamond && curl -LO ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz && gzip -d uniprot_sprot.fasta.gz
	 cd ${DIR}/software/diamond && ${DIR}/software/anaconda/install/envs/orp/bin/diamond makedb --in uniprot_sprot.fasta -d swissprot
endif

clean:
	${DIR}/software/anaconda/install/bin/conda remove -y --name orp --all
	rm -fr ${DIR}/software/anaconda/install
	rm -fr ${DIR}/software/OrthoFinder/
	rm -fr ${DIR}/software/orp-transrate
	rm -fr ${DIR}/software/transabyss
	rm -fr ${DIR}/software/anaconda/
	rm -fr ${DIR}/pathfile
