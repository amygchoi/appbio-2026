GENOME := Efaecium
FASTA_URL := https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/734/005/GCF_009734005.1_ASM973400v2/GCF_009734005.1_ASM973400v2_genomic.fna.gz
FASTA_DIR := fasta
FASTA_DOWNLOAD := $(FASTA_DIR)/GCF_009734005.1_ASM973400v2_genomic.fna.gz
FASTA_GZ := $(FASTA_DIR)/$(GENOME).fna.gz
FASTA_FILE := $(FASTA_DIR)/$(GENOME).fna
FASTA_INDEX := $(FASTA_FILE).fai
GFF_URL := https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/734/005/GCF_009734005.1_ASM973400v2/GCF_009734005.1_ASM973400v2_genomic.gff.gz
GFF_DIR := gff
GFF_DOWNLOAD := $(GFF_DIR)/GCF_009734005.1_ASM973400v2_genomic.gff.gz
GFF_GZ := $(GFF_DIR)/$(GENOME).gff.gz
GFF_FILE := $(GFF_DIR)/$(GENOME).gff

.PHONY: all clean

all: $(FASTA_INDEX) $(GFF_FILE)

$(FASTA_GZ): | $(FASTA_DIR)
	curl --fail --location --show-error --output $(FASTA_DOWNLOAD) $(FASTA_URL) && mv $(FASTA_DOWNLOAD) $@

$(FASTA_FILE): $(FASTA_GZ)
	gzip --decompress --stdout $< > $@

$(FASTA_INDEX): $(FASTA_FILE)
	samtools faidx $<

$(GFF_GZ): | $(GFF_DIR)
	curl --fail --location --show-error --output $(GFF_DOWNLOAD) $(GFF_URL) && mv $(GFF_DOWNLOAD) $@

$(GFF_FILE): $(GFF_GZ)
	gzip --decompress --stdout $< > $@

$(FASTA_DIR) $(GFF_DIR):
	mkdir -p $@

clean:
	rm -f $(FASTA_GZ) $(FASTA_FILE) $(FASTA_INDEX) $(GFF_GZ) $(GFF_FILE) \
		$(FASTA_DOWNLOAD) $(GFF_DOWNLOAD)