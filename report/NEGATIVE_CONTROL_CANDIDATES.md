# Replacing the negative-control panel

## Why the current panel fails

A negative control only informs specificity if it is **balanced at baseline**.
An outcome already commoner in the IIH arm before index cannot separate
detection from whatever produced that imbalance.

| Outcome | Baseline IIH | Baseline comparator | Ratio | p | Usable? |
|---|---|---|---|---|---|
| Herpes zoster | 1.64% | 0.50% | 3.24 | 3×10⁻⁶ | no |
| Renal / ureteric stone | 4.30% | 2.11% | 2.04 | 3×10⁻⁷ | no |
| Carpal tunnel syndrome | 4.07% | 1.60% | 2.54 | 7×10⁻¹⁰ | no |
| Acute appendicitis | 1.03% | 0.45% | 2.27 | 5×10⁻³ | no |
| Gallstones | 3.46% | 2.19% | 1.58 | 2×10⁻³ | no |
| Limb fracture | 0.14% | 0.28% | 0.50 | 0.44 | **balanced, but only 2 and 7 events** |

Five fail on balance. The sixth fails on power. Nothing is left.

Note the pattern: the imbalanced five are all plausibly downstream of obesity,
of IIH treatment, or of simply being under more medical observation. That is the
trap — anything correlated with obesity or with healthcare contact is
disqualified in this cohort, and those two things correlate with a great deal.

## What a usable control needs

1. **No plausible link to IIH, to obesity, or to acetazolamide and topiramate.**
2. **Acute and symptom-driven**, so presentation is forced by the patient's
   symptoms rather than by surveillance intensity.
3. **Common enough for power.** At the observed comparator rates, roughly 25
   events per arm are needed before an interval is narrow enough to be worth
   plotting; limb fracture at 2 and 7 is an order of magnitude short.
4. **Verified balanced at baseline before any post-index estimate is looked at.**
   This must be a screening step, not a post-hoc observation.

## Candidates worth pulling

Listed best first. Each needs the baseline check before its hazard ratio is
examined at all.

| Candidate | Codes | Why it may work | Risk |
|---|---|---|---|
| **All fractures, not just limb** | S02, S12, S22, S32, S42, S52, S62, S72, S82, S92; ICD-9 800–829 | Broadens the one outcome that already balanced, from 9 events to a usable number | Obesity affects fracture site distribution, though not strongly overall |
| **Acute upper respiratory infection and influenza** | J00–J06, J09–J11; ICD-9 460–466, 487 | Very common, acutely symptomatic, no obesity or IIH link | Presentation depends on whether a patient bothers to attend — healthcare-seeking behaviour |
| **Otitis media and externa** | H65, H66, H60; ICD-9 380–382 | Symptom-forced, unrelated to IIH | Lower incidence in this age band |
| **Laceration and superficial injury** | S01, S41, S51, S61, S81; ICD-9 870–884, 890–894 | Injury is close to exogenous; attendance is forced by the wound | Some contact-intensity dependence |
| **Inguinal hernia** | K40; ICD-9 550 | No obesity association in the protective direction, clean diagnosis | Male-predominant, and this cohort is 88% female |
| **Acute conjunctivitis** | H10; ICD-9 372.0 | Common, acute | **Probably disqualified** — IIH patients see ophthalmology far more, so detection is guaranteed to differ |

I would pull the first four together. Fractures and upper respiratory infection
are the two most likely to clear both the balance and the power bars.

## A different approach, if the panel cannot be rescued

Rather than a handful of hand-picked controls, take **fifty or more unrelated
outcomes**, estimate the hazard ratio for each, and use the resulting null
distribution to calibrate the seizure estimate empirically. This is the standard
method in pharmacoepidemiology. It needs no individual control to be perfect,
because it asks a different question: how extreme is the seizure estimate against
the distribution of estimates for outcomes that should show nothing?

It is more work — a diagnosis extract broad enough to cover many outcome
families — but it is the honest version of the argument the submitted manuscript
was trying to make, and it would survive scrutiny in a way that six hand-picked
controls will not.

## What to do if neither is possible

State plainly that no valid negative control was available, and rest the
specificity argument on what the data can support: that the association holds
across eight outcome and encounter specifications, that it is present when the
outcome is restricted to epilepsy-specific codes, and that it is present among
patients with a confirmed opening pressure of 25 cmH₂O or more. That is a
weaker claim than the submitted manuscript made, and it is one the data
actually support.
