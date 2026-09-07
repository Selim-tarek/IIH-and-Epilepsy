# Running the analysis on your own machine

## Option A — one file (simplest)

1. Put `IIH_analysis_standalone.R` and `IIH_MASTER_FINAL.xlsx` in the same folder.
2. Open R or RStudio in that folder and run:

```r
source("IIH_analysis_standalone.R")
```

Or from a terminal:

```bash
Rscript IIH_analysis_standalone.R
```

That is the whole thing. It creates `outputs/tables` (29 CSVs), `outputs/figures`
(8 PNG + PDF) and `outputs/logs/sessionInfo.txt`, and prints a summary.

**Requirements:** R >= 4.0. The script installs `survival`, `readxl` and
`ggplot2` if they are missing. Set `AUTO_INSTALL <- FALSE` at the top to install
them yourself instead.

**Runtime:** roughly one to two minutes. Most of it is the RMTL cluster
bootstrap — set `BOOT_REPS <- 100` at the top for a faster first run.

### Settings at the top of the file

| Setting | Default | What it does |
| --- | --- | --- |
| `DATA_FILE` | `"IIH_MASTER_FINAL.xlsx"` | Path to the workbook. Change it if the file lives elsewhere. |
| `OUT_DIR` | `"outputs"` | Where tables and figures are written. |
| `TAU` | `3` | Primary horizon in years after the 180-day washout. |
| `SEED` | `20250906` | Random seed. |
| `BOOT_REPS` | `400` | Bootstrap replicates for restricted mean time lost. |
| `MED_SUMMARY` / `MED_DETAIL` | medication CSVs | Optional. If absent, section 10 is skipped and everything else still runs. |

### Expected output

```
 Cohort           : 2618 IIH cases, 9122 matched controls
 Primary HR       : 3.66 (2.55 to 5.25)  (115 events, 3-year horizon)
 Adjusted HR      : 4.27 (2.68 to 6.80)
 Negative control : 1.23 (0.59 to 2.58)  <- should be null
 3-year risk      : 2.58% vs 0.74%, NNH 54
```

If your numbers differ, the workbook differs — the script asserts the data's
structure before analysing and will stop with a named failure rather than
produce a quiet wrong answer.

## Option B — the full repository

```bash
git clone -b claude/iih-epilepsy-cohort-analysis-lg3rui \
  https://github.com/Selim-tarek/IIH-and-Epilepsy.git
cd IIH-and-Epilepsy
Rscript run_final.R
```

Same statistics, split across `R/F1`–`R/F5`, plus the radiology text extraction,
the missing-data comparison, the STROBE/RECORD checklist and the written report
(`report/final_analysis_report.md`). Use this if you want to modify one stage
without touching the others.

## What the script computes

| Section | Contents |
| --- | --- |
| 1 | Import, typed variables, 11 structural assertions, washout symmetry, matching ratio, cohort flow |
| 2 | Table 1 with standardised mean differences |
| 3 | Incidence rates, exact Poisson CIs, exact incidence-rate ratios |
| 4 | Cox models: crude, stratified, IPTW, adjusted; proportional-hazards tests and Schoenfeld plots |
| 5 | Multivariable Cox: events-per-parameter, full coefficient table, PH per term, linearity, VIF, dfbeta influence, joint Wald tests |
| 6 | Competing risks (cause-specific and Fine–Gray), Aalen–Johansen absolute risk, risk difference, NNH, E-value |
| 7 | Negative-control outcome, time-split hazards, subgroups with interaction tests |
| 8 | 14 sensitivity analyses, tipping point, misclassification bias, restricted mean time lost |
| 9 | Within-IIH exploratory; encephalocele descriptive |
| 10 | Optional medication-anchored tipping point and ASM classification check |
| 11 | 8 figures |

## Two things the script will not do

It will not treat an unassessable scan as a negative one — codes 88 (not
assessable) and 99 (unknown after searching) are held apart from real values and
never imputed. And it excludes smoking from every model, because smoking is
recorded for cases only; including it would not adjust for smoking but would
re-estimate the exposure effect inside a case-only stratum.
