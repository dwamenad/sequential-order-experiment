#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
})

set.seed(20260222)

args <- commandArgs(trailingOnly = TRUE)
n <- ifelse(length(args) >= 1, as.integer(args[1]), 120L)
out_path <- ifelse(length(args) >= 2, args[2], "data/raw/qualtrics_export.csv")

stage_plan <- read_csv("sequential-order-experiment/materials/stage_plan.csv", show_col_types = FALSE)
dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

inv_logit <- function(x) 1 / (1 + exp(-x))

participants <- tibble(
  response_id = sprintf("R_%04d", 1:n),
  order_condition = sample(c("small_to_large", "large_to_small"), size = n, replace = TRUE),
  attention_1_pass = 1,
  attention_2_pass = 1,
  comprehension_pass = 1,
  satisfaction = sample(3:7, n, replace = TRUE),
  confidence = sample(3:7, n, replace = TRUE),
  trust_ai = sample(2:7, n, replace = TRUE),
  trust_expert = sample(3:7, n, replace = TRUE),
  advice_influence = sample(2:7, n, replace = TRUE),
  tech_trust_baseline = sample(2:7, n, replace = TRUE),
  ai_familiarity = sample(1:7, n, replace = TRUE)
)

sim_long <- participants |>
  crossing(stage = 1:8) |>
  left_join(stage_plan, by = "stage") |>
  mutate(
    choice_set_size = if_else(order_condition == "large_to_small", choice_set_large_to_small, choice_set_small_to_large),
    ai_option_id = sprintf("S%02d_AI", stage),
    expert_option_id = sprintf("S%02d_EX", stage),
    default_option_id = sprintf("S%02d_DF", stage),
    cue_lp = -1.0 + 0.22 * stage + 0.18 * (order_condition == "large_to_small") + 0.12 * stage * (order_condition == "large_to_small"),
    p_cue = pmin(pmax(inv_logit(cue_lp), 0.05), 0.90),
    expert_given_cue_lp = 0.75 - 0.10 * stage,
    p_expert_given_cue = pmin(pmax(inv_logit(expert_given_cue_lp), 0.10), 0.90),
    u1 = runif(n()),
    u2 = runif(n()),
    outcome = case_when(
      u1 > p_cue ~ "Neither",
      u2 <= p_expert_given_cue ~ "Expert",
      TRUE ~ "AI"
    ),
    choice = case_when(
      outcome == "AI" ~ ai_option_id,
      outcome == "Expert" ~ expert_option_id,
      TRUE ~ sprintf("S%02d_N%02d", stage, pmax(1, sample.int(6, n(), replace = TRUE)))
    ),
    rt_ms = round(exp(rnorm(n(), mean = log(2200 - 120 * stage), sd = 0.35))),
    selected_price = case_when(
      outcome == "Expert" ~ round(rnorm(n(), 135, 18)),
      outcome == "AI" ~ round(rnorm(n(), 128, 18)),
      TRUE ~ round(rnorm(n(), 118, 22))
    ),
    selected_quality = case_when(
      outcome == "Expert" ~ round(rnorm(n(), 79, 6)),
      outcome == "AI" ~ round(rnorm(n(), 76, 6)),
      TRUE ~ round(rnorm(n(), 72, 8))
    )
  )

final <- participants
for (k in 1:8) {
  sk <- sim_long |>
    filter(stage == k) |>
    transmute(
      response_id,
      !!sprintf("q_stage%d_choice", k) := choice,
      !!sprintf("q_stage%d_rt_ms", k) := rt_ms,
      !!sprintf("ed_stage%d_ai_option_id", k) := ai_option_id,
      !!sprintf("ed_stage%d_expert_option_id", k) := expert_option_id,
      !!sprintf("ed_stage%d_default_option_id", k) := default_option_id,
      !!sprintf("ed_stage%d_choice_set_size", k) := choice_set_size,
      !!sprintf("ed_stage%d_selected_price", k) := selected_price,
      !!sprintf("ed_stage%d_selected_quality", k) := selected_quality
    )
  final <- final |> left_join(sk, by = "response_id")
}

write_csv(final, out_path)
message("Wrote simulated raw Qualtrics-like file: ", out_path)
