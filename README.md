# IIH and Incident Epilepsy — matched cohort analysis

Reproducible R analysis for *Incident Seizures and Epilepsy After Idiopathic
Intracranial Hypertension: a retrospective matched cohort study* (protocol v2.0,
`IIH_Epilepsy_Protocol_v2.md`).

## Run it

```bash
Rscript run_all.R      # reruns everything from a clean session
```

Requires R >= 4.0 with `survival` (required) and `ggplot2` (for figures).
The pipeline checks for these at startup and fails with an actionable message.

## Layout

| Path | Contents |
| --- | --- |
| `data-raw/` | Source export, opened read-only and never modified |
| `R/00_setup.R` | Paths, seed, missing-value codes, statistical and plotting helpers |
| `R/01_import_and_dictionary.R` | Typed analytic frame + data dictionary generated from the file |
| `R/02_data_audit.R` | Descriptive audit; produces the numbered findings list |
| `R/03_eligibility_and_cohort_flow.R` | Cohort flow and timing-bias assessment |
| `R/04_matching_and_balance.R` | Realised-match verification, SMDs, propensity diagnostics |
| `R/05_outcome_algorithm.R` | Analytic survival dataset; rebuilds the competing-event indicator |
| `R/06_primary_survival_analysis.R` | Rates, Cox models, PH checks, competing risk, absolute risk, E-value |
| `R/07_secondary_analyses.R` | Negative control, time-split, EEG, exploratory within-IIH |
| `R/08_sensitivity_analyses.R` | 18 sensitivity specifications, tipping point, misclassification bias |
| `R/10_figures.R` – `R/12_report_generation.R` | Figures, tables, report |
| `outputs/` | `tables/`, `figures/`, `diagnostics/`, `logs/` |
| `report/analysis_report.md` / `.html` | Full narrative report |
| `STATISTICAL_REVIEW_MEMO.md` | Review memo: estimand, model choice, bias, decisions needing sign-off |

## Three kinds of missing

The source file distinguishes them and so does the pipeline. They are never
conflated, and none is imputed as a negative:

- **blank** — never extracted for that cohort (structural; e.g. all imaging in controls)
- **99** — unknown after searching
- **88** — not applicable / not technically assessable

An unassessable scan is not a negative scan.

## Reproducibility

`renv.lock` pins package versions; `outputs/logs/sessionInfo.txt` and
`outputs/logs/package_versions.csv` record the environment of the last run.
`report/STROBE_RECORD_checklist.md` tracks reporting completeness, including the
items that still need input (full code lists, abstract, funding).

## Data inputs

| File | Covers | Used for |
| --- | --- | --- |
| `IIH_MASTER_cases_and_controls_2.csv` | 3,601 cases + 9,742 controls | All primary analyses |
| `MDE Workflow Results for Radiology (25).csv` | 2,808 cases, 0 controls | Exploratory imaging text extraction (`R/13`), not used in any model |
| `IIH_medications_*.csv` / `.xlsx` | 2,821 controls (29%), 0 cases | Extract audit and the anchored tipping point (`R/15`); provisional |

All person-time is administratively censored at `FREEZE_DATE` (31 August 2026),
set in `R/00_setup.R`.

## Final pipeline (IIH_MASTER_FINAL.xlsx)

```bash
Rscript run_final.R
```

| Script | Contents |
| --- | --- |
| `R/F1_import_audit_final.R` | Typed import from the workbook, dictionary, washout/matching/flow audit, all structural assertions |
| `R/F2_analysis_final.R` | Rates, Cox models, PH checks, competing risks, absolute risk, E-value, negative control, timing, balance, subgroups, sensitivity, tipping point, RMTL, within-IIH exploratory |
| `R/F3_medications_final.R` | Medication linkage, ASM classification check, anchored tipping point (provisional) |
| `R/F4_figures_report_final.R` | 10 figures (`outputs/figures/FIN_*`) and `report/final_analysis_report.md` |

Outputs are prefixed `F_` (tables) and `FIN_` (figures) to keep them separate from
the earlier CSV-based pipeline, which is retained for provenance.

`R/F5_cox_regression_final.R` adds the multivariable Cox regression: univariable
and adjusted models, the full coefficient table, events-per-parameter budget,
per-term proportional-hazards tests, linearity checks, collinearity (VIF),
dfbeta influence, joint Wald tests by covariate block, and a coefficient forest
plot. Smoking is excluded and the reason tabulated — it is recorded only for
cases, so it is structurally collinear with the exposure.
