# Incident Seizures and Epilepsy After Idiopathic Intracranial Hypertension: A Matched Cohort Study

**Authors:** Selim Tarabeah, [co-authors], Michelle Lin
**Affiliation:** Mayo Clinic

> **Drafting notes for the authors.** Every number is drawn from the final
> from-scratch run of 18 September 2026 (`report/FINAL_RESULTS.md`); the
> supporting table is named in a comment beside each. Citations appear as
> `[CITE: …]` placeholders — none have been invented. Text in `«»` is a decision
> for the authors.

---

## Abstract

**Objective.** To estimate the rate of incident seizures and epilepsy after a
diagnosis of idiopathic intracranial hypertension (IIH), and to assess whether
differential healthcare surveillance could account for any association observed.

**Methods.** Matched cohort study in an integrated health-record system. Adults
with IIH were matched to comparators without IIH on sex, age, body mass index
(BMI) and BMI calendar year, in five relaxing tiers. Comparators inherited the
index date of the case to whom they were matched; a 180-day washout and a
prevalent-seizure exclusion were applied to both arms at that shared date. Both
arms were required to have at least one dated clinical encounter in the 12 months
before the index date. The outcome, defined identically in both arms, was a
qualifying seizure or epilepsy code after the washout, or anti-seizure medication
continued for 180 days or more. Cause-specific hazard ratios were estimated by
Cox regression with a robust variance clustered on the matched set. Differential
detection was assessed using eleven negative-control outcomes, empirical
calibration, six healthcare-contact measures and quantitative bias analysis.

**Results.** 2,490 IIH cases were matched to 5,743 comparators; 2,138 cases and
5,743 comparators contributed post-washout follow-up. Baseline covariates were
closely balanced (standardised mean differences ≤0.06 for age, sex and BMI).
Incident seizure or epilepsy occurred in 66 IIH patients (14.46 per 1,000
person-years, 95% CI 11.19–18.40) and 63 comparators (6.72, 5.16–8.60), giving a
hazard ratio of **2.28 (95% CI 1.62–3.22; p = 2.6 × 10⁻⁶)**. Proportional hazards
held (p = 0.94). Three-year cumulative incidence was 3.83% versus 1.71% (risk
difference 2.12 percentage points; number needed to harm 47). The estimate was
stable across specifications (1.93 to 2.79), landmark analyses (2.22 to 2.49),
competing-risk modelling (subdistribution HR 2.28) and overlap weighting (2.31).
Surveillance was higher in the IIH arm in every clinician-initiated setting
(rate ratios 2.27 to 5.74) but not in laboratory encounters (1.14). All eleven
negative-control outcomes were imbalanced at baseline (ratios 1.6 to 5.0). Under
healthcare-seeking adjustment every negative control moved toward the null across
all six contact measures, whereas the seizure estimate moved away from it.
Empirical calibration predicted a detection-attributable hazard ratio of 1.04
(0.37–2.90), an interval that includes the observed estimate.

**Conclusions.** IIH was associated with a substantially higher rate of incident
seizures and epilepsy. Differential surveillance was assessed directly and is
unlikely to account for the entire association, but could not be excluded as a
partial contributor. These findings support heightened clinical attention to
seizure symptoms in patients with IIH; they do not establish causation, and
confirmation in a cohort under equivalent specialist follow-up is required.

---

## Introduction

Idiopathic intracranial hypertension is characterised by raised intracranial
pressure without an identifiable structural, vascular or infectious cause. It
occurs predominantly in women of reproductive age with elevated body mass index,
and its recognised morbidity is dominated by headache and by visual loss from
papilledema. `[CITE: epidemiology and natural history of IIH]`

Whether IIH carries an increased risk of seizures is unresolved. Raised
intracranial pressure has plausible routes to cortical hyperexcitability, and
structural correlates of IIH such as meningoceles and encephaloceles of the skull
base have been described in patients presenting with seizures.
`[CITE: skull base meningocele / encephalocele and epilepsy]` Against this,
reported seizures in IIH cohorts have often been attributable to acetazolamide-
related metabolic disturbance, to co-existing conditions, or to the circumstances
of acute presentation rather than to intracranial hypertension itself.
`[CITE: prior IIH seizure reports]`

The question is difficult to answer with health-record data for a specific
reason. Patients with IIH are, by the nature of their condition, under intensive
specialist follow-up — neurology, neuro-ophthalmology, repeated imaging, frequent
clinic attendance. Any outcome ascertained through contact with the health system
will therefore appear more common in such patients, whether or not its true
incidence differs. An association between IIH and seizures is exactly the shape
of finding that differential detection can manufacture.

We therefore designed this study to do two things: to estimate the rate of
incident seizures and epilepsy after IIH in a matched cohort with symmetric
ascertainment, and to assess as directly as the data permit whether differential
surveillance could account for whatever we found.

---

## Methods

### Design and data source

Matched cohort study using an integrated electronic health record covering
inpatient, outpatient, emergency, procedural and laboratory encounters, with
linked diagnosis codes, medication records, flowsheet vital signs and vital
status. The data freeze was 3 September 2026. «Institutional review board
statement and approval number to be inserted.»

### Cohort and index date

Adults with a diagnosis of IIH formed the exposed arm. Each case was assigned an
index date at diagnosis. Comparators were patients without any IIH code at any
date.

**Comparators inherited the index date of the case to whom they were matched.**
Every time-anchored quantity — eligibility, washout, prevalence exclusion,
covariate measurement and the start of follow-up — was then computed from that
single shared date, so that the two arms of a matched set were observed over the
same calendar window. This is a protocol requirement and not a convenience: in a
preliminary analysis in which comparators retained their own index dates, 71% of
comparators differed from their matched case by more than 30 days and 48% by more
than one year, and that analysis was discarded.

### Eligibility

Both arms were required to have at least one **dated clinical encounter in the 12
months before the index date**, establishing that the patient was under
observation in the system at the time follow-up began. Encounter type was used to
distinguish clinical contact from administrative activity — patient messages,
order entry, refills, wait lists and record-keeping — using an exclusion list
applied identically to both arms. Approximately 60% of encounter rows in each arm
were administrative. Because this classification is a judgement, the entire
analysis was run twice: once counting clinical visits only (primary) and once
counting every encounter row (sensitivity). **Encounter type determined
eligibility and the censoring date only; it never entered the outcome
definition.**

Patients with a seizure code or qualifying anti-seizure medication before the end
of the washout were excluded from both arms, evaluated at the shared index date.

### Matching

Cases were matched to comparators on sex, age at index, BMI, and the calendar
year in which BMI was recorded, using five progressively relaxing tiers (age
within 3 then 5 years; BMI within 3 then 5 units). Race was specified as a
matching variable but **was absent for every IIH case and therefore never
constrained the match**; this is reported rather than concealed, and race is not
claimed as a matched covariate anywhere in this paper. BMI was taken from dated
flowsheet records, using the value closest in calendar year to the index date;
implausible values below the physiological range were excluded. Matching was
without replacement in four passes, yielding a variable ratio.

### Outcome

The outcome was **incident seizure or epilepsy after the 180-day washout**,
defined by a single rule applied identically to both arms:

- a qualifying diagnosis code (G40, 345, R56.9, 780.39); **or**
- anti-seizure medication continued for 180 days or more.

Codes for febrile, psychogenic and conversion seizures, family history, migraine,
syncope and drug adverse effects did not qualify. "Spells, neurological" counted
only when accompanied by chronic anti-seizure therapy. Topiramate, acetazolamide,
gabapentin, pregabalin and benzodiazepines were not treated as evidence of
seizure, since each has common non-seizure indications in this population.

A secondary outcome distinguished **recurrent unprovoked seizures or epilepsy**
from a single seizure event, among those with any event.

### Follow-up

Follow-up ran from the end of the washout to the first of: the outcome, death,
the last attended encounter, the data freeze, or three years. The censoring date
was derived from attendance and is **independent of the outcome**; an
outcome-censored clock cannot be used to define the at-risk window, and an
earlier analysis that did so was corrected.

### Statistical analysis

Cause-specific hazard ratios were estimated by Cox proportional-hazards
regression with a robust sandwich variance clustered on the matched set.
Proportional hazards were assessed by scaled Schoenfeld residuals. Cumulative
incidence was estimated by the Aalen–Johansen estimator treating death as a
competing event; 1 − Kaplan–Meier was not used. Subdistribution hazards were
estimated by the Fine–Gray model. Incidence rates carry exact Poisson intervals
and proportions exact binomial intervals. Subgroup effects were tested by a Wald
test on the interaction term using the sandwich covariance, never by comparing
significance between subgroups. An overlap-weighted analysis was fitted as a
non-matched check. Analyses were pre-specified in a statistical analysis plan
(`report/STATISTICAL_ANALYSIS_PLAN.md`); deviations are reported in that
document.

### Assessment of differential detection

Because differential surveillance is the principal threat to validity, it was
assessed directly by five methods, all pre-specified:

1. **Negative-control outcomes.** Eleven conditions with no plausible
   relationship to intracranial pressure, ascertained by the same mechanism as
   the primary outcome. Baseline prevalence was compared first, and decided
   admission.
2. **Empirical calibration.** The observed log hazard ratio for each control was
   regressed on its log baseline prevalence ratio, and the fitted value at
   baseline balance taken as the detection-attributable effect.
3. **Healthcare-seeking adjustment.** Six independent measures of pre-index
   contact, each used to adjust every outcome, examining the *direction* of
   movement rather than its size.
4. **Post-index surveillance.** Encounter rates by setting, reported
   descriptively. Post-index contact was **not** adjusted for in the primary
   model: it is a consequence of the outcome as well as a determinant of its
   ascertainment, and conditioning on it induces collider bias. This was
   demonstrated empirically rather than asserted.
5. **Quantitative bias analysis.** E-values for the point estimate and the
   confidence limit, compared against the measured surveillance rate ratios.

### Reproducibility

The entire analysis runs from the raw exports in a single command
(`./run_final.sh`). Derived datasets are deleted before the run. A provenance
gate verifies every input before any analysis executes and halts if the encounter
export falls at or below Excel's row ceiling, the failure mode that silently
truncated an earlier extract. A freshness gate verifies that every table entering
the results document was written by that run. Raw files are opened read-only.

---

## Results

### Cohort

Of 2,520 IIH patients meeting the engagement requirement, 2,490 (98.8%) were
matched, to 5,743 comparators (mean 2.31 per case; 87% matched at the strictest
tier). 2,138 cases and 5,743 comparators contributed follow-up beyond the
washout. *(Table K_T40)*

### Baseline characteristics

Age, sex and BMI were closely balanced (Table 1; standardised mean differences
−0.065, 0.034 and 0.050). Two imbalances were not resolved by matching and are
reported rather than smoothed over. Hypertension was more common in the IIH arm
(22.1% versus 16.4%, SMD 0.146). Recorded smoking differed implausibly (0.7%
versus 7.5%), which reflects differential capture of social history between the
two source extracts rather than a real difference, and smoking was therefore not
used as a covariate. Pre-index clinical visits differed substantially (20.6
versus 9.2 per year, SMD 0.526) — this is the surveillance imbalance itself, and
is the subject of the detection analyses below. *(Table SAP_T1)*

### Primary outcome

Incident seizure or epilepsy occurred in **66 of 2,138 IIH patients** (14.46 per
1,000 person-years, 95% CI 11.19–18.40) and **63 of 5,743 comparators** (6.72,
5.16–8.60). The cause-specific hazard ratio was **2.28 (95% CI 1.62–3.22;
p = 2.6 × 10⁻⁶)**, with proportional hazards satisfied (p = 0.94). Three-year
cumulative incidence was **3.83% versus 1.71%**, a risk difference of 2.12
percentage points and a number needed to harm of 47 over three years (Figure 1).
*(Table K_T38)*

### Sensitivity analyses

The estimate was stable across every specification examined (Figure 2):

| Specification | Hazard ratio |
|---|---|
| Primary | 2.28 (1.62–3.22) |
| Codes only, medication channel removed | 1.93 (1.34–2.77) |
| Epilepsy-specific codes only (G40/345) | 2.30 (1.35–3.92) |
| Restricted to opening pressure ≥25 cmH₂O | 2.25 (1.41–3.59) |
| All encounter rows counted as contact | 2.79 (1.98–3.93) |
| Complete matched sets only | 2.06 (1.46–2.92) |
| Landmark, first 30 days excluded | 2.49 (1.73–3.58) |
| Landmark, first 90 days excluded | 2.29 (1.54–3.41) |
| Landmark, first 180 days excluded | 2.22 (1.40–3.51) |
| Fine–Gray subdistribution | 2.28 (1.62–3.22) |
| Overlap-weighted | 2.31 (1.56–3.43) |
| Adjusted for OSA, hypertension and PCOS | 2.11 (1.48–3.01) |

Two of these warrant comment. The **complete-sets** analysis addresses a
structural feature of the matching: comparators were required at selection to
have follow-up beyond the washout, whereas cases were not, so 352 matched sets
lost their case while retaining 789 comparators who contributed person-time and
two events without a case in the set. Removing those comparators attenuates the
estimate to 2.06 (1.46–2.92) — a reduction of about 10%, which does not change
the conclusion but is reported because it is a real feature of the design.
«Authors to decide whether the complete-sets estimate should be the primary
one; the argument for it is that every comparator then sits in a set with its
case.» *(Table Z_T01)*

The **all-rows** analysis gives a larger estimate (2.79) than the primary,
confirming that the primary specification is the conservative of the two.

The **comorbidity-adjusted** analysis addresses the covariates matching did not
balance. Obstructive sleep apnoea (29.5% versus 15.4%, SMD 0.342), polycystic
ovary syndrome (0.171) and hypertension (0.146) all exceeded the balance
threshold. Confounding requires both imbalance and association with the outcome,
and only OSA met both (HR for seizure 1.87, 1.29–2.71, p < 0.001); PCOS was
imbalanced but unrelated to the outcome (1.14, 0.64–2.02, p = 0.65) and cannot
confound. Adjusting for all three moves the estimate from 2.28 to **2.11
(1.48–3.01)**, a reduction of 7.5%, driven entirely by OSA. Adding pre-index
visits returns it to 2.33 (1.58–3.45). Sleep apnoea therefore accounts for a
small part of the association and not for its existence. *(Tables Z_T04, Z_T05)*

Death was less frequent in the IIH arm (cause-specific HR 0.61, 0.29–1.29), so
the competing risk does not operate in a direction that would inflate the seizure
estimate. *(Table SAP_T4)*

### Secondary outcome

Among patients with any event, **41 of 66 IIH events (62%, 95% CI 49–74) were
recurrent seizures or epilepsy**, compared with 32 of 63 comparator events (51%,
38–64) (Figure 3). The difference is compatible with chance at this sample size,
and we do not claim that events in IIH patients were more severe. *(Table K_T39)*

### Subgroups

No interaction reached significance: age <35 versus ≥35 (1.90 versus 2.72,
interaction p = 0.31), BMI <35 versus ≥35 (2.86 versus 1.87, p = 0.26), and sex
(female 1.98, male 5.12, p = 0.055). The male estimate rests on 13 and 7 events
and should not be interpreted as evidence of effect modification. *(Table SAP_T5)*

### Differential detection

**Surveillance is unequal.** Post-index encounter rates were higher in the IIH arm
in every clinician-initiated setting: all clinical visits 2.70 (2.68–2.73),
office or clinic 2.92 (2.88–2.97), procedural or diagnostic 2.32 (2.28–2.37),
hospital or inpatient 2.27 (2.22–2.33), emergency department 5.74 (4.96–6.65).
They were **not** meaningfully higher in the one setting that is not
clinician-initiated: laboratory encounters, 1.14 (1.02–1.28). *(Table K_T54)*

**Ascertainment differs, and the negative controls show it.** All eleven controls
were more prevalent in the IIH arm before the index date (ratios 1.6 to 5.0, all
p < 0.01), so none satisfied the pre-specified balance criterion and the panel
cannot be used to claim specificity. On unadjusted rate ratios the seizure
outcome (2.15, 1.52–3.04) ranked **eighth of twelve** among these outcomes:
laceration (4.31), otitis (3.06), renal stone (3.00), herpes zoster (2.92),
carpal tunnel (2.90) and sprain (2.44) all exceeded it. *(Tables K_T42, K_T45,
K_T55)*

**Calibration does not exclude a detection explanation.** Regressing the observed
log hazard ratio on the log baseline ratio across the eleven controls gave
r = 0.66 (p = 0.026, slope 0.84, SE 0.31) and a predicted detection-attributable
hazard ratio at baseline balance of **1.04, 95% CI 0.37–2.90** (Figure 4). That
interval **includes the observed estimate of 2.28**. On this analysis alone the
association cannot be formally distinguished from a detection artefact.
*(Table K_T48)*

**The direction of response separates the outcomes.** Across six independent
measures of pre-index healthcare contact, every one of the eleven negative
controls moved **toward** the null under adjustment — 66 of 66 outcome-by-measure
combinations, median change −29% (range −46% to −3%) — whereas the seizure
estimate moved **away** from the null under all six (+7.8% to +28.6%) (Figure 5).
An outcome generated purely by differential detection would be expected to behave
as the controls did. *(Table K_T50)*

**Post-index contact is a collider, demonstrably.** Adjusting for post-index
contact drove the seizure estimate to 1.25 (0.85–1.85) — but it also drove the
upper respiratory infection control to 0.75 (0.61–0.92) and the fracture control
to 0.39 (0.23–0.67), both implausibly protective. Adjustment that makes IIH
appear to protect against fractures is not removing bias; it is introducing it.
*(Table K_T52)*

**Quantitative bias analysis.** An unmeasured mechanism would need to be
associated with both IIH status and seizure ascertainment by at least **3.99-fold
each**, conditional on the matched covariates, to reduce the hazard ratio to
unity, and by at least 2.62-fold to move the interval to include unity. Five of
the six measured surveillance channels fall below the first threshold. The
exception is emergency department contact at 5.74, which exceeds it.
*(Table K_T56)*

---

## Discussion

In a matched cohort with symmetric ascertainment, IIH was associated with roughly
a doubling of the rate of incident seizures and epilepsy: 14.5 versus 6.7 per
1,000 person-years, hazard ratio 2.28, an absolute three-year risk difference of
2.1 percentage points. The estimate was insensitive to how the outcome was
defined, to how encounters were counted, to when follow-up began, to the
competing risk of death, and to the analytic model.

The central interpretive question is not whether the association is statistically
robust — it is — but whether it is real. Patients with IIH are seen more often
than matched comparators, and an outcome that is ascertained through contact will
be found more often in people who are seen more often.

Three observations argue that detection does not account for the whole of the
association. First, empirical calibration across eleven negative controls
predicts a detection-attributable hazard ratio of 1.04: the central estimate of
what differential ascertainment alone should produce is essentially null, and the
observed 2.28 sits at the extreme upper margin of its interval. Second, and more
informative than magnitude, the direction of response to healthcare-seeking
adjustment separates the outcomes completely — 66 of 66 control-by-measure
combinations move toward the null while seizure moves away in all six. Third,
surveillance is elevated in every clinician-initiated setting but not in
laboratory encounters, the one channel a clinician does not initiate, and the
association persists.

Three observations cut the other way, and we state them as plainly. The
calibration interval includes the observed estimate. On unadjusted rate ratios
the seizure outcome does not stand apart from the negative controls but sits
eighth of twelve among them. And emergency department contact, at 5.74, exceeds
the E-value threshold in precisely the setting where a first seizure is most
likely to be ascertained. The E-value is a threshold on associations conditional
on the measured covariates, and emergency attendance in this cohort is
substantially driven by headache presentations for which the arms were matched —
but that is an argument from mechanism, not a measurement, and it does not
resolve the concern.

Our reading is therefore that differential detection is **unlikely to account for
the entire association but cannot be excluded as a partial contributor**. That
conclusion rests on the directional evidence and the quantitative bias analysis,
not on the calibration interval, and it is an interpretation rather than a
demonstration.

«Authors: a paragraph situating these findings against the prior literature
belongs here, once references are selected. `[CITE: prior cohort and
case-control studies of seizure risk in IIH]`»

If the association is causal in part, the mechanism is not established here. Skull
base meningoceles and encephaloceles, cortical irritation from chronically raised
pressure, and shared risk factors such as obesity and obstructive sleep apnoea
are each plausible and none is tested by these data. `[CITE: candidate
mechanisms]`

### Clinical implications

The absolute risk is low — about 3.8% over three years, against 1.7% in matched
comparators — and does not justify screening electroencephalography or
prophylactic treatment. What it supports is a lower threshold for taking seizure
symptoms seriously in a patient with IIH, and for investigating a first event
rather than attributing it to the headache disorder.

---

## Limitations

**Differential ascertainment could not be excluded.** It was assessed by five
methods and is present in this data source: all eleven negative controls are
imbalanced at baseline, and post-index surveillance is higher in every
clinician-initiated setting. The calibration interval contains the observed
estimate, and emergency department contact exceeds the E-value threshold. Our
conclusion that detection does not explain the whole association is an
interpretation supported by directional evidence, not a demonstration.

**The channels most specific to seizure ascertainment could not be measured.** The
encounter extract carries no specialty field — none of 171 encounter types names a
department — so neurology and ophthalmology visit rates are not estimable.
Imaging and electroencephalography are likewise unavailable as comparable
measures: the radiology extract covers comparators only, and EEG is recorded for
393 IIH patients and no comparators.

**No active comparator.** The comparator arm was drawn from the general clinical
population rather than from a condition under equivalent specialist follow-up. An
active comparator matched on reason for neurologic and neuro-ophthalmologic
surveillance would equalise ascertainment by design rather than by adjustment,
and is the analysis required to resolve the residual uncertainty. No single
condition satisfies both requirements — comparable surveillance intensity and no
established seizure association — so such a design would need to bracket the bias
with two comparator arms failing in opposite directions
(`report/ACTIVE_COMPARATOR_REQUEST.md`).

**Asymmetric eligibility screening.** Comparators were required at selection to
have follow-up beyond the washout; cases were not. The resulting orphaned
comparators inflate the comparator denominator, and removing them attenuates the
estimate from 2.28 to 2.06.

**Medication capture is not comparable between the arms.** The case file records
inpatient administrations; the comparator file records outpatient prescriptions,
and outpatient prescribing for the IIH arm was not obtainable. Chronic outpatient
therapy in the IIH arm is under-captured. Removing the medication channel
entirely leaves the estimate at 1.93 (1.34–2.77).

**Race could not be used.** It is absent for every IIH case and therefore never
constrained the match, despite being specified.

**Outcome misclassification.** Code-based seizure ascertainment is imperfect, and
chart validation of code-positive comparators has not been completed.

**Unmeasured and residual confounding by sleep-disordered breathing.** OSA was
substantially more common in the IIH arm despite matching, and is itself
associated with seizure risk in this cohort. Adjustment reduced the estimate by
7.5% but OSA is ascertained from codes and is under-diagnosed in both arms, so
residual confounding through this pathway remains plausible.

**Observational design.** No causal claim is made, and residual confounding by
factors raising both the likelihood of an IIH diagnosis and the likelihood of a
seizure diagnosis cannot be excluded.

---

## Conclusion

Idiopathic intracranial hypertension was associated with a higher rate of
incident seizures and epilepsy, with an absolute three-year risk difference of
about two percentage points. Differential healthcare surveillance was assessed
directly and is unlikely to account for the entire association, but could not be
excluded as a partial contributor. These findings support heightened clinical
attention to seizure symptoms in patients with IIH; they do not establish
causation, and confirmation in a cohort under equivalent specialist follow-up is
required.

---

## Tables

**Table 1.** Baseline characteristics of the matched cohort. *(SAP_T1)*
**Table 2.** Incidence rates, hazard ratios and cumulative incidence for the
primary outcome and its sensitivity analyses. *(K_T38, Z_T01)*
**Table 3.** Post-index healthcare surveillance by encounter setting. *(K_T54)*
**Table 4.** Negative-control outcomes: baseline prevalence ratios, post-index
hazard ratios and unadjusted rate ratios. *(K_T42, K_T45, K_T55)*

## Figure legends

**Figure 1.** Cumulative incidence of seizure or epilepsy after the 180-day
washout, by cohort, estimated by the Aalen–Johansen method with death as a
competing event. Shaded bands are 95% confidence intervals; numbers at risk are
shown beneath. *(K_F1)*

**Figure 2.** Hazard ratio for incident seizure or epilepsy across outcome
definitions, encounter definitions, landmark starting points and analytic models.
Points are hazard ratios, horizontal lines 95% confidence intervals, and the
vertical reference line the null. *(K_F2)*

**Figure 3.** Proportion of events classified as recurrent seizures or epilepsy
rather than a single seizure, by cohort, with exact binomial intervals. *(K_F3)*

**Figure 4.** Relationship between baseline imbalance and apparent post-index
effect across eleven negative-control outcomes. The fitted line is extrapolated
to baseline balance to give the predicted detection-attributable hazard ratio;
the observed seizure estimate is plotted for comparison. *(K_F8)*

**Figure 5.** Direction of movement of each outcome's hazard ratio under
adjustment for six independent measures of pre-index healthcare contact. Negative
controls are shown in grey, the primary outcome in colour. *(K_F7)*

---

*Analysis code, statistical analysis plan and complete result tables:
`report/FINAL_RESULTS.md`, `report/STATISTICAL_ANALYSIS_PLAN.md`. The full
analysis reproduces from the raw exports with `./run_final.sh`.*
