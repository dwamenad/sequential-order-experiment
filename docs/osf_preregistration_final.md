## Title
Sequential Order, Defaults, and Advice Source in Product Customization Decisions

## Authors
Derrick, Vinod

## Abstract/Description
Sequential decisions impose accumulating cognitive effort, which can shift people toward lower-effort strategies such as accepting defaults or following recommendations. Prior work shows that ordering choices from large to small choice sets increases later reliance on defaults. It remains unclear whether the same sequential structure increases deference to advice, and whether source labels (AI vs. expert) differentially shape adherence as decisions progress.

This study tests whether ordering by choice-set size (Large→Small vs. Small→Large) changes how participants allocate choices among three alternatives at each stage: selecting an AI-labeled recommendation, selecting an expert-labeled recommendation, or selecting neither cue. Participants complete an eight-stage customization task; each stage includes both an "AI Suggested" and an "Expert Recommended" option. We predict that Large→Small ordering will increase cue-following over stages relative to Small→Large, and that expert advice will be preferred over AI advice early but that this source gap will shrink across stages.

## 1) Have any data been collected for this study already?
No, no data have been collected for this study yet.

## 2) What's the main question being asked or hypothesis being tested in this study?
We test whether sequential order alters how cue-following evolves over stages, and whether preference for expert vs. AI advice changes across the sequence.

H1 (Order × Stage, cue uptake): Relative to Small→Large, Large→Small ordering will produce a stronger increase across stages in the probability of choosing either cued option (AI or Expert) rather than choosing neither.

H2 (Stage, cue uptake): Across participants, the probability of choosing a cued option (AI or Expert) rather than neither will increase across stages.

H3 (Source preference): Expert will be chosen more frequently than AI. Primary confirmatory test: model-implied probability of `Expert` > `AI` at Stage 1 (early-stage test).

H4 (Source gap shrinkage): The Expert-AI preference gap will decrease across stages (AI catches up to Expert over time).

## 3) Describe the key dependent variable(s) specifying how they will be measured.
Primary DV (stage-level, 3-category outcome): At each stage, the selected option will be coded as:
- `AI` = participant chose the AI-labeled option
- `Expert` = participant chose the Expert-labeled option
- `Neither` = participant chose any uncued option

This yields one outcome per participant per stage (8 outcomes per participant).

Secondary outcomes:
- `decision_time_ms` per stage (log-transformed for RT models)
- `chose_default` per stage (0/1), if a default is separately defined in the interface
- Total configured price
- Post-task satisfaction
- Post-task confidence
- Trust in AI advice
- Trust in expert advice
- Perceived influence of advice

## 4) How many and which conditions will participants be assigned to?
Between-subject factor:
- `Order`: Large→Small vs. Small→Large (1:1 random assignment)

Within-subject factor:
- `Stage`: 1-8

Task structure:
- Each stage contains both an "AI Suggested" and "Expert Recommended" option (plus uncued options)
- One mandatory choice per stage
- 1-second inter-stage delay
- Screen position of AI and Expert options will be randomized/counterbalanced across stages to avoid location confounds

## 5) Specify exactly which analyses you will conduct to examine the main question/hypothesis.
Primary confirmatory model:
- Mixed-effects multinomial logistic regression (participant random intercept)
- Outcome: `AI`, `Expert`, `Neither`
- Fixed effects: `Order`, `Stage` (1-8 continuous), `Order × Stage`
- Estimation: R, using `brms` (categorical family, logit link)

Random effects:
- `(1 | participant)` primary specification
- Add random slope for `Stage` only if convergence/stability are acceptable

Primary tests and hypothesis mapping:

Cue uptake tests (H1/H2):
- Contrast A: `AI` vs `Neither` as a function of `Stage` and `Order × Stage`
- Contrast B: `Expert` vs `Neither` as a function of `Stage` and `Order × Stage`
- H1 supported if `Order × Stage` increases odds of cued choice (AI and/or Expert) vs Neither in Large→Small relative to Small→Large
- H2 supported if `Stage` positively predicts cued choice (AI and/or Expert) vs Neither

Source preference tests (H3/H4):
- Contrast C: `Expert` vs `AI`
- H3 supported if model-implied probability of Expert exceeds AI at Stage 1
- H4 supported if the Stage coefficient in `Expert` vs `AI` indicates shrinking Expert advantage across stages (negative Stage effect under this contrast coding)

Inference/reporting:
- Two-tailed tests, alpha = .05
- Report log-odds, relative risk ratios (RRRs), 95% CIs, and marginal predicted probabilities by stage and order condition

Secondary analyses:
1. Decision time: `log(decision_time_ms) ~ Order * Stage + (1|participant)` (linear mixed-effects)
2. Defaults (if applicable): `chose_default ~ Order * Stage + (1|participant)` (mixed logistic)
3. Total price: `total_price ~ Order` (linear model; additional covariate models labeled exploratory)

## 6) Describe exactly how outliers will be defined and handled, and your precise rule(s) for excluding observations.
Participants will be excluded if any apply:
- Failed consent/eligibility
- Duplicate ID or incomplete submission
- Failed both attention checks
- Failed core comprehension check
- Median decision time across stages < 300 ms
- Missing >25% of stage-level outcomes

Handling missingness:
- Stage-level missingness handled by model likelihood in mixed models (no imputation)
- Participant-level removal only if exclusion thresholds above are met

No outcome-contingent exclusions beyond these preregistered rules.

## 7) How many observations will be collected or what will determine sample size?
N = 400 participants total (200 per order condition).
Data collection stops when 400 eligible completions are reached and all exclusion criteria are applied.

## 8) Anything else you would like to pre-register?
Robustness checks:
- Re-estimate with `Stage` categorical (dummy-coded) instead of continuous
- Re-estimate under stricter response-time exclusion threshold
- Add baseline technology-trust as a covariate to assess stability (labeled robustness)

Exploratory analyses:
- Test individual differences (AI familiarity, baseline trust in technology, need for cognition) as moderators of cue uptake/source preference
- All exploratory analyses will be explicitly labeled exploratory

Transparency:
- Anonymized data, codebook, and analysis scripts will be shared on OSF after dissemination.
