#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(brms)
})

args <- commandArgs(trailingOnly = TRUE)
input_path <- ifelse(length(args) >= 1, args[1], "data/derived/stage_level_long.csv")
out_dir <- ifelse(length(args) >= 2, args[2], "sequential-order-experiment/output")

if (!file.exists(input_path)) {
  stop(sprintf("Input file not found: %s", input_path))
}

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

dat <- read_csv(input_path, show_col_types = FALSE) |>
  mutate(
    participant_id = factor(participant_id),
    order_condition = factor(order_condition, levels = c("small_to_large", "large_to_small")),
    outcome = factor(outcome, levels = c("Neither", "AI", "Expert")),
    stage = as.numeric(stage)
  ) |>
  filter(!is.na(outcome), !is.na(stage), !is.na(order_condition))

priors <- c(
  prior(normal(0, 1.5), class = "b"),
  prior(student_t(3, 0, 2.5), class = "Intercept"),
  prior(exponential(1), class = "sd")
)

fit <- brm(
  formula = outcome ~ order_condition * stage + (1 | participant_id),
  data = dat,
  family = categorical(link = "logit"),
  prior = priors,
  chains = 4,
  iter = 3000,
  warmup = 1000,
  cores = min(4, parallel::detectCores()),
  seed = 20260222,
  backend = "rstan",
  control = list(adapt_delta = 0.95, max_treedepth = 12)
)

saveRDS(fit, file.path(out_dir, "fit_multinomial_brms.rds"))

fixef_tbl <- as.data.frame(fixef(fit)) |>
  tibble::rownames_to_column("term")
write_csv(fixef_tbl, file.path(out_dir, "fixef_multinomial_brms.csv"))

# Planned hypothesis tests mapped to preregistration.
# H1: Order x Stage increases cue uptake (AI/Expert vs Neither).
h_h1_ai <- hypothesis(fit, "muAI_order_conditionlarge_to_small:stage > 0")
h_h1_expert <- hypothesis(fit, "muExpert_order_conditionlarge_to_small:stage > 0")

# H2: Stage increases cue uptake.
h_h2_ai <- hypothesis(fit, "muAI_stage > 0")
h_h2_expert <- hypothesis(fit, "muExpert_stage > 0")

# H3: Expert > AI at stage 1 (in reference order condition).
# Difference in log-odds (Expert vs AI) at stage=1.
h_h3 <- hypothesis(
  fit,
  "(muExpert_Intercept + muExpert_stage*1) - (muAI_Intercept + muAI_stage*1) > 0"
)

# H4: Expert-AI gap shrinks over stage in reference order condition.
h_h4 <- hypothesis(fit, "muExpert_stage - muAI_stage < 0")

# Optional: whether shrinkage differs by order condition.
h_h4_order_diff <- hypothesis(
  fit,
  "(muExpert_order_conditionlarge_to_small:stage - muAI_order_conditionlarge_to_small:stage) != 0"
)

writeLines(capture.output(print(summary(fit))), file.path(out_dir, "model_summary.txt"))
writeLines(capture.output(print(h_h1_ai)), file.path(out_dir, "hypothesis_h1_ai.txt"))
writeLines(capture.output(print(h_h1_expert)), file.path(out_dir, "hypothesis_h1_expert.txt"))
writeLines(capture.output(print(h_h2_ai)), file.path(out_dir, "hypothesis_h2_ai.txt"))
writeLines(capture.output(print(h_h2_expert)), file.path(out_dir, "hypothesis_h2_expert.txt"))
writeLines(capture.output(print(h_h3)), file.path(out_dir, "hypothesis_h3.txt"))
writeLines(capture.output(print(h_h4)), file.path(out_dir, "hypothesis_h4.txt"))
writeLines(capture.output(print(h_h4_order_diff)), file.path(out_dir, "hypothesis_h4_order_diff.txt"))

# Marginal predicted probabilities by stage and order.
newdat <- tidyr::expand_grid(
  order_condition = levels(dat$order_condition),
  stage = 1:8
)

pp <- fitted(fit, newdata = newdat, summary = TRUE, scale = "response")

pred_tbl <- bind_cols(
  newdat,
  as_tibble(pp[, , "Estimate"], .name_repair = "minimal") |> setNames(c("p_Neither", "p_AI", "p_Expert")),
  as_tibble(pp[, , "Q2.5"], .name_repair = "minimal") |> setNames(c("p_Neither_l95", "p_AI_l95", "p_Expert_l95")),
  as_tibble(pp[, , "Q97.5"], .name_repair = "minimal") |> setNames(c("p_Neither_u95", "p_AI_u95", "p_Expert_u95"))
)

write_csv(pred_tbl, file.path(out_dir, "predicted_probabilities_by_stage_order.csv"))

message("Confirmatory model complete. Outputs saved to: ", out_dir)
