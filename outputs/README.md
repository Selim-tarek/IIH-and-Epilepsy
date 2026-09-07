# Reading the outputs

This directory holds **two generations** of results. Only one is current.

| Prefix | Source data | Status |
| --- | --- | --- |
| `F_T*`, `F_S*` (tables), `FIN_*` (figures) | `IIH_MASTER_FINAL.xlsx` | **CURRENT — use these** |
| `T*`, `S*`, `F1_`–`F13_` (no `F_`/`FIN_` prefix) | `IIH_MASTER_cases_and_controls_2.csv` | **SUPERSEDED** — kept only for provenance |

The two generations disagree, and they are meant to. The superseded export had a
one-sided 180-day washout, person-time running past the data cutoff, and no dates
for controls. Fixing those changed the estimates:

| Quantity | Superseded (`T4d`) | Current (`F_T4d`) |
| --- | --- | --- |
| 3-year risk difference | 1.43 pp | **1.84 pp** |
| Number needed to harm | 70 | **54** |
| Primary hazard ratio | 3.42 | **3.66** |

Quote the `F_`/`FIN_` values. `report/final_analysis_report.md` is the current
report; `report/analysis_report.md` is the superseded one and carries a banner
saying so.
