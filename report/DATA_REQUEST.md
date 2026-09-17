# Outstanding data requests

Ordered by effect on the result. Items 1-3 change the estimate. Items 4-7
change what can be defended at review. Items 8-9 close documented deviations.

---

## 1. Encounters for the IIH cases  — BLOCKING

**Have:** dated encounters for all 9,122 controls (889,925 rows).
**Missing:** the same for the 2,618 cases. Zero are in the supplied file.

**Why it matters.** Engagement, the at-risk window and censoring are now derived
from dated encounters for controls, but from the master workbook's single
`last_encounter_date` for cases. Two arms, two sources — the precise class of
asymmetry that produced the reviewer's finding. Until both arms come from one
encounter definition, the comparison is not airtight.

**Format:** `clinic_number, encounter_date` — same layout as the control file.

---

## 2. Outpatient prescriptions for the IIH cases — BLOCKING for the drug channel

**Have:** `MDE_Medications_cases_22.csv`, which records inpatient
ADMINISTRATIONS for 2,187 cases. The commonest antiseizure agent in it is
fosphenytoin, given intravenously for acute seizures. The control file records
outpatient PRESCRIPTIONS.

**Consequence:** only 20 IIH patients and 7 controls meet a 180-day antiseizure
span, out of 11,740 people. Chronic outpatient therapy in the case arm is
essentially invisible, so the medication limb of the outcome and the
"indefinite antiseizure therapy" secondary both rest on almost nothing.

**Format:** prescriptions with `start_date` and `end_date`, matching the
control file's structure.

---

## 3. Which encounter types built `enc_pre12` — one email, not a data pull

The supplied encounter file reproduces the `engaged` flag for 93% of controls,
not all: 519 flagged engaged have no encounter in the 12-month window, 127 the
reverse, and the file's distinct-day counts run below `enc_pre12` for 2,792
controls. Timestamps follow clinic hours, so the dates are sound; the gap is
most likely a narrower encounter-type filter in one of the two queries.

**Question:** which encounter types (office visit, telephone, lab-only,
administrative, inpatient) did each query count?

---

## 4. Confirmation that exclusions were applied to BOTH arms

Protocol section 2.2 says comparator exclusions are "identical to section 2.1",
which lists traumatic brain injury, stroke, intracranial tumour, cerebral venous
sinus thrombosis and craniotomy. The analytic file is post-exclusion, so it
cannot demonstrate that the rule was executed symmetrically. Reviewer comment 6
asks precisely this.

**Question:** was each exclusion applied to the case pool as well as the
comparator pool, and at what date relative to index?

---

## 5. Chart review of 50 comparators with seizure codes

Comparators are scored from codes; cases were chart-confirmed. Codes over-count,
because a convulsion code can be entered for an episode a reviewer would reject.
A random 50 of the code-positive comparators, each answered "real seizure: yes
or no", converts the single largest remaining uncertainty into a measured
misclassification rate that can be published.

---

## 6. Seizure codes for the IIH arm, unfiltered

The supplied case extract had rows for seizure-free cases removed by hand.
That is fine for counting events, but it makes two things impossible: verifying
that seizure-free cases truly carry no codes, and computing the baseline
seizure prevalence ratio the same way it was computed for the negative controls
(reviewer comment 4).

---

## 7. Seizures presenting to the emergency department or as inpatients

Requested earlier and still outstanding. Would separate seizures that brought a
patient into care from those found during routine follow-up, which bears
directly on the healthcare-contact confounding that keeps surfacing.

---

## 8. BMI measurement date

The protocol matches females on BMI calendar year +/-2. No BMI measurement date
exists in any supplied file, so the criterion was dropped from the re-match and
recorded as a deviation. One date field closes it.

---

## 9. Opening pressure — a cleaning question

Recorded for 73% of cases, range 2 to 70 cmH2O. A value of 2 is not compatible
with a diagnostic lumbar puncture in idiopathic intracranial hypertension.
Should implausible values be treated as missing, and below what threshold?

---

## Not needed

Radiology, smoking, carpal tunnel and the five negative-control extracts are
complete and consistent. Nothing further is required on those.
