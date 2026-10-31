# URL of the FASTA reference genome
FASTA_URL = https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/635/GCF_000001635.27_GRCm39/GCF_000001635.27_GRCm39_genomic.fna.gz

# URL of the GFF reference genome annotation
GFF_URL = https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/635/GCF_000001635.27_GRCm39/GCF_000001635.27_GRCm39_genomic.gff.gz

# Name of the reference genome
NAME = GRCm39

# Genome fasta file
FASTA = fasta/$(NAME).fa.gz

# GFF annotation file
GFF = gff/$(NAME).gff.gz

# SRR accession number
SRR=SRR26515792

# Sample name 
SAMPLE =  STZ_SCD_Rep2

# Number of reads to download
N = 10000000

# Reads in fastq format. 
R1 = fastq/$(SRR)_1.fastq
R2 = fastq/$(SRR)_2.fastq

# BAM file derived from the sample name
BAM = bam/$(SAMPLE).bam

# BigWig coverage file
BW = bw/$(SAMPLE).bw

# BWA index sentinel
INDEX = $(FASTA).bwt

# The output Peak file
PEAKS = peaks/$(SAMPLE)_peaks.narrowPeak

# Current directory
DIR = $(shell pwd)

# Netcat command to send commands to IGV
NC = nc localhost 60151

# The design file
DESIGN = design.csv

# Run two jobs at a time since the alignment is already multithreadedwith 4 threads, thus using 2x4=8 cores
PARALLEL = parallel --eta --colsep , --header : --jobs 2 --lb


# --- All definitions above this line. All code below this line ---

usage:
	@echo "#"
	@echo "# ATAC-seq analysis with GRCm39"
	@echo "#"
	@echo "# SRR=$(SRR)"
	@echo "# NAME=$(NAME)"
	@echo "# SAMPLE=$(SAMPLE)"
	@echo "# N=$(N)"
	@echo "#"
	@echo "# BW=$(BW)"
	@echo "# FASTA=$(FASTA)"
	@echo "# GFF=$(GFF)"
	@echo "#"
	@echo "# BAM=$(BAM)"
	@echo "# PEAKS=$(PEAKS)"
	@echo "#"
	@echo "# make all"
	@echo "#"
	@echo "# make genome"
	@echo "# make gff"
	@echo "# make fastq"
	@echo "# make align"
	@echo "# make peaks"
	@echo "# make clean"
	@echo "#"

# Download the genome.
genome: $(FASTA) $(GFF)
	@ls -lh $(FASTA)
	@ls -lh $(GFF)

# Need to uncompress and recompress to BGzip format.
$(FASTA):
	mkdir -p $(dir $@)
	curl -fsSL $(FASTA_URL) | gunzip | bgzip > $@
	samtools faidx $@
	seqkit stats $@

# Download the GFF annotation.
gff: $(GFF)
	ls -lh $(GFF)
	
$(GFF):
	mkdir -p $(dir $@)
	curl -fsSL $(GFF_URL) | gunzip > gff/GRCm39.raw.gff
	LC_ALL=C sort -t "$$(printf '\t')" -k1,1 -k4,4n \
		gff/GRCm39.raw.gff | bgzip > $@
	tabix -f -p gff $@
	rm gff/GRCm39.raw.gff

# Download the fastq files.
fastq: $(R1) $(R2)
	seqkit stats $(R1) $(R2)

$(R1) $(R2) &:
	mkdir -p fastq
	fastq-dump -X $(N) --split-files -O fastq $(SRR)

# Index the genome.
index: $(INDEX)

$(INDEX): $(FASTA)
	bwa index $<

# Align the fastq files to the genome.
align: $(BAM) $(BW)
	@ls -lh $(BAM)
	@ls -lh $(BW)

$(BAM): $(INDEX) $(R1) $(R2)
	mkdir -p $(dir $@)
	bwa mem -t 4 $(FASTA) $(R1) $(R2) | samtools sort -o $@
	samtools index $@
	samtools flagstat $@

${BW}: $(BAM)
	mkdir -p $(dir $@)
	bamCoverage --binSize 1 --bam $< -o $@

$(PEAKS): $(BAM)
	mkdir -p peaks
	macs3 callpeak \
		-t $(BAM) \
		-f BAMPE \
		-g mm \
		-q 0.01 \
		-n $(SAMPLE) \
		--outdir peaks

peaks: $(PEAKS)
	@ls -lh $(PEAKS)

# Run all steps.
all: genome align peaks

# Visualize with IGV 
igv: 
	echo "new" | ${NC}
	echo "genome ${DIR}/$(FASTA)" | ${NC}
	echo "load ${DIR}/$(GFF)" | ${NC}
	# Loads up the coverage files for each sample.
		cat $(DESIGN) | $(PARALLEL) 'echo "load ${DIR}/peaks/{sample}_peaks.narrowPeak" | ${NC}'

batch:
	cat $(DESIGN) | $(PARALLEL) make SRR={run_accession} SAMPLE={sample} all
	
# Remove some of the generated files.
clean:
	rm -rf fasta fastq bam vcf gff bw peaks

.PHONY: usage all genome gff fastq index align clean peaks igv