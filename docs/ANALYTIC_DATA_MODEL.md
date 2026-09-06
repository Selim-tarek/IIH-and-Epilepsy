# Proposed analytic data model

One row per person is the correct grain — there are no repeated measures, no
medication episodes, and no serial imaging in the delivered files, so the
person-period expansions the protocol anticipates cannot be built.

## Tables to be derived (in `R/`, from `data-raw/` only; raw files never written)

**`person`** — 13,453 rows, keyed on `record_id`. The master sheet, cleaned:
missing codes recoded to explicit `NA_unknown` (99) / `NA_not_applicable` (88)
factors rather than plain `NA`, dates parsed, `88`/`99` never silently dropped.

**`matched`** — 12,584 rows, `in_matched_analysis == 1`, keyed on `record_id`,
with `match_set` (2,732 levels) as the stratifying factor and `set_size`
(1–4) and `match_tier` retained as design variables, not covariates.

**`survival`** — the analysis frame, `record_id`, `match_set`, `group`,
`sex`, `age_index`, `bmi_index`, and:

| Field | Definition | Note |
|---|---|---|
| `time` | `followup_years` as delivered | Case rule unverifiable (Q1) |
| `time_trunc` | `min(time, 5)` | Prior analysis's primary window |
| `event_cs` | 1 = seizure, 0 otherwise | Cause-specific |
| `event_cr` | `status`: 0 censored / 1 seizure / 2 death | Death is control-only (Q2) |
| `time_capped` | recomputed censoring at min(delivered end, 2026-09-06) | Sensitivity for the 1,046 future-dated controls |

**`case_detail`** — 3,601 rows, case-only clinical/imaging/EEG block. Used
only for **within-IIH** analyses (severity, opening pressure, encephalocele
stratification). It can never enter a case-vs-control model because every
column is structurally absent for controls.

**`control_detail`** — control-only block (`race`, `enc_pre12`, `enc_post`,
`outcome_criterion`, `pnes_ever`). Descriptive only, same reason.

**`radiology`** — 3,115 free-text MR reports, unlinked (Q9). Kept out of the
analytic path until a join key is confirmed.

## Estimands, given what the data actually support

1. **Primary (executable).** Cause-specific hazard ratio of first incident
   seizure/epilepsy, IIH vs matched non-IIH, Cox stratified by `match_set`,
   time since index. Target population: matched IIH cases at a Mayo campus,
   2002–2025. Estimand is *cause-specific*, and with case deaths unascertained
   a Fine–Gray subdistribution model is **not** interpretable here — it would
   assign zero competing risk to the exposed arm by construction.
2. **Incidence rates** per 1,000 person-years with exact Poisson CIs, reported
   with and without the future-date censoring fix, so the reader can see how
   much of the rate ratio is a person-time artifact.
3. **Within-IIH severity contrast** (shunt/stent = severe vs neither): a crude
   two-level proxy, explicitly labelled **post hoc exploratory**, not the
   protocol's three-level cumulative-burden gradient.
4. **Opening pressure**, continuous, within cases only, `op_first_lp`, 1,451
   observed. With 102 case events total, a 3-knot restricted cubic spline is
   already ~1 event per parameter across strata; a linear term plus a
   pre-specified linearity test is what the events support.
5. **Negative control** (carpal tunnel) — **female pairs only**; the overall
   negative-control estimate in the FINAL workbook is not estimable for men.

Everything else in the brief (§4 MSM, §5 secondary outcomes, §7 mediation and
reverse cohort, §8 validation and kappa, most of §9) is **blocked by absent
variables**, not by modelling choices, and will be reported as such rather
than approximated.

## Handling decisions that need sign-off before any model is fitted

Listed as questions in `docs/CRITICAL_QUESTIONS.md`. The three that change the
primary estimate materially: case censoring rule (Q1), case death
ascertainment (Q2), and whether cases and controls went through the same
outcome algorithm (Q3).
