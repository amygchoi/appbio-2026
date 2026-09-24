# parameters =====================================================
GENOME_URL = https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/734/005/GCF_009734005.1_ASM973400v2/GCF_009734005.1_ASM973400v2_genomic.fna.gz
GENOME_NAME = efaecium
GENOME_FASTA = fasta/$(GENOME_NAME).fasta

SRR = SRR37686361
N = 250000
SAMPLE_NAME = V2271

FASTQ_DIR := fastq/$(SRR)_$(N)
FASTQ_1 := $(FASTQ_DIR)/$(SRR)_1.fastq
FASTQ_2 := $(FASTQ_DIR)/$(SRR)_2.fastq
FASTQ_DONE := $(FASTQ_DIR)/.downloaded

BAM := results/$(SAMPLE_NAME)_$(N).bam
BAI := $(BAM).bai
FLAGSTAT := $(BAM).flagstat
INDEX := $(GENOME_FASTA).bwt
GENOME_GZ := $(GENOME_FASTA).gz


# code ============================================================

.PHONY: all genome fastq index align stats clean

all: $(FLAGSTAT)

genome: $(GENOME_FASTA)

$(GENOME_FASTA): $(GENOME_GZ)
	mkdir -p $(dir $@)
	gunzip -c $< > $@

$(GENOME_GZ):
	mkdir -p $(dir $@)
	curl -L --fail -o $@ $(GENOME_URL)


fastq: $(FASTQ_DONE)

$(FASTQ_DONE):
	mkdir -p $(FASTQ_DIR)
	fastq-dump --split-files --outdir $(FASTQ_DIR) -X $(N) $(SRR)
	test -s $(FASTQ_1)
	test -s $(FASTQ_2)
	touch $@

index: $(INDEX)

$(INDEX): $(GENOME_FASTA)
	bwa index $<

align: $(BAI)

$(BAM): $(FASTQ_DONE) $(INDEX)
	mkdir -p $(dir $@)
	bwa mem $(GENOME_FASTA) $(FASTQ_1) $(FASTQ_2) | samtools sort -o $@ -

$(BAI): $(BAM)
	samtools index $<

stats: $(FLAGSTAT)

$(FLAGSTAT): $(BAI)
	samtools flagstat $(BAM) > $@

clean:
	rm -rf fasta fastq results
