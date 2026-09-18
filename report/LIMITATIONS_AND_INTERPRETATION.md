# Limitations and interpretation — draft text

Drafted against the final analysis (K15) and the bias framework (K20–K27). Every
number below is traceable to an output table. Square-bracketed notes are for the
authors and are not part of the manuscript text.

---

## Abstract — conclusion

> Idiopathic intracranial hypertension was associated with a higher rate of
> incident seizures (HR 2.28, 95% CI 1.62–3.22; 3-year risk 3.83% vs 1.71%).
> Differential healthcare surveillance was directly assessed and is unlikely to
> account for the entire association, but could not be excluded as a partial
> contributor. These findings support heightened clinical attention to seizure
> symptoms in patients with IIH; they do not establish causation, and confirmation
> in a cohort under equivalent specialist follow-up is required.

[Note for Michelle: "unlikely to account for the entire association" is the
strongest claim the data support. "Detection bias was excluded" is not supportable —
the empirical calibration interval contains the observed estimate, and a reviewer
who reads §Limitations will find that.]

---

## Discussion — interpretation of the surveillance assessment

Patients with IIH have more contact with the healthcare system than matched
comparators, and seizures are ascertained through that contact. This raises the
possibility that the observed association reflects differential detection rather
than differential incidence. We assessed this directly rather than assuming it away.

Three observations argue against detection accounting for the whole of the
association. First, empirical calibration across eleven negative-control outcomes
predicted a detection-attributable hazard ratio of 1.04 (95% CI 0.37–2.90) — the
central estimate is essentially null, and the observed estimate of 2.28 lies at the
extreme upper margin of that interval. Second, and more informative than magnitude,
the *direction* of response to healthcare-seeking adjustment differed
systematically: all eleven negative-control outcomes moved toward the null under
adjustment, across all six contact measures examined (66 of 66 outcome-by-measure
combinations), whereas the seizure estimate moved away from the null under all six.
An outcome generated purely by differential detection would be expected to behave
as the negative controls did. Third, post-index surveillance was elevated in every
clinician-initiated setting (outpatient visits RR 2.70, hospitalisation RR 2.27,
emergency department RR 5.74) but not in the one setting that is not
clinician-initiated (laboratory encounters RR 1.14), while the association persisted.

Quantitative bias analysis gives the same reading. An unmeasured mechanism would
need to be associated with both IIH status and seizure ascertainment by at least
3.99-fold each, conditional on the matched and adjusted covariates, to reduce the
observed hazard ratio to unity, and by at least 2.62-fold to move the confidence
interval to include unity (E-values, VanderWeele and Ding). Three of the four
measured surveillance channels fall below the first threshold and two fall below
the second.

Set against this, emergency department contact (RR 5.74) exceeds the E-value
threshold, and the emergency department is the most plausible single route by which
a first seizure is ascertained. We note that the E-value is a threshold on
associations conditional on measured covariates, and that emergency department
contact in this cohort is substantially driven by headache presentations for which
the cohorts were matched; but this is an argument from mechanism and not a
measurement, and it does not resolve the concern.

## Limitations

[Placed before any causal language elsewhere in the Discussion.]

**Surveillance and detection.** The principal limitation is differential
ascertainment. Although assessed extensively, it could not be excluded. All eleven
negative-control outcomes — conditions with no plausible relationship to
intracranial pressure — were more frequent in the IIH arm at baseline (rate ratios
1.6 to 5.0, all p<0.01), establishing that differential ascertainment is present in
this data source. Empirical calibration regressing the observed log hazard ratio on
the log baseline rate ratio across those controls yielded a predicted
detection-attributable hazard ratio of 1.04, with a 95% interval of 0.37 to 2.90
that **includes the observed estimate of 2.28**. On that analysis alone, the observed
association cannot be formally distinguished from a detection artefact. Further, on
unadjusted rate ratios the seizure outcome (2.15) lies within the range spanned by
the negative controls rather than outside it. Our conclusion that detection is
unlikely to explain the entire association rests on the directional evidence and the
quantitative bias analysis described above, not on the calibration interval, and is
an interpretation rather than a demonstration.

**Post-index adjustment was not performed in the primary model.** Post-index
healthcare contact is a consequence of the outcome as well as a cause of its
ascertainment, and conditioning on it induces collider bias; we therefore report it
descriptively and as a sensitivity analysis only.

**Comparator.** The comparator arm was drawn from the general clinical population
rather than from a condition under equivalent specialist follow-up. An active
comparator matched on reason for neurologic and neuro-ophthalmologic surveillance
would equalise ascertainment by design rather than by adjustment, and is the
analysis required to resolve the residual uncertainty. No available condition
satisfies both requirements — comparable surveillance intensity and no established
seizure association — so such a design would need to bracket the bias using two
comparator arms failing in opposite directions.

**Ascertainment definition.** Seizure status was defined by diagnosis codes together
with sustained anti-seizure medication exposure. Outpatient prescription data were
unavailable for the IIH arm, so the code-based definition was applied symmetrically
across both arms in the primary analysis. Code-based seizure ascertainment is
imperfect; chart validation of code-positive comparators has not been completed.

**Observational design.** This is an observational association. No causal claim is
made, and no mechanism linking raised intracranial pressure to seizure generation is
established or tested here.

---

## What this paper does not claim

- That IIH causes seizures.
- That surveillance or detection bias has been excluded or proven absent.
- That the negative-control framework validated the primary estimate; it
  characterised the bias, and the characterisation is partly unfavourable.
