# STROBE + RECORD checklist

Cohort-study STROBE items with the RECORD extension for routinely collected
health data. "Location" points at the file that carries the item.

| # | Item | Status | Location / note |
|---|---|---|---|
| 1a | Study design in title/abstract | Done | Report title; retrospective matched cohort |
| 1b | Informative abstract | **Outstanding** | Manuscript task, not pipeline |
| 2 | Background/rationale | Partial | Protocol §1; manuscript task |
| 3 | Objectives with prespecified hypotheses | Done | Protocol §1; report §2 |
| 4 | Study design | Done | Report §2 (estimand table) |
| 5 | Setting, locations, dates | Done | Mayo (3 sites), index 1990–2025 |
| 6a | Eligibility, sources, selection | Partial | `T2_cohort_flow`; upstream exclusions not itemisable (`S10`) |
| 6b | Matching criteria and number matched | Done | `S12_matching_tolerance_check`, `S3_realised_matching_ratio` |
| 7 | Variables defined | Done | `S1_data_dictionary` |
| 8 | Data sources / measurement | Done | Report §2; protocol §4 |
| 9 | Bias | Done | Report §5–6; `S11_timing_bias_assessment`; `S9_audit_findings` |
| 10 | Study size | Done | `S14_events_by_horizon` (events per parameter) |
| 11 | Quantitative variables handling | Done | Report §11 (formulas); `T5d` explains why no spline |
| 12a–e | Statistical methods, subgroups, missing data, loss to follow-up, sensitivity | Done | `R/06`–`R/09`, `R/14`; `T6`, `T8`, `T11` |
| 13 | Participants at each stage | Done | `T2_cohort_flow`, `F1_cohort_flow` |
| 14 | Descriptive data + missingness | Done | `T1_baseline_balance`, `S25`, `F8_missingness` |
| 15 | Outcome events / summary measures over time | Done | `T3_incidence_rates`, `T4c` |
| 16 | Unadjusted and adjusted estimates | Done | `T4_primary_models_combined`, `T6` |
| 17 | Other analyses | Done | `T5a`–`T5e`, `T8`, `T9`, `T10` |
| 18 | Key results | Done | Report §1 |
| 19 | Limitations | Done | Report §10; protocol §7 |
| 20 | Interpretation | Done | Report §10 |
| 21 | Generalisability | Partial | Matchable IIH-coded patients only; 869 unmatched cases excluded |
| 22 | Funding | **Outstanding** | Manuscript task |

## RECORD extension

| # | Item | Status | Location / note |
|---|---|---|---|
| RECORD 1.1 | Database/data source named in title or abstract | **Outstanding** | Manuscript task |
| RECORD 1.2 | Geographic and time period detailed | Done | Report §2 |
| RECORD 1.3 | Linkage described if applicable | Done | `S21_radiology_linkage`; radiology links to cases only |
| RECORD 6.1 | Codes/algorithms used to select population | **Partial — gap** | ICD-9 348.2 / ICD-10 G93.2 stated in protocol §2.1, but the full code list is not in this repository |
| RECORD 6.2 | Validation of codes | **Not done** | No validation sample exists (`T7`); protocol limitation 7 |
| RECORD 6.3 | Population selection flow diagram | Done | `F1_cohort_flow` |
| RECORD 7.1 | Codes/algorithms for exposures, outcomes, confounders | **Partial — gap** | Outcome and ASM definitions in protocol §4.1–4.3; underlying code lists not supplied |
| RECORD 12.1 | Data cleaning methods | Done | `R/01`, `R/02`; `S9_audit_findings` |
| RECORD 12.2 | Linkage quality | Done | `S21`; 2,808/3,601 cases linked, 0 controls |
| RECORD 12.3 | Access and cleaning of the database | Done | Raw file read-only; `run_all.R` |
| RECORD 13.1 | Unavailable data described | Done | Report §8; `S10`, `T7` |
| RECORD 19.1 | Implications of using non-research-collected data | Done | Report §10 |
| RECORD 22.1 | Statement on data availability / protocol | **Outstanding** | Manuscript task |

## Outstanding items requiring input

1. **Full ICD/CPT/RxNorm code lists** for exposure, outcome, ASMs, exclusions and
   the negative control (RECORD 6.1, 7.1). These are referenced by the protocol
   but were not supplied; they belong in a supplementary table.
2. **Code validation** (RECORD 6.2) — impossible without a chart-review sample.
3. Abstract, funding, data-availability statement — manuscript tasks.
