# parameters =====================================================
DESIGN=design.csv
PARALLEL = parallel --colsep , --header : --eta --lb -j 4 --halt soon,fail=1
N ?= 250000


GENOME_URL = https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/734/005/GCF_009734005.1_ASM973400v2/GCF_009734005.1_ASM973400v2_genomic.fna.gz
GENOME_NAME = efaecium
GENOME_FASTA = fasta/$(GENOME_NAME).fasta

GFF_URL = https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/734/005/GCF_009734005.1_ASM973400v2/GCF_009734005.1_ASM973400v2_genomic.gff.gz
GFF = gff/$(GENOME_NAME).gff
INDEX := $(GENOME_FASTA).bwt

FASTQ_DIR := fastq/$(SRR)_$(N)
FASTQ_1 := $(FASTQ_DIR)/$(SRR)_1.fastq
FASTQ_2 := $(FASTQ_DIR)/$(SRR)_2.fastq
FASTQ_DONE := $(FASTQ_DIR)/.downloaded

BAM := bam/$(SAMPLE_NAME)_$(N).bam
BAI := $(BAM).bai
FAI := $(GENOME_FASTA).fai
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

SAMPLES = $(shell parallel --colsep , --header : -j1 \
	'printf "%s_%s\n" {sample_alias} {run_accession}' \
	:::: "$(DESIGN)")
SAMPLE_VCFS = $(foreach s,$(SAMPLES),vcf/$(s)_$(N).vcf.gz)
SAMPLE_BAMS = $(foreach s,$(SAMPLES),bam/$(s)_$(N).bam)

MERGED_VCF := vcf/merged-VCF_$(N).vcf.gz
JOINT_VCF := vcf/merged-BAM_$(N).vcf.gz


# code ============================================================

.PHONY: all batch genome gff fastq index align stats variants vcf-stats clean merge-vcf joint-call clean

.DEFAULT_GOAL := batch

all: $(GFF) $(FLAGSTAT) $(VCF_INDEX) $(VCF_STATS)

batch:
	+$(MAKE) index gff
	+$(PARALLEL) $(MAKE) -j1 \
		SRR={run_accession} \
		SAMPLE_NAME={sample_alias}_{run_accession} \
		N=$(N) \
		all :::: "$(DESIGN)"
	+$(MAKE) joint-call

genome: $(GENOME_FASTA)

$(GENOME_FASTA): $(GENOME_GZ)
	mkdir -p $(dir $@)
	gunzip -c $< > $@

$(GENOME_GZ):
	mkdir -p $(dir $@)
	curl -L --fail -o $@ $(GENOME_URL)

gff: $(GFF)

$(GFF):
	mkdir -p $(dir $@)
	curl -fL -o $@.gz $(GFF_URL)
	gunzip -c $@.gz > $@
	rm $@.gz


fastq: $(FASTQ_DONE)

$(FASTQ_DONE):
	mkdir -p $(FASTQ_DIR)
	fastq-dump --split-files --outdir $(FASTQ_DIR) -X $(N) $(SRR)
	test -s $(FASTQ_1)
	test -s $(FASTQ_2)
	touch $@

index: $(INDEX) $(FAI)

$(INDEX): $(GENOME_FASTA)
	bwa index $<

$(FAI): $(GENOME_FASTA)
	samtools faidx $<

align: $(BAI)

$(BAM): $(FASTQ_DONE) $(INDEX)
	mkdir -p $(dir $@)
		bwa mem -R '@RG\tID:$(SAMPLE_NAME)\tSM:$(SAMPLE_NAME)' $(GENOME_FASTA) $(FASTQ_1) $(FASTQ_2) | samtools sort -o $@ -

$(BAI): $(BAM)
	samtools index $<

stats: $(FLAGSTAT)

$(FLAGSTAT): $(BAI)
	samtools flagstat $(BAM) > $@

variants: $(VCF_INDEX)

$(VCF): $(BAM) $(GENOME_FASTA) $(FAI)
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


merge-vcf:
	mkdir -p vcf
	bcftools merge --write-index=tbi -Oz \
		-o $(MERGED_VCF) $(SAMPLE_VCFS)

joint-call:
	mkdir -p vcf
	samtools faidx $(GENOME_FASTA)
	bash -o pipefail -c 'bcftools mpileup \
		-d 100 \
		--annotate INFO/AD,FORMAT/DP,FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/SP \
		-Ou -f $(GENOME_FASTA) $(SAMPLE_BAMS) | \
		bcftools call $(CALL) -mv -Ou | \
		bcftools norm -f $(GENOME_FASTA) -d all -Ou | \
		bcftools sort --write-index=tbi -Oz -o $(JOINT_VCF)'

clean:
	rm -rf fasta fastq bam vcf gff