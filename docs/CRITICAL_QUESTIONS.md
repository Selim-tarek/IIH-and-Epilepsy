# Critical questions — answers needed before inferential models

Ordered by how much they move the primary result.

**Q1 — How was case follow-up time computed?** `last_encounter_date` and
`death_date` are blank for all 2,732 cases, so `followup_years` is exactly
reproducible for controls and unverifiable for cases. Cases have 1.3 years
more median follow-up. Can you supply case last-encounter and death dates, or
the rule used? Until then the incidence-rate ratio rests on an undocumented
denominator.

**Q2 — Was death ascertained for cases at all?** Zero deaths in 2,732 IIH
cases versus 151 in 9,852 controls is not plausible as a finding. If death was
control-only, the competing-risk analysis (FINAL Table 6) must be withdrawn,
not reported.

**Q3 — Was the outcome algorithm applied identically to both arms?**
`outcome_criterion` and `pnes_ever` are populated for every control and no
case. If cases were ascertained by a different (e.g. richer, chart-based)
route than controls, the hazard ratio is partly an ascertainment contrast.
Please confirm the case-side criterion, and supply it per case if it exists.

**Q4 — The 57 cases with `presenting_seizure = 1`.** They are inside the
matched cohort, coded `seizure_incident = 0`, contributing person-time as
non-events. Protocol says they violate seizure-free-at-index. Confirm: exclude
them from the primary analysis and report them descriptively?

**Q5 — What does `enceph_index = 88` mean?** 2,661 of 2,732 cases carry it,
against 52 positive and 19 negative. "Not assessed", "no encephalocele", or
"imaging not adequate"? I will not treat it as negative without your
confirmation. If it means not assessed, the mediation aim is dead on 2.6%
coverage and I will propose a descriptive stratified alternative instead.

**Q6 — 1,046 controls censored at a future `last_encounter_date`** (up to
2034-04-16). Are these scheduled appointments? If so they inflate control
person-time and the HR, and I will re-censor at the data-pull date as the
primary, with the delivered version as sensitivity.

**Q7 — Which cohort is primary: as-delivered or protocol-conformant?** The
delivered cohort has no Friedman adjudication, includes 45 people under 16,
686 with under 12 months of follow-up, and 556 cases with OP <25 cmH₂O. I
propose reporting both and pre-registering the as-delivered one as primary,
since the protocol cohort cannot be reconstructed without adjudication data.

**Q8 — Why were 869 cases dropped from matching?** No reason field exists.
304 lack BMI; the other 565 are unexplained. Differential drop-out at matching
is a selection mechanism I currently cannot characterise.

**Q9 — How does the radiology export link to the cohort?** 3,115 MR reports
keyed on "Clinic Number"; `clinic_number` is blank for every master row. With
a crosswalk this file could support an imaging-adequacy flag and a
case-only encephalocele re-read — the two things the mediation aim needs most.

**Q10 — Do any of the absent variables exist elsewhere?** Specifically:
medications (ASM and acetazolamide/topiramate/zonisamide with dates), Frisén
grade, perimetry, symptom-onset date, encounter counts for cases, comorbidities
for controls, race for cases, site/campus, and the validation/double-read
samples. Each one unlocks a named protocol aim; without them those aims will
be reported as not executable rather than approximated.

**Q11 — Prior results.** `IIH_Epilepsy_FINAL.xlsx` already contains a complete
analysis (HR 3.15, 2.30–4.31). Do you want that reproduced and checked line by
line, or a clean independent re-analysis? I would recommend the latter, with a
reconciliation table, because several of its inputs are affected by Q1–Q3.
