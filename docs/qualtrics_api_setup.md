# Qualtrics API Setup

This connects your Qualtrics account to the local analysis workflow.

## 1) Required values

- `QUALTRICS_API_TOKEN`: from Qualtrics Account Settings -> Qualtrics IDs
- `QUALTRICS_DATACENTER`: datacenter ID from your Qualtrics URL
  - Example URL: `https://dukeuniversity.qualtrics.com/...`
  - Datacenter value to use: `dukeuniversity`

## 2) Set environment variables (zsh)

```bash
export QUALTRICS_API_TOKEN="YOUR_TOKEN_HERE"
export QUALTRICS_DATACENTER="YOUR_DATACENTER_HERE"
```

To persist across terminal sessions, add those lines to `~/.zshrc`.

## 3) Verify connection

```bash
cd "/Users/kwakufinest/Documents/New project/sequential-order-experiment"
Rscript analysis/04_qualtrics_api.R whoami
```

Expected result: user/account info from Qualtrics API.

## 4) Download responses directly to CSV

```bash
Rscript analysis/04_qualtrics_api.R export-responses SV_XXXXXXXXXXXXXXX \
"/Users/kwakufinest/Documents/New project/data/raw/qualtrics_export.csv"
```

Replace `SV_...` with your Qualtrics Survey ID.

## 5) Run existing prep + models

```bash
Rscript analysis/01_prepare_qualtrics_data.R \
"/Users/kwakufinest/Documents/New project/data/raw/qualtrics_export.csv" \
"/Users/kwakufinest/Documents/New project/data/derived"

Rscript analysis/02_confirmatory_models_brms.R \
"/Users/kwakufinest/Documents/New project/data/derived/stage_level_long.csv" \
"/Users/kwakufinest/Documents/New project/sequential-order-experiment/output"
```

## Notes

- The response export endpoint returns a ZIP; the script extracts the first CSV automatically.
- If your account/plan restricts API access, `whoami` or export endpoints will return a 4xx error.
