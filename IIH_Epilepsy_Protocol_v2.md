# Incident Seizures and Epilepsy After Idiopathic Intracranial Hypertension

## Study Protocol — Version 2.0 (revised)

**PI:** Michelle Lin, MD · **Analyst:** Selim Tarabeah, MBBCh
**Institution:** Mayo Clinic (Jacksonville, Rochester, Arizona)
**Design:** Retrospective matched cohort study with negative control outcome

---

### Summary of changes from v1.0

| # | Change | Reason |
|---|---|---|
| 1 | **Friedman criteria adjudication dropped.** Cohort is ICD-code identified. | Effort not feasible; documented as the principal limitation |
| 2 | **Age restricted to 13–60 years** at index | Paediatric IIH <13 is phenotypically distinct; IIH onset >60 is rare and likely miscoded. The control pool also lacked coverage at both extremes |
| 3 | **Controls required ≥1 encounter in the 12 months before the inherited index date** | Protocol v1.0 matched on baseline encounter count but this was not achieved: control median was 0 vs 15 in cases. Without this, the comparison is between engaged and disengaged patients |
| 4 | **Primary model truncates follow-up at 3 years** | The proportional hazards assumption fails over full follow-up (p=0.020) and remains marginal at 5 years (p=0.043). It holds at 3 years |
| 5 | **Matching ratio stated as "1:4 attempted"** with the achieved distribution reported | Post-matching exclusions leave many sets with fewer than 4 controls |
| 6 | **Male matching omitted the calendar-year constraint** | BMI capture dates in the male extract were unreliable; the male pool's records also do not span the full study period |
| 7 | **GERD negative control and blinded chart confirmation dropped** | Descoped |
| 8 | **Mediation aim (encephalocele) suspended** | Assessable in ~3% of cases; no informative matched sets |

---

## 1. Objectives

**Primary.** To estimate the hazard of incident seizure or epilepsy in patients with
an IIH diagnosis relative to non-IIH patients matched on sex, age and body mass
index.

**Secondary.**
1. To test whether the association is specific, using incident carpal tunnel
   syndrome as a negative control outcome.
2. To describe the temporal pattern of risk after diagnosis.
3. To describe EEG findings among IIH patients who develop seizures.

**Suspended.** Whether skull-base structural change (temporal encephalocele)
mediates the association. Retained as a future aim contingent on a blinded
imaging re-read.

---

## 2. Population

### 2.1 Cases

Patients with ICD-9 348.2 or ICD-10 G93.2 at any Mayo Clinic site, index date =
first diagnostic lumbar puncture. **Index dates span 1990–2025.**

**Inclusions**
- Age **13–60 years** at index date
- ≥12 months of records before and after index (unless death occurred earlier)
- Measured height and weight available (required for matching)

**Exclusions (applied at or before index)**
- Seizure or epilepsy code (ICD-9 345.x, 780.39; ICD-10 G40.x, R56.x)
- Antiseizure medication — **unambiguous agents only** (see §4.2)
- Epileptiform EEG
- Traumatic brain injury, stroke, intracranial tumour, cerebral venous sinus
  thrombosis, or craniotomy
- Seizure within **180 days** of index (treated as a presenting rather than
  incident event; analysed separately)

**Cohort after exclusions: 3,601 patients.**

### 2.2 Controls

Non-IIH Mayo patients drawn from the general clinical population, matched
**1:4 (attempted), without replacement**.

**Inclusions**
- No IIH code at any time
- **Measured** height and weight — an obesity ICD code is not an acceptable substitute
- Age 13–60 at index
- **≥1 clinical encounter in the 12 months before the inherited index date**
  *(new in v2.0 — ensures both groups were in active care)*

**Exclusions** — identical to §2.1, applied relative to the inherited index date.
Controls are additionally screened against the case MRN list so that no patient
contributes to both groups.

### 2.3 Index date for controls

Each control **inherits the index date of its matched case**. All exclusions,
follow-up time and outcome ascertainment are measured from that date. A control's
own diagnoses, encounters and BMI measurement dates do not define it.

---

## 3. Matching

| Variable | Tolerance |
|---|---|
| Sex | Exact |
| Age at index | ± 3 years |
| BMI | ± 3 kg/m² |
| Race | Exact where recorded |
| BMI calendar year | ± 2 years **(female matching only)** |

Cases are processed in randomised order; nearest neighbour on BMI then age.
Where 1:4 cannot be achieved, tolerances are relaxed in a pre-specified order
(drop race → BMI ± 5 → year ± 3 → age ± 5), and the tier used is recorded per
control. **Sex is never relaxed.**

**Achieved:** standardised mean differences of −0.007 (age), −0.006 (BMI) and
+0.025 (sex). Propensity model c-statistic 0.517, confirming the groups are
indistinguishable on matched covariates.

---

## 4. Outcomes

### 4.1 Primary outcome — incident seizure or epilepsy

Ascertained by the **identical algorithm in cases and controls**. A patient meets
the outcome if either:

1. **Two epilepsy-specific codes** (ICD-10 G40.x / ICD-9 345.x) recorded ≥30 days
   apart, **or**
2. **One epilepsy-specific code plus ≥1 unambiguous antiseizure medication**

Non-specific convulsion codes (R56.x, 780.39) **exclude** a patient at baseline
but do **not** satisfy the outcome. Psychogenic non-epileptic seizure codes
(F44.5) are flagged for sensitivity analysis.

### 4.2 Antiseizure medication definition

**Counted:** levetiracetam, lamotrigine, carbamazepine, oxcarbazepine, valproate,
divalproex, phenytoin, fosphenytoin, lacosamide, zonisamide, perampanel,
brivaracetam, felbamate, rufinamide, vigabatrin, tiagabine, primidone,
ethosuximide, phenobarbital, eslicarbazepine, cenobamate.

**Not counted:** midazolam, lorazepam, diazepam, clonazepam (procedural sedation);
**gabapentin and pregabalin** (neuropathic pain); **topiramate and acetazolamide**
(IIH treatments). In the control medication extract, 83% of records were
non-ASM — counting them would have produced ~2,700 false positives.

### 4.3 Negative control outcome

**Incident carpal tunnel syndrome** (ICD-10 G56.0x, ICD-9 354.0), ascertained by
the same method and over the same window. Carpal tunnel has no plausible causal
relationship with IIH; an elevated hazard would indicate that the analysis is
measuring healthcare contact rather than disease.

*Not extracted for male controls — this outcome is analysed in female pairs only.*

### 4.4 Follow-up and censoring

From index to the earliest of: first seizure, death, or last documented clinical
encounter. Deaths before a seizure are treated as a competing event.

---

## 5. Statistical analysis

### 5.1 Primary

Cox proportional hazards, IIH status as exposure, **follow-up truncated at
3 years**, where the proportional hazards assumption is satisfied. Reported with
the 5-year and full-follow-up models as secondary.

### 5.2 Secondary and sensitivity

- Cox stratified by matched set
- Inverse probability of treatment weighting on the propensity score
- Sex-stratified models
- Time-split analysis (0–2 years vs ≥2 years)
- Exclusion of PNES-coded participants
- Stricter outcome (criterion 1 only)
- Competing-risk cumulative incidence (Aalen–Johansen) vs Kaplan–Meier
- Restriction of controls to the top quartile of post-index encounters

### 5.3 Adjustment for healthcare contact

Post-index encounter volume differs substantially between groups (case median 81
vs control 17). Models adjusting for it are reported as a **conservative bound
only**, not as the primary estimate: encounters after diagnosis are a consequence
of having IIH and of having seizures, so conditioning on them is adjustment for a
mediator and can bias the estimate toward or past the null. The pre-index
encounter restriction (§2.2) is the appropriate design-stage control.

---

## 6. Results as analysed under v2.0

**2,215 cases and 4,337 matched controls.**

| Outcome | Rate per 1,000 py | Hazard ratio (95% CI) |
|---|---|---|
| Seizure — 3-year truncated (**primary**) | — | **3.34 (2.01–5.55)** |
| Seizure — 5-year truncated | 6.42 vs 1.72 | 3.84 (2.39–6.15) |
| Seizure — stratified by matched set | — | 3.78 (2.31–6.19) |
| Seizure — IPTW | — | 3.77 (2.36–6.02) |
| **Carpal tunnel (negative control)** | — | **1.09 (0.69–1.74), p=0.71** |

Time-split: HR 3.11 (0–2 years), 8.16 (≥2 years).

---

## 7. Limitations to be stated

1. **Cases are identified by diagnosis code without chart adjudication.** The
   cohort is "patients coded as IIH", not verified IIH.
2. The proportional hazards assumption fails over full follow-up; the primary
   estimate is therefore restricted to 3 years.
3. 1,386 of 3,601 cases could not be matched (no measured BMI, BMI <25 or ≥45,
   or index year outside the control pool's coverage) and are excluded from the
   comparative analysis. They are retained for descriptive reporting.
4. Controls have shorter follow-up than cases (median 2.7 vs 4.2 years).
5. The negative control outcome was not extracted for male controls.
6. Male matching used no calendar-year constraint, unlike female matching,
   because BMI capture dates in the male extract were unreliable.
7. Outcome ascertainment relies on coded data; no blinded chart confirmation was
   performed, so the positive predictive value of the algorithm is unknown.
8. Residual confounding by healthcare-seeking behaviour cannot be excluded,
   though the null negative control and the widening risk gradient over time
   both argue against it being the sole explanation.
