# ZIP-Based SES Plan

## 1) Collect ZIP

In Qualtrics demographics block, include:
- `What is your 5-digit ZIP code?`
- Validation regex: `^[0-9]{5}$`

## 2) Privacy

- Store raw `zip_code` only in restricted data.
- For analysis/reporting, prefer `zip3` or merged area-level SES indices.
- Do not report cells with very small n by ZIP.

## 3) SES merge options

- American Community Survey (ACS) variables by ZIP Code Tabulation Area (ZCTA):
  - median household income
  - poverty rate
  - unemployment
  - bachelor+ education
- Area Deprivation Index (ADI) by ZIP/ZCTA crosswalk.

## 4) Modeling

Add SES as participant-level predictor/moderator in confirmatory robustness analyses:
- `outcome ~ order_condition * stage * ses_index + (1|participant_id)`

