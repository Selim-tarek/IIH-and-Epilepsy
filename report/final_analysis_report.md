---
title: "IIH and Incident Epilepsy: Final Analysis"
---

# Incident seizures and epilepsy after IIH

### Final analysis report

**Source:** `IIH_MASTER_FINAL.xlsx` · **Cutoff:** 3 September 2026 · **Analysis date:** 2026-09-07 · **Seed:** 20250906 · **R:** R version 4.3.3 (2024-02-29)

---

## 1. Headline

Among **2,618 IIH cases** and **9,122 matched controls**, over the three years following a symmetric 180-day washout:

> **Hazard ratio 3.66 (2.55 to 5.25)**, 115 events (p < 0.001)

Three-year absolute risk 2.58% versus 0.74%: a difference of 1.84 percentage points (1.16 to 2.53), or one extra seizure per **54** patients followed three years. Over the same three years, time spent in the post-seizure state averages **18.73 (13.92 to 23.79) days** per IIH patient against **4.75 (3.46 to 6.03) days** per control -- an excess of **13.98 (9.30 to 19.06) days** (all from Table F_T9).

**This is an association. It is not a demonstration that IIH causes epilepsy** (section 10).

---

## 2. What this workbook fixed

The earlier export had four defects that this one resolves. They are listed because each changed an estimate.

| Defect in the earlier export | Resolution here | Effect |
| --- | --- | --- |
| 180-day washout applied to cases only; earliest case event day 183, earliest control event day 16 | Applied to **both** arms (earliest event day 183 vs 187) | Removes an artefact that biased the HR toward the null |
| Person-time to 2038 from scheduled future appointments | Person-time to last **attended** encounter, cutoff 3 Sep 2026 | Removes inflated denominators |
| Controls carried no dates; censoring unverifiable | Controls carry last encounter and death date; `censoring_verifiable` = 1 for all 11,740 | Censoring is auditable in both arms |
| Competing-event flag coded death for controls only | Rebuilt from death dates present in both arms | Death HR moves from an implausible 0.23 to 0.57 |

The supplied `e3`/`t3` and `e5`/`t5` columns reproduce exactly from `t_y` and `event`; the pipeline asserts this rather than trusting it.

---

## 3. Estimand

| Element | Specification |
| --- | --- |
| Population | Matchable IIH-coded patients aged 13-60 and their matched non-IIH controls |
| Exposure | An IIH diagnosis code, **not chart-adjudicated IIH** |
| Outcome | First incident coded seizure/epilepsy, identical algorithm in both arms |
| Time zero | Day 180 after index (index = diagnostic LP; controls inherit it) |
| Contrast | Cause-specific hazard ratio over 3 years |
| Competing event | Death (Aalen-Johansen for absolute risk) |
| Censoring | Event, death, or last attended encounter, whichever first |

---

## 4. Incidence and models

| horizon | cohort | n | events | person_years | rate_per_1000py | rate_lo | rate_hi | irr | irr_lo | irr_hi |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 3 years (primary) | Non-IIH control | 9122 | 55 | 20724.9 | 2.65 | 2.00 | 3.45 | NA | NA | NA |
| 3 years (primary) | IIH | 2618 | 60 | 6319.3 | 9.49 | 7.25 | 12.22 | 3.58 | 2.44 | 5.26 |
| 5 years | Non-IIH control | 9122 | 61 | 27495.1 | 2.22 | 1.70 | 2.85 | NA | NA | NA |
| 5 years | IIH | 2618 | 77 | 8851.1 | 8.70 | 6.87 | 10.87 | 3.92 | 2.77 | 5.58 |
| full follow-up | Non-IIH control | 9122 | 64 | 34321.0 | 1.86 | 1.44 | 2.38 | NA | NA | NA |
| full follow-up | IIH | 2618 | 102 | 12796.6 | 7.97 | 6.50 | 9.68 | 4.27 | 3.10 | 5.94 |

| model | n | events | estimate | p |
| --- | --- | --- | --- | --- |
| Cox, 3-year (PRIMARY) | 11740 | 115 | 3.66 (2.55 to 5.25) | 0 |
| Cox stratified by matched set, 3 y | 11740 | 115 | 4.17 (2.84 to 6.13) | 0 |
| Cox, 3 y, IPTW (stabilised, trimmed) | 11740 | 115 | 3.69 (2.57 to 5.30) | 0 |
| Cox, 3 y, + age/BMI/sex | 11740 | 115 | 3.67 (2.54 to 5.29) | 0 |
| Cox, 5-year | 11740 | 138 | 4.09 (2.93 to 5.70) | 0 |
| Cox, full follow-up | 11740 | 166 | 4.67 (3.43 to 6.35) | 0 |

### Proportional hazards

| horizon_y | chisq | df | p_ph | conclusion |
| --- | --- | --- | --- | --- |
| 3 | 3.74 | 1 | 0.053 | PH not rejected |
| 5 | 0.10 | 1 | 0.746 | PH not rejected |
| Inf | 1.19 | 1 | 0.275 | PH not rejected |

**PH now holds at every horizon, including full follow-up.** In the earlier export it failed (p = 0.031). That violation was an artefact of contaminated person-time, not a feature of the biology — a good illustration of why the data-quality work mattered.

### Competing risk

| estimand | estimate | interpretation |
| --- | --- | --- |
| Cause-specific HR, seizure (PRIMARY) | 3.66 (2.55 to 5.25) | Rate of seizure among those still alive and seizure-free -- aetiological |
| Cause-specific HR, death (competing event) | 0.57 (0.34 to 0.95) | Whether IIH also alters mortality; interpret the seizure estimands against it |
| Subdistribution HR, seizure (Fine-Gray) | 3.66 (2.55 to 5.26) | Effect on cumulative INCIDENCE with death retained in the risk set -- prognostic |

Cause-specific and subdistribution estimates are nearly identical because death is uncommon over three years. The death hazard is now 0.57 (0.34-0.95) rather than the earlier implausible 0.23, consistent with IIH being a disease of otherwise-healthier younger adults.

---

## 5. Is this just healthcare contact?

IIH patients have far more clinical contact (post-index encounters 171 vs 35), so they have more opportunity to be **detected**. Three lines of evidence:

**1. The negative control is null.**

| outcome | n | events | estimate | p |
| --- | --- | --- | --- | --- |
| Incident seizure/epilepsy (positive outcome) | 10101 | 95 | 3.19 (2.14 to 4.76) | <0.001 |
| Incident carpal tunnel syndrome (NEGATIVE CONTROL) | 10101 | 35 | 1.23 (0.59 to 2.58) | 0.580 |

Carpal tunnel syndrome has no plausible causal link to IIH and is ascertained identically. If the design were measuring contact, it would be elevated. It is not. This is the single strongest argument that the result is not pure ascertainment.

**2. Risk is sustained, not front-loaded.**

| period | events | estimate |
| --- | --- | --- |
| 0.5-2 y | 99 | 3.77 (2.55 to 5.59) |
| 2-5 y | 39 | 5.07 (2.64 to 9.73) |
| >5 y | 28 | 14.28 (4.13 to 49.37) |

A work-up detection artefact would spike early and decay.

**3. Adjusting for contact attenuates but does not abolish it.**

Adjusted for post-index encounters: 1.60 (1.02 to 2.51). Reported as a **conservative lower bound only** — post-index encounters are a consequence of both exposure and outcome, so conditioning on them is mediator adjustment and opens a collider path.

---

## 6. Balance

| variable | iih | control | smd | balance |
| --- | --- | --- | --- | --- |
| Age at index, y | 34.7 (10.2) | 34.9 (9.7) | -0.017 | balanced (|SMD|<0.1) |
| BMI, kg/m2 | 36.3 (7.3) | 36.4 (6.6) | -0.001 | balanced (|SMD|<0.1) |
| Female | 2273 (86.8%) | 7828 (85.8%) | 0.029 | balanced (|SMD|<0.1) |
| Index year | 2019.5 (4.4) | 2019.4 (4.5) | 0.025 | balanced (|SMD|<0.1) |
| Obstructive sleep apnoea | 702 (26.8%) | 1151 (12.6%) | 0.363 | IMBALANCED |
| Hypertension | 520 (19.9%) | 1264 (13.9%) | 0.161 | IMBALANCED |
| PCOS | 292 (11.2%) | 593 (6.5%) | 0.165 | IMBALANCED |
| Encounters, 12 mo pre-index | 27.3 (36.1) | 7.7 (19.3) | 0.676 | IMBALANCED |
| Encounters post-index (POST-EXPOSURE) | 171.4 (232.9) | 35.1 (57.8) | 0.804 | IMBALANCED |
| Post-washout follow-up, y (POST-EXPOSURE) | 4.9 (4.0) | 3.8 (3.1) | 0.315 | IMBALANCED |

Matched targets are balanced (propensity c-statistic 0.513). Sleep apnoea, hypertension and PCOS were **not** matching targets, remain imbalanced, and are unadjusted residual confounders.

---

## 6b. Multivariable Cox regression

Matching handles age, sex, BMI and index year. It does **not** handle sleep apnoea, hypertension or PCOS, which were never matching targets and remain imbalanced. This section adjusts them and reports every coefficient.

### Smoking cannot be adjusted for

Detailed smoking status (Never / Former / Current) is recorded for IIH cases only; **all 9,122 controls are coded Unknown**. Smoking is therefore perfectly nested within the exposure - a Current or Former smoker can only be a case - so its coefficients are unidentified. Including it does not adjust for smoking; it re-estimates the exposure effect inside a case-only stratum and inflates the exposure standard error (the first fit hit separation and a singular information matrix). It is excluded from every model, and residual confounding by smoking therefore remains.

### Degrees of freedom

| quantity | value |
| --- | --- |
| Events at 3 years | 114.0 |
| Parameters in the full model | 8.0 |
| Events per parameter | 14.2 |
| Rule-of-thumb minimum | 10.0 |

### Exposure estimate across specifications

| model | n | events | estimate | p |
| --- | --- | --- | --- | --- |
| Crude (matched design only) -- PRIMARY | 11740 | 115 | 3.66 (2.55 to 5.25) | <0.001 |
| Adjusted: + age, BMI, sex, OSA, HTN, PCOS | 11740 | 115 | 3.48 (2.41 to 5.04) | <0.001 |
| Adjusted: + pre-index healthcare contact | 11728 | 114 | 4.27 (2.68 to 6.80) | <0.001 |
| Adjusted, stratified by matched set | 11728 | 114 | 5.15 (2.85 to 9.32) | <0.001 |

Adjustment does not weaken the association. Adding comorbidity moves it slightly down (3.48); adding pre-index healthcare contact moves it up (4.27), which is what a confounder suppressing the estimate looks like - controls with more baseline contact are more likely to have an event detected.

### Full multivariable model

| term | estimate | se | z | p_fmt |
| --- | --- | --- | --- | --- |
| iih | 4.27 (2.68 to 6.80) | 0.252 | 6.10 | <0.001 |
| age_index | 0.98 (0.97 to 1.00) | 0.010 | -1.80 | 0.071 |
| bmi_index | 0.99 (0.96 to 1.02) | 0.014 | -0.78 | 0.435 |
| sexM | 1.19 (0.70 to 2.03) | 0.261 | 0.63 | 0.526 |
| osa | 1.37 (0.84 to 2.21) | 0.245 | 1.27 | 0.203 |
| htn | 1.30 (0.76 to 2.20) | 0.252 | 0.96 | 0.337 |
| pcos | 0.75 (0.36 to 1.55) | 0.376 | -0.78 | 0.434 |
| log_enc_pre | 0.89 (0.75 to 1.06) | 0.086 | -1.30 | 0.194 |

No covariate other than the exposure reaches significance. **Covariate hazard ratios are adjusted associations, not causal effects of those covariates** - the model is specified to estimate the IIH effect, not theirs.

Post-index encounters are deliberately excluded: they are a consequence of both exposure and outcome, so adjusting for them is mediator adjustment (reported separately as a conservative bound in section 9).

### Diagnostics

**Proportional hazards, per term:**

| term | chisq | df | p | conclusion |
| --- | --- | --- | --- | --- |
| iih | 4.23 | 1 | 0.040 | PH VIOLATED |
| age_index | 0.94 | 1 | 0.334 | PH not rejected |
| bmi_index | 0.53 | 1 | 0.465 | PH not rejected |
| sex | 2.70 | 1 | 0.100 | PH not rejected |
| osa | 3.17 | 1 | 0.075 | PH not rejected |
| htn | 0.44 | 1 | 0.509 | PH not rejected |
| pcos | 0.02 | 1 | 0.882 | PH not rejected |
| log_enc_pre | 4.15 | 1 | 0.042 | PH VIOLATED |
| GLOBAL | 10.27 | 8 | 0.247 | PH not rejected |

The global test is not rejected (p = 0.247), but the exposure term is borderline at three years (p = 0.040; the univariable test gives p = 0.053). It is clean at five years and over full follow-up. The hazard ratio should therefore be read as an average over the three-year window, and the restricted mean time lost (section 1) is the assumption-free companion that does not depend on proportionality at all.

**Linearity of continuous covariates:**

| covariate | knots | lrt_chisq | df | p_nonlinearity | conclusion |
| --- | --- | --- | --- | --- | --- |
| age_index | 21.2, 34.9, 48.1 | 0.04 | 1 | 0.834 | linear term adequate |
| bmi_index | 29.1, 35.7, 46 | 0.06 | 1 | 0.810 | linear term adequate |

Linear terms are adequate; no spline is warranted.

**Collinearity and influence:**

| term | vif | interpretation |
| --- | --- | --- |
| iih | 1.36 | acceptable |
| age_index | 1.10 | acceptable |
| bmi_index | 1.13 | acceptable |
| sexM | 1.11 | acceptable |
| osa | 1.19 | acceptable |
| htn | 1.13 | acceptable |
| pcos | 1.05 | acceptable |
| log_enc_pre | 1.41 | acceptable |

All variance inflation factors are near 1. The most influential single patient moves the IIH log hazard ratio by 5.37% of its value, and no patient exceeds 10%: the result is not driven by any individual.

**Joint tests by covariate block:**

| block | df | wald_chisq | p |
| --- | --- | --- | --- |
| Exposure (IIH) | 1 | 37.21 | 0.000 |
| Matched covariates | 3 | 5.32 | 0.149 |
| Comorbidity | 3 | 4.49 | 0.213 |
| Pre-index healthcare contact | 1 | 1.69 | 0.194 |

Only the exposure block carries information. The covariates are included because they are confounders, not because they predict the outcome.

---

## 7. Effect modification

| modifier | subgroup | n | events | estimate | interaction_p |
| --- | --- | --- | --- | --- | --- |
| Overall | Overall | 11740 | 115 | 3.66 (2.55 to 5.25) | NA |
| Sex | Female | 10101 | 95 | 3.19 (2.14 to 4.76) | 0.094 |
| Sex | Male | 1639 | 20 | 7.22 (3.02 to 17.26) | NA |
| Age at index | Age <35 y | 5876 | 61 | 2.59 (1.58 to 4.24) | 0.053 |
| Age at index | Age >=35 y | 5864 | 54 | 5.40 (3.11 to 9.36) | NA |
| BMI at index | BMI <35 | 5412 | 51 | 5.88 (3.32 to 10.42) | 0.028 |
| BMI at index | BMI >=35 | 6328 | 64 | 2.52 (1.56 to 4.07) | NA |
| Calendar period | Index <2015 | 1873 | 30 | 3.83 (1.85 to 7.93) | 0.919 |
| Calendar period | Index >=2015 | 9867 | 85 | 3.67 (2.42 to 5.56) | NA |
| Baseline surveillance | Pre-index enc <2 | 5652 | 47 | 2.30 (0.31 to 17.06) | 0.246 |
| Baseline surveillance | Pre-index enc >=2 | 6076 | 67 | 8.06 (3.97 to 16.35) | NA |

Subgroup HRs are descriptive; only the interaction p-value tests modification. The BMI interaction (p = 0.028) is the one signal worth pursuing: the association is stronger below BMI 35. Either IIH coded in a non-obese patient is more often secondary or miscoded intracranial hypertension carrying its own seizure risk, or obesity-related confounding dilutes the high-BMI stratum. This analysis cannot separate them. Post hoc.

---

## 8. What would overturn this

### Tipping point

| pct_censored_controls_with_hidden_seizure | hidden_events_added | hr | lo | hi | crosses_null |
| --- | --- | --- | --- | --- | --- |
| 0.0 | 0 | 3.66 | 2.55 | 5.25 | FALSE |
| 0.5 | 45 | 1.99 | 1.45 | 2.75 | FALSE |
| 1.0 | 91 | 1.37 | 1.01 | 1.85 | FALSE |
| 2.0 | 181 | 0.84 | 0.63 | 1.11 | TRUE |
| 5.0 | 453 | 0.38 | 0.29 | 0.50 | TRUE |
| 10.0 | 907 | 0.20 | 0.15 | 0.26 | TRUE |

About **2%** of censored controls carrying an unrecorded seizure would erase the association — a consequence of only 64 control events among 9,122 controls.

### An empirical anchor from the medication extract

60 of 2657 covered controls (2.26%) received an unambiguous antiseizure medication without ever being coded with epilepsy. These are named patients with real first-ASM dates.

| pct_of_ASM_discordant_assumed_true | events_added | hr | lo | hi | crosses_null |
| --- | --- | --- | --- | --- | --- |
| 0 | 0 | 3.66 | 2.55 | 5.25 | FALSE |
| 25 | 9 | 3.14 | 2.21 | 4.45 | FALSE |
| 50 | 20 | 2.68 | 1.91 | 3.75 | FALSE |
| 75 | 30 | 2.36 | 1.70 | 3.28 | FALSE |
| 100 | 39 | 2.13 | 1.55 | 2.94 | FALSE |

Assuming **every** one is a true missed seizure, the association survives (2.13, 1.55-2.94).

| pct_assumed_true | extrapolated_added | hr | lo | hi | crosses_null |
| --- | --- | --- | --- | --- | --- |
| 0 | 0 | 3.66 | 2.55 | 5.25 | FALSE |
| 50 | 73 | 1.35 | 1.00 | 1.82 | TRUE |
| 100 | 146 | 0.82 | 0.62 | 1.09 | TRUE |

Extrapolating the same rate to controls with no medication data reaches the null at about half. **Both scenarios add hidden events to controls and none to cases**, because no case medications were extracted — a worst case by construction. If IIH patients have a similar ASM-without-diagnosis rate, the misclassification is non-differential and the HR barely moves.

### E-value

| quantity | value | plain_language |
| --- | --- | --- |
| E-value, point estimate | 6.78 | An unmeasured confounder would need to be associated with BOTH IIH and seizure by a risk ratio of at least 6.78 each, beyond age, sex and BMI, to explain the estimate away. |
| E-value, CI limit nearest the null | 4.54 | To pull the confidence interval to the null it would need associations of at least 4.54 each. |

### Outcome misclassification

| sensitivity_iih | sensitivity_control | scenario | corrected_IRR |
| --- | --- | --- | --- |
| 1.0 | 1.0 | non-differential | 3.58 |
| 0.9 | 0.9 | non-differential | 3.58 |
| 0.8 | 0.8 | non-differential | 3.58 |
| 0.9 | 0.7 | DIFFERENTIAL (favours exposed detection) | 2.78 |
| 0.9 | 0.6 | DIFFERENTIAL (favours exposed detection) | 2.39 |

Non-differential misclassification does not move a rate ratio. Only differential detection does.

---

## 9. Sensitivity analyses

| analysis | status | n | events | estimate | p |
| --- | --- | --- | --- | --- | --- |
| Primary: Cox, 3-year | PRE-SPECIFIED | 11740 | 115 | 3.66 (2.55 to 5.25) | <0.001 |
| Landmark: further 1 year(s) after washout | PRE-SPECIFIED | 10256 | 63 | 3.21 (1.97 to 5.24) | <0.001 |
| Landmark: further 2 year(s) after washout | PRE-SPECIFIED | 7829 | 39 | 5.07 (2.64 to 9.73) | <0.001 |
| Female sets only | PRE-SPECIFIED | 10101 | 95 | 3.19 (2.14 to 4.76) | <0.001 |
| Male sets only | PRE-SPECIFIED | 1639 | 20 | 7.22 (3.02 to 17.26) | <0.001 |
| Stratified by matched set | PRE-SPECIFIED | 11740 | 115 | 4.17 (2.84 to 6.13) | <0.001 |
| IPTW on propensity score | PRE-SPECIFIED | 11740 | 115 | 3.69 (2.57 to 5.30) | <0.001 |
| Adjusted for pre-index encounters (valid confounder) | PROTOCOL-DERIVED | 11728 | 114 | 4.41 (2.80 to 6.97) | <0.001 |
| Adjusted for post-index encounters (CONSERVATIVE BOUND ONLY) | PRE-SPECIFIED | 11713 | 115 | 1.60 (1.02 to 2.51) | 0.039 |
| Controls restricted to top quartile of post-index encounters | PRE-SPECIFIED | 4946 | 83 | 2.30 (1.42 to 3.73) | <0.001 |
| Full 1:4 sets only | POST HOC | 8050 | 88 | 3.41 (2.25 to 5.16) | <0.001 |
| Index year >= 2010 | POST HOC | 11404 | 109 | 3.67 (2.53 to 5.32) | <0.001 |
| 5-year horizon | PRE-SPECIFIED | 11740 | 138 | 4.09 (2.93 to 5.70) | <0.001 |
| Full follow-up | PRE-SPECIFIED | 11740 | 166 | 4.67 (3.43 to 6.35) | <0.001 |

---

## 10. Why this is not proof that IIH causes epilepsy

1. **The exposure is a code, not a diagnosis.** Friedman adjudication was dropped; among cases with a recorded opening pressure, 28% fall below the 25 cmH2O threshold.
2. **Confounding by indication for investigation.** Both IIH and seizure prompt neuroimaging and neurology referral; matching on age, sex and BMI does not close that path.
3. **Control event rates are low enough that ~2% differential under-ascertainment reverses the finding**, and the medication data show a real mechanism by which that could happen.
4. **Follow-up remains unequal** (median 4.9 vs 3.8 years), which is why the estimand is truncated.
5. **No mechanism is demonstrated.** The encephalocele hypothesis is untestable here (section 11).
6. **Residual confounding** by sleep apnoea (SMD 0.36), PCOS (0.17) and hypertension (0.16) is present and unadjusted.

The defensible claim: *patients carrying an IIH diagnosis code have a substantially higher recorded rate of incident seizure and epilepsy than matched non-IIH patients, and this is not explained by healthcare contact alone.*

---

## 11. Still not possible with this workbook

| Analysis | Blocker |
| --- | --- |
| Encephalocele mediation | Assessable in a small minority of cases and in **zero** controls. Not identifiable, not merely underpowered. |
| Severity gradient (mild/moderate/severe) | No severity variable. Shunt/stent is a post-index decision carrying immortal time. |
| Opening-pressure splines | Too few events to place knots; linear term reported and null. |
| Time-varying treatment / marginal structural model | No medication start-stop data for cases. |
| Acetazolamide-only restriction | No case medications, and acetazolamide appears **nowhere** in the extract. |
| Algorithm PPV, sensitivity, reliability kappas | No blinded review sample and no double-read overlap. |
| GERD negative control; male carpal tunnel | Never extracted. |
| Reverse cohort (epilepsy then IIH) | Requires an epilepsy-indexed cohort. |

---

## 12. Reproducibility

- Seed 20250906; R 4.3.3; `survival` 3.5.8
- Raw workbook opened read-only and never modified.
- Run `Rscript run_final.R` to regenerate every number, table and figure.

### Model formulas

```
Primary:      coxph(Surv(t, ev) ~ iih, cluster = match_set, robust = TRUE)
              t = pmin(t_y, 3); t_y already runs from day 180
Stratified:   coxph(Surv(t, ev) ~ iih + strata(match_set))
IPTW:         coxph(Surv(t, ev) ~ iih, weights = stabilised trimmed IPTW,
                    cluster = match_set, robust = TRUE)
Fine-Gray:    coxph(Surv(fgstart, fgstop, fgstatus) ~ iih, weights = fgwt)
Propensity:   glm(iih ~ age_index + bmi_index + sex + index_year, binomial)
```

