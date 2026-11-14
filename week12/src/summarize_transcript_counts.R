# Sum transcript counts by gene using the GTF transcript-to-gene mapping.
TRANSCRIPT_COUNTS_FILE <- "results/transcript_counts.csv"
GTF_FILE <- "gtf/chr22.gtf"
OUTPUT_FILE <- "results/gene_counts_from_transcripts.csv"

extract_gtf_attribute <- function(attributes, key) {
  pattern <- paste0('(?:^|;)[[:space:]]*', key, '[[:space:]]+"([^"]+)"')
  matches <- regmatches(attributes, regexec(pattern, attributes, perl = TRUE))
  vapply(matches, function(match) {
    if (length(match) >= 2L) match[[2L]] else NA_character_
  }, character(1))
}

if (!file.exists(TRANSCRIPT_COUNTS_FILE)) {
  stop("Transcript count file does not exist: ", TRANSCRIPT_COUNTS_FILE)
}
if (!file.exists(GTF_FILE)) {
  stop("GTF file does not exist: ", GTF_FILE)
}

transcript_counts <- read.csv(
  TRANSCRIPT_COUNTS_FILE,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
if (!"transcript" %in% names(transcript_counts) || ncol(transcript_counts) < 2L) {
  stop("Transcript count file must have a 'transcript' column and sample columns.")
}
if (anyNA(transcript_counts$transcript) ||
    any(!nzchar(transcript_counts$transcript)) ||
    anyDuplicated(transcript_counts$transcript)) {
  stop("Transcript IDs must be unique and non-empty.")
}
sample_names <- setdiff(
  names(transcript_counts),
  c("transcript", "gene_id", "gene_name")
)
if (anyNA(transcript_counts[sample_names]) ||
    !all(vapply(transcript_counts[sample_names], is.numeric, logical(1)))) {
  stop("Transcript sample columns must contain numeric counts without missing values.")
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

mapping_index <- match(transcript_counts$transcript, transcript_map$transcript)
if (anyNA(mapping_index)) {
  stop(
    "Transcript IDs not found in the GTF: ",
    paste(head(transcript_counts$transcript[is.na(mapping_index)], 10L), collapse = ", ")
  )
}
matched_map <- transcript_map[mapping_index, , drop = FALSE]
count_matrix <- as.matrix(transcript_counts[sample_names])
gene_counts <- rowsum(count_matrix, group = matched_map$gene_id, reorder = FALSE)

gene_map <- matched_map[!duplicated(matched_map$gene_id), c("gene_id", "gene_name")]
gene_map <- gene_map[match(rownames(gene_counts), gene_map$gene_id), , drop = FALSE]
result <- data.frame(
  gene_id = rownames(gene_counts),
  gene_name = gene_map$gene_name,
  gene_counts,
  check.names = FALSE,
  stringsAsFactors = FALSE
)

dir.create(dirname(OUTPUT_FILE), showWarnings = FALSE, recursive = TRUE)
write.csv(result, OUTPUT_FILE, row.names = FALSE, quote = FALSE)
cat("Wrote summed gene counts to ", OUTPUT_FILE, "\n", sep = "")
