# Final results — complete from-scratch run

**Run date:** 2026-09-18 · **Master:** `IIH_MASTER_FINAL.xlsx` · **Freeze:** 3 September 2026 · **Seed:** 20250906

Every number below was produced by a single uninterrupted execution of
`run_final.sh`, beginning from the raw exports. Derived datasets were deleted
before the run; nothing was inherited from any earlier analysis. Raw files were
opened read-only.

---

## 0. Data provenance

Verified by `R/Z0_provenance.R` before any analysis ran. The gate fails closed:
a missing input, or a case encounter file at or below Excel's 1,048,575-row
ceiling (which would indicate silent truncation), halts the run.

| File | Rows | md5 (12) | Role |
|---|---|---|---|
| IIH_MASTER_FINAL.xlsx | — | b314ba066d03 | master cohort, index dates, matching vars, outcome |
| MDE_Encounters_types_full.csv | 1199125 | 79ca279ce326 | dated encounters + Encounter Type, CASES |
| MDE_Encounters_controls_typed.csv | 995409 | 84fc9b547c35 | dated encounters + Encounter Type, COMPARATORS |
| MDE_Flowsheets_BMI.csv | 387125 | 47e515642d08 | dated BMI, both arms |
| SZ_dx_62.csv | 2591 | 91adb958b138 | seizure diagnosis codes |
| SZ_conditions_10.csv | 258 | e4a35762e95c | seizure conditions |
| MDE_Medications_cases_22.csv | 236973 | fe2b40d81bd8 | medications, cases |
| IIH_medications_detail.csv | 27354 | 486ae53d80bf | medications, comparators |
| MDE_Diagnosis_carpal_12.csv | 2187 | 7471946e22aa | carpal tunnel (negative control) |
| NC_dx_21.csv | 566 | e0c55626c6ad | negative control outcome |
| NC_dx_58.csv | 5792 | e06020569cfc | negative control outcome |
| NC_dx_59.csv | 1996 | fd9d42816630 | negative control outcome |
| NC_dx_60.csv | 325 | 0ced1e4a0adc | negative control outcome |
| NC_dx_61.csv | 602 | 864fb78fb3a6 | negative control outcome |
| NC2_dx_13.csv | 12157 | 6751817cebc7 | negative control outcome |
| NC2_dx_14.csv | 1978 | 645701e75df5 | negative control outcome |
| NC2_dx_16.csv | 3392 | c4e82743d0a0 | negative control outcome |
| NC2_dx_17.csv | 1101 | 184924054785 | negative control outcome |
| NC2_dx_18.csv | 624 | ba29629d257a | negative control outcome |
| NC2_dx_20.csv | 2876 | e2c154c3f647 | negative control outcome |


Two superseded files remain in `data-raw/` and are **not** read by this pipeline:
`IIH_MASTER_cases_and_controls_2.csv` (one-sided washout) and
`MDE_Encounters_controls.csv` (no Encounter Type).

---

## 1. Cohort and matching

| quantity | value |
|---|---|
| IIH engaged & eligible | 2520 |
| cases matched | 2490 |
| cases unmatched | 30 |
| controls used | 5743 |
| mean controls per case | 2.31 |
| tier-1 matches | 2172 |


### Baseline balance after matching

| variable | iih | control | smd |
|---|---|---|---|
| Age at index | 34.95 | 35.54 | -0.059 |
| BMI | 36.39 | 36.18 | 0.0302 |
| Female | 0.876 | 0.866 | 0.0303 |


### Baseline characteristics, full (Z_T02)

Covariates with |SMD| > 0.10 are residual imbalance and are reported as such.
Availability is shown per arm: a variable recorded in only one arm cannot be
compared.

| Variable | IIH | Comparator | SMD | Available_IIH | Available_Comparator |
|---|---|---|---|---|---|
| n | 2,138 | 5,743 | — | 100% | 100% |
| Person-years | 4563.0 | 9375.2 | — | 100% | 100% |
| Follow-up, years, median (IQR) | 2.77 (1.23-3.00) | 1.51 (0.52-3.00) | — | 100% | 100% |
| Age at index, years, mean (SD) | 34.9 (10.2) | 35.5 (9.5) | -0.065 | 100% | 100% |
| Female | 1875 (87.7%) | 4972 (86.6%) | 0.034 | 100% | 100% |
| BMI, kg/m2, mean (SD) | 36.5 (7.3) | 36.2 (6.5) | 0.050 | 100% | 100% |
| Obese (BMI >= 30) | 1712 (80.1%) | 4478 (78.0%) | 0.052 | 100% | 100% |
| Hypertension | 473 (22.1%) | 940 (16.4%) | 0.146 | 100% | 100% |
| Obstructive sleep apnoea | 630 (29.5%) | 884 (15.4%) | 0.342 | 100% | 100% |
| Polycystic ovary syndrome | 264 (12.3%) | 418 (7.3%) | 0.171 | 100% | 100% |
| Bariatric surgery | 74 (3.5%) | 124 (2.2%) | 0.079 | 100% | 100% |
| Clinical visits, 12 months before index, mean (SD) | 20.6 (26.5) | 9.2 (15.2) | 0.526 | 100% | 100% |
| Clinical visits, 12 months before index, median (IQR) | 12.00 (5.00-26.00) | 4.00 (1.00-10.00) | — | 100% | 100% |
| Current smoker (NOT COMPARABLE - see note) | 16 (0.7%) | 433 (7.5%) | -0.346 | 100% | 100% |
| Opening pressure, cmH2O, mean (SD) (IIH only) | 29.5 (9.7) | NaN (NA) | — | 74% | 0% |
| Died during follow-up | 38 (1.8%) | 89 (1.5%) | 0.018 | 100% | 100% |


Matching is on sex, age, BMI and BMI calendar year, in five relaxing
tiers. Comparators inherit the index date of the case they are matched to
(protocol §2.3); the 12-month engagement requirement and the prevalent-seizure
exclusion are both evaluated at that inherited date, so the two arms are
screened identically.

---

## 2. Primary outcome

Seizure or epilepsy after a 180-day washout, defined identically in both arms:
a qualifying code, or anti-seizure medication continued 180+ days.

### Encounter definition: clinical visits (primary)

| analysis | iih | comparator | iih_rate | ctl_rate | HR | p | ph_p | cif3_iih | cif3_ctl | risk_diff_pp | NNH |
|---|---|---|---|---|---|---|---|---|---|---|---|
| PRIMARY: any seizure code or indefinite ASM | 66/2138 | 63/5743 | 14.46 (11.19 to 18.40) | 6.72 (5.16 to 8.60) | 2.28 (1.62 to 3.22) | 2.62e-06 | 0.944 | 3.83 | 1.71 | 2.12 | 47 |
| Codes only, medication channel removed | 56/2138 | 63/5743 | 12.21 (9.23 to 15.86) | 6.72 (5.16 to 8.60) | 1.93 (1.34 to 2.77) | 0.000408 | 0.976 | 3.28 | 1.71 | 1.57 | 64 |
| Epilepsy-specific codes only (G40/345) | 26/2138 | 24/5743 | 5.62 (3.67 to 8.24) | 2.55 (1.63 to 3.79) | 2.30 (1.35 to 3.92) | 0.00221 | 0.775 | 1.53 | 0.68 | 0.85 | 118 |
| Restricted to opening pressure >= 25 cmH2O | 36/1122 | 34/2986 | 15.25 (10.68 to 21.11) | 7.16 (4.96 to 10.00) | 2.25 (1.41 to 3.59) | 0.000712 | 0.919 | 4.11 | 1.83 | 2.28 | 44 |


### Encounter definition: all encounter rows (sensitivity)

| analysis | iih | comparator | iih_rate | ctl_rate | HR | p | ph_p | cif3_iih | cif3_ctl | risk_diff_pp | NNH |
|---|---|---|---|---|---|---|---|---|---|---|---|
| PRIMARY: any seizure code or indefinite ASM | 65/2507 | 67/7905 | 10.70 (8.26 to 13.63) | 4.00 (3.10 to 5.08) | 2.79 (1.98 to 3.93) | 4.29e-09 | 0.288 | 2.91 | 1.04 | 1.88 | 53 |
| Codes only, medication channel removed | 55/2507 | 67/7905 | 9.02 (6.79 to 11.74) | 4.00 (3.10 to 5.08) | 2.35 (1.64 to 3.38) | 3.21e-06 | 0.304 | 2.49 | 1.04 | 1.45 | 69 |
| Epilepsy-specific codes only (G40/345) | 26/2507 | 26/7905 | 4.23 (2.76 to 6.20) | 1.55 (1.01 to 2.27) | 2.83 (1.66 to 4.83) | 0.000139 | 0.967 | 1.17 | 0.42 | 0.75 | 133 |
| Restricted to opening pressure >= 25 cmH2O | 36/1323 | 36/4155 | 11.15 (7.81 to 15.44) | 4.09 (2.87 to 5.67) | 2.85 (1.78 to 4.56) | 1.27e-05 | 0.359 | 3.08 | 1.06 | 2.02 | 50 |


### Complete matched sets (Z_T01)

Comparators were required at selection to have follow-up beyond the washout;
cases were not. 352 sets therefore lost their case while retaining 789
comparators who contribute person-time to a set with no case in it.

| analysis | iih | comparator | HR | p |
|---|---|---|---|---|
| Primary, as reported (all matched comparators retained) | 66/2138 | 63/5743 | 2.28 (1.62 to 3.22) | 2.62e-06 |
| Complete sets only (comparators whose case was dropped removed) | 66/2138 | 61/4954 | 2.06 (1.46 to 2.92) | 4.23e-05 |


Encounter type decides engagement and the censoring date only. It never touches
the outcome.

---

## 3. Secondary outcome — recurrent seizures or epilepsy among those with an event

| arm | with_event | recurrent_or_epilepsy | single_seizure | pct |
|---|---|---|---|---|
| IIH | 66 | 41 | 25 | 62% (49 to 74) |
| Comparator | 63 | 32 | 31 | 51% (38 to 64) |



| quantity | value |
|---|---|
| IIH recurrent/epilepsy | 41/66 (62%, 95% CI 49-74) |
| Comparator recurrent/epilepsy | 32/63 (51%, 95% CI 38-64) |
| Fisher exact p | 0.217 |
| Odds ratio (95% CI) | 1.58 (0.74 to 3.40) |


---

## 4. Pre-specified analyses (SAP)

### Landmark analyses

| analysis | iih_events | ctl_events | HR |
|---|---|---|---|
| Primary (180-day washout only) | 66 | 63 | 2.28 (1.62 to 3.22) |
| Landmark: events in the first 30 days after washout excluded | 62 | 53 | 2.49 (1.73 to 3.58) |
| Landmark: events in the first 90 days after washout excluded | 49 | 44 | 2.29 (1.54 to 3.41) |
| Landmark: events in the first 180 days after washout excluded | 39 | 35 | 2.22 (1.40 to 3.51) |


### Competing risks

| estimand | estimate |
|---|---|
| Cause-specific HR, seizure (primary) | 2.28 (1.62 to 3.22) |
| Subdistribution HR, seizure (Fine-Gray) | 2.28 (1.62 to 3.22) |
| Cause-specific HR, death (competing event) | 0.61 (0.29 to 1.29) |


### Subgroups

| subgroup | level | iih_events | ctl_events | HR | interaction_p |
|---|---|---|---|---|---|
| Age | Age < 35 | 31 | 33 | 1.90 (1.19 to 3.05) | 0.311 |
| Age | Age >= 35 | 35 | 30 | 2.72 (1.66 to 4.45) | 0.311 |
| Sex | Female | 53 | 56 | 1.98 (1.37 to 2.88) | 0.055 |
| Sex | Male | 13 | 7 | 5.12 (2.09 to 12.54) | 0.055 |
| BMI | BMI < 35 | 32 | 27 | 2.86 (1.70 to 4.83) | 0.259 |
| BMI | BMI >= 35 | 34 | 36 | 1.87 (1.18 to 2.98) | 0.259 |


### Propensity and overlap

| quantity | value |
|---|---|
| Propensity model c-statistic | 0.72 |
| Propensity overlap, IIH range | 0.069 to 0.862 |
| Propensity overlap, comparator range | 0.063 to 0.855 |
| SMD age, unweighted -> overlap-weighted | -0.065 -> -0.000 |
| SMD BMI, unweighted -> overlap-weighted | 0.050 -> 0.000 |
| SMD pre-index visits, unweighted -> overlap-weighted | 0.526 -> -0.073 |
| Overlap-weighted hazard ratio | 2.31 (1.56 to 3.43) |


### Comorbidity-adjusted sensitivity (Z_T04, Z_T05)

Matching did not balance obstructive sleep apnoea, polycystic ovary syndrome or
hypertension. All three are measured at or before index, so none is a collider
and all are adjustable. Stated before running: reported whatever the result.

Whether a variable can confound requires BOTH imbalance and association with the
outcome:

| covariate | prevalence_iih | prevalence_ctl | SMD | HR_for_outcome | p |
|---|---|---|---|---|---|
| Obstructive sleep apnoea | 29.5% | 15.4% | 0.342 | 1.87 (1.29 to 2.71) | 0.000862 |
| Hypertension | 22.1% | 16.4% | 0.146 | 1.41 (0.95 to 2.08) | 0.0902 |
| Polycystic ovary syndrome | 12.3% | 7.3% | 0.171 | 1.14 (0.64 to 2.02) | 0.65 |


Only OSA meets both criteria. PCOS is imbalanced but unrelated to the outcome
(HR 1.14, p = 0.65) and therefore cannot confound.

| model | HR | p | change |
|---|---|---|---|
| Primary (matched, unadjusted) | 2.28 (1.62 to 3.22) | 2.62e-06 | — |
| + obstructive sleep apnoea | 2.11 (1.49 to 2.99) | 2.65e-05 | -7.5% |
| + hypertension | 2.24 (1.59 to 3.16) | 4.59e-06 | -1.8% |
| + polycystic ovary syndrome | 2.28 (1.61 to 3.24) | 4.14e-06 | +0.0% |
| + all three comorbidities | 2.11 (1.48 to 3.01) | 3.68e-05 | -7.5% |
| + all three, and pre-index visits | 2.33 (1.58 to 3.45) | 1.95e-05 | +2.2% |


---

## 5. Detection and surveillance assessment

### 5a. Post-index surveillance

| measure | IIH_n | Comparator_n | IIH_rate | Comparator_rate | rate_ratio | note |
|---|---|---|---|---|---|---|
| All clinical visits | 102924 | 78190 | 22.56 (22.42 to 22.69) | 8.34 (8.28 to 8.40) | 2.70 (2.68 to 2.73) |  |
| Emergency encounters | 676 | 242 | 0.15 (0.14 to 0.16) | 0.03 (0.02 to 0.03) | 5.74 (4.96 to 6.65) |  |
| Hospital or inpatient encounters | 13961 | 12635 | 3.06 (3.01 to 3.11) | 1.35 (1.32 to 1.37) | 2.27 (2.22 to 2.33) |  |
| Office or clinic visits | 45921 | 32263 | 10.06 (9.97 to 10.16) | 3.44 (3.40 to 3.48) | 2.92 (2.88 to 2.97) |  |
| Procedural or diagnostic encounters | 19380 | 17145 | 4.25 (4.19 to 4.31) | 1.83 (1.80 to 1.86) | 2.32 (2.28 to 2.37) |  |
| Laboratory encounters | 474 | 851 | 0.10 (0.09 to 0.11) | 0.09 (0.08 to 0.10) | 1.14 (1.02 to 1.28) |  |
| Neurology visits | — | — | not available | not available | not estimable | no encounter type names a specialty; none of the 171 types is Neurology |
| Ophthalmology visits | — | — | not available | not available | not estimable | same; the Historic Ophthalmology types are imported records, not visits |
| Brain MRI or CT | — | — | not available | not available | not estimable | radiology extract covers comparators only (1,234 patients, 0 IIH); the Radiology encounter type has 386 case against 12 comparator rows and cannot be a record of scans |
| EEG | — | — | not available | not available | not estimable | recorded for 393 IIH patients and 0 comparators |


### 5b. Negative-control outcomes, panel 1

| outcome | baseline_iih_pct | baseline_ctl_pct | baseline_ratio | baseline_p | balanced | events_iih | events_ctl | hr | lo | hi | estimate |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Herpes zoster | 1.64 | 0.5 | 3.24 | 3.17e-06 | FAIL | 17 | 12 | 2.98261966132921 | 1.4070341391147 | 6.32253319009366 | 2.98 (1.41 to 6.32) |
| Renal/ureteric stone | 4.3 | 2.11 | 2.04 | 3e-07 | FAIL | 63 | 44 | 3.08955507900151 | 2.0949538677889 | 4.55635359467777 | 3.09 (2.09 to 4.56) |
| Gallstones | 3.46 | 2.19 | 1.58 | 0.00212 | FAIL | 39 | 40 | 1.99969883976446 | 1.28577180291734 | 3.11003510940456 | 2.00 (1.29 to 3.11) |
| Acute appendicitis | 1.03 | 0.45 | 2.27 | 0.00527 | FAIL | 4 | 8 | 1.05716960694159 | 0.319044217211243 | 3.50298647507235 | 1.06 (0.32 to 3.50) |
| Limb fracture | 0.14 | 0.28 | 0.5 | 0.437 | PASS | 2 | 7 | — | — | — | not estimable |
| Carpal tunnel | 4.07 | 1.6 | 2.54 | 7.08e-10 | FAIL | 40 | 29 | 2.84245630095793 | 1.76647319834837 | 4.57383549912317 | 2.84 (1.77 to 4.57) |


### 5c. Negative-control outcomes, panel 2

| outcome | patients_in_file_iih | patients_in_file_ctl | baseline_iih_pct | baseline_ctl_pct | baseline_ratio | baseline_p | events_iih | events_ctl | hr | lo | hi | estimate | verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Upper respiratory infection | 797 | 937 | 21.52 | 10.6 | 2.03 | 1.19e-33 | 173 | 213 | 2.02108165052779 | 1.64885242833378 | 2.47734179718432 | 2.02 (1.65 to 2.48) | EXCLUDED - baseline imbalanced |
| Otitis media or externa | 277 | 179 | 6.08 | 1.65 | 3.68 | 1.25e-22 | 72 | 51 | 3.08572486333757 | 2.14973372842241 | 4.42924526248521 | 3.09 (2.15 to 4.43) | EXCLUDED - baseline imbalanced |
| Sprain or strain | 228 | 172 | 5.05 | 1.78 | 2.84 | 5.48e-14 | 54 | 47 | 2.47300263137023 | 1.66575650951878 | 3.67145016682593 | 2.47 (1.67 to 3.67) | EXCLUDED - baseline imbalanced |
| Laceration or open wound | 133 | 65 | 2.85 | 0.57 | 4.97 | 1.64e-14 | 33 | 16 | 4.28157597285898 | 2.36691301074124 | 7.74506402566203 | 4.28 (2.37 to 7.75) | EXCLUDED - baseline imbalanced |
| Contact dermatitis | 76 | 69 | 1.73 | 0.68 | 2.55 | 7.14e-05 | 18 | 20 | 1.85033654547166 | 0.978931329856044 | 3.4974315634698 | 1.85 (0.98 to 3.50) | EXCLUDED - baseline imbalanced |
| Fracture, excluding skull/face | 108 | 132 | 2.25 | 1.24 | 1.82 | 0.00171 | 24 | 40 | 1.22476196576165 | 0.756509345743447 | 1.98284645287786 | 1.22 (0.76 to 1.98) | EXCLUDED - baseline imbalanced |


### 5d. Unadjusted rates, primary outcome against every negative control

| outcome | iih_events | ctl_events | IIH_per1000py | Comparator_per1000py | rate_ratio |
|---|---|---|---|---|---|
| SEIZURE OR EPILEPSY (primary outcome) | 66 | 63 | 14.46 (11.19 to 18.40) | 6.72 (5.16 to 8.60) | 2.15 (1.52 to 3.04) |
| Laceration or open wound | 33 | 16 | 7.36 (5.06 to 10.33) | 1.71 (0.98 to 2.77) | 4.31 (2.37 to 7.83) |
| Otitis media or externa | 72 | 51 | 16.92 (13.24 to 21.30) | 5.53 (4.12 to 7.27) | 3.06 (2.14 to 4.38) |
| Renal/ureteric stone | 63 | 44 | 14.33 (11.01 to 18.34) | 4.77 (3.47 to 6.40) | 3.00 (2.04 to 4.42) |
| Herpes zoster | 17 | 12 | 3.73 (2.18 to 5.98) | 1.28 (0.66 to 2.23) | 2.92 (1.39 to 6.11) |
| Carpal tunnel | 40 | 29 | 9.04 (6.46 to 12.30) | 3.12 (2.09 to 4.48) | 2.90 (1.80 to 4.67) |
| Sprain or strain | 54 | 47 | 12.46 (9.36 to 16.25) | 5.10 (3.75 to 6.78) | 2.44 (1.65 to 3.61) |
| Gallstones | 39 | 40 | 8.80 (6.26 to 12.03) | 4.35 (3.11 to 5.92) | 2.02 (1.30 to 3.14) |
| Upper respiratory infection | 173 | 213 | 51.92 (44.47 to 60.26) | 26.01 (22.63 to 29.75) | 2.00 (1.63 to 2.44) |
| Contact dermatitis | 18 | 20 | 3.95 (2.34 to 6.24) | 2.14 (1.31 to 3.30) | 1.85 (0.98 to 3.49) |
| Fracture, excl. skull/face | 24 | 40 | 5.30 (3.39 to 7.88) | 4.31 (3.08 to 5.87) | 1.23 (0.74 to 2.04) |
| Acute appendicitis | 4 | 8 | 0.87 (0.24 to 2.22) | 0.85 (0.37 to 1.68) | 1.02 (0.31 to 3.39) |


### 5e. Empirical calibration

| quantity | value |
|---|---|
| negative controls in the fit | 11 |
| correlation, log baseline ratio with log HR | r = 0.663 (p = 0.0263) |
| slope | 0.84 (SE 0.31) |
| predicted detection-only HR at baseline balance | 1.04 (0.37 to 2.90) |
| observed seizure HR, unadjusted | 2.28 |
| observed seizure HR, contact-adjusted | 2.57 |
| median change in negative-control HR on adjustment | -28.7% |
| change in seizure HR on adjustment | +12.6% |


### 5f. Response to healthcare-seeking adjustment

| measure | controls_median_change | controls_range | controls_moving_up | seizure_hr | seizure_change | seizure_direction |
|---|---|---|---|---|---|---|
| (unadjusted) | - | - | — | 2.28 | - | - |
| visits_12m | -27.9% | -42% to -16% | 0 | 2.46 | +7.8% | AWAY from null |
| visits_24m | -28.1% | -39% to -19% | 0 | 2.64 | +15.6% | AWAY from null |
| months_12m | -24.1% | -41% to -10% | 0 | 2.62 | +14.8% | AWAY from null |
| visits_all | -31.8% | -46% to -22% | 0 | 2.93 | +28.6% | AWAY from null |
| history_years | -11.3% | -21% to -3% | 0 | 2.69 | +18.1% | AWAY from null |
| office_12m | -32.8% | -43% to -20% | 0 | 2.57 | +12.6% | AWAY from null |


### 5g. Collider demonstration

| outcome | unadjusted | adj_pre_index | adj_post_index_COLLIDER |
|---|---|---|---|
| SEIZURE OR EPILEPSY | 2.28 (1.62 to 3.22) | 2.57 (1.75 to 3.78) | 1.25 (0.85 to 1.85) |
| Fracture (negative control) | 1.22 (0.76 to 1.98) | 0.87 (0.52 to 1.45) | 0.39 (0.23 to 0.67) |
| Upper respiratory infection (negative control) | 2.02 (1.65 to 2.48) | 1.49 (1.21 to 1.84) | 0.75 (0.61 to 0.92) |


### 5h. Quantitative bias analysis

| quantity | value | vs_threshold |
|---|---|---|
| E-value, point estimate | 3.99 | - |
| E-value, CI limit nearest the null | 2.62 | - |
| surveillance RR, all clinical visits | 2.7 | below point-estimate threshold |
| surveillance RR, office or clinic | 2.92 | below point-estimate threshold |
| surveillance RR, procedural or diagnostic | 2.32 | below point-estimate threshold |
| surveillance RR, hospital or inpatient | 2.27 | below both thresholds |
| surveillance RR, emergency department | 5.74 | EXCEEDS point-estimate threshold |
| surveillance RR, laboratory | 1.14 | below both thresholds |


---

## 6. Figures

Every figure listed here was regenerated by this run. Figures from earlier
pipelines were moved to `outputs/figures_superseded/`, so a figure built on a
cohort that has since been rebuilt cannot be picked up by mistake. Nothing in
that directory belongs to the current manuscript.

- `outputs/figures/K_F1_cumulative_incidence`
- `outputs/figures/K_F2_forest_specifications`
- `outputs/figures/K_F3_recurrent_vs_single`
- `outputs/figures/K_F4_negative_control_calibration`
- `outputs/figures/K_F5_timing_of_events`
- `outputs/figures/K_F6_severity_cascade`
- `outputs/figures/K_F7_contact_adjustment`
- `outputs/figures/K_F8_calibration_v2`


---

## 7. Reproduction

```
./run_final.sh
```

Runs the provenance gate, rebuilds the master dataset, re-matches both arms on
dated encounters, recomputes every estimate and regenerates every figure. Halts
on the first failure.

