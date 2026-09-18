# Outcome definition — as implemented in `R/K9_final_primary.R`

One rule. Applied to IIH cases and matched comparators without any difference
between them. This is the change from the submitted manuscript, where the two
arms were ascertained differently.

---

## A patient is a positive event if, after the washout and within the at-risk
## window, EITHER of the following is true

**1. A qualifying seizure code**

Counted:

| | |
|---|---|
| ICD-10 | `G40.x` (epilepsy), `R56.9` and other `R56.x` (convulsions) |
| ICD-9 | `345.x` (epilepsy), `780.39` (other convulsions) |
| legacy | `0345x`, `07703x` variants of the above |

Not counted, and removed before anything else:

| | |
|---|---|
| `F44.5`, `300.11` | conversion disorder / psychogenic non-epileptic seizures |
| `R56.1`, `780.32`, `780.33` | post-traumatic and febrile convulsions (provoked) |
| `Z82.0` | family history of epilepsy — not a diagnosis of the patient |
| `G43.x` | migraine |
| `E936`, `966` | anticonvulsant adverse effect or poisoning |
| any descriptor matching | febrile, non-epileptic, psychogenic, conversion, family history, migraine, poisoning, adverse |

One conditional exclusion: `R56.9 "Spells Neurological (HCC)"` counts only if
the patient was also on indefinite antiseizure medication. A patient whose only
in-window evidence is a Spells code and who was never on chronic therapy is not
an event. This affected one patient, an IIH case.

Codes are drawn from both supplied sources — the dated diagnosis extract and
the problem list. For problem-list entries the onset date is used where
present and the recorded date otherwise, the earlier of the two being the
conservative choice for an incident outcome.

**2. Indefinite antiseizure medication**

Antiseizure records spanning 180 days or more, or a single prescription written
for 180 days or more. Agents counted are the protocol's unambiguous list only:
levetiracetam, lamotrigine, carbamazepine, oxcarbazepine, valproate,
divalproex, phenytoin, fosphenytoin, lacosamide, zonisamide, perampanel,
brivaracetam, felbamate, rufinamide, vigabatrin, tiagabine, primidone,
ethosuximide, phenobarbital, eslicarbazepine, cenobamate.

Deliberately **not** counted: topiramate and acetazolamide (both IIH
treatments — counting either would manufacture events in the IIH arm by
construction), gabapentin and pregabalin (analgesics), and the benzodiazepines
midazolam, lorazepam, diazepam and clonazepam (procedural sedation). The case
file's `9999-12-31` end-date sentinel is read as therapy still active at the
data freeze rather than discarded.

---

## Timing rules, identical in both arms

**Washout.** 180 days. Any qualifying code, or chronic antiseizure therapy
starting, on or before day 180 makes the patient prevalent and removes them
from the at-risk set entirely. It does not make them an event.

**Event date.** The earlier of the first qualifying code and the first
antiseizure record among patients meeting the chronic criterion.

**At-risk window.** Index date to the earliest of last attended encounter,
death, or data freeze, capped at three years past the washout. This clock is
defined without reference to the outcome. The clock used in the submitted
analysis cannot be used here because it is censored at the delivered event, so
a confirmatory code 30 days later can never be observed.

**Follow-up time.** From the end of the washout to the event or to the end of
the window.

---

## What is NOT used

The delivered `seizure_incident` flag no longer decides anything. In the
submitted analysis it decided the IIH arm while a code algorithm decided the
comparator arm, and the two were not the same standard: of 102 IIH events, 70
rested only on a non-specific convulsion code, while all 64 comparator events
required an epilepsy-specific code and 194 comparators carrying codes were
never counted.

Discarding that flag turns out to cost nothing. Every chart-abstracted IIH
event also carries a qualifying code or drug under the rule above, so the
clinical determinations and the coded evidence agree completely in the IIH arm.
Running the analysis with the flag added back changes no number. The IIH
ascertainment was never the problem.

---

## What this definition produces

**Updated to the final re-matched cohort (18 September 2026 run, `K_T38`).**
The figures previously in this section (HR 1.87) predated the re-match on dated
encounters and no longer hold.

| Cohort | IIH | Comparators | Hazard ratio |
|---|---|---|---|
| Primary (visits definition) | 66 / 2,138 | 63 / 5,743 | **2.28 (1.62 to 3.22)** |
| Codes only, medication channel removed | 56 / 2,138 | 63 / 5,743 | 1.93 (1.34 to 2.77) |
| Epilepsy-specific codes only (G40/345) | 26 / 2,138 | 24 / 5,743 | 2.30 (1.35 to 3.92) |
| All encounter rows counted as contact | 65 / 2,507 | 67 / 7,905 | 2.79 (1.98 to 3.93) |
| Complete matched sets only | 66 / 2,138 | 61 / 4,954 | 2.06 (1.46 to 2.92) |

Rates 14.46 against 6.72 per 1,000 person-years (4,563.0 and 9,375.2
person-years); three-year risk 3.83% against 1.71%; difference 2.12 percentage
points; number needed to harm 47. Proportional hazards p = 0.94.

## The one asymmetry that remains, and cannot be fixed by definition

Medication capture differs by source and not by biology. The case file records
inpatient **administrations** for 2,187 of 2,618 IIH patients — the commonest
agent recorded is fosphenytoin, given intravenously for acute seizures rather
than as maintenance — while the comparator file records outpatient
**prescriptions**. Only 20 IIH patients and 7 comparators meet the 180-day
span, out of 11,740 people.

Chronic outpatient antiseizure therapy in the IIH arm is therefore
substantially under-captured. The medication channel adds 10 IIH events and 1
comparator here, so it does not distort the estimate, but it cannot be
presented as an evenhanded ascertainment route and no weight should rest on it.
