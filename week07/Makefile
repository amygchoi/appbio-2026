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

BAM := bam/$(SAMPLE_NAME)_$(N).bam
BAI := $(BAM).bai
FLAGSTAT := $(BAM).flagstat
INDEX := $(GENOME_FASTA).bwt
GENOME_GZ := $(GENOME_FASTA).gz


VCF := vcf/$(SAMPLE_NAME)_$(N).vcf.gz
VCF_INDEX := $(VCF).tbi
VCF_STATS := $(VCF).stats.txt

# e faecium is haploid
PLOIDY = 1

ANN = -d 1000 --annotate INFO/AD,FORMAT/DP,FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/SP
CALL = --ploidy $(PLOIDY) --annotate FORMAT/GQ


DIR = $(shell pwd)
NC = nc localhost 60151


# code ============================================================

.PHONY: all genome fastq index align stats variants vcf-stats igv clean

all: $(FLAGSTAT) $(VCF_INDEX) $(VCF_STATS)

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

variants: $(VCF_INDEX)

$(VCF): $(BAM) $(GENOME_FASTA)
	mkdir -p $(dir $@)
	bcftools mpileup $(ANN) -Ou -f $(GENOME_FASTA) $(BAM) | \
		bcftools call $(CALL) -mv -Ou | \
		bcftools norm -f $(GENOME_FASTA) -d all -Ou | \
		bcftools sort -Oz -o $@

$(VCF_INDEX): $(VCF)
	bcftools index --tbi $<

vcf-stats: $(VCF_STATS)

$(VCF_STATS): $(VCF)
	bcftools stats $< > $@

igv: $(BAI) $(VCF_INDEX)
	echo "new" | $(NC)
	echo "genome $(DIR)/$(GENOME_FASTA)" | $(NC)
	echo "load $(DIR)/$(BAM)" | $(NC)
	echo "load $(DIR)/$(VCF)" | $(NC)

clean:
	rm -rf fasta fastq bam vcf