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

**The methodological point is correct and we have adopted it. The framework has
since been rebuilt on a larger panel, and the answer it now gives is less
favourable to us than the one in the submitted manuscript.**

Placing seizure at a prevalence ratio of 1.00 "by design" was an assumption
rather than a measurement, and we have withdrawn it. The panel was rebuilt from
six candidate controls to **eleven**, selected as outcomes with no plausible
relationship to intracranial pressure and extracted on the re-matched cohort.
Calibration now regresses the observed log hazard ratio on the log baseline
prevalence ratio across all eleven: r = 0.66 (p = 0.026), slope 0.84 (SE 0.31),
giving a predicted detection-attributable hazard ratio at baseline balance of
**1.04, with a 95% interval of 0.37 to 2.90**.

That interval **includes our observed estimate of 2.28**. We report this
explicitly in the Limitations rather than the single extrapolated point value
used previously. The r = 0.925 figure in the submitted manuscript was computed on
the arm-asymmetric matching and does not carry over.

## 5. Some negative controls are not clean

**Accepted in full. The specificity claim is withdrawn; what replaces it is a
weaker, directional argument, and we have been explicit about which parts of our
conclusion it can and cannot support.**

The reviewer is right about each mechanism: acetazolamide and topiramate
predispose to renal stones and both treat IIH; gallstones follow weight loss and
bariatric surgery; carpal tunnel syndrome is associated with obesity.

Re-examination on the rebuilt cohort showed the problem is general rather than
confined to those three. **All eleven** controls are more prevalent in the IIH arm
before index — ratios 1.6 to 5.0, all p < 0.01 — so none can distinguish
detection from whatever produced that imbalance. We therefore make no specificity
claim anywhere in the manuscript, and the negative-control figure caption states
what the panel shows: that baseline imbalance is pervasive in this data source.

We also report, because a reader would find it, that on unadjusted rate ratios
the seizure outcome (2.15) ranks **eighth of twelve** among these outcomes rather
than standing apart from them. Laceration (4.31), otitis (3.06), renal stone
(3.00), herpes zoster (2.92), carpal tunnel (2.90) and sprain (2.44) all exceed
it.

What the panel does support is a directional argument, which we advance as an
interpretation and not a demonstration. Across six independent healthcare-contact
measures, every one of the eleven controls moved **toward** the null under
adjustment — 66 of 66 outcome-by-measure combinations, median change −29% — while
the seizure estimate moved **away** from the null on all six (+7.8% to +28.6%).
An outcome generated purely by differential detection would be expected to behave
as the controls did. We have added a quantitative bias analysis alongside it:
E-values of 3.99 for the point estimate and 2.62 for the confidence limit, against
measured surveillance rate ratios of 1.14 to 5.74 across six settings.

Our conclusion is stated as: detection bias is unlikely to account for the entire
association, but cannot be excluded as a partial contributor. We do not claim it
has been ruled out.

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

The full text is in `report/FINAL_METHODS_RESULTS.md` (Limitations) and
`report/LIMITATIONS_AND_INTERPRETATION.md`; the pre-specification is in
`report/STATISTICAL_ANALYSIS_PLAN.md`. In summary:

**Surveillance.** Differential ascertainment is present and was not excluded.
All eleven negative controls are baseline-imbalanced; post-index surveillance is
higher in every clinician-initiated setting (2.27 to 5.74) but not in the one
that is not (laboratory, 1.14); the calibration interval contains our estimate;
emergency department contact exceeds the E-value threshold. Against this, the
directional evidence and the E-values argue that detection is unlikely to explain
the whole association. We state which parts of our conclusion rest on which
evidence.

**Channels we cannot measure.** The encounter extract carries no specialty field,
so neurology and ophthalmology rates are not estimable; the radiology extract
covers comparators only and EEG is recorded for IIH patients only. The channels
most specific to seizure ascertainment are the ones unavailable to us.

**No active comparator.** The comparator arm is drawn from the general clinical
population, not from a condition under equivalent specialist follow-up. We have
specified the design that would resolve this (`report/ACTIVE_COMPARATOR_REQUEST.md`)
and report it as required future work rather than claiming the present data
substitute for it.

**Ascertainment definition.** Medication capture differs between the arms —
inpatient administrations for cases, outpatient prescriptions for comparators —
and outpatient prescribing for the IIH arm was not obtainable. Removing the
medication channel entirely leaves the estimate at 1.93 (1.34 to 2.77). Chart
validation of code-positive comparators is not complete.

**Design.** Observational; no causal claim is made.
