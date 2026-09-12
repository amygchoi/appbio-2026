GENOME      := Efaecium
ACCESSION   := GCF_009734005.1
ASSEMBLY    := ASM973400v2

BASE_URL    := https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/734/005/$(ACCESSION)_$(ASSEMBLY)
FASTA_URL   := $(BASE_URL)/$(ACCESSION)_$(ASSEMBLY)_genomic.fna.gz
GFF_URL     := $(BASE_URL)/$(ACCESSION)_$(ASSEMBLY)_genomic.gff.gz

FASTA_DIR       := fasta
FASTA_DOWNLOAD  := $(FASTA_DIR)/$(ACCESSION)_$(ASSEMBLY)_genomic.fna.gz
FASTA_GZ        := $(FASTA_DIR)/$(GENOME).fna.gz
FASTA_FILE      := $(FASTA_DIR)/$(GENOME).fna
FASTA_INDEX     := $(FASTA_FILE).fai
GFF_DIR         := gff
GFF_DOWNLOAD    := $(GFF_DIR)/$(ACCESSION)_$(ASSEMBLY)_genomic.gff.gz
GFF_GZ          := $(GFF_DIR)/$(GENOME).gff.gz
GFF_FILE        := $(GFF_DIR)/$(GENOME).gff

.PHONY: all clean

all: $(FASTA_INDEX) $(GFF_FILE)

$(FASTA_GZ): | $(FASTA_DIR)
	curl --fail --location --show-error --output $(FASTA_DOWNLOAD) $(FASTA_URL) && mv $(FASTA_DOWNLOAD) $@

$(FASTA_FILE): $(FASTA_GZ)
	gzip --decompress --stdout $< > $@

$(FASTA_INDEX): $(FASTA_FILE)
	samtools faidx $

$(GFF_GZ): | $(GFF_DIR)
	curl --fail --location --show-error --output $(GFF_DOWNLOAD) $(GFF_URL) && mv $(GFF_DOWNLOAD) $@

$(GFF_FILE): $(GFF_GZ)
	gzip --decompress --stdout $< > $@

$(FASTA_DIR) $(GFF_DIR):
	mkdir -p $@

clean:
	rm -f $(FASTA_GZ) $(FASTA_FILE) $(FASTA_INDEX) $(GFF_GZ) $(GFF_FILE) \
		$(FASTA_DOWNLOAD) $(GFF_DOWNLOAD)