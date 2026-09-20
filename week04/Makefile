SHELL := /bin/sh

# Change ACC and N on the command line to process another SRA subset.
ACC ?= SRR37540651
N ?= 100000

# Every output for one accession and subset size stays in this directory.
RUN_DIR := results/$(ACC)_$(N)
RAW_DIR := $(RUN_DIR)/fastq/raw
RAW_QC_DIR := $(RUN_DIR)/qc-raw
TRIM_DIR := $(RUN_DIR)/fastq/trimmed
TRIM_QC_DIR := $(RUN_DIR)/qc-trimmed
MULTIQC_DIR := $(RUN_DIR)/multiqc
STAMPS := $(RUN_DIR)/.stamps

DOWNLOAD_STAMP := $(STAMPS)/download.done
STATS_STAMP := $(STAMPS)/stats.done
RAW_QC_STAMP := $(STAMPS)/qc-raw.done
TRIM_STAMP := $(STAMPS)/trim.done
TRIM_QC_STAMP := $(STAMPS)/qc-trimmed.done
MULTIQC_STAMP := $(STAMPS)/multiqc.done

.PHONY: all download stats qc-raw trim qc-trimmed multiqc clean

all: multiqc

# The SRA download and initial QC steps are platform-independent.  The
# fastp step below is intended mainly for Illumina short-read data.
download: $(DOWNLOAD_STAMP)

$(DOWNLOAD_STAMP):
	mkdir -p "$(RAW_DIR)" "$(STAMPS)"
	fastq-dump -X $(N) -F --split-files -O "$(RAW_DIR)" $(ACC)
	files="$$(find "$(RAW_DIR)" -type f -name '*.fastq' -print -quit)"; test -n "$$files"
	touch "$@"

stats: $(STATS_STAMP)

$(STATS_STAMP): $(DOWNLOAD_STAMP)
	seqkit stats "$(RAW_DIR)"/*.fastq > "$(RUN_DIR)/stats.txt"
	touch "$@"

qc-raw: $(RAW_QC_STAMP)

$(RAW_QC_STAMP): $(DOWNLOAD_STAMP)
	mkdir -p "$(RAW_QC_DIR)"
	fastqc --outdir "$(RAW_QC_DIR)" "$(RAW_DIR)"/*.fastq
	touch "$@"

trim: $(TRIM_STAMP)

$(TRIM_STAMP): $(DOWNLOAD_STAMP)
	mkdir -p "$(TRIM_DIR)"
	if [ -f "$(RAW_DIR)/$(ACC)_1.fastq" ] && [ -f "$(RAW_DIR)/$(ACC)_2.fastq" ]; then \
		fastp --in1 "$(RAW_DIR)/$(ACC)_1.fastq" \
			--in2 "$(RAW_DIR)/$(ACC)_2.fastq" \
			--out1 "$(TRIM_DIR)/$(ACC)_1.trimmed.fastq" \
			--out2 "$(TRIM_DIR)/$(ACC)_2.trimmed.fastq" \
			--detect_adapter_for_pe --cut_tail \
			--html "$(TRIM_DIR)/$(ACC).trimmed.fastp.html" \
			--json "$(TRIM_DIR)/$(ACC).trimmed.fastp.json"; \
	elif [ -f "$(RAW_DIR)/$(ACC).fastq" ]; then \
		fastp --in1 "$(RAW_DIR)/$(ACC).fastq" \
			--out1 "$(TRIM_DIR)/$(ACC).trimmed.fastq" \
			--cut_tail \
			--html "$(TRIM_DIR)/$(ACC).trimmed.fastp.html" \
			--json "$(TRIM_DIR)/$(ACC).trimmed.fastp.json"; \
	elif [ -f "$(RAW_DIR)/$(ACC)_1.fastq" ]; then \
		fastp --in1 "$(RAW_DIR)/$(ACC)_1.fastq" \
			--out1 "$(TRIM_DIR)/$(ACC)_1.trimmed.fastq" \
			--cut_tail \
			--html "$(TRIM_DIR)/$(ACC).trimmed.fastp.html" \
			--json "$(TRIM_DIR)/$(ACC).trimmed.fastp.json"; \
	else \
		echo "No supported FASTQ layout found in $(RAW_DIR)" >&2; \
		exit 1; \
	fi
	touch "$@"

qc-trimmed: $(TRIM_QC_STAMP)

$(TRIM_QC_STAMP): $(TRIM_STAMP)
	mkdir -p "$(TRIM_QC_DIR)"
	fastqc --outdir "$(TRIM_QC_DIR)" "$(TRIM_DIR)"/*.fastq
	touch "$@"

multiqc: $(MULTIQC_STAMP)

$(MULTIQC_STAMP): $(STATS_STAMP) $(RAW_QC_STAMP) $(TRIM_QC_STAMP)
	mkdir -p "$(MULTIQC_DIR)"
	multiqc "$(RAW_QC_DIR)" "$(TRIM_QC_DIR)" "$(TRIM_DIR)" --outdir "$(MULTIQC_DIR)"
	touch "$@"

clean:
	rm -rf "$(RUN_DIR)"
