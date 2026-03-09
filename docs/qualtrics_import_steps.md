# Import Steps (QSF)

1. In Qualtrics, create/open a project.
2. Use `Tools` or project menu -> `Import/Export` -> `Import Survey`.
3. Select:
   `/Users/kwakufinest/Documents/New project/sequential-order-experiment/docs/sequential_order_experiment_template.qsf`
4. After import, verify Survey Flow includes:
   - embedded data `order_condition`
   - randomizer that sets `large_to_small` or `small_to_large`
5. In each stage question (QID4-QID11), keep choice coding as:
   - `1` = AI Suggested
   - `2` = Expert Recommended
   - `3+` = Neither
6. Add page timer elements if you want stage-level RT fields (`q_stage*_rt_ms`) exported.
7. Publish, run test responses, export CSV to:
   `data/raw/qualtrics_export.csv`
8. Run prep + analysis scripts.

## Notes

- This template is a starter structure. You still need to swap placeholder options with your real headphone stimuli.
- The analysis script has a fallback assuming AI=1 and Expert=2 if embedded option IDs are not exported.
