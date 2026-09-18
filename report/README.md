# Which document is which

Written 18 September 2026, after the final from-scratch run. Anything not listed
here is from a superseded analysis and should not be used.

## Current — use these

| File | What it is |
|---|---|
| `MANUSCRIPT.md` / `MANUSCRIPT.docx` | The manuscript. Word version has Tables 1–4 built from the run's CSVs. |
| `STATISTICAL_METHODS_DETAIL.md` | **Every estimator as a formula**, the code that computed it, the table it wrote, the value obtained. |
| `FINAL_RESULTS.md` | Every result table from the final run, with data provenance. |
| `STATISTICAL_ANALYSIS_PLAN.md` | Pre-specification, 19 sections, plus deviations. |
| `LIMITATIONS_AND_INTERPRETATION.md` | Drafted limitations and abstract conclusion. |
| `REVIEWER_RESPONSE.md` | Point-by-point response to the nine reviewer comments. |
| `ACTIVE_COMPARATOR_REQUEST.md` | Extraction spec for the proposed active-comparator arms. |
| `OUTCOME_DEFINITION.md`, `NEGATIVE_CONTROL_CODES.md` | Code lists and outcome rules. |
| `STROBE_RECORD_checklist.md` | Reporting checklist. |
| `FINAL_METHODS_RESULTS.md` | Longer methods/results narrative; overlaps the manuscript. |

## Superseded — do not cite

`FINAL_report.md`, `analysis_report.md`, `final_analysis_report.md`,
`rebuilt_analysis_report.md`, `epilepsy_secondary_outcome_paragraphs.md`,
`DATA_REQUEST.md`, `NEGATIVE_CONTROL_CANDIDATES.md`, and every `.html` built
from them. These predate the re-match on dated encounters and carry hazard
ratios that no longer hold.

Figures: `outputs/figures/` holds the 8 current figures. `outputs/figures_superseded/`
holds 48 from earlier pipelines — none belong to this manuscript.

Reproduce everything: `./run_final.sh`
