---
title: "IIH and Incident Epilepsy: Rebuilt Analysis"
---

# Rebuilt analysis, all sources ingested

Analysis date 2026-09-08. Seed 20250906. Supersedes the F-series.

## 1. What changed in this rebuild

| Correction | Consequence |
| --- | --- |
| Carpal tunnel was censored at `t_y`, which is censored at the SEIZURE. Carpal diagnoses occurring after a patient's seizure were discarded. | Each outcome now runs on its own clock, to last attended encounter. |
| Carpal prevalence at baseline had never been examined. | It is 3.6x commoner in cases BEFORE index. The negative control was not balanced to begin with. |
| Protocol v2.0 required controls to have >=1 pre-index encounter. 55.7% have zero. | An engagement-restricted cohort is analysed alongside the full one. |
| Case medications went from 53 to 2,187 patients (83.5%); smoking now covers 89.8% of controls; radiology now exists for both arms. | Smoking is adjustable; medication coverage is no longer 2% vs 29%. |

## 2. Results

| cohort | outcome | model | events_iih | events_ctl | estimate | p |
| --- | --- | --- | --- | --- | --- | --- |
| FULL | seizure | Cox, 3-year | 60 | 55 | 3.66 (2.55 to 5.25) | <0.001 |
| FULL | seizure | Cox, stratified | 60 | 55 | 4.17 (2.84 to 6.13) | <0.001 |
| FULL | seizure | Cox, adjusted | 60 | 55 | 3.48 (2.41 to 5.04) | <0.001 |
| FULL | seizure | Cox, adjusted + smoking | 60 | 55 | 3.30 (2.21 to 4.93) | <0.001 |
| FULL | carpal | NEGATIVE CONTROL, 3-year | 40 | 51 | 2.60 (1.73 to 3.91) | <0.001 |
| FULL | carpal | NEGATIVE CONTROL, stratified | 40 | 51 | 2.65 (1.71 to 4.10) | <0.001 |
| ENGAGED | seizure | Cox, 3-year | 59 | 15 | 5.58 (3.15 to 9.87) | <0.001 |
| ENGAGED | seizure | Cox, stratified | 59 | 15 | 5.33 (2.82 to 10.07) | <0.001 |
| ENGAGED | seizure | Cox, adjusted | 59 | 15 | 5.24 (2.95 to 9.29) | <0.001 |
| ENGAGED | seizure | Cox, adjusted + smoking | 59 | 15 | 5.63 (3.00 to 10.58) | <0.001 |
| ENGAGED | carpal | NEGATIVE CONTROL, 3-year | 40 | 20 | 2.66 (1.58 to 4.47) | <0.001 |
| ENGAGED | carpal | NEGATIVE CONTROL, stratified | 40 | 20 | 2.83 (1.58 to 5.06) | <0.001 |

## 3. Incidence rates

| outcome | cohort | n | events | py | rate | lo | hi |
| --- | --- | --- | --- | --- | --- | --- | --- |
| seizure | FULL | 2618 | 60 | 6319 | 9.49 | 7.25 | 12.22 |
| seizure | FULL | 9122 | 55 | 20725 | 2.65 | 2.00 | 3.45 |
| carpal | FULL | 2524 | 40 | 6159 | 6.49 | 4.64 | 8.84 |
| carpal | FULL | 9032 | 51 | 20518 | 2.49 | 1.85 | 3.27 |
| seizure | ENGAGED | 2606 | 59 | 6289 | 9.38 | 7.14 | 12.10 |
| seizure | ENGAGED | 4037 | 15 | 8413 | 1.78 | 1.00 | 2.94 |
| carpal | ENGAGED | 2512 | 40 | 6128 | 6.53 | 4.66 | 8.89 |
| carpal | ENGAGED | 3959 | 20 | 8224 | 2.43 | 1.49 | 3.76 |

## 4. The negative control

Carpal tunnel is elevated in BOTH cohorts (2.60 and 2.66) and the engagement restriction does not move it, while it raises the seizure estimate from 3.66 to 5.58. So baseline disengagement of controls explains part of the picture but not the carpal excess.

### Baseline prevalence

| cohort | arm | n | prevalent_carpal | pct |
| --- | --- | --- | --- | --- |
| FULL | IIH | 2618 | 94 | 3.59 |
| FULL | Control | 9122 | 90 | 0.99 |
| ENGAGED | IIH | 2606 | 94 | 3.61 |
| ENGAGED | Control | 4037 | 78 | 1.93 |

The imbalance exists before index, so it cannot be caused by IIH or by post-index surveillance. It reflects a pre-existing difference in who these patients are. That makes carpal tunnel a poor negative control: it violates the requirement of no association with the exposure other than through bias.

### Calibration

| cohort | seizure | negative_control | calibrated |
| --- | --- | --- | --- |
| FULL | 3.66 (2.55 to 5.25) | 2.60 (1.73 to 3.91) | 1.41 (0.82 to 2.42) |
| ENGAGED | 5.58 (3.15 to 9.87) | 2.66 (1.58 to 4.47) | 2.10 (0.97 to 4.54) |


## 5. Balance

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

## 6. Proportional hazards (engagement-restricted)

| horizon | chisq | p | conclusion |
| --- | --- | --- | --- |
| 3 | 1.27 | 0.259 | PH not rejected |
| 5 | 0.05 | 0.829 | PH not rejected |
| Inf | 0.49 | 0.485 | PH not rejected |

## 7. Absolute risk (engagement-restricted)

| cohort | iih_risk_pct | control_risk_pct | diff_pp | lo | hi | nnh |
| --- | --- | --- | --- | --- | --- | --- |
| ENGAGED | 2.54 | 0.49 | 2.05 | 1.35 | 2.74 | 49 |

## 8. What this means

The seizure association is robust and gets STRONGER when controls are restricted to those actually in care: 5.58 (3.15-9.87). That is the estimate least contaminated by comparing engaged patients with disengaged ones.

But the negative control remains elevated at 2.66 and is already imbalanced at baseline, so it cannot be used to certify specificity. The calibrated estimate, 2.10 (0.97-4.54), is the conservative reading and is borderline.

The honest position: a substantial association that survives every adjustment available, alongside a negative control that fails its own validity check and therefore cannot settle the surveillance-bias question either way.

