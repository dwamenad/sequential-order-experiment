# Run Order

From `/Users/kwakufinest/Documents/New project`:

```bash
Rscript sequential-order-experiment/analysis/00_check_packages.R
Rscript sequential-order-experiment/analysis/99_simulate_example_data.R 120 data/raw/qualtrics_export.csv
Rscript sequential-order-experiment/analysis/01_prepare_qualtrics_data.R data/raw/qualtrics_export.csv data/derived
Rscript sequential-order-experiment/analysis/02_confirmatory_models_brms.R data/derived/stage_level_long.csv sequential-order-experiment/output
Rscript sequential-order-experiment/analysis/03_secondary_models.R data/derived/stage_level_long.csv data/derived/participant_summary.csv sequential-order-experiment/output
```

If you are running real data, skip the simulation step.
