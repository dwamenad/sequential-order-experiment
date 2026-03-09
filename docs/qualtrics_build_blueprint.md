# Qualtrics Build Blueprint

## 1) Survey Flow

1. `Block: Consent`
2. `Block: Eligibility`
3. `Randomizer`: assign `order_condition`
   - Branch A: set embedded data `order_condition = large_to_small`
   - Branch B: set embedded data `order_condition = small_to_large`
4. `Block: Instructions`
5. `Block: Decision Task (8 stages)`
6. `Block: Attention + Comprehension`
7. `Block: Post-task scales`
8. `Block: Demographics`
9. End of survey

## 2) Embedded Data Fields

Set at survey start:
- `participant_id` (Qualtrics `ResponseID` can be copied in analysis)
- `order_condition`
- `device_type` (optional)

Per stage (1-8):
- `stage_{k}_choice` (selected option id)
- `stage_{k}_rt_ms` (reaction time)
- `stage_{k}_ai_option_id`
- `stage_{k}_expert_option_id`
- `stage_{k}_default_option_id`
- `stage_{k}_choice_set_size`
- `stage_{k}_selected_price`
- `stage_{k}_selected_quality`

Post-task:
- `satisfaction`
- `confidence`
- `trust_ai`
- `trust_expert`
- `advice_influence`
- `tech_trust_baseline`
- `ai_familiarity`

Checks:
- `attention_1_pass`
- `attention_2_pass`
- `comprehension_pass`

## 3) Stage Structure

Use `materials/stage_plan.csv` for set size by condition.
Each stage question:
- Single-answer multiple choice
- Include exactly one option labeled `AI Suggested`
- Include exactly one option labeled `Expert Recommended`
- Include uncued options
- Include one pre-selected default option (if enabled in settings)

After each stage page:
- Add Timing question to capture page submit time
- Add 1-second timer page before next stage

## 4) Counterbalancing Rules

1. AI and Expert labels are present at every stage.
2. Position of AI and Expert options should rotate across stages.
3. Screen positions should not be fixed by condition.
4. If using JavaScript randomization, write back chosen labels/option ids to embedded fields.

## 5) Naming Convention (important for scripts)

Decision item variable names must be:
- `Q_stage1_choice` ... `Q_stage8_choice`
- `Q_stage1_rt_ms` ... `Q_stage8_rt_ms`
- `ED_stage1_ai_option_id` ... `ED_stage8_ai_option_id`
- `ED_stage1_expert_option_id` ... `ED_stage8_expert_option_id`
- `ED_stage1_default_option_id` ... `ED_stage8_default_option_id`
- `ED_stage1_choice_set_size` ... `ED_stage8_choice_set_size`
- `ED_stage1_selected_price` ... `ED_stage8_selected_price`
- `ED_stage1_selected_quality` ... `ED_stage8_selected_quality`

Survey-level fields:
- `order_condition`
- `zip_code`
- `attention_1_pass`
- `attention_2_pass`
- `comprehension_pass`
- `satisfaction`
- `confidence`
- `trust_ai`
- `trust_expert`
- `advice_influence`
- `tech_trust_baseline`
- `ai_familiarity`

## 6) Quality Controls

1. Add two instructed-response attention checks.
2. Add one comprehension item about cue meaning.
3. Desktop-only eligibility filter.
4. Prevent back button edits during sequential stages.
5. Add ZIP input validation: exactly 5 digits (`^[0-9]{5}$`).

## 7) Export Settings

Export as CSV with:
- Choice text and recodes
- Timing fields
- Embedded data fields included

Save file as:
`data/raw/qualtrics_export.csv`
