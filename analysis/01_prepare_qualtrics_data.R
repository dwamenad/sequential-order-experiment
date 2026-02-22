#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(janitor)
})

args <- commandArgs(trailingOnly = TRUE)
input_path <- ifelse(length(args) >= 1, args[1], "data/raw/qualtrics_export.csv")
out_dir <- ifelse(length(args) >= 2, args[2], "data/derived")

if (!file.exists(input_path)) {
  stop(sprintf("Input file not found: %s", input_path))
}

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

raw <- read_csv(input_path, show_col_types = FALSE) |> clean_names()

# Remove possible Qualtrics metadata rows if present.
if ("response_id" %in% names(raw)) {
  raw <- raw |> filter(!is.na(response_id), response_id != "Response ID")
}

required_cols <- c("order_condition")
missing_required <- setdiff(required_cols, names(raw))
if (length(missing_required) > 0) {
  stop(sprintf("Missing required columns: %s", paste(missing_required, collapse = ", ")))
}

if (!"response_id" %in% names(raw)) {
  raw <- raw |> mutate(response_id = row_number() |> as.character())
}

stage_range <- 1:8

choice_cols <- sprintf("q_stage%d_choice", stage_range)
rt_cols <- sprintf("q_stage%d_rt_ms", stage_range)
ai_cols <- sprintf("ed_stage%d_ai_option_id", stage_range)
expert_cols <- sprintf("ed_stage%d_expert_option_id", stage_range)
default_cols <- sprintf("ed_stage%d_default_option_id", stage_range)
setsize_cols <- sprintf("ed_stage%d_choice_set_size", stage_range)
price_cols <- sprintf("ed_stage%d_selected_price", stage_range)
quality_cols <- sprintf("ed_stage%d_selected_quality", stage_range)

present <- function(x) x[x %in% names(raw)]

base <- raw |>
  mutate(
    participant_id = response_id,
    order_condition = as.character(order_condition)
  ) |>
  select(any_of(c(
    "participant_id", "order_condition", "attention_1_pass", "attention_2_pass",
    "comprehension_pass", "satisfaction", "confidence", "trust_ai", "trust_expert",
    "advice_influence", "tech_trust_baseline", "ai_familiarity"
  )))

choices_choice <- raw |>
  select(response_id, any_of(choice_cols)) |>
  pivot_longer(
    cols = -response_id,
    names_to = "stage",
    names_pattern = "q_stage(\\d+)_choice",
    values_to = "choice"
  ) |>
  mutate(stage = as.integer(stage))

choices_rt <- raw |>
  select(response_id, any_of(rt_cols)) |>
  pivot_longer(
    cols = -response_id,
    names_to = "stage",
    names_pattern = "q_stage(\\d+)_rt_ms",
    values_to = "rt_ms"
  ) |>
  mutate(stage = as.integer(stage))

choices_long <- choices_choice |>
  left_join(choices_rt, by = c("response_id", "stage"))

ed_long <- raw |>
  select(
    response_id,
    any_of(ai_cols), any_of(expert_cols), any_of(default_cols),
    any_of(setsize_cols), any_of(price_cols), any_of(quality_cols)
  ) |>
  pivot_longer(
    cols = -response_id,
    names_to = c("prefix", "stage", "measure"),
    names_pattern = "(ed)_stage(\\d+)_(ai_option_id|expert_option_id|default_option_id|choice_set_size|selected_price|selected_quality)",
    values_to = "value",
    values_transform = list(value = as.character)
  ) |>
  select(-prefix) |>
  mutate(stage = as.integer(stage)) |>
  pivot_wider(names_from = measure, values_from = value)

long <- choices_long |>
  left_join(ed_long, by = c("response_id", "stage")) |>
  left_join(base, by = c("response_id" = "participant_id")) |>
  rename(participant_id = response_id) |>
  mutate(
    stage = as.integer(stage),
    rt_ms = suppressWarnings(as.numeric(rt_ms)),
    choice_set_size = suppressWarnings(as.numeric(choice_set_size)),
    selected_price = suppressWarnings(as.numeric(selected_price)),
    selected_quality = suppressWarnings(as.numeric(selected_quality)),
    outcome = case_when(
      !is.na(choice) & !is.na(ai_option_id) & choice == ai_option_id ~ "AI",
      !is.na(choice) & !is.na(expert_option_id) & choice == expert_option_id ~ "Expert",
      !is.na(choice) ~ "Neither",
      TRUE ~ NA_character_
    ),
    outcome = factor(outcome, levels = c("Neither", "AI", "Expert")),
    chose_default = if_else(!is.na(choice) & !is.na(default_option_id) & choice == default_option_id, 1L, 0L, missing = 0L)
  ) |>
  arrange(participant_id, stage)

participant_exclusions <- long |>
  group_by(participant_id, order_condition) |>
  summarise(
    median_rt_ms = median(rt_ms, na.rm = TRUE),
    missing_stage_prop = mean(is.na(choice)),
    .groups = "drop"
  ) |>
  left_join(
    base |> transmute(
      participant_id,
      attention_1_pass = suppressWarnings(as.numeric(attention_1_pass)),
      attention_2_pass = suppressWarnings(as.numeric(attention_2_pass)),
      comprehension_pass = suppressWarnings(as.numeric(comprehension_pass))
    ),
    by = "participant_id"
  ) |>
  mutate(
    exclude_attention = if_else(attention_1_pass == 0 & attention_2_pass == 0, TRUE, FALSE, missing = FALSE),
    exclude_comprehension = if_else(comprehension_pass == 0, TRUE, FALSE, missing = FALSE),
    exclude_speed = if_else(is.finite(median_rt_ms) & median_rt_ms < 300, TRUE, FALSE, missing = FALSE),
    exclude_missing = if_else(missing_stage_prop > 0.25, TRUE, FALSE, missing = FALSE),
    excluded = exclude_attention | exclude_comprehension | exclude_speed | exclude_missing
  )

analysis_long <- long |>
  left_join(participant_exclusions |> select(participant_id, excluded), by = "participant_id") |>
  filter(!excluded) |>
  mutate(
    order_condition = factor(order_condition, levels = c("small_to_large", "large_to_small")),
    stage_c = stage - mean(stage, na.rm = TRUE),
    log_rt = log(pmax(rt_ms, 1))
  )

participant_summary <- analysis_long |>
  group_by(participant_id, order_condition) |>
  summarise(
    total_price = sum(selected_price, na.rm = TRUE),
    mean_rt_ms = mean(rt_ms, na.rm = TRUE),
    ai_share = mean(outcome == "AI", na.rm = TRUE),
    expert_share = mean(outcome == "Expert", na.rm = TRUE),
    cue_share = mean(outcome %in% c("AI", "Expert"), na.rm = TRUE),
    neither_share = mean(outcome == "Neither", na.rm = TRUE),
    .groups = "drop"
  )

write_csv(long, file.path(out_dir, "stage_level_long_all.csv"))
write_csv(analysis_long, file.path(out_dir, "stage_level_long.csv"))
write_csv(participant_exclusions, file.path(out_dir, "participant_exclusions.csv"))
write_csv(participant_summary, file.path(out_dir, "participant_summary.csv"))

message("Wrote:\n",
        "- ", file.path(out_dir, "stage_level_long_all.csv"), "\n",
        "- ", file.path(out_dir, "stage_level_long.csv"), "\n",
        "- ", file.path(out_dir, "participant_exclusions.csv"), "\n",
        "- ", file.path(out_dir, "participant_summary.csv"))
