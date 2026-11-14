# RNA-Seq Analysis with the Salmon aligner

# The location for the data
DATA_URL=http://data.biostarhandbook.com/data/rnaseq-tutorial-2026.tar.gz

# The reference genome file
FASTA=fasta/chr22.transcripts.fa

# The directory for the index
FASTA_IDX_DIR = fasta/chr22.salmon

# The index file sentinel
FASTA_IDX = ${FASTA_IDX_DIR}/index.ctab

# The annotation file
GTF=gtf/chr22.gtf

# The sample name
SAMPLE = HBR_1

# The path to the read file
R1=fastq/${SAMPLE}_R1.fq

# Countdir files as text
COUNT_DIR = counts/${SAMPLE}

# Salmon counts file
COUNTS = ${COUNT_DIR}/quant.sf

# Design file
DESIGN = design.csv


# The design file
DESIGN = design.csv

# Run two jobs at a time since the alignment is already multithreadedwith 4 threads, thus using 2x4=8 cores
PARALLEL = parallel --eta --colsep , --header : --jobs 2 --lb

# --- All definitions above this line. All code below this line ---

# First target is the help.-
help:
	@echo "# "
	@echo "# SAMPLE=${SAMPLE}"
	@echo "# FASTA=${FASTA}"
	@echo "# R1=${R1}"
	@echo "# COUNT=${COUNT}"
	@echo "# "
	@echo "# make data"
	@echo "# make index"
	@echo "# make align"
	@echo "# make count"
	@echo "# "
	@echo "# make all"
	@echo "# "


# Download and unpack the data
${FASTA} ${GTF} ${R1} &:
	curl ${DATA_URL} | tar xzvf -

data: ${FASTA} ${GTF} ${R1}
	ls -lh ${FASTA} ${GTF} ${R1}

# The index file
${FASTA_IDX}: ${FASTA}
	salmon index --transcripts ${FASTA} --index ${FASTA_IDX_DIR}

# Index the genome.
index: ${FASTA_IDX}
	ls -lh ${FASTA_IDX}

${COUNTS}: ${FASTA_IDX} ${R1}
	mkdir -p $(dir ${COUNT_DIR})
	salmon quant --index ${FASTA_IDX_DIR} --libType A -r ${R1} --output ${COUNT_DIR}

counts: ${COUNTS}
	ls -lh ${COUNTS}

all: counts

# Generate all counts for every sample
batch:
	# Ensure that the index is built before running the alignments.
	make -f transcript_level.mk index
	
	# Run the quantifications for each sample.
	cat $(DESIGN) | $(PARALLEL) make -f transcript_level.mk SAMPLE={sample} all
	

.PHONY: all help download index align bam bw counts

# Additional Makefile settings
SHELL := bash
.DELETE_ON_ERROR:
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-print-directory
