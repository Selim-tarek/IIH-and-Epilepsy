---
title: "IIH and Incident Epilepsy: Analysis Report"
---

# Incident Seizures and Epilepsy After Idiopathic Intracranial Hypertension

### Analysis report

**Protocol:** v2.0 · **Analysis date:** 2026-09-06 · **Seed:** 20250906 · **R:** R version 4.3.3 (2024-02-29)

---

## 1. Headline result

Among 2,732 patients coded as IIH and 9,742 matched non-IIH controls, the cause-specific hazard of a first incident coded seizure or epilepsy over three years was:

> **HR 3.40 (2.36 to 4.91)** (corrected primary specification, 112 events)

Three-year absolute risk was 2.25% in IIH versus 0.83% in controls, a difference of 1.43 percentage points (0.81 to 2.05), or one additional seizure per 70 patients followed three years.

**This is an association, not a demonstration that IIH causes epilepsy.** Section 6 sets out why.

---

## 2. Estimand

| Element | Specification |
| --- | --- |
| Population | Matchable patients coded as IIH (ICD-9 348.2 / ICD-10 G93.2) aged 13-60, and their matched non-IIH controls |
| Exposure | An IIH diagnosis code, **not chart-adjudicated IIH** (protocol v2.0 change #1) |
| Outcome | First incident seizure/epilepsy by the coded algorithm (protocol s4.1), applied identically in both arms |
| Time zero | Date of diagnostic lumbar puncture; controls inherit their case's index date |
| Contrast | Cause-specific hazard ratio, 0.5-3 years after index |
| Competing event | Death, handled as a competing risk (Aalen-Johansen for absolute risk) |
| Censoring | Earliest of first seizure, death, last documented encounter, study end |

The **cause-specific** hazard is primary because the question is aetiological. The Fine-Gray subdistribution hazard is reported alongside it because it answers a different, prognostic question; the two agree closely here (see section 4).

---

## 3. A design defect found in the data, and how it was handled

Protocol v2.0 s2.1 treats a seizure within 180 days of index as a *presenting* rather than incident event and excludes it. **That rule was applied to cases only.** In this export:

- the earliest incident event in an IIH case is on day 183;
- the earliest in a control is on day 16;
- **14 control events** fall inside a window in which no case can have an event by construction.

Comparing the arms from day 0 therefore compares a case arm with a 180-day blanking period against a control arm without one. This biases the hazard ratio **toward the null**.

| Specification | Events | HR (95% CI) |
| --- | --- | --- |
| Protocol as written (from day 0) | 126 | 2.74 (1.93 to 3.88) |
| **Symmetric 180-day window (corrected)** | 112 | **3.40 (2.36 to 4.91)** |

The corrected specification applies the same outcome-eligibility window to both arms via delayed entry. It is the estimate reported above, and it is what the protocol's own eligibility rule actually defines. **This requires the investigators' confirmation** (section 8).

---

## 4. Primary results

### Incidence rates

| horizon | cohort | n | events | person_years | rate_per_1000py | lo | hi |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 3 years (primary) | Non-IIH control | 9742 | 70 | 24016.4 | 2.91 | 2.27 | 3.68 |
| 3 years (primary) | IIH | 2732 | 56 | 7118.1 | 7.87 | 5.94 | 10.22 |
| 5 years | Non-IIH control | 9742 | 80 | 32348.9 | 2.47 | 1.96 | 3.08 |
| 5 years | IIH | 2732 | 76 | 10242.1 | 7.42 | 5.85 | 9.29 |
| full follow-up | Non-IIH control | 9742 | 83 | 41130.8 | 2.02 | 1.61 | 2.50 |
| full follow-up | IIH | 2732 | 102 | 15925.1 | 6.40 | 5.22 | 7.78 |

All person-time is administratively censored at the 31 August 2026 data freeze. This removes 0.2% of case and 0.8% of control person-time and leaves the 3-year primary estimate unchanged; projected end-of-follow-up ran to 2031 in cases and 2034 in controls before the cap.

The control rate *falls* as the horizon lengthens while the case rate is stable: control person-time accrues without events. Full follow-up is the least reliable column, because case person-time is computed from an encounter-date field containing impossible values (to 2038).

### Models

| model | n | events | estimate |
| --- | --- | --- | --- |
| Cox, 3-y truncated (PRIMARY) | 12474 | 126 | 2.74 (1.93 to 3.88) |
| Cox stratified by matched set, 3 y | 12473 | 126 | 3.11 (2.15 to 4.48) |
| Cox, 5-y truncated | 12474 | 156 | 3.10 (2.27 to 4.23) |
| Cox, full follow-up | 12474 | 185 | 3.56 (2.68 to 4.74) |
| Cox, 3 y, + age/BMI/sex | 12474 | 126 | 2.74 (1.93 to 3.89) |
| Cox, 3 y, IPTW (stabilised, trimmed) | 12474 | 126 | 2.76 (1.95 to 3.91) |

### Competing risk

| estimand | estimate | interpretation |
| --- | --- | --- |
| Cause-specific HR, seizure (PRIMARY) | 2.74 (1.93 to 3.88) | Rate of seizure among those still alive and seizure-free -- aetiological question |
| Cause-specific HR, death (competing event) | 0.23 (0.11 to 0.48) | Whether IIH also changes mortality; if ~1, the two seizure estimands should agree closely |
| Subdistribution HR, seizure (Fine-Gray) | 2.75 (1.94 to 3.89) | Effect on the cumulative INCIDENCE of seizure with death held in the risk set -- prognostic question |

The cause-specific and subdistribution estimates are nearly identical because death is uncommon over three years. The **death hazard itself is markedly below 1**, which is either a genuine feature of the cohorts or an artefact of differential death ascertainment; the two cannot be separated here and it is a priority question for the data team.

### Proportional hazards

| horizon_y | chisq | df | p_ph | conclusion |
| --- | --- | --- | --- | --- |
| 3 | 0.00 | 1 | 0.989 | PH not rejected |
| 5 | 1.35 | 1 | 0.245 | PH not rejected |
| Inf | 4.55 | 1 | 0.033 | PH VIOLATED |

PH holds at 3 years and fails over full follow-up, exactly as protocol v2.0 change #4 anticipated. This is the reason for truncation.

---

## 5. Is the result just healthcare contact?

This is the central threat: IIH patients see doctors far more often (post-index encounter median 81 vs 17), so they have more opportunity to be *detected* as having a seizure.

Three lines of evidence bear on it.

**1. The negative-control outcome is null.**

| outcome | n | ev | estimate | p |
| --- | --- | --- | --- | --- |
| Incident seizure/epilepsy (positive outcome) | 10684 | 103 | 2.39 (1.62 to 3.53) | <0.001 |
| Incident carpal tunnel syndrome (NEGATIVE CONTROL) | 10684 | 34 | 0.81 (0.35 to 1.89) | 0.630 |

Carpal tunnel syndrome has no plausible causal link to IIH and is ascertained the same way over the same window. If the design were simply measuring healthcare contact, it would be elevated too. It is not. This is the strongest single argument that the seizure result is not pure ascertainment.

**2. The excess risk is sustained, not concentrated at diagnosis.**

| period | events | estimate |
| --- | --- | --- |
| 0-6 months | 14 | 0.00 (0.00 to 0.00) |
| 6 mo - 2 y | 91 | 3.55 (2.35 to 5.37) |
| >2 years | 80 | 5.34 (3.31 to 8.61) |

A detection artefact from the diagnostic work-up would produce a spike early and decay. The opposite is seen. (The 0-6 month row is uninterpretable for the reason given in section 3.)

**3. Adjusting for contact attenuates but does not eliminate the association.**

Adjusted for post-index encounters: 1.51 (0.97 to 2.37) (112 events). This is reported as a **conservative lower bound only** (protocol s5.3). Post-index encounters are a consequence of both the exposure and the outcome, so conditioning on them is adjustment for a mediator and opens a collider path; it can push an estimate past the null even when a true effect exists. The legitimate design-stage control is the pre-index encounter restriction, and adjusting for *pre-index* contact gives 4.16 (2.65 to 6.53) (111 events).

---

## 6. What would overturn this result

### The tipping point is uncomfortably close

| pct_censored_controls_with_hidden_seizure | hidden_events_added | hr | lo | hi | crosses_null |
| --- | --- | --- | --- | --- | --- |
| 0 | 0 | 3.40 | 2.36 | 4.91 | FALSE |
| 1 | 95 | 1.25 | 0.92 | 1.70 | TRUE |
| 2 | 189 | 0.76 | 0.57 | 1.02 | TRUE |
| 5 | 474 | 0.35 | 0.26 | 0.46 | TRUE |
| 10 | 947 | 0.18 | 0.14 | 0.23 | TRUE |
| 20 | 1895 | 0.09 | 0.07 | 0.11 | TRUE |

If roughly **1% of censored controls had an unrecorded seizure**, the association would disappear. This follows directly from the very low control event count (83 events among 9,742 controls): a small absolute number of hidden events is a large proportional change. This is the study's most serious quantitative vulnerability.

What argues against it: the null negative control, and the fact that controls were required to have an encounter in the year before index, so they are not disengaged patients. What cannot be ruled out: controls have **no date fields at all** in this export, so their censoring cannot be independently verified.

### E-value

| quantity | value | plain_language |
| --- | --- | --- |
| E-value, point estimate | 4.92 | An unmeasured confounder would have to be associated with BOTH IIH status AND seizure by a risk ratio of at least 4.92 each, above and beyond age, sex and BMI, to explain away the observed HR. |
| E-value, CI limit nearest the null | 3.27 | To move the confidence interval to include the null, such a confounder would need associations of at least 3.27 each. |

### Outcome misclassification

| sensitivity_iih | sensitivity_control | scenario | corrected_IRR |
| --- | --- | --- | --- |
| 1.0 | 1.0 | non-differential | 2.7 |
| 0.9 | 0.9 | non-differential | 2.7 |
| 0.8 | 0.8 | non-differential | 2.7 |
| 0.9 | 0.7 | DIFFERENTIAL (favours exposed detection) | 2.1 |
| 0.9 | 0.6 | DIFFERENTIAL (favours exposed detection) | 1.8 |

Non-differential misclassification does not move the rate ratio at all (it scales both arms equally). Only *differential* detection does. Sensitivity would have to be substantially better in cases than controls to account for the finding.

---

## 7. Sensitivity analyses

| analysis | status | n | events | estimate | p |
| --- | --- | --- | --- | --- | --- |
| Cox, 3 y, symmetric 180-day landmark (CORRECTED PRIMARY) | PROTOCOL-DERIVED | 12204 | 112 | 3.40 (2.36 to 4.91) | <0.001 |
| Cox, 3 y, no landmark (protocol as written) | PRE-SPECIFIED | 12474 | 126 | 2.74 (1.93 to 3.88) | <0.001 |
| Landmark: excluding events before 6 months | PRE-SPECIFIED | 12199 | 112 | 3.40 (2.36 to 4.91) | <0.001 |
| Landmark: excluding events before 12 months | PRE-SPECIFIED | 11783 | 69 | 2.27 (1.40 to 3.67) | <0.001 |
| Landmark: excluding events before 24 months | PRE-SPECIFIED | 9459 | 21 | 2.83 (1.21 to 6.64) | 0.017 |
| Restricted to female sets | PRE-SPECIFIED | 10442 | 92 | 2.91 (1.94 to 4.38) | <0.001 |
| Restricted to male sets | PRE-SPECIFIED | 1762 | 20 | 7.19 (2.99 to 17.29) | <0.001 |
| Excluding PNES-coded participants | PRE-SPECIFIED | 12149 | 107 | 3.72 (2.55 to 5.43) | <0.001 |
| Stricter outcome (criterion 1: two codes >=30 d apart, only) | PRE-SPECIFIED | NA | NA | NOT ESTIMABLE | NA |
| Adjusted for post-index encounters (CONSERVATIVE BOUND ONLY) | PRE-SPECIFIED | 12177 | 112 | 1.51 (0.97 to 2.37) | 0.069 |
| Controls restricted to top quartile of post-index encounters | PRE-SPECIFIED | 5096 | 80 | 2.08 (1.29 to 3.36) | 0.003 |
| Adjusted for pre-index encounters (legitimate confounder) | PROTOCOL-DERIVED | 12192 | 111 | 4.16 (2.65 to 6.53) | <0.001 |
| Stratified by matched set | PRE-SPECIFIED | 12203 | 112 | 3.91 (2.65 to 5.77) | <0.001 |
| IPTW on the propensity score | PRE-SPECIFIED | 12204 | 112 | 3.43 (2.38 to 4.95) | <0.001 |
| Full follow-up (no truncation) | PRE-SPECIFIED | 12204 | 171 | 4.23 (3.13 to 5.72) | <0.001 |
| 5-year truncation | PRE-SPECIFIED | 12204 | 142 | 3.72 (2.68 to 5.16) | <0.001 |
| Full-ratio sets only (1:4 complete) | POST HOC | 8896 | 88 | 3.38 (2.23 to 5.12) | <0.001 |
| Index year >= 2010 | POST HOC | 11859 | 107 | 3.33 (2.29 to 4.85) | <0.001 |

---

## 7b. Effect modification

| modifier | subgroup | n | events | estimate | interaction_p |
| --- | --- | --- | --- | --- | --- |
| Overall | Overall | 12204 | 112 | 3.40 (2.36 to 4.91) | NA |
| Sex | Female | 10442 | 92 | 2.91 (1.94 to 4.38) | 0.068 |
| Sex | Male | 1762 | 20 | 7.19 (2.99 to 17.29) | NA |
| Age at index | Age <35 y | 6085 | 59 | 2.42 (1.46 to 4.01) | 0.064 |
| Age at index | Age >=35 y | 6119 | 53 | 4.94 (2.85 to 8.55) | NA |
| BMI at index | BMI <35 | 5689 | 51 | 5.50 (3.12 to 9.71) | 0.023 |
| BMI at index | BMI >=35 | 6515 | 61 | 2.28 (1.39 to 3.73) | NA |
| Calendar period | Index <2015 | 2010 | 28 | 4.50 (2.12 to 9.56) | 0.418 |
| Calendar period | Index >=2015 | 10194 | 84 | 3.15 (2.07 to 4.78) | NA |
| Baseline surveillance | Pre-index encounters <2 | 5932 | 48 | 2.09 (0.28 to 15.38) | 0.230 |
| Baseline surveillance | Pre-index encounters >=2 | 6260 | 63 | 7.70 (3.79 to 15.65) | NA |

Subgroup hazard ratios are descriptive. Whether the effect differs is judged **only** by the interaction p-value, never by which subgroup reached significance. With 112 events these tests have low power, so a large p-value does not establish a uniform effect.

The one signal worth following up is **BMI (interaction p = 0.023)**: the association is stronger in patients with BMI <35 (5.54) than >=35 (2.29). Two readings compete, and this analysis cannot separate them. Either IIH coded in a non-obese patient is more often a secondary or miscoded intracranial hypertension with its own seizure risk, or obesity-related confounding dilutes the estimate in the high-BMI stratum. This is post hoc.

### Restricted mean time lost to seizure

| quantity | estimate |
| --- | --- |
| Non-IIH control | 5.16 (4.06 to 6.43) |
| IIH | 13.79 (10.12 to 17.84) |
| Difference (IIH - control) | 8.64 (4.70 to 12.93) |

Days spent in the post-seizure state per patient over three years. This requires no proportional-hazards assumption and treats death as a competing event, so it is a useful companion to the hazard ratio rather than a restatement of it.

---

## 7c. Missing data

| approach | n | ev | estimate | note |
| --- | --- | --- | --- | --- |
| Complete case | 12192 | 111 | 4.09 (2.60 to 6.43) | Drops 12 of 12204 rows. |
| Missing indicator | 12204 | 112 | 4.13 (2.63 to 6.49) | Biased in general; acceptable here only because missingness is an extract property. |
| Multiple imputation (m=10, PMM) | 12204 | 112 | 4.14 (2.64 to 6.51) | Imputation model includes the Nelson-Aalen hazard and event indicator so it is congenial with the outcome model. |

Complete-case, missing-indicator and multiple imputation agree to two decimal places. This is not a coincidence: only 12 of 12,204 rows are missing any adjustment-set variable. **Missing data is not a material threat to this analysis.**

What *is* material is structural absence, which imputation must never touch:

| variable | Non-IIH control | IIH | abs_difference | assessment |
| --- | --- | --- | --- | --- |
| age_index | 0.00 | 0.00 | 0.00 | comparable across arms |
| bmi_index | 0.00 | 0.00 | 0.00 | comparable across arms |
| sex | 0.00 | 0.00 | 0.00 | comparable across arms |
| index_year | 0.00 | 0.00 | 0.00 | comparable across arms |
| enc_pre12 | 0.06 | 0.22 | 0.16 | comparable across arms |
| enc_post | 0.20 | 0.33 | 0.13 | comparable across arms |
| osa | 0.00 | 0.00 | 0.00 | comparable across arms |
| htn | 0.00 | 0.00 | 0.00 | comparable across arms |
| pcos | 0.00 | 0.00 | 0.00 | comparable across arms |
| smoking | 4.47 | 1.28 | 3.19 | comparable across arms |
| alcohol | 100.00 | 21.38 | 78.62 | STRUCTURAL / strongly differential -- do NOT impute |
| followup_years | 0.00 | 0.00 | 0.00 | comparable across arms |

---

## 7d. Radiology free text (exploratory, not validated)

3,115 MRI reports link to 2,808 of 3,601 IIH cases and to **zero controls**, so nothing here can support a case-control comparison.

| finding | positive | negated | not_mentioned | pct_addressed |
| --- | --- | --- | --- | --- |
| encephalocele | 97 | 17 | 2694 | 4.1 |
| empty_sella | 597 | 83 | 2128 | 24.2 |
| sinus_stenosis | 92 | 68 | 2648 | 5.7 |
| onsd_distension | 28 | 28 | 2752 | 2.0 |
| globe_flattening | 104 | 77 | 2627 | 6.4 |
| skullbase_thin | 0 | 0 | 2808 | 0.0 |
| csf_leak | 84 | 19 | 2705 | 3.7 |
| tonsillar_desc | 91 | 71 | 2646 | 5.8 |

A negation-aware extractor classified each report as positive, negated, or **not mentioned** - the last being a distinct category, never a negative.

| finding | structured_assessed | text_addressed | newly_addressable | agree_both_assessed | disagree_both_assessed |
| --- | --- | --- | --- | --- | --- |
| encephalocele | 90 | 114 | 45 | 65 | 4 |
| empty_sella | 902 | 680 | 24 | 640 | 16 |
| sinus_stenosis | 978 | 160 | 47 | 37 | 6 |
| onsd_distension | 864 | 56 | 1 | 51 | 4 |
| globe_flattening | 382 | 181 | 27 | 152 | 2 |
| skullbase_thin | 36 | 0 | 0 | 0 | 0 |
| csf_leak | 2808 | 103 | 0 | 61 | 42 |

**The yield is modest.** Only 4.1% of reports discuss the skull base at all, so encephalocele assessability rises from 90 cases to about 135, not to thousands. Where both sources speak, agreement is high (65 of 69 for encephalocele). This does not revive the mediation aim.

No output of this extraction enters any model. `S23_radiology_review_sample.csv` contains 214 reports (all 97 text-positive plus stratified samples of the rest, with sampling fractions recorded) for blinded review before any of it is used.

---

## 7e. Medications: an empirical anchor for the tipping point (provisional)

The medication extract covers **2,821 of 9,742 matched controls (29%) and zero IIH cases**. It therefore still cannot support the acetazolamide-only restriction, time-varying treatment models or a marginal structural model - and acetazolamide does not appear anywhere in the extract.

Three checks pass cleanly:

- **Classification matches protocol section 4.2.** Gabapentin (2,971 rows) and pregabalin (742) are classified as gabapentinoids and not counted as ASMs; topiramate (458) is classified as IIH treatment; benzodiazepines are excluded. Zonisamide is counted.
- **No cohort contamination.** 59 IIH cases surfaced in the control extract; none was used as a matched control.
- **The pre-index ASM exclusion held.** Every discordant control below started their ASM after index.

### The finding that matters

**63 of 2821 controls with medication data (2.23%) received an unambiguous antiseizure medication but were never coded with epilepsy.** Levetiracetam (32) and lamotrigine (14) dominate.

Until now the tipping-point analysis was hypothetical. These are named patients, and their first ASM date gives a real event time rather than an invented one.

**Scenario 1 - observed candidates only:**

| pct_of_ASM_discordant_controls_assumed_true | controls_reclassified | events_added_in_window | hr | lo | hi | crosses_null |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | 0 | 0 | 3.40 | 2.36 | 4.91 | FALSE |
| 25 | 16 | 10 | 2.89 | 2.03 | 4.11 | FALSE |
| 50 | 32 | 20 | 2.50 | 1.77 | 3.52 | FALSE |
| 75 | 47 | 29 | 2.23 | 1.59 | 3.12 | FALSE |
| 100 | 63 | 40 | 1.98 | 1.42 | 2.75 | FALSE |

Even assuming every one is a true missed seizure, the association survives (1.98, 1.42-2.75).

**Scenario 2 - extrapolating the same rate to the 71% of controls with no medication data:**

| pct_assumed_true | observed_candidates_used | extrapolated_events_added | hr | lo | hi | crosses_null |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | 0 | 0 | 3.40 | 2.36 | 4.91 | FALSE |
| 50 | 20 | 75 | 1.25 | 0.92 | 1.70 | TRUE |
| 100 | 40 | 151 | 0.76 | 0.57 | 1.01 | TRUE |

Here the null **is** reached at about half. So the reassurance from scenario 1 is conditional on the medication-covered controls being representative, which is untested.

### The asymmetry that decides it

Both scenarios add hidden events to controls and none to cases, because **no case medications were extracted**. That is the worst case by construction and is almost certainly wrong - IIH patients also receive levetiracetam and lamotrigine for non-epilepsy reasons. If the ASM-without-diagnosis rate is similar in both arms the misclassification is non-differential and the hazard ratio moves very little.

The whole question turns on whether that rate differs by exposure, and this extract cannot answer it. **Extracting the same medication data for the 2,732 matched IIH cases is now the highest-value single addition to the study.**

---

## 8. Analyses that could NOT be done, and why

These were requested but are not supported by this export. None was approximated.

| Planned analysis | Why not |
| --- | --- |
| Cumulative IIH burden gradient (mild/moderate/severe) | No severity variable exists. Shunt/stent is a post-index decision and is not a baseline severity marker. |
| Restricted cubic spline for opening pressure | Recorded in 70% of cases; 42 events among those with a value. Knot placement would be set by a handful of events. A linear term is reported instead, and is null. |
| Time-varying treatment / marginal structural model | No medication start or stop dates exist. |
| Acetazolamide-only restriction | No per-drug data. |
| Encephalocele mediation (natural, interventional or separable effects) | Mediator measured in 2.5% of cases and 0% of controls; 8 events in the assessable subgroup. Not identifiable, not merely underpowered. Protocol v2.0 change #8 already suspends it. |
| Algorithm PPV, sensitivity, confusion matrix | No blinded review sample (v2.0 change #7). |
| Cohen's kappa (adjudication), imaging reader kappa | No double-read or overlap sample. |
| Stricter outcome (criterion 1 only) | `outcome_criterion` is populated for controls only. Applying it would drop control events while keeping every case event and would inflate the HR by construction. |
| GERD negative control | Never extracted. |
| Drug-resistant epilepsy, Engel class, lesionectomy outcomes | Not extracted. |
| Reverse cohort (epilepsy then IIH) | Requires an epilepsy-indexed cohort that does not exist here. |

---

## 9. Data quality findings

| id | severity | finding |
| --- | --- | --- |
| B1 | MAJOR | 1:4 matching NOT achieved: mean 3.57 controls/case, only 66.4% of sets are full |
| B2 | MAJOR | 869 IIH cases (6.5%) could not be matched and are excluded from all comparative analyses |
| B3 | MAJOR | Analytic counts do NOT reproduce protocol v2.0 section 6 |
| C1 | CRITICAL | 2087 IIH cases have last_encounter_date AFTER the data-freeze date (max 2038-09-21) |
| C2 | CRITICAL | Controls have NO date fields at all (last_encounter, first_encounter, death, DOB all blank) |
| D1 | CRITICAL | Supplied `status` never codes death in cases: 91 IIH cases have died_fu=1 but 0 have status=2 |
| E1 | MAJOR | Follow-up is markedly longer in cases (median 4.75 y) than controls (median 3.42 y) |
| F1 | CRITICAL | 37 variables are extracted for one cohort only |
| F2 | CRITICAL | Race was matched on but is unverifiable |
| F3 | MAJOR | smoking uses different encodings in the two cohorts (text in cases, 0/1/2 in controls) |
| G1 | CRITICAL | Encephalocele assessable in only 90/3601 cases (2.5%); 65 positive; 5 and 3 incident seizures in enceph+/enceph- |
| H1 | MAJOR | Opening pressure is recorded for 2517/3601 cases (70%) and is <25 cmH2O in 726 (29% of measured) |
| H2 | MAJOR | No severity (mild/moderate/severe), Frisen grade, perimetry, fulminant flag, symptom-onset interval, or ASM/treatment start-stop dates exist in this file |
| H3 | MAJOR | No validation sample and no double-read/adjudication overlap exist in this file |
| I1 | MAJOR | Post-index encounters: case median 81 vs control median 17 |

Full list, including detail and consequence, in `outputs/tables/S9_audit_findings.csv`.

---

## 10. Why this is not evidence that IIH causes epilepsy

1. **The exposure is a code, not a diagnosis.** Friedman adjudication was dropped. Among cases with a recorded opening pressure, 29% are below the 25 cmH2O diagnostic threshold. The cohort is 'patients coded as IIH'.
2. **Confounding by indication for investigation.** Both IIH and seizure prompt neuroimaging and neurology referral. Matching on age, sex and BMI does not close that path; the null negative control constrains it but does not eliminate it.
3. **The control event rate is low enough that small differential under-ascertainment reverses the finding** (section 6).
4. **Follow-up is not comparable** and case person-time is demonstrably contaminated by impossible dates.
5. **No mechanism is demonstrated.** The structural hypothesis (skull-base thinning and temporal encephalocele) is untestable in this data.
6. **Residual confounding** by sleep apnoea, PCOS and hypertension is present and unadjusted: these are imbalanced after matching (SMD 0.36, 0.16, 0.17) and were not matching targets.

The defensible claim is: *patients carrying an IIH diagnosis code have a substantially higher recorded rate of incident seizure and epilepsy than matched non-IIH patients, and this is not explained by the amount of healthcare contact alone.*

---

## 11. Reproducibility appendix

- **Seed:** 20250906 (set in `R/00_setup.R`)
- **R version:** R version 4.3.3 (2024-02-29)
- **Analysis date:** 2026-09-06 20:31
- **Key packages:**
  - survival 3.5.8
  - ggplot2 3.4.4
- **Raw data:** `data-raw/IIH_MASTER_cases_and_controls_2.csv`, opened read-only and never modified.
- **Pipeline:** `Rscript run_all.R` reruns everything from a clean session.

### Model formulas

```
Primary (corrected):  coxph(Surv(t0, t, ev) ~ iih, cluster = match_set, robust = TRUE)
                      t0 = 180/365.25, t = min(followup_years, 3)
Stratified:           coxph(Surv(t0, t, ev) ~ iih + strata(match_set))
IPTW:                 coxph(Surv(t0, t, ev) ~ iih, weights = stabilised trimmed IPTW,
                            cluster = match_set, robust = TRUE)
Fine-Gray:            coxph(Surv(fgstart, fgstop, fgstatus) ~ iih, weights = fgwt)
Propensity score:     glm(iih ~ age_index + bmi_index + sex + index_year, binomial)
```

### Exclusions applied inside this pipeline

- Rows with missing or non-positive follow-up.
- Unmatched IIH cases (n = 869) from all comparative analyses; retained for description.
- For the stratified model only: matched sets containing a single arm.

No other observations were dropped. Sentinel codes 88 and 99 were never converted to zeros.

