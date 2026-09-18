# Methods and Results — final analysis

Every figure below is reproducible from `R/K15_final_analysis.R` and
`R/K16_final_figures.R`; tables carry the `K_T38`–`K_T41` and `K_S1`–`K_S2`
prefixes. This supersedes the submitted analysis, in which the two arms were
ascertained by different standards.

---

## Methods

### Cohort and matching

Patients with IIH were identified by ICD-9 348.2 or ICD-10 G93.2 with an index
date at the first diagnostic lumbar puncture. Comparators were drawn from the
general clinical population and matched without replacement on sex (exact),
race where recorded in both, age at index (±3 years), body-mass index (±3
kg/m²), and — for women — a BMI measurement within ±2 calendar years of the
case's. Where 1:4 could not be achieved the tolerances were relaxed in the
pre-specified order (drop race, drop the BMI-year rule, BMI ±5, age ±5); sex
was never relaxed. Cases were processed in randomised order with nearest-
neighbour selection on BMI then age, in successive passes so that every case
obtained one comparator before any case obtained a second.

Each comparator inherits the index date of its matched case, and every
time-anchored quantity — engagement, the washout, the prevalence exclusion, the
at-risk window and the day offset of every diagnosis code — is measured from
that date.

Eligibility was evaluated against the case's index date: at least one clinical
encounter in the preceding 12 months; no qualifying seizure code and no chronic
antiseizure therapy on or before day 180; and an at-risk window extending past
day 180.

### Encounters

Engagement and censoring were derived from dated encounter records covering all
2,618 cases and all 9,122 comparators. Encounter type was available for both
arms and was used to exclude administrative activity — patient messages,
clinical communications, order entry, refills, wait lists, record conversions —
from the definition of a clinical encounter. Of 171 distinct types, 125 were
counted and 46 excluded, retaining 941,840 of 2,194,296 rows. The classification
is listed in full in `K_S1` and was applied identically to both arms. Because
which rows count is a judgement, the entire analysis was also run counting every
encounter row, and both are reported.

Encounter type determines engagement and the censoring date only. It plays no
part in the outcome definition and therefore cannot create or suppress events in
either arm.

### Outcome

The primary outcome was incident seizure or epilepsy, with no distinction
between them, ascertained by an identical algorithm in both arms: a qualifying
seizure code recorded more than 180 days after index, or antiseizure medication
continued for 180 days or more.

Qualifying codes were ICD-10 G40.x and R56.x and ICD-9 345.x and 780.39.
Excluded were F44.5 and 300.11 (psychogenic non-epileptic seizures), R56.1 and
780.32/.33 (post-traumatic, non-epileptic), febrile convulsions, Z82.0 (family
history), G43.x (migraine) and E936/966 (anticonvulsant adverse effect), together
with any descriptor denoting these. A "Spells Neurological" code counted only in
a patient also receiving indefinite antiseizure therapy.

Antiseizure medication was restricted to unambiguous agents. Topiramate and
acetazolamide were excluded because both treat IIH itself; gabapentin and
pregabalin as analgesics; and midazolam, lorazepam, diazepam and clonazepam as
procedural sedation.

Follow-up ran from the end of the 180-day washout to the earliest of the event,
last attended encounter, death, data freeze, or three years.

### Analysis

Cause-specific hazard ratios were estimated by Cox regression with a robust
sandwich variance clustered on matched set. Cumulative incidence used the
Aalen–Johansen estimator with death as a competing risk. Proportional hazards
were assessed on scaled Schoenfeld residuals. Rates carry exact Poisson
intervals and proportions exact binomial intervals.

---

## Results

### Cohort

Of 2,618 patients with IIH, 2,520 had a clinical encounter in the 12 months
before index and 2,490 were matched to at least one comparator, drawing 5,743
comparators in total (mean 2.31 per case; 319 sets of one, 1,284 of two, 692 of
three, 195 of four). 2,172 cases matched at the strictest tier. Index dates
spanned 2002 to 2025.

Matching achieved close balance: mean age 34.95 against 35.54 years
(standardised mean difference −0.059), BMI 36.39 against 36.18 kg/m²
(0.030), and 87.6% against 86.6% female (0.030).

### Primary outcome

Incident seizure or epilepsy occurred in 66 of 2,138 patients with IIH and 63 of
5,743 comparators, over 4,563 and 9,375 person-years respectively. Rates were
14.46 per 1,000 person-years (95% CI 11.19 to 18.40) and 6.72 (5.16 to 8.60),
giving a hazard ratio of **2.28 (95% CI 1.62 to 3.22; p = 2.6 × 10⁻⁶)**. The
proportional-hazards assumption was satisfied (p = 0.94).

Three-year cumulative incidence, treating death as a competing risk, was 3.83%
in the IIH arm and 1.71% among comparators — an absolute difference of 2.12
percentage points, or one additional patient with seizure or epilepsy for every
47 patients with IIH followed for three years. Eleven deaths occurred in the IIH
arm and 33 among comparators during the at-risk window.

### Sensitivity analyses

| Specification | Clinical visits only | All encounter rows |
|---|---|---|
| Primary | **2.28 (1.62 to 3.22)** | 2.79 (1.98 to 3.93) |
| Codes only, medication channel removed | 1.93 (1.34 to 2.77) | 2.35 (1.64 to 3.38) |
| Epilepsy-specific codes only (G40/345) | 2.30 (1.35 to 3.92) | 2.83 (1.66 to 4.83) |
| Opening pressure ≥ 25 cmH₂O | 2.25 (1.41 to 3.59) | 2.85 (1.78 to 4.56) |

All eight estimates are significant and fall between 1.9 and 2.9. Opening
pressures below 6 cmH₂O were treated as missing, being incompatible with a
diagnostic lumbar puncture.

The epilepsy-specific-code row deserves particular note. Restricting the outcome
to G40.x/345.x removes the non-specific convulsion codes that carry most events
in both arms, and it is the specification most sensitive to asymmetric
ascertainment: in the submitted analysis it read 0.50 and pointed in the
opposite direction. Scored identically in both arms it agrees with the primary.

### Secondary outcome

Among patients with an incident event, 41 of 66 with IIH (62%, 95% CI 49 to 74)
and 32 of 63 comparators (51%, 38 to 64) met criteria for recurrent or
established epilepsy — two or more coded seizures at least 30 days apart, an
epilepsy-specific code, or indefinite antiseizure therapy. These proportions do
not differ. The arms differ in how often seizures occur, not in how likely a
seizure is to recur once it has happened.

---

## Limitations

**Surveillance and detection.** The principal limitation is differential
ascertainment. It was assessed directly rather than assumed away, and it could
not be excluded.

Differential ascertainment is demonstrably present in this data source. All
eleven negative-control outcomes — conditions with no plausible relationship to
intracranial pressure — were more frequent in the IIH arm before index (ratios
1.6 to 5.0, all p < 0.01). Post-index, surveillance was higher in every
clinician-initiated setting: all clinical visits 2.70 (2.68 to 2.73), office or
clinic 2.92 (2.88 to 2.97), procedural or diagnostic 2.32 (2.28 to 2.37),
hospital or inpatient 2.27 (2.22 to 2.33), emergency department 5.74 (4.96 to
6.65). It was not higher in the one setting that is not clinician-initiated —
laboratory encounters, 1.14 (1.02 to 1.28).

Three observations argue against detection accounting for the whole of the
association. First, empirical calibration across the eleven controls (r = 0.66,
p = 0.026; slope 0.84, SE 0.31) predicts a detection-attributable hazard ratio
at baseline balance of 1.04 — essentially null — with the observed estimate of
2.28 lying at the extreme upper margin of its interval. Second, and more
informative than magnitude, the direction of response to healthcare-seeking
adjustment separates the outcomes cleanly: across six independent contact
measures, every one of the eleven controls moved toward the null (66 of 66
outcome-by-measure combinations; median change −29%, range −46% to −3%), while
the seizure estimate moved away from the null on all six (+7.8% to +28.6%). An
outcome generated purely by differential detection would be expected to behave as
the controls did. Third, quantitative bias analysis: an unmeasured mechanism
would need to be associated with both IIH status and seizure ascertainment by at
least 3.99-fold each, conditional on the matched and adjusted covariates, to
reduce the hazard ratio to unity, and by at least 2.62-fold to move the interval
to include unity. Five of the six measured surveillance channels fall below the
first threshold.

Three observations cut the other way, and we state them rather than omit them.
The calibration interval is 0.37 to 2.90 and **includes the observed estimate of
2.28**; on that analysis alone the association cannot be formally distinguished
from a detection artefact. On unadjusted rate ratios the seizure outcome (2.15,
1.52 to 3.04) ranks eighth of twelve among the negative-control outcomes rather
than standing apart from them — laceration 4.31, otitis 3.06, renal stone 3.00,
herpes zoster 2.92, carpal tunnel 2.90 and sprain 2.44 all exceed it. And
emergency department contact (5.74) exceeds the E-value threshold, in the setting
that is the most plausible single route by which a first seizure is ascertained.
The E-value is a threshold on associations conditional on the measured
covariates, and emergency attendance in this cohort is substantially driven by
headache presentations for which the arms were matched — but that is an argument
from mechanism, not a measurement, and it does not resolve the concern.

Our reading is therefore that detection bias is unlikely to account for the
entire association but cannot be excluded as a partial contributor. That
conclusion rests on the directional evidence and the quantitative bias analysis,
not on the calibration interval, and it is an interpretation rather than a
demonstration.

**Surveillance could not be characterised where it would matter most.** The
encounter extract carries no specialty field — none of the 171 encounter types
names a department — so neurology and ophthalmology visit rates are not
estimable. Imaging and EEG are likewise unavailable as comparable measures: the
radiology extract covers comparators only, and EEG is recorded for 393 IIH
patients and no comparators. The channels most specific to seizure ascertainment
are the ones we cannot measure.

**Post-index contact was not adjusted for in the primary model.** Post-index
healthcare contact is a consequence of the outcome as well as a determinant of
its ascertainment, so conditioning on it induces collider bias. It is reported
descriptively and as a sensitivity analysis only; contact adjustment raises the
estimate to 2.57.

**Comparator.** The comparator arm was drawn from the general clinical population
rather than from a condition under equivalent specialist follow-up. An active
comparator matched on reason for neurologic and neuro-ophthalmologic surveillance
would equalise ascertainment by design rather than by adjustment, and is the
analysis required to resolve the residual uncertainty. No available condition
satisfies both requirements — comparable surveillance intensity and no
established seizure association — so such a design would need to bracket the bias
with two arms failing in opposite directions.

**Ascertainment definition.** Seizure status was defined by diagnosis codes
together with sustained anti-seizure medication exposure, applied symmetrically
to both arms. Medication capture is not comparable between the arms: the case
file records inpatient administrations, the comparator file outpatient
prescriptions, and outpatient prescribing for the IIH arm was not obtainable.
Chronic outpatient therapy in the IIH arm is therefore under-captured. Removing
the medication channel entirely leaves the estimate at 1.93 (1.34 to 2.77).
Code-based seizure ascertainment is imperfect, and chart validation of
code-positive comparators has not been completed.

**Design.** This is an observational matched cohort. The association should not
be read as causal. No mechanism linking raised intracranial pressure to seizure
generation is established or tested here, and residual confounding by factors
raising both the likelihood of an IIH diagnosis and the likelihood of a seizure
diagnosis cannot be excluded.

---

*Supporting tables: K_T38 (primary), K_T45 and K_T42 (negative controls),
K_T48 (calibration), K_T50 (contact robustness), K_T52 (collider), K_T54
(post-index surveillance), K_T55 (negative-outcome rates), K_T56 (E-values;
supersedes T4e, which was computed against an earlier estimate). Full
pre-specification in `report/STATISTICAL_ANALYSIS_PLAN.md`; drafted manuscript
text in `report/LIMITATIONS_AND_INTERPRETATION.md`.*
