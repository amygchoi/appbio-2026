# Combine per-sample featureCounts tables into one gene count matrix.
DESIGN_FILE <- "design.csv"
COUNT_DIR <- "counts"
GTF_FILE <- "gtf/chr22.gtf"
OUTPUT_FILE <- "results/gene_counts.csv"

read_counts <- function(sample, count_dir) {
  path <- file.path(count_dir, paste0(sample, ".txt"))
  if (!file.exists(path)) {
    stop("Count file does not exist: ", path)
  }

  table <- read.delim(
    path,
    comment.char = "#",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  if (!"Geneid" %in% names(table) || ncol(table) < 2L) {
    stop("Invalid featureCounts table: ", path)
  }

  genes <- table$Geneid
  if (anyDuplicated(genes)) {
    stop("Duplicate gene IDs in featureCounts table: ", path)
  }

  values <- suppressWarnings(as.numeric(table[[ncol(table)]]))
  if (anyNA(values)) {
    stop("Non-numeric counts in featureCounts table: ", path)
  }
  setNames(values, genes)
}

extract_gtf_attribute <- function(attributes, key) {
  pattern <- paste0('(?:^|;)[[:space:]]*', key, '[[:space:]]+"([^"]+)"')
  matches <- regmatches(attributes, regexec(pattern, attributes, perl = TRUE))
  vapply(matches, function(match) {
    if (length(match) >= 2L) match[[2L]] else NA_character_
  }, character(1))
}

read_gene_names <- function(gtf_file) {
  if (!file.exists(gtf_file)) {
    stop("GTF file does not exist: ", gtf_file)
  }

  annotation <- read.delim(
    gtf_file,
    header = FALSE,
    sep = "\t",
    comment.char = "#",
    quote = "",
    colClasses = "character",
    stringsAsFactors = FALSE
  )
  if (ncol(annotation) < 9L) {
    stop("Invalid GTF file: ", gtf_file)
  }

  genes <- annotation[annotation[[3L]] == "gene", , drop = FALSE]
  gene_ids <- extract_gtf_attribute(genes[[9L]], "gene_id")
  gene_names <- extract_gtf_attribute(genes[[9L]], "gene_name")
  if (anyNA(gene_ids) || anyDuplicated(gene_ids)) {
    stop("Missing or duplicate gene IDs in GTF: ", gtf_file)
  }
  setNames(gene_names, gene_ids)
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

count_columns <- lapply(samples, read_counts, count_dir = COUNT_DIR)
gene_ids <- names(count_columns[[1L]])
for (i in seq_along(count_columns)) {
  if (!setequal(names(count_columns[[i]]), gene_ids)) {
    stop("Gene IDs do not match across count files; check sample: ", samples[[i]])
  }
}

count_matrix <- do.call(cbind, lapply(count_columns, function(counts) {
  unname(counts[gene_ids])
}))
colnames(count_matrix) <- samples

gene_names <- read_gene_names(GTF_FILE)
result <- data.frame(
  gene = gene_ids,
  name = unname(gene_names[gene_ids]),
  count_matrix,
  check.names = FALSE,
  stringsAsFactors = FALSE
)

dir.create(dirname(OUTPUT_FILE), showWarnings = FALSE, recursive = TRUE)
write.csv(result, OUTPUT_FILE, row.names = FALSE, quote = FALSE)
cat("Wrote combined gene counts to ", OUTPUT_FILE, "\n", sep = "")
