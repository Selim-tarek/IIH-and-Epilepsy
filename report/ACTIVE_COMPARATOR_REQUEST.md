# Active-comparator extraction request

**Study:** Incident Seizures and Epilepsy After Idiopathic Intracranial Hypertension
**Purpose:** build a third arm — an *active comparator* — so that the seizure hazard is estimated against a group under equivalent specialist surveillance, rather than against a general-population comparator whose contact rate is roughly half that of the IIH arm.

## 1. Why this arm is needed

The current estimate is HR 2.28 (1.62–3.22). The detection-bias assessment classifies the finding as **partially mitigated**, not clean:

- post-index surveillance is higher in the IIH arm across clinician-initiated settings (visits RR 2.70, hospital 2.27, ED 5.74), though **not** in the one non-clinician-initiated setting (laboratory RR 1.14);
- all 11 negative-control outcomes are baseline-imbalanced (RR 1.6–5.0, all p<0.01);
- empirical calibration predicts a detection-only HR of 1.04 (0.37–2.90), whose interval **contains** 2.28.

Adjustment cannot resolve this, because the healthcare-contact variables available post-index are colliders. A comparator matched on *reason for specialist follow-up* equalises surveillance by design instead. That is the one change that would move the verdict from partially to substantially mitigated.

## 2. Comparator condition

**Primary: chronic migraine without IIH.**
Same neurologists, same brain MRI pathway, comparable clinic cadence, similar age/sex/BMI distribution. Trade-off, stated plainly: migraine is itself associated with epilepsy, so this comparator biases the IIH estimate **toward the null** — it is conservative, and an HR that survives it is hard to attribute to surveillance.

**Secondary (optional): PCOS without IIH.**
Young women, elevated BMI, regular specialist follow-up, no plausible seizure association — so it is not conservative in the way migraine is, but its surveillance match is endocrine rather than neurologic (no routine brain imaging, no neurology clinic). Useful as a second anchor; not a substitute for the migraine arm.

We would analyse each comparator arm separately, never pooled.

## 3. Cohort definition (to be applied by the extraction team)

Include a patient if, at any point in the source period:
- **≥2 outpatient encounters** carrying a qualifying diagnosis code, on **different dates ≥30 days apart** (single codes are unreliable), OR one inpatient discharge with the code;
  - chronic migraine: G43.7x (chronic migraine without aura), plus G43.0x/G43.1x/G43.8x/G43.9x if the ≥2-encounter rule is met;
  - PCOS: E28.2;
- age ≥18 at the qualifying date;
- **no IIH code ever** (G93.2, G97.2 — exclude on any occurrence, any date, including after the index date);
- not already in the case or comparator files supplied for this study.

Do **not** pre-filter to patients who had seizures, and do **not** drop patients with no outcome. Send everyone who meets the definition. Index-date assignment and washout are ours to apply downstream (protocol §2.3); the extract should carry all dates so we can do that.

## 4. Size needed

From the events actually available in the IIH arm (2,138 patients × 2.13 person-years × 14.5/1,000 py ≈ 66 events), Schoenfeld:

| Smallest HR to detect (80% power, α=0.05) | 1:1 | 1:2 | 1:3 |
|---|---|---|---|
| 1.50 | ~6,100 | ~7,300 | ~9,200 |
| 1.75 | ~2,000 | ~2,700 | ~3,900 |
| 2.00 | already powered at 1:1 | ~500 | ~1,400 |
| 2.28 (observed) | already powered | already powered | already powered |

**Ask: everyone meeting the definition, up to ~10,000 chronic-migraine patients.** At that size we can detect an HR as small as 1.5, which matters because the migraine comparator is expected to attenuate the estimate. If the pull is capped, 3,000–4,000 is still a usable arm (detects ~1.75); below ~2,000 the arm can only confirm or exclude an effect near 2.0 and should be framed as supportive, not confirmatory.

## 5. Required extracts

Identical in structure to what was supplied for the existing two arms — same columns, same format, so the pipeline runs unchanged. One set of files per comparator condition.

1. **Diagnoses** — MRN, ICD-10 code, code description, diagnosis date. **Unfiltered**: every code, every date, not restricted to seizure/epilepsy codes and not restricted to post-index. Needed for the index anchor, the 180-day washout, comorbidity covariates, and the 11 negative-control outcomes.
2. **Encounters** — MRN, encounter date, **Encounter Type** (the same field supplied in `MDE_Encounters_types_full.csv`). This is essential: it is what defines cohort engagement, the at-risk clock, and every surveillance measure. Without Encounter Type we cannot strip administrative contacts and the arm is not comparable to the existing two.
3. **BMI flowsheets** — MRN, BMI value, capture date. Dated values only; matching uses the BMI closest in calendar year to the index date.
4. **Medications** — MRN, drug name, order/start date, stop date, inpatient/outpatient flag. Anti-seizure medications are part of the outcome definition (a patient continued on an ASM counts as a positive event even without a code), so an ASM-only pull is not sufficient — we need the full list to establish indication and duration. If outpatient prescriptions are unavailable for this arm as they were for the cases, say so and we will apply the code-only definition symmetrically across all three arms.
5. **Vital status** — MRN, death date if any. Needed for competing-risk censoring.
6. **Demographics** — MRN, birth year, sex, race/ethnicity. Matching variables.

Format: CSV, zipped. Please do not export via Excel — the .xlsb exports supplied earlier were silently truncated at Excel's 1,048,576-row ceiling (the case encounter file has 1,199,125 rows). Export from the query tool directly to CSV.

## 6. What we will and will not claim

With this arm we can report whether the seizure hazard persists against a group under equivalent neurologic surveillance. We will report the estimate whatever it shows, including a null. We will not pool the comparator arms, will not present the active-comparator analysis as proof that surveillance bias is absent, and will not drop the general-population comparator — both are reported side by side.
