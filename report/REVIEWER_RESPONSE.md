# Response to reviewer comments

We thank the reviewer. Several comments led us to re-examine the outcome
ascertainment, and that examination found a defect more serious than any raised:
**the two arms had not been ascertained by the same standard.** The analysis has
been rebuilt from source with a single algorithm applied identically to both
arms, and the manuscript now reports the result of that rebuild. We set that out
first, because it changes the headline estimate, and then answer each comment.

Every figure below is reproducible from `R/K15_final_analysis.R` and
`R/K16_final_figures.R`.

---

## The principal change

In the submitted analysis the IIH arm was chart-abstracted while the comparator
arm was scored by a code algorithm, and the two were not equivalent. Of 102 IIH
events, 70 rested only on a non-specific convulsion code (R56.9 or 780.39). All
64 comparator events carried an epilepsy-specific code, and 194 comparators
carrying qualifying codes within their own follow-up were never counted. The
derivation record confirms it: the `outcome_criterion` field is populated for
every comparator and blank for every case.

The outcome is now defined once and applied to both arms: a qualifying seizure
code after the 180-day washout, or antiseizure medication continued 180 days or
more. Matching was rebuilt against dated encounter records covering all 2,618
cases and all 9,122 comparators, with each comparator inheriting its case's
index date and every time-anchored quantity re-derived from it.

**The primary estimate is now a hazard ratio of 2.28 (95% CI 1.62 to 3.22;
p = 2.6 × 10⁻⁶),** with three-year cumulative incidence 3.83% against 1.71%, an
absolute difference of 2.12 percentage points and a number needed to harm of 47.
Eight specifications — four outcome definitions crossed with two encounter
definitions — all fall between 1.9 and 2.9 and all are significant (Figure 2).

---

## 1. The "late excess" claim contradicts the data

**Accepted, and removed.** The reviewer is correct. In the submitted analysis
60% of the three-year risk and 64% of the three-year risk difference were already
present at one year. The claim has been removed from Results, Discussion and
Conclusion. The rebuilt cumulative-incidence figure shows curves separating
early and continuing to diverge more slowly thereafter, and is described that
way.

## 2. The timing numbers do not add up

**The reviewer is right that they disagreed; the cause was a clock-origin
mismatch rather than an error in the event counts.** Latency had been measured
from the index date and the survival analysis from the end of the 180-day
washout, so "within three years" meant index + 3 years in one table and index +
3.49 years in another (55 and 14 events against 59 and 15). Both tables were
internally correct and mutually inconsistent. All timing results are now
reported on the survival clock with the origin stated.

## 3. The explanation for the restriction result was backwards

**We agree the published explanation was wrong. We tested the proposed
replacement and it is not supported, so we have not adopted it.**

The suggestion is that comparators without prior records could not be screened
for old seizures, so prevalent cases were counted as incident. That predicts
events clustering soon after index among the excluded comparators. They do not:
21% of their events fell within one year of index against 25% among those
retained, with median latencies of 614 and 584 days. The prediction fails, and
in the opposite direction.

This is now moot in the rebuilt analysis, because engagement is evaluated
against the matched case's index date at the point of matching rather than
applied as a post-hoc restriction, so no comparator is deleted after selection.
We would welcome guidance if the reviewer considers a specific alternative worth
testing.

## 4. The negative-control extrapolation may be unfair

**The methodological point is correct and we have adopted it. Measured, it moves
the result in the opposite direction to the one anticipated.**

Placing seizure at a prevalence ratio of 1.00 "by design" was an assumption
rather than a measurement. Computed as it was for the other outcomes, prevalent
seizure coding before index is 0.31% in the IIH arm and 0.38% among comparators
— a ratio of **0.80**, not a value above one. The predicted detection-only
hazard ratio therefore falls from 0.79 (0.28 to 2.24) at a ratio of 1.00 to
**0.63 (0.21 to 1.91)** at the measured ratio. The manuscript now reports the
measured ratio.

## 5. Some negative controls are not clean

**Accepted in full, and on re-examination the problem is worse than the reviewer
suggests. We have withdrawn the specificity claim entirely.**

The reviewer is right about each mechanism: acetazolamide and topiramate
predispose to renal stones and both treat IIH; gallstones follow weight loss and
bariatric surgery; carpal tunnel syndrome is associated with obesity.

Recomputing the panel on the rebuilt cohort showed more. Five of six candidate
controls are already more prevalent in the IIH arm before index — ratios of 1.6
to 3.2, all p < 0.01 — so none of them can distinguish detection from whatever
produced that imbalance. The only outcome meeting the balance criterion, limb
fracture, has two and seven events and cannot be estimated. And the calibration
extrapolation reported in the submitted manuscript does not replicate: across
the five estimable controls the relationship between baseline imbalance and
apparent effect is weak and not significant (r = 0.28, p = 0.65; slope 0.48,
SE 0.94), giving a predicted detection-only hazard ratio at balance of 1.51 with
an interval of 0.07 to 30.8. The earlier figure (r = 0.925) was computed on the
arm-asymmetric matching and does not carry over.

We also note, because a reader would find it, that several controls sit at
hazard ratios of 2.0 to 3.1, overlapping the primary estimate. Since those
outcomes are baseline-imbalanced this does not establish that the seizure
association is detection-driven, but it cannot be excluded either.

The manuscript therefore makes no specificity claim. The negative-control figure
is retained and its caption states what it shows: that the approach cannot
adjudicate specificity in these data.

## 6. Exclusions may have been applied only to comparators

**Confirmed applied to both arms.** The investigators have confirmed that
traumatic brain injury, stroke, intracranial tumour, cerebral venous sinus
thrombosis and craniotomy were excluded from the case pool as well as the
comparator pool, as protocol section 2.2 specifies.

## 7. G93.2 also captures cerebral venous sinus thrombosis

**Partly addressed by design, and now supported by the requested sensitivity
analysis.** Cerebral venous sinus thrombosis is an explicit exclusion at or
before index, and every case is anchored to a first diagnostic lumbar puncture,
so the lumbar-puncture tier is the entire cohort and a separate tier analysis is
not available.

Restricting to patients with an opening pressure of 25 cmH₂O or more, with their
matched comparators, gives **2.25 (1.41 to 3.59)** against 2.28 in the primary.
Opening pressure is recorded for 73% of the IIH arm; values below 6 cmH₂O were
treated as missing, being incompatible with a diagnostic lumbar puncture.

## 8. The outcome definition needs work

**This comment led to the principal change described above.** Taking the three
specific points in turn:

*ICD-9 codes in the prior-epilepsy exclusion.* The protocol does list them
(345.x and 780.39). Implementation had been imperfect rather than absent: six
patients had entered with a pre-index qualifying code whose only evidence was
ICD-9. The rebuilt analysis applies the exclusion to both coding systems.

*Topiramate.* Topiramate is not counted as antiseizure evidence, alongside
acetazolamide, precisely because both treat IIH. This is now stated in Methods.
Gabapentin, pregabalin and the benzodiazepines are likewise excluded.

*R56.9 capturing functional seizures and syncope.* Psychogenic and non-epileptic
codes are excluded explicitly. Beyond that, the reviewer's concern is answered
by the sensitivity analysis restricted to epilepsy-specific codes, which removes
R56.x and 780.39 entirely: **2.30 (1.35 to 3.92)**. This is the specification
most sensitive to asymmetric ascertainment — it read 0.50 in the submitted
analysis and pointed the other way — and with both arms scored identically it
agrees with the primary.

## 9. Lower mortality in the IIH arm

**Accepted, and now discussed.** Deaths occurred at 2.50 per 1,000 person-years
in the IIH arm against 4.40 among comparators. Matched comparators dying at
nearly twice the rate of patients with a non-fatal headache disorder is not
plausible as a peer group, and indicates that matching on age, sex and BMI did
not produce comparators of similar underlying health. The Discussion now states
this and treats it as evidence that residual differences in baseline health and
healthcare contact persist after matching.

---

## Remaining limitations, stated in the manuscript

Comparators are ascertained from codes while the IIH events were additionally
chart-confirmed; coded ascertainment over-counts, so the comparator count is if
anything generous and the estimate conservative. Medication capture is not
comparable between the arms — inpatient administrations for cases, outpatient
prescriptions for comparators — and outpatient prescribing data for the IIH arm
was not obtainable; removing the medication channel entirely leaves the estimate
at 1.93 (1.34 to 2.77). An outcome defined by benzodiazepine exposure alone
yields a hazard ratio of similar magnitude, so residual confounding by
healthcare contact cannot be excluded. Median follow-up was longer in the IIH
arm (2.77 against 1.51 years).
