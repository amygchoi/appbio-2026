# Compare featureCounts gene counts with transcript-summed gene counts by group.
GENOME_COUNTS_FILE <- "results/gene_counts.csv"
TRANSCRIPT_COUNTS_FILE <- "results/gene_counts_from_transcripts.csv"
DESIGN_FILE <- "design.csv"
OUTPUT_FILE <- "results/gene_expression_errors.csv"
TOP_N <- 8L

genome_counts <- read.csv(
  GENOME_COUNTS_FILE,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
transcript_counts <- read.csv(
  TRANSCRIPT_COUNTS_FILE,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
design <- read.csv(DESIGN_FILE, check.names = FALSE, stringsAsFactors = FALSE)

if (!all(c("gene", "name") %in% names(genome_counts)) ||
    !all(c("gene_id", "gene_name") %in% names(transcript_counts))) {
  stop("Count files must contain gene IDs and gene names.")
}
if (!all(c("sample", "group") %in% names(design)) ||
    nrow(design) == 0L ||
    anyNA(design$sample) ||
    any(!nzchar(design$sample)) ||
    anyDuplicated(design$sample) ||
    anyNA(design$group) ||
    any(!nzchar(design$group))) {
  stop("Design file must contain unique sample names and non-empty group labels.")
}
if (anyNA(genome_counts$gene) ||
    any(!nzchar(genome_counts$gene)) ||
    anyDuplicated(genome_counts$gene) ||
    anyNA(transcript_counts$gene_id) ||
    any(!nzchar(transcript_counts$gene_id)) ||
    anyDuplicated(transcript_counts$gene_id)) {
  stop("Gene IDs in both count files must be unique and non-empty.")
}

samples <- design$sample
if (!all(samples %in% names(genome_counts)) ||
    !all(samples %in% names(transcript_counts))) {
  stop("Some samples in design.csv are missing from one or both count files.")
}
if (!all(vapply(genome_counts[samples], is.numeric, logical(1))) ||
    !all(vapply(transcript_counts[samples], is.numeric, logical(1))) ||
    anyNA(genome_counts[samples]) ||
    anyNA(transcript_counts[samples])) {
  stop("Sample count columns must contain numeric values without missing data.")
}

transcript_index <- match(genome_counts$gene, transcript_counts$gene_id)
shared_genes <- !is.na(transcript_index)
if (!any(shared_genes)) {
  stop("The two count files do not contain any matching gene IDs.")
}
genome <- genome_counts[shared_genes, , drop = FALSE]
transcript <- transcript_counts[transcript_index[shared_genes], , drop = FALSE]

groups <- unique(design$group)
comparisons <- lapply(groups, function(group) {
  group_samples <- design$sample[design$group == group]
  genome_mean <- rowMeans(genome[group_samples])
  transcript_mean <- rowMeans(transcript[group_samples])
  absolute_error <- abs(genome_mean - transcript_mean)
  denominator <- (genome_mean + transcript_mean) / 2
  relative_error <- numeric(length(absolute_error))
  nonzero_denominator <- denominator != 0
  relative_error[nonzero_denominator] <-
    absolute_error[nonzero_denominator] / denominator[nonzero_denominator]

  data.frame(
    gene = genome$gene,
    name = genome$name,
    group = group,
    genome = genome_mean,
    transcript = transcript_mean,
    abs_error = absolute_error,
    rel_error = relative_error,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
})
comparison <- do.call(rbind, comparisons)
comparison <- comparison[
  c("gene", "name", "group", "genome", "transcript", "abs_error", "rel_error")
]

metric_names <- c(
  "genes",
  "mean abs error",
  "median abs error",
  "mean rel error",
  "median rel error"
)
summary_values <- lapply(groups, function(group) {
  values <- comparison[comparison$group == group, , drop = FALSE]
  c(
    nrow(values),
    mean(values$abs_error),
    median(values$abs_error),
    mean(values$rel_error),
    median(values$rel_error)
  )
})
summary_matrix <- do.call(cbind, summary_values)
summary_display <- as.data.frame(lapply(seq_along(groups), function(i) {
  c(as.character(as.integer(summary_matrix[1L, i])),
    sprintf("%.2f", summary_matrix[-1L, i]))
}), stringsAsFactors = FALSE)
names(summary_display) <- groups
rownames(summary_display) <- metric_names

dir.create(dirname(OUTPUT_FILE), showWarnings = FALSE, recursive = TRUE)
write.csv(comparison, OUTPUT_FILE, row.names = FALSE, quote = FALSE)

print(summary_display, quote = FALSE)

most_dissimilar <- head(
  comparison[order(-comparison$abs_error), , drop = FALSE],
  TOP_N
)
numeric_columns <- c("genome", "transcript", "abs_error", "rel_error")
most_dissimilar[numeric_columns] <- lapply(
  most_dissimilar[numeric_columns],
  round,
  digits = 2L
)
print(most_dissimilar, row.names = FALSE)
cat("\nPer-gene errors saved to ", OUTPUT_FILE, "\n", sep = "")
