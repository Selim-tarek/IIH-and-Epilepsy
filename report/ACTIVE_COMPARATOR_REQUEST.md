# Active-comparator extraction request

**Study:** Incident Seizures and Epilepsy After Idiopathic Intracranial Hypertension
**Purpose:** build active-comparator arms so the seizure hazard is estimated against groups under specialist surveillance comparable to IIH, rather than only against a general-population comparator whose healthcare-contact rate is roughly half that of the IIH arm.

## 1. Why these arms are needed

The current estimate is HR 2.28 (1.62–3.22). The detection-bias assessment classifies the finding as **partially mitigated**, not clean:

- post-index surveillance is higher in the IIH arm across clinician-initiated settings (visits RR 2.70, hospital 2.27, ED 5.74), though **not** in the one non-clinician-initiated setting (laboratory RR 1.14);
- all 11 negative-control outcomes are baseline-imbalanced (RR 1.6–5.0, all p<0.01);
- empirical calibration predicts a detection-only HR of 1.04 (0.37–2.90), whose interval **contains** 2.28.

Adjustment cannot resolve this, because the healthcare-contact variables available post-index are colliders — post-index visits are caused by the outcome. A comparator matched on *reason for specialist follow-up* equalises surveillance by design instead.

## 2. The design problem, stated honestly

An ideal active comparator would satisfy two requirements at once:

1. healthcare utilisation and surveillance similar to IIH;
2. no established or substantial association with seizure risk.

**No single condition satisfies both.** Every candidate fails one:

| Candidate | Surveillance match | Seizure association | Verdict |
|---|---|---|---|
| Chronic migraine | Excellent | Established | Fails (2) |
| Obstructive sleep apnoea | Good | Established, bidirectional; PSG adds a detection channel | Fails (2) |
| Multiple sclerosis | Excellent | Established | Fails (2) |
| PCOS | Weak — no neurology, no brain imaging | Documented (partly but not wholly valproate-mediated) | Fails both |
| IBD | Contact volume only | Weak | Fails (1) |
| Optic disc drusen / pseudopapilledema | Good on referral pathway | None established | Passes both; too small alone |
| Chiari I malformation | Good | None established | Passes both; small alone |
| Pituitary microadenoma / sellar incidentaloma | Good (serial MRI) | None established | Passes both; small alone |

PCOS was proposed in an earlier draft of this request as the seizure-clean option. That was wrong and is withdrawn: the PCOS–epilepsy association is documented, partly valproate-driven but also reported independent of it.

**Approach: bracket the bias with two arms that fail in opposite directions**, and state this explicitly in the manuscript rather than claiming a clean comparator exists.

- **Arm A, surveillance-matched with a known seizure association** → biases toward the null → yields a **conservative lower bound** on the hazard ratio.
- **Arm B, seizure-clean with a somewhat lower surveillance intensity** → residual surveillance shortfall biases *away* from the null → yields an **upper bound**.

If both brackets exclude 1, the effect is robust to the direction of the residual bias, and a detection-only explanation must hold against both simultaneously.

## 3. The two arms

### Arm A — chronic migraine without IIH (conservative lower bound)

Same neurologists, same brain MRI pathway, comparable clinic cadence, similar age and sex distribution. Migraine is itself associated with epilepsy and generates "spells" workups that carry their own EEG-detection channel; both push the estimate toward the null. This arm is therefore reported as a **lower bound**, not as a clean comparator.

### Arm B — benign neuro-surveillance cohort, pooled (upper bound)

A pooled cohort of three conditions sharing one defining feature: a **benign finding under protocolised serial brain imaging and neurology / neuro-ophthalmology follow-up, in a young, female-predominant population, with no epileptogenic mechanism.**

- optic disc drusen / pseudopapilledema — referred down the *identical* pathway as IIH (suspected papilledema → brain MRI/MRV → visual fields, OCT → serial neuro-ophthalmology follow-up);
- Chiari I malformation — headache presentation, serial brain MRI, neurosurgery/neurology follow-up;
- pituitary microadenoma / sellar incidentaloma — protocolised repeat MRI, endocrine and neurosurgical follow-up.

Pooling *these* is defensible because they share that surveillance mechanism; pooling any of them with migraine would not be. Pooling also solves the power problem that sinks each one individually.

**Two weaknesses to handle in advance, not after review:**

- **Chiari contamination.** Tonsillar ectopia can be *acquired* from raised intracranial pressure, so a share of Chiari I patients may be undiagnosed IIH — the same hazard as papilledema codes. Exclude any IIH code at any date, and report the arm both with and without the Chiari component.
- **Heterogeneity.** Per-component hazard ratios are pre-specified and reported alongside the pooled estimate. If the components disagree, the pooling assumption is wrong and we say so rather than resolving it into a single number.

## 4. Cohort definitions (to be applied by the extraction team)

Include a patient if, at any point in the source period:

- **≥2 outpatient encounters** carrying a qualifying diagnosis code, on **different dates ≥30 days apart**, OR one inpatient discharge with the code (single codes are unreliable);
- age ≥18 at the qualifying date;
- **no IIH code ever** (G93.2, G97.2 — exclude on any occurrence, any date, including after the index date);
- not already present in the case or comparator files supplied for this study.

Qualifying codes:

| Arm | Codes |
|---|---|
| A — chronic migraine | G43.7x; also G43.0x / G43.1x / G43.8x / G43.9x where the ≥2-encounter rule is met |
| B1 — optic disc drusen / pseudopapilledema | H47.32, H47.33 |
| B2 — Chiari I malformation | Q07.00, Q07.01 (exclude Chiari II/III) |
| B3 — pituitary microadenoma / sellar incidentaloma | D35.2, E22.1 (prolactinoma), plus benign sellar lesion codes if locally used |

**Additional exclusions for Arm B, applied to all three components:**

- any papilledema code **H47.1x** at any date — it indicates raised intracranial pressure and may mark an uncoded IIH case;
- any intracranial mass or epileptogenic lesion: meningioma (D32.x), glioma and other primary brain tumour (C71.x), brain metastasis (C79.31), pituitary **macro**adenoma with mass effect or chiasmal compression where distinguishable;
- multiple sclerosis (G35), prior stroke (I60–I63), traumatic brain injury (S06.x), CNS infection (G00–G09), neurosurgical resection or craniotomy.

Do **not** pre-filter to patients who had seizures, and do **not** drop patients with no outcome. Send everyone meeting the definition. Index-date assignment and the 180-day washout are ours to apply downstream (protocol §2.3); the extract must carry all dates so we can do that.

## 5. Size needed

From the events available in the IIH arm (2,138 patients × 2.13 person-years × 14.5/1,000 py ≈ 66 events), Schoenfeld:

| Smallest HR detectable (80% power, α=0.05) | 1:1 | 1:2 | 1:3 |
|---|---|---|---|
| 1.50 | ~6,100 | ~7,300 | ~9,200 |
| 1.75 | ~2,000 | ~2,700 | ~3,900 |
| 2.00 | already powered at 1:1 | ~500 | ~1,400 |
| 2.28 (observed) | already powered | already powered | already powered |

**Arm A: everyone meeting the definition, up to ~10,000.** The size matters specifically because migraine is expected to attenuate — at ~2,000 the arm can only confirm or exclude an effect near 1.75, and would be framed as supportive rather than confirmatory.

**Arm B: everyone who qualifies across all three components.** Pooling is what makes this arm viable; the table above states what the resulting count will and will not support, and the arm is framed accordingly rather than dropped. **Please report the eligible count per component before running the full extraction**, so the pooling and framing decisions can be made on real numbers.

## 6. Required extracts

Identical in structure to what was supplied for the existing two arms — same columns, same format, so the pipeline runs unchanged. One set of files per arm; for Arm B, include a column identifying which component (B1/B2/B3) each patient qualified under, since per-component estimates are pre-specified. If pulling both arms at once is burdensome, Arm A is the priority.

1. **Diagnoses** — MRN, ICD-10 code, code description, diagnosis date. **Unfiltered**: every code, every date, not restricted to seizure/epilepsy codes and not restricted to post-index. Needed for the index anchor, the 180-day washout, comorbidity covariates, the exclusions in §4, and the 11 negative-control outcomes.
2. **Encounters** — MRN, encounter date, **Encounter Type** (the same field supplied in `MDE_Encounters_types_full.csv`). Essential: it defines cohort engagement, the at-risk clock, and every surveillance measure. Without Encounter Type we cannot strip administrative contacts and the arm is not comparable to the existing two.
3. **BMI flowsheets** — MRN, BMI value, capture date. Dated values only; matching uses the BMI closest in calendar year to the index date.
4. **Medications** — MRN, drug name, order/start date, stop date, inpatient/outpatient flag. Anti-seizure medications are part of the outcome definition (a patient continued on an ASM counts as a positive event even without a code), so an ASM-only pull is not sufficient — the full list is needed to establish indication and duration. If outpatient prescriptions are unavailable for these arms as they were for the cases, say so and we will apply the code-only definition symmetrically across all arms.
5. **Vital status** — MRN, death date if any. Needed for competing-risk censoring.
6. **Demographics** — MRN, birth year, sex, race/ethnicity. Matching variables.

Format: CSV, zipped. Please do not export via Excel — the .xlsb exports supplied earlier were silently truncated at Excel's 1,048,576-row ceiling (the case encounter file has 1,199,125 rows). Export from the query tool directly to CSV.

## 7. What we will and will not claim

We will report whether the seizure hazard persists against a surveillance-matched arm (A) and against a seizure-clean arm (B), with each arm's direction of residual bias stated. Each arm is reported separately with its own power; Arm A and Arm B are never pooled with each other, and the general-population comparator is retained and reported alongside them.

We will report the estimates whatever they show, including a null. We will **not** present the active-comparator analysis as proof that surveillance bias is absent — it narrows the range of explanations, it does not eliminate one.
