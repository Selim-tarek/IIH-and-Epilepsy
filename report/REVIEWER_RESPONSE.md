# Response to reviewer comments

Every number below was re-derived from the analytic data. Verification code is
in `R/K1_reviewer_checks.R` and `R/K2_symmetric_outcome.R`; the outputs are
tables `K_T01`-`K_T04`.

**Summary.** We accept comments 1, 2, 5 and 9 in full and have made the
corresponding changes. Comment 7 is addressed with a new sensitivity analysis
that leaves the estimate essentially unchanged. For comments 3 and 4 we tested
the reviewer's proposed mechanism directly; in both cases the data do not
support it, and we explain why rather than adopting the suggested wording.
Comment 8 led us to a more serious problem than the one raised, which we
report in full below and which we believe requires the primary outcome to be
re-ascertained before this work is fit to publish.

---

## 1. The "late excess" claim contradicts the data

**Accepted.** The reviewer is right. Cumulative incidence in the IIH arm is
1.53% at 1 year against 2.54% at 3 years, so 60% of the 3-year risk is already
present at 1 year; 64% of the 3-year risk *difference* is present at 1 year
(1.32 of 2.05 percentage points). The claim has been removed from Results,
Discussion and Conclusion, and the text now states that the excess appears
early and that the curves continue to separate more slowly thereafter.

## 2. The timing numbers do not add up

**The discrepancy is real; the cause is a clock-origin mismatch, not an error
in the event counts.** Latency was measured from the index date, whereas the
survival analysis measures time from the end of the 180-day washout. "Within
3 years" therefore means index + 3 years in the timing table and index + 3.49
years in the survival tables. On the latency clock there are 55 IIH and 14
comparator events within 3 years; on the survival clock, 59 and 15. Both
tables were internally correct and mutually inconsistent. All timing results
are now reported on the survival clock, with the origin stated explicitly.

## 3. The explanation for the restriction result was backwards

**We agree the published explanation was wrong, but we tested the
replacement and it is not supported, so we have not adopted it.**

The reviewer proposes that comparators with no prior records could not be
screened for old seizures, so that prevalent cases were counted as incident.
That mechanism predicts events clustering shortly after index in the excluded
comparators. They do not cluster: 21% of events among excluded comparators
fall within 1 year of index, against 25% among retained comparators, with
median latencies of 614 and 584 days. The prediction fails, and in the
opposite direction.

The observation itself is robust. Excluded comparators have a seizure rate of
3.25 per 1,000 person-years against 1.78 in those retained, yet they are seen
*less* often after index (30 against 41 encounters). We can describe this
pattern but cannot explain it from the available data, and the revised
manuscript says so rather than offering a mechanism we have not verified. We
would welcome the reviewer's guidance on whether a specific alternative should
be tested.

## 4. The negative-control extrapolation may be unfair

**The concern is methodologically correct and we have adopted the reviewer's
approach; measured, it moves the result in the opposite direction.**

The reviewer is right that placing seizures at a prevalence ratio of 1.00 "by
design" is an assumption rather than a measurement, and that the fair
comparison uses the pre-exclusion ratio computed as it was for the other
outcomes. Measured that way, prevalent seizure coding before index is 0.31% in
the IIH arm and 0.38% in comparators, a ratio of **0.80** rather than a value
above 1. The predicted detection-only hazard ratio therefore falls from 0.79
(0.28 to 2.24) at ratio 1.00 to **0.63 (0.21 to 1.91)** at the measured ratio.
The revised manuscript reports the measured ratio instead of the assumption.

We note one caveat that cuts against this reassurance, and we raise it
ourselves under comment 8: prior seizure was an exclusion criterion, and the
IIH seizure-code extract appears to be incomplete, so the IIH baseline figure
may be understated.

## 5. Some negative controls are not clean

**Accepted.** The reviewer is right about all three mechanisms:
acetazolamide and topiramate both predispose to renal stones and are IIH
treatments; gallstones follow weight loss and bariatric surgery; carpal tunnel
syndrome is associated with obesity. We would add that our own validity
screen already marked these outcomes as failing the baseline-balance
criterion, and that of six candidate negative controls only limb fracture
passes it. The revised manuscript states plainly that a single clean negative
control remains, and tempers the specificity argument accordingly.

## 6. Exclusions may have been applied only to comparators

**The protocol specifies both arms; we cannot verify the implementation from
the delivered data and are seeking confirmation.** Protocol section 2.2 states
that comparator exclusions are "identical to section 2.1", and section 2.1
lists traumatic brain injury, stroke, intracranial tumour, cerebral venous
sinus thrombosis and craniotomy. The analytic file we received is
post-exclusion, so it cannot demonstrate that the rule was executed
symmetrically. Given the asymmetry we report under comment 8, we do not think
symmetry should be assumed, and we have asked the data-extraction team to
confirm the exclusion logic applied to each arm. We will report the answer.

## 7. G93.2 also captures cerebral venous sinus thrombosis

**Partly pre-empted by design, and addressed with the requested sensitivity
analysis.** Cerebral venous sinus thrombosis is an explicit exclusion at or
before index (section 2.1), and every case is anchored to a first diagnostic
lumbar puncture, so the lumbar-puncture tier is the entire cohort and a
separate tier analysis is not available.

The opening-pressure analysis the reviewer asks for has been added.
Restricting to patients with opening pressure >= 25 cmH2O and their matched
comparators gives **HR 5.55 (2.65 to 11.63)** against 5.58 in the main
analysis: 1,376 IIH patients with 36 events and 2,124 comparators with 9.
Opening pressure is recorded for 73% of the IIH arm, and the recorded range
runs from 2 to 70 cmH2O, so some values are implausible; both facts are now
stated.

## 8. The outcome definition needs work

**Two of the three specific points are addressed by the protocol as written.
The third led us to a substantially more serious problem.**

*ICD-9 codes in the prior-epilepsy exclusion.* The protocol does list them
(345.x and 780.39 alongside G40.x and R56.x). Implementation was imperfect
rather than absent: six patients entered with a pre-index qualifying code
whose only evidence was ICD-9 (two IIH, four comparators). These are now
excluded and the analysis re-run; the estimate is unchanged.

*Topiramate.* Topiramate is explicitly **not** counted as an antiseizure
medication (section 4.2), alongside acetazolamide, precisely because both are
IIH treatments. This is now stated in the Methods rather than left to the
protocol.

*R56.9 capturing functional seizures and syncope.* The protocol already
specifies that R56.x and 780.39 exclude a patient at baseline but **do not
satisfy the outcome**, which requires an epilepsy-specific G40.x/345.x code.
Testing whether that rule was in fact applied is what uncovered the following.

### The problem this uncovered

Of 102 IIH events, **31 (30%) carry a post-washout epilepsy-specific G40/345
code**. Of 64 comparator events, **64 (100%) do**. The protocol requires such
a code for the outcome, so the algorithm was not applied identically between
the arms. The same asymmetry appears from the other direction: 194 comparators
carry qualifying seizure codes inside their own follow-up window and were
never counted as events, against none in the IIH arm.

We applied the protocol's algorithm identically to both arms from a single
source (`K_T02`). Doing so requires abandoning the published at-risk clock,
which is censored at the delivered seizure and therefore makes the
two-code criterion unobservable by construction: 62 patients meet it on an
open clock and one on the seizure clock. On an outcome-independent clock the
symmetric estimates are 0.55 (0.23 to 1.31) for the code limb and 0.37 (0.16
to 0.87) including the medication limb, against 3.44 (2.36 to 5.00) for the
delivered outcome on the same at-risk set. Forty-eight of 54 delivered IIH
events are unsupported by the extract; 35 of 53 comparator events are
supported.

**We do not propose these as corrected estimates, because the source is not
arm-complete.** Of 156 IIH patients appearing in the seizure-code extract, 102
are delivered events, and not one of the remaining 54 carries a qualifying
code outside the washout; what they carry is F44.5, migraine and family-history
codes. The comparator arm contributes 194 such patients. An unconditioned pull
would produce non-event code carriers in both arms. The most economical
reading is that the IIH seizure codes were pulled conditional on the outcome,
which would make the symmetric re-derivation biased against IIH just as the
delivered outcome appears biased in favour of it.

What we can state with confidence is that the primary estimate is not
reproducible from a common source, that the direction of the discrepancy
depends on the arm, and that the true value is not bounded by our current
data. We are requesting a complete, outcome-independent seizure-code pull for
both arms and will re-derive the primary outcome from it. We recognise that
this may materially change the headline result, and we would rather establish
that now than after publication.

## 9. Lower mortality in the IIH arm

**Accepted, and now discussed.** Deaths occur at 2.50 per 1,000 person-years
in the IIH arm against 4.40 in comparators (HR 0.56, 0.33 to 0.97, on full
follow-up; the 0.47 reported in the manuscript is the cause-specific estimate
censored at seizure, the same direction on a different estimand). Matched
comparators dying at nearly twice the rate of patients with a non-fatal
headache disorder is not plausible as a peer group, and indicates that
matching on age, sex and BMI did not produce comparators of similar underlying
health. The Discussion now states this and treats it, alongside the
engagement-restriction finding, as evidence that residual differences in
baseline health and healthcare contact remain after matching.
