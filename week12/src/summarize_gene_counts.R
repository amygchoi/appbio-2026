
# Summarize gene expression by group

# Input files
COUNT_FILE <- "results/gene_counts.csv"
DESIGN_FILE <- "design.csv"

# Output directory
OUT_DIR <- "results"

# 1. Read input data
counts <- read.csv(
  COUNT_FILE,
  check.names = FALSE
)

design <- read.csv(
  DESIGN_FILE,
  stringsAsFactors = FALSE
)

# 2. Identify gene columns
gene_col <- if ("gene" %in% names(counts)) {
  "gene"
} else {
  "gene_id"
}

name_col <- if ("name" %in% names(counts)) {
  "name"
} else {
  "gene_name"
}

# 3. Check sample columns
samples <- design$sample

stopifnot(all(samples %in% names(counts)))

# 4. Calculate mean expression per group
groups <- unique(design$group)

group_means <- data.frame(
  gene = counts[[gene_col]],
  name = counts[[name_col]]
)

for (grp in groups) {

  group_samples <- design$sample[
    design$group == grp
  ]

  group_means[[grp]] <- rowMeans(
    counts[, group_samples, drop = FALSE]
  )
}

# 5. Count expressed and non-expressed genes
summary_list <- list()

for (grp in groups) {

  values <- group_means[[grp]]

  summary_list[[grp]] <- data.frame(
    group = grp,
    not_expressed = sum(values == 0),
    expressed = sum(values > 0),
    total_genes = length(values)
  )
}

expression_summary <- do.call(
  rbind,
  summary_list
)

# 6. Define expression bins
breaks <- c(0, 1, 10, 50, 100, 500, 1000, Inf)

labels <- c(
  "(0, 1]",
  "(1, 10]",
  "(10, 50]",
  "(50, 100]",
  "(100, 500]",
  "(500, 1000]",
  ">1000"
)

# 7. Count genes in each expression bin
bin_results <- list()

for (grp in groups) {

  values <- group_means[[grp]]

  bins <- cut(
    values,
    breaks = breaks,
    labels = labels,
    right = TRUE,
    include.lowest = FALSE
  )

  bin_counts <- table(
    factor(bins, levels = labels)
  )

  bin_results[[grp]] <- data.frame(
    group = grp,
    expression_level = labels,
    gene_count = as.integer(bin_counts)
  )
}

expression_bins <- do.call(
  rbind,
  bin_results
)

# 8. Save results
dir.create(
  OUT_DIR,
  showWarnings = FALSE,
  recursive = TRUE
)

write.csv(
  group_means,
  file.path(OUT_DIR, "group_mean_counts.csv"),
  row.names = FALSE
)

write.csv(
  expression_summary,
  file.path(OUT_DIR, "expression_summary.csv"),
  row.names = FALSE
)

write.csv(
  expression_bins,
  file.path(OUT_DIR, "expression_bins.csv"),
  row.names = FALSE
)

# 9. Print results
cat("\n=== Gene Expression Summary ===\n")
print(expression_summary, row.names = FALSE)

cat("\n=== Expression Level Distribution ===\n")
print(expression_bins, row.names = FALSE)

cat("\nResults saved in:", OUT_DIR, "\n")
