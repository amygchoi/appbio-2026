# Combine Salmon estimated counts into a transcript-by-sample matrix.
DESIGN_FILE <- "design.csv"
QUANT_DIR <- "counts"
GTF_FILE <- "gtf/chr22.gtf"
OUTPUT_FILE <- "results/transcript_counts.csv"

extract_gtf_attribute <- function(attributes, key) {
  pattern <- paste0('(?:^|;)[[:space:]]*', key, '[[:space:]]+"([^"]+)"')
  matches <- regmatches(attributes, regexec(pattern, attributes, perl = TRUE))
  vapply(matches, function(match) {
    if (length(match) >= 2L) match[[2L]] else NA_character_
  }, character(1))
}

design <- read.csv(DESIGN_FILE, stringsAsFactors = FALSE, check.names = FALSE)
if (!"sample" %in% names(design) ||
    nrow(design) == 0L ||
    anyNA(design$sample) ||
    any(!nzchar(design$sample)) ||
    anyDuplicated(design$sample)) {
  stop("Design file must contain unique, non-empty sample names in a 'sample' column.")
}

samples <- design$sample
files <- setNames(
  file.path(QUANT_DIR, samples, "quant.sf"),
  samples
)
missing_files <- files[!file.exists(files)]
if (length(missing_files) > 0L) {
  stop(
    "Missing Salmon quantification file(s): ",
    paste(missing_files, collapse = ", ")
  )
}

if (!file.exists(GTF_FILE)) {
  stop("GTF file does not exist: ", GTF_FILE)
}
annotation <- read.delim(
  GTF_FILE,
  header = FALSE,
  sep = "\t",
  comment.char = "#",
  quote = "",
  colClasses = "character",
  stringsAsFactors = FALSE
)
if (ncol(annotation) < 9L) {
  stop("Invalid GTF file: ", GTF_FILE)
}
transcripts <- annotation[annotation[[3L]] == "transcript", , drop = FALSE]
transcript_map <- data.frame(
  transcript = extract_gtf_attribute(transcripts[[9L]], "transcript_id"),
  gene_id = extract_gtf_attribute(transcripts[[9L]], "gene_id"),
  gene_name = extract_gtf_attribute(transcripts[[9L]], "gene_name"),
  stringsAsFactors = FALSE
)
if (anyNA(transcript_map$transcript) ||
    anyNA(transcript_map$gene_id) ||
    anyDuplicated(transcript_map$transcript)) {
  stop("GTF transcript records must have unique transcript IDs and gene IDs.")
}

txi <- tximport::tximport(
  files,
  type = "salmon",
  txOut = TRUE,
  countsFromAbundance = "no"
)
transcript_counts <- txi$counts
if (!identical(colnames(transcript_counts), samples)) {
  stop("tximport returned sample columns that do not match design.csv.")
}

mapping_index <- match(rownames(transcript_counts), transcript_map$transcript)
if (anyNA(mapping_index)) {
  stop(
    "Transcript IDs not found in the GTF: ",
    paste(head(rownames(transcript_counts)[is.na(mapping_index)], 10L), collapse = ", ")
  )
}
transcript_metadata <- transcript_map[
  mapping_index,
  c("gene_id", "gene_name"),
  drop = FALSE
]
if (anyNA(transcript_metadata$gene_name)) {
  stop("Some counted transcripts have no gene name in the GTF.")
}

result <- data.frame(
  transcript = rownames(transcript_counts),
  transcript_metadata,
  transcript_counts,
  check.names = FALSE,
  stringsAsFactors = FALSE
)

dir.create(dirname(OUTPUT_FILE), showWarnings = FALSE, recursive = TRUE)
write.csv(result, OUTPUT_FILE, row.names = FALSE, quote = FALSE)
cat("Wrote transcript counts to ", OUTPUT_FILE, "\n", sep = "")
