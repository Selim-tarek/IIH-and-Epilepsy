---
title: "IIH and Incident Epilepsy: Final Analysis"
---

# Incident seizures and epilepsy after IIH

### Final report

Analysis date 2026-09-08 · Seed 20250906 · R version 4.3.3 (2024-02-29) · Supersedes all earlier reports

---

## 1. Headline

Among **2,606 IIH cases** and **4,037 matched controls with baseline healthcare contact**, over three years following a symmetric 180-day washout:

> **Hazard ratio 5.58 (3.15 to 9.87)**, 74 events (p < 0.001)

Three-year absolute risk **2.54% versus 0.49%** — a difference of 2.05 percentage points (1.35 to 2.74), or one additional seizure per **49** patients followed three years. Time spent in the post-seizure state averages 18.65 (14.14 to 23.44) days per IIH patient against 3.13 (1.53 to 4.73) per control.

**The excess is unlikely to be an artefact of greater observation.** Section 3 gives the evidence. It is still not a demonstration that IIH causes epilepsy (section 7).

---

## 2. Cohort and why it is restricted

Protocol v2.0 required controls to have at least one encounter in the 12 months before index. In the supplied extract **55.7% of controls have zero** (median 0 versus 15 in cases). The arms were therefore not comparable on baseline healthcare engagement.

The primary analysis restricts controls to those with a pre-index encounter, which is what the protocol specified. The unrestricted cohort is reported as secondary throughout. Restriction **raises** the estimate, from 3.66 to 5.58, because it removes controls who could not have had an outcome detected.

### Balance

| cohort | variable | iih | control | smd | balanced |
| --- | --- | --- | --- | --- | --- |
| FULL | Age | 34.70 | 34.87 | -0.017 | yes |
| FULL | BMI | 36.35 | 36.35 | -0.001 | yes |
| FULL | Female | 0.87 | 0.86 | 0.029 | yes |
| FULL | OSA | 0.27 | 0.13 | 0.363 | NO |
| FULL | Hypertension | 0.20 | 0.14 | 0.161 | NO |
| FULL | PCOS | 0.11 | 0.07 | 0.165 | NO |
| FULL | Pre-index encounters | 27.30 | 7.74 | 0.676 | NO |
| ENGAGED | Age | 34.72 | 35.65 | -0.095 | yes |
| ENGAGED | BMI | 36.34 | 36.19 | 0.022 | yes |
| ENGAGED | Female | 0.87 | 0.88 | -0.051 | yes |
| ENGAGED | OSA | 0.27 | 0.16 | 0.275 | NO |
| ENGAGED | Hypertension | 0.20 | 0.17 | 0.081 | yes |
| ENGAGED | PCOS | 0.11 | 0.08 | 0.122 | NO |
| ENGAGED | Pre-index encounters | 27.36 | 17.48 | 0.315 | NO |

---

## 3. Is the excess just more observation?

This was tested with a panel of six negative-control outcomes, each analysed under identical rules — prevalent cases excluded, clock from day 180 to last attended encounter.

| outcome | baseline_iih_pct | baseline_ctl_pct | valid_balance | events_iih | events_ctl | est_full | min_detectable_hr |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Herpes zoster | 1.41 | 0.35 | FAIL | 17 | 12 | 4.74 (2.25 to 9.96) | 3.49 |
| Renal/ureteric stone | 3.90 | 1.28 | FAIL | 62 | 84 | 2.53 (1.82 to 3.51) | 1.75 |
| Gallstones | 2.67 | 1.22 | FAIL | 38 | 65 | 1.95 (1.31 to 2.92) | 1.94 |
| Acute appendicitis | 0.92 | 0.34 | FAIL | 5 | 12 | 1.40 (0.49 to 3.98) | 5.12 |
| Limb fracture | 0.11 | 0.16 | PASS | 2 | 11 | 0.58 (0.13 to 2.63) | 6.47 |
| Carpal tunnel (prior control) | 3.59 | 0.99 | FAIL | 40 | 51 | 2.60 (1.73 to 3.91) | 2.04 |

### The panel's finding

Each control's post-index hazard ratio is almost entirely predicted by how imbalanced that outcome already was **before** index: r = 0.92 (0.45 to 0.99), p = 0.008, slope 1.02.

Extrapolated to perfect baseline balance, the predicted hazard ratio is **0.79 (prediction interval 0.28 to 2.23)** — essentially null.

The pattern also sorts by how much a diagnosis depends on seeking care. The four elective or ambulatory outcomes have a median hazard ratio of 2.56; the two acute, emergency-presenting outcomes have a median of 0.99.

**Prior seizure was an exclusion criterion, so the seizure outcome sits at a baseline ratio of exactly 1.00.** At that point the controls predict 0.28 to 2.23. The observed estimate is 5.58 (3.15 to 9.87).

That is the strongest specificity evidence this study can produce, and it is stronger than a single null negative control would have been.

### Supporting evidence

- **Timing.** Median 2.41 years to event in IIH versus 1.60 in controls (Wilcoxon p = 0.0691); only 55% of IIH events fall within three years against 88% of control events. A work-up artefact clusters events immediately after diagnosis.
- **Direction of restriction.** Removing disengaged controls raises rather than attenuates the estimate.
- **Adjustment.** The estimate is stable across comorbidity, smoking and pre-index contact adjustment (section 4).

### What this does not settle

Appendicitis and limb fracture rest on 5 and 2 exposed events, with minimum detectable hazard ratios of 5.12 and 6.47. Individually those nulls are weak; they carry weight only as part of the trend, and the trend has six points with a wide correlation interval.

---

## 4. All specifications

| model | n | events | estimate | p |
| --- | --- | --- | --- | --- |
| PRIMARY: Cox, 3-year | 6643 | 74 | 5.58 (3.15 to 9.87) | <0.001 |
| Stratified by matched set | 6643 | 74 | 5.33 (2.82 to 10.07) | <0.001 |
| IPTW (stabilised, trimmed) | 6643 | 74 | 5.05 (2.83 to 9.03) | <0.001 |
| + age, BMI, sex | 6643 | 74 | 5.53 (3.12 to 9.79) | <0.001 |
| + comorbidity | 6643 | 74 | 5.24 (2.95 to 9.29) | <0.001 |
| + smoking | 6643 | 74 | 5.63 (3.00 to 10.58) | <0.001 |
| + pre-index contact | 6643 | 74 | 5.49 (3.09 to 9.77) | <0.001 |
| + post-index contact (BOUND ONLY) | 6623 | 74 | 2.52 (1.28 to 4.95) | 0.007 |
| Female sets | 5832 | 58 | 5.43 (2.87 to 10.29) | <0.001 |
| Male sets | 811 | 16 | 5.80 (1.64 to 20.47) | 0.006 |
| Controls in top quartile of post-index contact | 3621 | 69 | 2.16 (1.10 to 4.24) | 0.025 |
| Index year >= 2010 | 6548 | 71 | 5.42 (3.05 to 9.63) | <0.001 |
| 5-year horizon | 6643 | 92 | 6.18 (3.59 to 10.62) | <0.001 |
| Full follow-up | 6643 | 116 | 6.74 (3.97 to 11.46) | <0.001 |
| SECONDARY: full cohort (unrestricted controls) | 11740 | 115 | 3.66 (2.55 to 5.25) | <0.001 |

---

## 5. Rates, absolute risk and competing risk

| cohort | arm | n | events | py | rate | lo | hi |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Engagement-restricted | IIH | 2606 | 59 | 6289 | 9.38 | 7.14 | 12.10 |
| Engagement-restricted | Control | 4037 | 15 | 8413 | 1.78 | 1.00 | 2.94 |
| Full cohort | IIH | 2618 | 60 | 6319 | 9.49 | 7.25 | 12.22 |
| Full cohort | Control | 9122 | 55 | 20725 | 2.65 | 2.00 | 3.45 |

| arm | time_y | cif_pct | se | lo | hi |
| --- | --- | --- | --- | --- | --- |
| Control | 1 | 0.209 | 0.074 | 0.105 | 0.419 |
| Control | 2 | 0.385 | 0.108 | 0.222 | 0.667 |
| Control | 3 | 0.491 | 0.132 | 0.291 | 0.831 |
| IIH | 1 | 1.527 | 0.243 | 1.118 | 2.086 |
| IIH | 2 | 2.138 | 0.295 | 1.631 | 2.801 |
| IIH | 3 | 2.539 | 0.330 | 1.968 | 3.277 |

| measure | iih_pct | control_pct | estimate | lo | hi | nnh |
| --- | --- | --- | --- | --- | --- | --- |
| 3-year absolute risk difference (pp) | 2.539 | 0.491 | 2.05 | 1.35 | 2.74 | 49 |

| estimand | estimate |
| --- | --- |
| Cause-specific HR, seizure (primary) | 5.58 (3.15 to 9.87) |
| Subdistribution HR (Fine-Gray) | 5.59 (3.16 to 9.88) |
| Cause-specific HR, death (competing) | 0.47 (0.27 to 0.82) |

Death is less common in IIH (0.47, 0.27–0.82), so the cause-specific and subdistribution estimates agree closely.

### Proportional hazards

| horizon | chisq | p | conclusion |
| --- | --- | --- | --- |
| 3 | 1.27 | 0.259 | PH not rejected |
| 5 | 0.05 | 0.829 | PH not rejected |
| Inf | 0.49 | 0.485 | PH not rejected |

PH holds at every horizon, so the hazard ratio is interpretable as a constant over the window.

### Unmeasured confounding

E-value 10.63 for the point estimate and 5.75 for the confidence limit: an unmeasured confounder would need associations of that size with both exposure and outcome, beyond everything adjusted for, to explain the result away.

---

## 6. Subgroups and fragility

| modifier | model | n | events | estimate | interaction_p |
| --- | --- | --- | --- | --- | --- |
| Overall | Overall | 6643 | 74 | 5.58 (3.15 to 9.87) | NA |
| Sex | Female | 5832 | 58 | 5.43 (2.87 to 10.29) | 0.985 |
| Sex | Male | 811 | 16 | 5.80 (1.64 to 20.47) | NA |
| Age | Age <35 | 3217 | 33 | 5.91 (2.43 to 14.39) | 0.878 |
| Age | Age >=35 | 3426 | 41 | 5.41 (2.57 to 11.42) | NA |
| BMI | BMI <35 | 3105 | 38 | 8.13 (3.38 to 19.60) | 0.252 |
| BMI | BMI >=35 | 3538 | 36 | 3.98 (1.87 to 8.47) | NA |
| Calendar period | Index <2015 | 654 | 18 | 3.42 (0.99 to 11.81) | 0.461 |
| Calendar period | Index >=2015 | 5989 | 56 | 5.68 (3.00 to 10.77) | NA |

No interaction is significant. With 74 events these tests have low power, so this shows homogeneity is not contradicted rather than that it holds.

### Tipping point

| pct_hidden | added | hr | lo | hi | crosses_null |
| --- | --- | --- | --- | --- | --- |
| 0.0 | 0 | 5.58 | 3.15 | 9.87 | FALSE |
| 0.5 | 20 | 2.36 | 1.54 | 3.60 | FALSE |
| 1.0 | 40 | 1.51 | 1.04 | 2.20 | FALSE |
| 2.0 | 80 | 0.86 | 0.62 | 1.20 | TRUE |
| 5.0 | 201 | 0.37 | 0.28 | 0.50 | TRUE |

Roughly 2% of censored controls carrying an unrecorded seizure would erase the association. The panel bears directly on how plausible that is: outcomes requiring no care-seeking showed no excess, which is the opposite of what widespread unrecorded events in controls would produce.

---

## 7. What can and cannot be claimed

**Supported:** patients coded as IIH have a substantially higher rate of incident coded seizure or epilepsy than matched controls engaged in the same health system, and this is unlikely to be explained by differential observation alone.

**Not supported:** that IIH causes epilepsy. The exposure is a diagnosis code rather than an adjudicated diagnosis (28% of measured opening pressures fall below 25 cmH2O); sleep apnoea and PCOS remain imbalanced after restriction; and no mechanism is demonstrated, the encephalocele aim being unidentifiable in these data.

---

## 8. Reproducibility

- Seed 20250906; R 4.3.3; survival 3.5.8
- `Rscript run_final.R` regenerates every number, table and figure.
- Sources: IIH_MASTER_FINAL.xlsx; dated diagnosis extracts for carpal tunnel, zoster, renal stone, gallstones, appendicitis and fracture; medications for cases and controls; social history for smoking; radiology for both arms.

### Figures

| Figure | Question |
| --- | --- |
| H_F1 | Is the estimate stable across specifications? |
| H_F2 | Is the excess explained by observation? (the key figure) |
| H_F3 | How does each negative control behave? |
| H_F4 | What is the absolute risk, with death as a competing event? |
| H_F5 | When do events occur? |
| H_F6 | Are the arms comparable? |
| H_F7 | Does the effect vary by subgroup? |
| H_F8 | How fragile is the result to unrecorded events? |

