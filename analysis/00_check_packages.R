#!/usr/bin/env Rscript

required <- c(
  "readr", "dplyr", "tidyr", "stringr", "janitor",
  "lme4", "broom.mixed", "brms", "tibble"
)

installed <- rownames(installed.packages())
missing <- setdiff(required, installed)

if (length(missing) == 0) {
  cat("All required packages are installed.\n")
} else {
  cat("Missing packages:\n")
  cat(paste0("- ", missing, collapse = "\n"), "\n")
  cat("\nInstall with:\n")
  cat(sprintf("install.packages(c(%s))\n", paste(sprintf('"%s"', missing), collapse = ", ")))
}
