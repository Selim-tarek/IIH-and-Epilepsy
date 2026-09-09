# Statistical review memo

**Study:** Incident seizures and epilepsy after IIH (protocol v2.0)
**Data reviewed:** `IIH_MASTER_cases_and_controls_2.csv` — 13,343 rows, 66 columns, one row per patient
**Analyst-facing summary. Read section 10 before interpreting any result.**

---

## 1. Recommended primary estimand

The **cause-specific hazard ratio of a first coded incident seizure/epilepsy, 0.5–3 years
after index**, in matchable IIH-coded patients versus matched non-IIH patients.

Three years because proportional hazards holds there (p = 0.98) and fails over full
follow-up (p = 0.031), exactly as protocol v2.0 anticipated — and because case
person-time beyond three years is contaminated by impossible encounter dates.

Cause-specific rather than subdistribution because the question is aetiological.
Report Fine–Gray alongside; here the two agree (2.75 vs 2.76 uncorrected).

## 2. Recommended primary model

```r
coxph(Surv(t0, t, ev) ~ iih, cluster = match_set, robust = TRUE)   # t0 = 180/365.25
```

**HR 3.42 (2.37–4.94)**, 112 events.

Robust variance clustered on `match_set` rather than matched-set stratification: the
realised design is variable-ratio (0–4 controls per case, mean 3.57), and the
stratified model discards every set with no event. Both are reported; they agree
(stratified 3.91).

## 3. Alternative models and when to use them

| Model | Use it when |
| --- | --- |
| Stratified by matched set | You want the conditional estimand and accept losing uninformative sets |
| IPTW on the propensity score | You want a marginal estimand over the matched population (3.45) |
| Fine–Gray | The question is absolute risk in the presence of death |
| Time-split | Reporting *when* risk is elevated — do this, the pattern matters |
| Adjusted for post-index encounters | **Only** as a declared conservative lower bound (1.54, 0.98–2.40) |

## 4. Most important sources of bias

Ranked by how much they could move the estimate.

1. **Differential outcome under-ascertainment in controls.** Now partly measured
   rather than assumed. 63 of 2,821 controls with medication data (2.23%) received
   an unambiguous ASM without ever being coded with epilepsy. Treating **all** of
   them as true missed seizures still leaves HR 1.98 (1.42–2.75). But extrapolating
   that rate to the 71% of controls with no medication data reaches the null at
   about half. Both scenarios add events only to controls, because no case
   medications exist — see decision #11.
2. **Asymmetric outcome window (found in the data, not the protocol text).** The
   180-day presenting-seizure rule was applied to cases only. Earliest case event
   day 183; earliest control event day 16; 14 control events in a window cases
   cannot occupy. Biases toward the null. Corrected by symmetric delayed entry.
3. **Surveillance/detection.** Post-index encounters 81 vs 17. Constrained — not
   eliminated — by the null negative control.
4. **Exposure misclassification.** Cases are code-identified; 29% of measured
   opening pressures are below 25 cmH₂O. Non-differential, so attenuating.
5. **Residual confounding.** OSA (SMD 0.36), PCOS (0.16), hypertension (0.17) are
   imbalanced and unadjusted. E-value 6.14 (CI limit 3.43) — a confounder would need
   associations of ~6 with both exposure and outcome, which is large but not absurd
   for a variable like OSA.
6. **Follow-up integrity.** 2,087 cases have last-encounter dates after the data
   freeze (to 2038); controls have no date fields at all.
7. **Death-ascertainment asymmetry.** Cause-specific HR for death 0.23 (0.11–0.49).
   Real, or differential capture. Cannot be resolved here.

## 5. Is the mediation analysis defensible?

**No — not identifiable, not merely underpowered.** Protocol v2.0 change #8 already
suspends it, correctly.

Encephalocele is assessable in 90 of 3,601 cases (2.5%) and in **zero controls**.
Eight incident seizures across the assessable subgroup. Imaging was ordered because
of the exposure, so mediator measurement is exposure-dependent, and `88 = not
assessable` is informative missingness that must never be recoded as absent.
Congenital encephalocele is a competing causal explanation that cannot be separated
without serial imaging.

No reformulation rescues it — not interventional effects, not separable effects.
Report the 2×2 descriptively and stop. **A larger hazard ratio in the encephalocele
subgroup would not be evidence of mediation.**

## 6. Does the sample support the requested analyses?

| Analysis | Events available | Verdict |
| --- | --- | --- |
| Primary Cox, 3 y | 112 | Yes — comfortably |
| Negative control | 32 | Yes, but wide (0.38–2.07); null is reassuring, not decisive |
| Sex-stratified | 95 F / 20 M | Female yes; male exploratory only — 80% power required HR ≥ 4.65 |
| Time-split | 91 / 80 | Yes |
| Opening-pressure spline | 42 | **No** — linear term only; knots would be set by a few events |
| Severity gradient | — | **No variable exists** |
| Mediation | 8 | **No** |
| Algorithm validation, kappa | 0 | **No sample exists** |

## 7. Most informative figures

1. **F11 negative control** — the specificity check; the single most persuasive panel.
2. **F9 tipping point** — the honest statement of fragility.
3. **F5 forest** — robustness across 18 specifications.
4. **F4 cumulative incidence** — absolute risk, competing death handled properly.
5. **F8 missingness** — makes the three kinds of absence visible.

F6 (hazard by time) matters for the detection-bias argument. F2 and F7 belong in the
supplement.

## 8. Downgrade or omit

| Analysis | Action |
| --- | --- |
| Encephalocele mediation | **Omit** from inference; descriptive 2×2 only |
| Severity gradient | **Omit** — no variable; do not substitute shunt/stent |
| Shunt/stent contrast | **Exploratory only** — post-index, immortal time |
| Opening-pressure spline | **Downgrade** to linear; it is null (HR 1.03 per 10 cmH₂O) |
| Full-follow-up models | **Downgrade to supplement** — PH violated, person-time contaminated |
| Stricter outcome (criterion 1) | **Do not run** until the criterion flag is extracted for cases |
| Male-only estimate | **Exploratory** — 20 events, no calendar-year matching constraint |
| Algorithm PPV / kappa | **Omit**; report absence as a limitation |

## 9. Pipeline

```
R/00_setup.R                     seed, paths, missing codes, helpers, house style
R/01_import_and_dictionary.R     typed frame + data dictionary from the file
R/02_data_audit.R                19 findings (6 critical)
R/03_eligibility_and_cohort_flow.R
R/04_matching_and_balance.R      realised match, SMDs, propensity diagnostics
R/05_outcome_algorithm.R         analytic dataset; REBUILDS the competing-event flag
R/06_primary_survival_analysis.R rates, Cox, PH, competing risk, absolute risk, E-value
R/07_secondary_analyses.R        negative control, time-split, EEG, exploratory
R/08_sensitivity_analyses.R      18 specifications, tipping point, misclassification
R/10_figures.R  R/11_tables.R  R/12_report_generation.R
```

Run: `Rscript run_all.R`. Outputs to `outputs/{tables,figures,diagnostics,logs}` and
`report/analysis_report.{md,html}`.

## 10. Decisions requiring your approval before anything is interpreted

1. **Adopt the symmetric 180-day window as primary?** It changes the headline from
   2.75 to 3.42. I believe it is what protocol §2.1 actually defines, but it is a
   deviation from the protocol *as written* and is yours to ratify.
2. **Confirm the 180-day rule was applied to cases only.** My inference is from the
   data (day 183 vs day 16). Please verify against the extraction code.
3. **`status` as supplied is unusable** — it codes death for 144 controls and 0 cases
   despite 91 case deaths. I rebuilt it from `died_fu`. Confirm `died_fu` is the
   correct source for both arms.
4. **Follow-up for controls cannot be verified.** They carry no date fields. Please
   supply last-encounter and death dates, or confirm the derivation rule was identical.
5. ~~2,087 cases have last-encounter dates after the data freeze.~~ **Resolved.**
   All person-time is now administratively censored at 31 August 2026. This removes
   0.2% of case and 0.8% of control person-time and leaves the 3-year primary
   estimate unchanged. Note the correction: projected end-of-follow-up ran past the
   freeze in **both** arms, and proportionally more in controls (12.1%) than cases
   (6.0%) — it was not a case-only problem.
6. **This export does not reproduce protocol §6** (2,215 cases / 4,337 controls there;
   2,732 / 9,742 here). Which extract is the study of record?
7. **Death ascertainment**: is the HR of 0.23 real, or differential capture?
8. **Zonisamide counts as an unambiguous ASM** (protocol §4.2) but is also used for
   IIH. Confirm; its impact is untestable without per-drug data.
9. **Race was a matching variable but is blank for every case.** Confirm the match
   was actually executed on race.
11. **Extract medications for the 2,732 matched IIH cases.** Highest-value single
    addition to the study. It converts the largest remaining uncertainty — whether
    ASM-without-diagnosis is commoner in controls than cases — from an untestable
    assumption into a measurement. Extending control coverage beyond the current
    29% is second.
12. **Confirm the medication extracts are final.** You said you would revise and
    filter them; everything in `R/15` is marked provisional until you do.
    Note acetazolamide appears **nowhere** in the extract (0 rows).
10. **Extract the `outcome_criterion` flag for cases** if you want the stricter
    outcome definition. It is currently controls-only and unusable.


---

## 11. Added after the final workbook (F6/F7)

**A dichotomy manufactured a finding, and the continuous analysis retracts it.**
The BMI subgroup interaction (p = 0.028 split at 35) does **not** survive when BMI
is modelled continuously: interaction p = 0.558, HR 0.92 per 5 BMI units. Do not
report BMI effect modification. Age is the borderline one instead (p = 0.067,
HR 1.41 per decade), and it too is only hypothesis-generating.

**The negative control is weaker evidence than I first said.** It had 80% power
only for HR ≥ 1.99. Its null result excludes a *large* surveillance effect, not a
modest one of 1.3–1.5. State that explicitly rather than calling it decisive.

**Timing argues against work-up detection.** Median latency 2.46 y in IIH vs
1.68 y in controls (Wilcoxon p = 0.052); only 55% of IIH events fall inside three
years against 80% of control events. A detection artefact would cluster events
immediately after index. It does not.

**The design effect is ~1.0** (robust/naive SE ratio 0.981), so matched-set
clustering costs essentially nothing. An exact permutation test that permutes
exposure within matched sets gives p < 0.0005 with no large-sample or
proportional-hazards assumption.

**Calendar stability.** Rates fall over time in both arms, but the exposure-by-era
interaction is p = 0.994. The ICD-9 to ICD-10 transition did not move the contrast.

**Attributable fraction among the exposed: 72.7% (60.7–81.0)** — valid only under
a causal reading the study does not support. Report as an upper bound on clinical
impact or omit.

**Absolute risk is small everywhere.** The largest subgroup risk difference is in
men, 3.29 percentage points over three years (NNH 30). Lead with absolute risk
alongside the hazard ratio; a threefold ratio on a 0.7% baseline is easy to
over-read.


---

## 12. Investigator decisions recorded (final)

**Dropped from the protocol, by decision:**
- **GERD** as a second negative-control outcome. Removed; not to appear in the
  protocol, the analysis plan, or the limitations.
- **Chart adjudication of the IIH diagnosis.** Not feasible. The cohort is
  "patients coded as IIH" and that is now a stated fixed limitation, not an
  outstanding data request.

**Outcome-algorithm validation.** The investigators drew a random sample and
reviewed it manually against the coded outcome, reporting excellent agreement.
The review results themselves have not reached this pipeline, so no positive
predictive value, sensitivity or two-phase-corrected estimate has been computed
here. To put a number in the paper, send the per-patient review file (MRN,
algorithm result, gold-standard result, sampling stratum) and the confusion
matrix and corrected estimates can be produced.

**Smoking, now resolved and now adjustable.** The social-history extract
populates smoking for controls, so it is no longer perfectly nested within the
exposure. Adjusting for it barely moves the estimate: 4.27 to 4.01.

But it is populated, not comparable. Case smoking comes from the workbook's
chart abstraction and control smoking from social-history flowsheets, and the
distributions differ by an order of magnitude: Former 1.5% of cases vs 15.9% of
controls, Current 0.7% vs 8.0%. That is not biology, it is measurement. Report
smoking descriptively; do not lean on the adjusted estimate as evidence that
smoking confounding has been removed. A further caveat: 5,010 control records
post-date index, so for those patients smoking is not strictly a baseline
covariate. Restricting to pre-index records gives 4.93 (2.63-9.23) on 75 events.

**The carpal tunnel rebuild supersedes everything earlier about the negative
control.** See section 13.

## 13. The finding that changes the paper

The dated diagnosis extract shows the negative-control outcome is NOT null:
incident carpal tunnel HR **2.57 (1.71-3.87)**, stable across every
specification. The seizure hazard ratio is 3.66. An outcome with no plausible
causal link to IIH is elevated almost as much as the outcome of interest.

Adjusting for post-index healthcare contact reverses the carpal excess to 0.60,
which points at detection rather than biology. Dividing the seizure estimate by
the negative-control estimate leaves **1.43 (0.83-2.46)**, which crosses the
null.

The equal-bias assumption behind that division is strong and unverifiable, and
two things still argue for a real effect: the timing (median 2.46 y to event in
IIH vs 1.68 y in controls, where a detection artefact would cluster early), and
the fact that seizure and carpal tunnel travel different referral routes so the
bias need not be equal in size. But the sentence "the negative control was null,
therefore this is not surveillance bias" can no longer be written.


---

## 14. OUTSTANDING: patient-identifiable data in the git repository

**75 MB of raw patient-level extracts are committed to this repository and
pushed to GitHub.** Fourteen files under `data-raw/`, including the master
cohort workbook (MRNs, dates of birth, index dates, diagnoses, outcomes), a
237,000-row medication administration file, six dated diagnosis extracts and
the social-history file. Two output tables also carry clinic numbers:
`outputs/tables/S22_radiology_per_patient_for_review.csv` (2,808) and
`S23_radiology_review_sample.csv` (214), the latter with radiology report text.

This accumulated because the analysis pipeline was committed with `git add -A`
after each data drop, without separating source data from code. `data-raw/` is
now in `.gitignore`, which stops further additions but does not remove what is
already tracked.

**Nothing has been removed pending the investigator's decision.** Options:

1. `git rm --cached` on the 14 files plus the two output tables. One commit,
   files stay on local disk, PR history unaffected. The data remains
   retrievable from earlier commits.
2. Purge from history with `git filter-repo` and force-push. Fully removes it;
   rewrites the branch behind PR #1 and invalidates existing clones.
3. Leave as-is if the repository is private and its access list matches the
   IRB-approved study team.

Option 1 is the minimum; option 2 is appropriate if the repository is public or
has ever been public. This should be resolved before the branch is merged.
