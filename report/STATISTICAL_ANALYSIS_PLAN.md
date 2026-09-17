# IIH and incident seizure — statistical analysis plan and findings

Every number is reproducible from `R/K15`–`R/K24`. Nothing here is estimated,
assumed, or carried over from the earlier analysis unless stated.

---

## 1. Estimand

| | |
|---|---|
| **Population** | Patients aged 13–60 with no seizure or epilepsy before index, with ≥1 clinical visit in the 12 months before index |
| **Exposure** | Incident IIH (ICD-9 348.2 / ICD-10 G93.2), index date = first diagnostic lumbar puncture |
| **Comparator** | Non-IIH patients from the general clinical population, matched and inheriting the case's index date |
| **Index date** | First diagnostic LP (cases); inherited (comparators) |
| **Follow-up** | End of a symmetric 180-day washout to the earliest of event, last clinical visit, death, freeze, or 3 years |
| **Outcome** | First incident seizure or epilepsy, no distinction between them |
| **Effect measure** | Cause-specific hazard ratio; 3-year cumulative incidence difference; NNH |

**This is an association, not a causal effect.** Nothing below should be read as
establishing that IIH causes seizures.

## 2–3. Cohort and comparator

Cases: incident IIH anchored to the first diagnostic LP, with ≥12 months of
records either side. Exclusions at or before index: any seizure or epilepsy code
(ICD-9 345.x, 780.39; ICD-10 G40.x, R56.x), unambiguous antiseizure medication,
epileptiform EEG, TBI, stroke, intracranial tumour, cerebral venous sinus
thrombosis, craniotomy, and seizure within 180 days of index. The investigators
confirm these were applied to **both** arms.

Comparators were re-matched from scratch against dated encounter records: sex
exact, age ±3, BMI ±3, and for women a BMI measurement within ±2 calendar years,
with the pre-specified relaxation ladder. Each comparator inherits its case's
index date and **every** time-anchored quantity is re-derived from it.

**An active comparator could not be constructed.** A cohort under equivalent
specialist follow-up — chronic migraine, say, or another headache disorder —
would be the right design given what Section 8 shows, and no such cohort exists
in the delivered data. This is the single most valuable missing element.

**Race could not be used.** It is recorded for 100% of comparators and 0% of IIH
cases, so the protocol's race-matching criterion could not constrain anything.

## 4. Table 1 (`SAP_T1`)

| | IIH | Comparator | SMD |
|---|---|---|---|
| Age, mean (SD) | 34.9 (10.2) | 35.5 (9.5) | −0.065 |
| Female | 1,875 (87.7%) | 4,972 (86.6%) | 0.034 |
| BMI, mean (SD) | 36.5 (7.3) | 36.2 (6.5) | 0.050 |
| Obese (≥30) | 1,712 (80.1%) | 4,478 (78.0%) | 0.052 |
| Hypertension | 473 (22.1%) | 940 (16.4%) | **0.146** |
| Current smoker* | 16 (0.7%) | 433 (7.5%) | −0.346 |
| Visits, 12 months pre-index | 20.6 (26.5) | 9.2 (15.2) | **0.526** |

\* Smoking is populated in both arms but the distributions are not credible
(former smokers 1.5% of IIH against 15.9% of comparators). Reported, not
adjusted for.

Matched covariates balance well. Two do not: hypertension, and — decisively —
pre-index healthcare contact.

**Not available in any delivered file:** diabetes, hyperlipidemia, stroke/TIA,
TBI, CNS infection, brain tumour, migraine, sleep disorders, psychiatric
conditions, alcohol and substance use. Stroke, TBI, tumour and CVST were
exclusions, so their absence is by design; the rest are simply missing, and
Table 1 is thin because of it.

## 5. Outcome definition

**Primary:** a qualifying seizure code more than 180 days after index, **or**
antiseizure medication continued ≥180 days. Applied identically to both arms.

Counted: G40.x, R56.x, 345.x, 780.39. Excluded: F44.5 and 300.11 (psychogenic
non-epileptic), R56.1 and 780.32/.33 (post-traumatic), febrile convulsions,
Z82.0 (family history), G43.x (migraine), E936/966. "Spells Neurological" counts
only with indefinite therapy. Topiramate and acetazolamide are excluded from the
medication limb (both treat IIH), as are gabapentin, pregabalin and the
benzodiazepines.

**High-specificity variant:** epilepsy-specific codes only (G40/345).

Chart validation of code-positive comparators was proposed and has not been
done. It remains the most valuable outstanding check.

## 6. Primary analysis (`K_T38`, `K_F1`)

| | IIH | Comparator |
|---|---|---|
| Events | 66 / 2,138 | 63 / 5,743 |
| Rate per 1,000 py | 14.46 (11.19–18.40) | 6.72 (5.16–8.60) |
| 3-year cumulative incidence | 3.83% | 1.71% |

**HR 2.28 (95% CI 1.62–3.22), p = 2.6 × 10⁻⁶.** Risk difference 2.12 percentage
points; **NNH 47**. Proportional hazards satisfied (p = 0.94). Cumulative
incidence is Aalen–Johansen with death as a competing risk, never 1−KM.

## 7. Confounding, and the causal structure

| Variable | Role | Handling |
|---|---|---|
| Age, sex, BMI | Confounder | Matched |
| BMI measurement year | Confounder (women) | Matched ±2 years |
| Pre-index healthcare contact | Confounder — fixed before the outcome | Adjusted in sensitivity; overlap-weighted |
| **Post-index healthcare contact** | **Collider — caused by the outcome** | **Never adjusted for** (Section 8E) |
| Acetazolamide, topiramate | Mediator / consequence of exposure | Never adjusted; excluded from the outcome |
| Shunt, stent | Consequence of exposure | Descriptive only |
| Hypertension | Possible confounder | Imbalanced (SMD 0.146), unadjusted — declared |

Overlap weighting on age, sex, BMI and pre-index visits removes the visit
imbalance (SMD 0.526 → −0.073) and gives **2.31 (1.56–3.43)** against 2.28
unweighted. Propensity c-statistic 0.72; overlap is complete (IIH 0.069–0.862,
comparators 0.063–0.855), so positivity holds.

Events per parameter: 129 events, 1 parameter in the primary model, 32 per
parameter in the propensity model. No model here is overfitted.

## 8. Detection and surveillance bias

### A. Surveillance is grossly unequal (`SAP_T2`)

| Per person-year | IIH | Comparator | Rate ratio |
|---|---|---|---|
| All clinical visits | 22.56 (22.42–22.69) | 8.34 (8.28–8.40) | **2.70** |
| Hospital/inpatient | 3.05 (3.00–3.10) | 1.34 (1.32–1.37) | **2.27** |
| Emergency | 0.15 (0.14–0.16) | 0.03 (0.02–0.03) | **5.74** |

Neurology and ophthalmology cannot be separated: encounter type distinguishes
office visit from hospital encounter but carries no specialty. EEG is recorded
for 15% of IIH and 0% of comparators; opening pressure 73% and 0%; brain imaging
counts exist for comparators only. None supports a between-arm comparison.

### B. Comparable-surveillance restriction

Both arms already require ≥1 clinical visit in the pre-index year. Beyond that,
overlap weighting equalises pre-index contact (above) and leaves the estimate
unchanged at 2.31.

### C. Timing (`SAP_T3`, `K_F5`)

Period-specific hazard ratios: **2.37, 2.00, 2.70, 1.81** across 0–6 months,
6–12 months, 1–2 years and 2–3 years. No downward trend. A detection effect
driven by the diagnostic encounter should concentrate early and decay; this
does not.

Landmark analyses excluding the first 30, 90 and 180 days after the washout:
**2.49, 2.29, 2.22** against 2.28. The 180-day washout already implements a
stronger version of the requested 30- and 90-day exclusions.

61% of IIH and 67% of comparator events fall in the first year after washout —
the same shape in both arms, so timing does not discriminate.

### D. Outcome-definition sensitivity (`K_T38`, `K_F2`)

| | Visits only | All encounter rows |
|---|---|---|
| Primary | **2.28 (1.62–3.22)** | 2.79 (1.98–3.93) |
| Codes only, no medication limb | 1.93 (1.34–2.77) | 2.35 (1.64–3.38) |
| Epilepsy-specific codes only | 2.30 (1.35–3.92) | 2.83 (1.66–4.83) |
| Opening pressure ≥25 cmH₂O | 2.25 (1.41–3.59) | 2.85 (1.78–4.56) |

Eight specifications, all significant, all between 1.9 and 2.9. Seizure
requiring ED or hospitalisation could not be constructed: encounter type is not
linked to the diagnosis record.

### E. Post-index adjustment is a collider, demonstrated (`K_T52`)

Patients with an event have 40.5 post-index visits against 17 without one (IIH)
and 9 against 3 (comparators). Visits are **caused by** the outcome.

| | Unadjusted | Adj. pre-index | Adj. post-index |
|---|---|---|---|
| Seizure | 2.28 | 2.57 | 1.25 (0.85–1.85) |
| Fracture | 1.22 | 0.87 | **0.39 (0.23–0.67)** |
| URI | 2.02 | 1.49 | 0.75 (0.61–0.92) |

Adjusting for post-index visits makes IIH appear to **protect against
fracture**. The adjustment is invalid, and the 1.25 it produces for seizure is
uninformative — not evidence against the association.

## 9. Negative controls (`K_T45`–`K_T50`, `K_F7`, `K_F8`)

Eleven outcomes with no plausible link to IIH: fracture, upper respiratory
infection, otitis, sprain, laceration, contact dermatitis, herpes zoster, renal
stone, gallstones, appendicitis, carpal tunnel.

**All eleven are over-represented in the IIH arm before index**, ratios 1.6–5.0,
all p < 0.01. None is usable as a conventional negative control, and the
specificity claim in the submitted manuscript is withdrawn.

Two analyses rescue something from this.

**Calibration.** Apparent effect scales with baseline imbalance (r = 0.66,
p = 0.026; slope 0.84, SE 0.31) — the signature of detection bias. Extrapolated
to perfect balance the predicted detection-only HR is **1.04 (0.37–2.90)**. The
seizure estimate of 2.28 sits above 1.04 but **inside** that interval, so
calibration alone cannot clear it.

**Adjustment for healthcare-seeking — the discriminating test.** Under six
separate pre-index measures (12- and 24-month visit counts, distinct months with
a visit, all pre-index visits, years of history, office visits only):

- **66 of 66** control-by-measure combinations moved **toward** the null, by
  medians of 11% to 33%
- The seizure association moved **away** from the null on **all six**, by +7.8%
  to +28.6%

It is the only one of twelve outcomes to behave this way. Had the excess been
produced by patients with IIH simply being seen more often, it should have
shrunk with the rest.

## 10. Competing risks (`SAP_T4`)

| Estimand | Estimate |
|---|---|
| Cause-specific HR, seizure | 2.28 (1.62–3.22) |
| Subdistribution HR (Fine-Gray) | 2.28 (1.62–3.22) |
| Cause-specific HR, death | 0.61 (0.29–1.29) |

Cause-specific is primary: the question is aetiological, not prognostic.
Fine-Gray agrees, and death does not compete materially.

## 11. Missing data (`SAP_T7`)

Age, sex, BMI and hypertension are complete in both arms; no imputation is
needed. Race (absent for every IIH case), opening pressure (IIH only) and EEG
(IIH only) are not missing at random in any modellable sense — they are absent
by arm. **Imputation would be fabrication** and is not performed. Opening
pressure is used for one sensitivity analysis within the IIH arm and never for
adjustment.

## 12. Subgroups (`SAP_T5`) — exploratory

| Subgroup | HR | Interaction p |
|---|---|---|
| Age <35 / ≥35 | 1.90 / 2.72 | 0.311 |
| BMI <35 / ≥35 | 2.86 / 1.87 | 0.259 |
| Female / Male | 1.98 / 5.12 | 0.055 |

No interaction survives testing. The male estimate rests on 13 events and is
**not interpreted**. Interaction is tested on the sandwich covariance, never by
comparing whether subgroup estimates are individually significant.

## 13. Treatment and time-varying exposure

Acetazolamide and topiramate are consequences of the exposure and are excluded
from the antiseizure-medication definition precisely so they cannot manufacture
events in the IIH arm. Shunt and stent are zero in comparators by definition and
are descriptors, not covariates. No post-index variable enters the primary model.

## 14. Sensitivity analyses performed

| Analysis | Result | Bias addressed |
|---|---|---|
| Epilepsy-specific codes only | 2.30 (1.35–3.92) | Outcome misclassification |
| Medication limb removed | 1.93 (1.34–2.77) | Outcome misclassification |
| All encounter rows counted | 2.79 (1.98–3.93) | Encounter definition |
| Opening pressure ≥25 | 2.25 (1.41–3.59) | Exposure misclassification (CVST) |
| Landmark +30 / +90 / +180 days | 2.49 / 2.29 / 2.22 | Early detection |
| Period-specific | 2.37, 2.00, 2.70, 1.81 | Time-varying detection |
| Overlap weighting | 2.31 (1.56–3.43) | Confounding by contact |
| Pre-index contact adjustment | 2.57 (1.75–3.78) | Surveillance |
| Fine-Gray | 2.28 (1.62–3.22) | Competing risk |
| 11 negative controls, 6 contact measures | 66/66 shrink; seizure never | Residual surveillance |

## 15–17. Reporting and multiplicity

**Primary:** one outcome, one model — HR 2.28. Everything else is secondary or
exploratory and is labelled as such. The epilepsy-versus-single-seizure split
(62% against 51%) is secondary. Subgroups are exploratory, unadjusted for
multiplicity, and not interpreted.

Tables: `SAP_T1` baseline, `SAP_T2` surveillance, `K_T38` primary and
sensitivity, `K_T45`–`K_T50` negative controls. Figures: `K_F1` cumulative
incidence, `K_F2` specification forest, `K_F5` timing, `K_F6` severity cascade,
`K_F7` contact adjustment, `K_F8` calibration.

---

## 18A. Primary finding

Among patients with no prior seizure or epilepsy, IIH was associated with an
incident seizure rate of 14.46 per 1,000 person-years against 6.72 among matched
comparators — **HR 2.28 (95% CI 1.62–3.22)**, 3-year cumulative incidence 3.83%
against 1.71%, one additional case per 47 patients followed for three years.
The association is present in all eight outcome and encounter specifications and
survives landmark, competing-risk and propensity analyses.

**This is an association.** The design cannot establish causation.

## 18B. Detection and surveillance bias: **partially mitigated**

Not "substantially mitigated", and not "unresolved".

**Why not unresolved.** Surveillance is grossly unequal (2.70× visits, 5.74× ED
encounters), yet the estimate does not behave like a detection artefact: it is
flat across time rather than concentrated after diagnosis; it survives landmark
exclusions; it survives restriction to epilepsy-specific codes; it survives
overlap weighting that removes the contact imbalance; and — most tellingly — of
twelve outcomes subjected to six adjustments for healthcare-seeking, the eleven
negative controls moved toward the null in 66 of 66 combinations while the
seizure outcome moved away from it in 6 of 6.

**Why not substantially mitigated.** Every negative control failed the baseline
balance criterion, so the panel cannot bound residual bias. Calibration predicts
a detection-only HR of 1.04 with a prediction interval of 0.37–2.90 that
**contains** the observed 2.28. Adjustment for healthcare-seeking relies on
pre-index counts that cannot capture observation intensity fully. No active
comparator exists. And the arms cannot be equalised on specialist contact,
because specialty is not recorded.

## 18C. Residual limitations

**Confounding.** Hypertension is imbalanced and unadjusted. Diabetes,
hyperlipidemia, migraine, sleep apnoea, psychiatric and substance-use
comorbidity are entirely absent. Obesity is matched on BMI but severity and
duration are not captured.

**Selection.** Comparators drawn from the general clinical population, not an
active comparator. Requiring a pre-index visit in both arms is necessary but
selects comparators already engaged with care.

**Misclassification.** Comparator outcomes are code-ascertained while IIH events
were additionally chart-confirmed. Coded ascertainment over-counts, so the
comparator count is generous and the estimate conservative. No chart validation
of code-positive comparators has been done.

**Detection.** As in 18B.

**Missing data.** Race absent for every case; EEG and opening pressure for the
IIH arm only; outpatient prescribing unavailable for cases, so the medication
limb captures inpatient administrations on one side and outpatient prescriptions
on the other.

**Reverse causation.** Undiagnosed seizure disorder could prompt the neurological
work-up that finds IIH. The 180-day washout and landmark analyses address this;
they cannot eliminate it.

**Generalisability.** A single tertiary referral system, 88% female, index dates
2002–2025. Referral patterns here are unlikely to match community practice.

---

## 18D. Methods (manuscript-ready)

> **Statistical analysis.** Patients with incident IIH were matched without
> replacement to non-IIH comparators on sex (exact), age (±3 years), body-mass
> index (±3 kg/m²) and, for women, a BMI measurement within ±2 calendar years,
> with a pre-specified relaxation ladder where matching failed; sex was never
> relaxed. Cases were processed in randomised order with nearest-neighbour
> selection on BMI then age, in successive passes so that every case obtained
> one comparator before any obtained a second. Each comparator inherited its
> case's index date, and engagement, the washout, the prevalence exclusion, the
> at-risk window and all diagnosis-code offsets were derived from that date.
> Eligibility required ≥1 clinical visit in the preceding 12 months, no
> qualifying seizure code or chronic antiseizure therapy on or before day 180,
> and follow-up extending beyond day 180. Encounter type was used to restrict
> both arms to clinical visits, excluding messaging, order entry and
> record-keeping activity; the classification is given in the supplement and the
> analysis is repeated counting all encounter records.
>
> Follow-up ran from the end of a symmetric 180-day washout to the earliest of
> the outcome, last clinical visit, death, data freeze, or three years. The
> primary outcome was incident seizure or epilepsy, ascertained identically in
> both arms as a qualifying seizure code or antiseizure medication continued for
> ≥180 days.
>
> Cause-specific hazard ratios were estimated by Cox regression with a robust
> sandwich variance clustered on matched set, and proportional hazards assessed
> on scaled Schoenfeld residuals. Cumulative incidence used the Aalen–Johansen
> estimator with death as a competing risk; subdistribution hazards were
> estimated by the Fine–Gray method. Rates carry exact Poisson intervals and
> proportions exact binomial intervals.
>
> Because patients with IIH are observed more intensively than comparators,
> detection bias was addressed prospectively. Surveillance was quantified as
> visits, hospital encounters and emergency encounters per person-year. Eleven
> outcomes with no plausible causal relationship to IIH served as negative
> controls, each screened for baseline balance before any hazard ratio was
> examined. Healthcare-seeking was adjusted for using six pre-index measures,
> each fixed before the outcome could occur; post-index encounter counts were
> not adjusted for, being consequences of the outcome, and the consequences of
> doing so are shown in the supplement. Confounding was additionally addressed by
> overlap weighting on age, sex, BMI and pre-index visits.
>
> Subgroup effects were tested by interaction on the sandwich covariance rather
> than by comparing subgroup significance, and are reported as exploratory.
> Analyses used R 4.x with the survival package. No imputation was performed:
> variables with substantial missingness were absent by arm rather than at
> random, and imputing them would not be supportable.

## 18E. Results (manuscript-ready)

> Of 2,618 patients with IIH, 2,520 had a clinical visit in the 12 months before
> index and 2,490 were matched, drawing 5,743 comparators (mean 2.31 per case;
> 2,172 matched at the strictest tier). Index dates spanned 2002 to 2025.
> Matching achieved close balance on age (34.9 against 35.5 years, standardised
> mean difference −0.065), BMI (36.5 against 36.2 kg/m², 0.050) and sex (87.7%
> against 86.6% female, 0.034). Hypertension remained imbalanced (22.1% against
> 16.4%, 0.146), as did pre-index healthcare contact (20.6 against 9.2 visits,
> 0.526).
>
> Patients with IIH were observed far more intensively: 22.56 against 8.34
> clinical visits per person-year (rate ratio 2.70), 3.05 against 1.34 hospital
> encounters (2.27) and 0.15 against 0.03 emergency encounters (5.74).
>
> Incident seizure or epilepsy occurred in 66 of 2,138 patients with IIH (14.46
> per 1,000 person-years, 95% CI 11.19 to 18.40) and 63 of 5,743 comparators
> (6.72, 5.16 to 8.60), giving a cause-specific hazard ratio of 2.28 (95% CI
> 1.62 to 3.22; p = 2.6 × 10⁻⁶). Proportional hazards were satisfied (p = 0.94).
> Three-year cumulative incidence was 3.83% against 1.71%, an absolute
> difference of 2.12 percentage points (number needed to harm 47). The
> subdistribution hazard ratio was identical at 2.28, and death did not compete
> materially (cause-specific hazard ratio 0.61, 0.29 to 1.29).
>
> The estimate was stable across specifications. Restricting the outcome to
> epilepsy-specific codes gave 2.30 (1.35 to 3.92); removing the medication limb,
> 1.93 (1.34 to 2.77); counting all encounter records rather than clinical
> visits, 2.79 (1.98 to 3.93); restricting to opening pressure ≥25 cmH₂O, 2.25
> (1.41 to 3.59). Landmark analyses excluding the first 30, 90 and 180 days
> after the washout gave 2.49, 2.29 and 2.22. Period-specific hazard ratios were
> 2.37, 2.00, 2.70 and 1.81 across the first three years, without downward
> trend. Overlap weighting, which removed the pre-index visit imbalance
> (standardised mean difference 0.526 to −0.073), gave 2.31 (1.56 to 3.43).
>
> All eleven negative-control outcomes were more prevalent in the IIH arm before
> index (prevalence ratios 1.6 to 5.0, all p < 0.01), and none met the
> pre-specified balance criterion. Across these controls the apparent post-index
> effect scaled with baseline imbalance (r = 0.66, p = 0.026), predicting a
> detection-only hazard ratio at perfect balance of 1.04 (0.37 to 2.90).
> Adjusting for healthcare-seeking under six pre-index measures moved every
> negative control toward the null in all 66 control-by-measure combinations
> (median shrinkage 11% to 33%), whereas the seizure association moved away from
> the null under all six measures (+7.8% to +28.6%).
>
> Among patients with an incident event, 41 of 66 with IIH (62%, 49 to 74) and 32
> of 63 comparators (51%, 38 to 64) met criteria for recurrent or established
> epilepsy; these proportions did not differ. No subgroup interaction reached
> significance (age p = 0.311, BMI p = 0.259, sex p = 0.055).
