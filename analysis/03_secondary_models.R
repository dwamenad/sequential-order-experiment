#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lme4)
  library(broom.mixed)
})

args <- commandArgs(trailingOnly = TRUE)
long_path <- ifelse(length(args) >= 1, args[1], "data/derived/stage_level_long.csv")
summary_path <- ifelse(length(args) >= 2, args[2], "data/derived/participant_summary.csv")
out_dir <- ifelse(length(args) >= 3, args[3], "sequential-order-experiment/output")

if (!file.exists(long_path)) stop(sprintf("Missing file: %s", long_path))
if (!file.exists(summary_path)) stop(sprintf("Missing file: %s", summary_path))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

long_dat <- read_csv(long_path, show_col_types = FALSE) |>
  mutate(
    participant_id = factor(participant_id),
    order_condition = factor(order_condition, levels = c("small_to_large", "large_to_small")),
    stage = as.numeric(stage),
    log_rt = log(pmax(rt_ms, 1)),
    chose_default = as.integer(chose_default)
  )

summary_dat <- read_csv(summary_path, show_col_types = FALSE) |>
  mutate(order_condition = factor(order_condition, levels = c("small_to_large", "large_to_small")))

# RT model
m_rt <- lmer(log_rt ~ order_condition * stage + (1 | participant_id), data = long_dat)

# Default acceptance model (only if default data exists)
default_ok <- "chose_default" %in% names(long_dat) &&
  any(!is.na(long_dat$chose_default)) &&
  dplyr::n_distinct(long_dat$chose_default[!is.na(long_dat$chose_default)]) > 1
if (default_ok) {
  m_default <- glmer(chose_default ~ order_condition * stage + (1 | participant_id),
                     data = long_dat,
                     family = binomial())
}

# Total price model
m_price <- lm(total_price ~ order_condition, data = summary_dat)

write_csv(tidy(m_rt, effects = "fixed", conf.int = TRUE), file.path(out_dir, "secondary_rt_fixed_effects.csv"))
if (default_ok) {
  write_csv(tidy(m_default, effects = "fixed", conf.int = TRUE, exponentiate = TRUE),
            file.path(out_dir, "secondary_default_fixed_effects.csv"))
}
write_csv(tidy(m_price, conf.int = TRUE), file.path(out_dir, "secondary_total_price_effects.csv"))

writeLines(capture.output(summary(m_rt)), file.path(out_dir, "secondary_rt_summary.txt"))
if (default_ok) {
  writeLines(capture.output(summary(m_default)), file.path(out_dir, "secondary_default_summary.txt"))
}
writeLines(capture.output(summary(m_price)), file.path(out_dir, "secondary_total_price_summary.txt"))

message("Secondary models complete. Outputs saved to: ", out_dir)
