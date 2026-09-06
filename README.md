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
