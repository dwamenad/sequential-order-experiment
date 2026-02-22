# Sequential Order Experiment

This folder contains a complete starter implementation for your preregistered study:

- `docs/osf_preregistration_final.md`: OSF-ready prereg text.
- `docs/qualtrics_build_blueprint.md`: block-by-block Qualtrics build instructions.
- `materials/stage_plan.csv`: stage sizes and order mapping for both conditions.
- `materials/option_bank_headphones.csv`: reusable option pool (price/quality).
- `analysis/01_prepare_qualtrics_data.R`: converts Qualtrics wide export to long panel data.
- `analysis/02_confirmatory_models_brms.R`: primary multinomial mixed model + hypothesis tests.
- `analysis/03_secondary_models.R`: preregistered secondary analyses.
- `analysis/99_simulate_example_data.R`: generate mock data to test scripts before launch.

## Suggested Workflow

1. Build survey in Qualtrics using `docs/qualtrics_build_blueprint.md`.
2. Export a test CSV from Qualtrics into `data/raw/`.
3. Run `analysis/01_prepare_qualtrics_data.R`.
4. Run `analysis/02_confirmatory_models_brms.R`.
5. Run `analysis/03_secondary_models.R`.

## Expected Data Paths

- Raw Qualtrics CSV: `data/raw/qualtrics_export.csv`
- Analysis-ready long file: `data/derived/stage_level_long.csv`
- Outputs: `sequential-order-experiment/output/`

## Notes

- Default model engine is `brms` for mixed-effects multinomial logistic regression.
- Secondary models use `lme4`.
- If package install is needed, run in your local R environment.
