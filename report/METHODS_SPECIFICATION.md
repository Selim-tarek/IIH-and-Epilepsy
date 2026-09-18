# Methods specification — answers to the ten submission questions

All values from the final from-scratch run of 18 September 2026. Where something
is **not in the data I hold**, it says so; nothing here is inferred.

---

## 1. IIH case definition

**What I can state from the data.**

- **Index date = the diagnostic lumbar puncture date** (master workbook Codebook,
  verbatim: *"Cases: diagnostic LP date. Controls: inherited from the matched
  case"*). Every case therefore had an LP, and the index anchor is the LP, not a
  first diagnosis code.
- **Opening pressure** is recorded for **74% of cases (1,585 of 2,138)**, mean
  29.5 cmH₂O (SD 9.7), and for **0% of comparators**. It was used for one
  sensitivity analysis (restriction to ≥25 cmH₂O: HR 2.25, 1.41–3.59) and never
  for adjustment or matching.
- **Study period (index dates): 7 June 2002 to 11 November 2025**, median 31
  January 2021 (IIH). Data freeze 3 September 2026.
- **Look-back:** ≥1 dated clinical encounter in the **12 months** before index.
- **Follow-up:** from index + 180 days to the earliest of outcome, death, last
  attended encounter, or freeze, capped at **3 years** past the washout.

> **NOT AVAILABLE — you must supply this.** The IIH **code list**, and whether a
> lumbar puncture or an opening-pressure threshold was *required for inclusion*,
> are not in any file I hold. The cases arrive pre-assembled from
> `IIH__1_FILLED__2_.xlsx (Data_Collection)`, a chart-abstraction workbook that
> is not in `data-raw/`. The index date being the LP date implies an LP was done
> in all cases, but **that is an inference and I will not write it into the
> Methods as a criterion.** Likewise whether modified Dandy criteria were
> applied. Please state these from the original protocol.

---

## 2. Matching

| Item | Specification |
|---|---|
| Variables | sex (exact), age at index, BMI, BMI calendar year, race |
| Ratio | **variable, up to 1:4**; achieved mean **2.31** comparators per case |
| Calipers | age ±3 y, BMI ±3 units (tiers 1–3); relaxed to ±3/±5 then ±5/±5 |
| BMI year | comparator BMI measured within **±2 calendar years** of the case's |
| Replacement | **without replacement** — each comparator used at most once |
| Passes | 4 sequential passes over a randomly ordered case list (seed 20250906) |
| Tier 1 achieved | **2,172 of 2,490 (87%)** |

Five relaxing tiers, applied in order; a case is matched at the strictest tier
with an available comparator:

1. race + BMI-year + age ±3 + BMI ±3
2. BMI-year + age ±3 + BMI ±3
3. age ±3 + BMI ±3
4. age ±3 + BMI ±5
5. age ±5 + BMI ±5

Within a tier, the closest comparator by |ΔBMI| then |Δage| is taken.

> **Race was specified but never constrained the match**: it is absent for 100%
> of IIH cases, so the tier-1 race condition was inoperative. Do not list race as
> a matched covariate.

### What "re-match on dated encounters" means

The submitted analysis required comparators to be "engaged" using a variable
carried in the master workbook. Two things were wrong with that:

1. **The engagement window was evaluated at the comparator's own index date.**
   After matching, comparators inherit the case's index date, so the window had
   been checked at the wrong time. In a preliminary re-match, **71% of
   comparators differed from their matched case by >30 days and 48% by >1 year.**
2. **Encounter *dates* were not used at all** — only a pre-computed count.

The re-match rebuilds engagement from the **dated encounter files for both arms**
(1,199,125 case rows; 995,409 comparator rows, both carrying Encounter Type) and
evaluates it, along with every other time-anchored condition, at the **case's
index date**, which the comparator inherits. Concretely, a comparator is eligible
for case *c* only if that comparator has a clinical encounter dated in
`[d_c − 365, d_c − 1]`.

This also means the master workbook's `enc_pre12` is **stale** — computed on
comparators' original index dates. It gives 30.5 vs 11.3 visits where the correct
recomputed value is **20.6 vs 9.2**. `enc_pre12` must not be used.

---

## 3. Exclusions — and confirmation of symmetry

Applied to **both arms, evaluated at the shared (inherited) index date**:

| Exclusion | Applied to |
|---|---|
| Any qualifying seizure code on or before index + 180 days | both arms |
| Chronic anti-seizure therapy starting on or before index + 180 days | both arms |
| No follow-up beyond index + 180 days | both arms |
| No clinical encounter in the 12 months before index | both arms |
| Age < 18 at index | both arms |

**Confirmation.** The washout is symmetric: earliest event day 183 (IIH) and 187
(comparator), and `R/F1_import_audit_final.R` asserts at load that no event falls
inside the 180-day window in either arm. The outcome function `ev_day()` in
`R/K15_final_analysis.R` is a single function called identically for both arms —
there is no arm-specific branch anywhere in it.

> **One residual asymmetry, and it is real.** The prevalence and follow-up
> screens were applied to comparators *at selection*; cases were screened for the
> washout but not pre-filtered on having follow-up past it. So 2,490 cases were
> matched but 2,138 contributed follow-up, leaving **352 sets whose case dropped
> out while 789 comparators remained**, contributing person-time and 2 events to
> sets with no case. Removing them gives **HR 2.06 (1.46–2.92)** against 2.28
> (`Z_T01`). This is in the manuscript as a sensitivity analysis and a
> limitation.

---

## 4. Outcome rule and code list

A patient is an event if, **after day 180 and within the at-risk window**, either
condition holds. One rule, both arms, no arm-specific branch.

**(a) A qualifying seizure code**

| Counted | Codes |
|---|---|
| ICD-10 | `G40.x` (epilepsy), `R56.9` and other `R56.x` (convulsions) |
| ICD-9 | `345.x` (epilepsy), `780.39` (other convulsions) |
| legacy | `0345x`, `07703x` variants |

| Explicitly excluded | Codes / rule |
|---|---|
| Psychogenic / conversion | `F44.5`, `300.11` |
| Provoked (post-traumatic, febrile) | `R56.1`, `780.32`, `780.33` |
| Family history | `Z82.0` |
| Migraine | `G43.x` |
| Anticonvulsant adverse effect / poisoning | `E936`, `966` |
| Descriptor match | febrile, non-epileptic, psychogenic, conversion, family history, migraine, poisoning, adverse |

Conditional: `R56.9 "Spells Neurological (HCC)"` counts **only** with concurrent
indefinite anti-seizure therapy. Affected one patient (an IIH case).

Sources: the dated diagnosis extract and the problem list. For problem-list
entries the onset date is used where present, otherwise the recorded date —
the earlier of the two, the conservative choice for an incident outcome.

**(b) Indefinite anti-seizure medication**

Records spanning ≥180 days, or a single prescription written for ≥180 days.
Agents counted: levetiracetam, lamotrigine, carbamazepine, oxcarbazepine,
valproate, divalproex, phenytoin, fosphenytoin, lacosamide, zonisamide,
perampanel, brivaracetam, felbamate, rufinamide, vigabatrin, tiagabine,
primidone, ethosuximide, phenobarbital, eslicarbazepine, cenobamate.

**Not counted:** topiramate and acetazolamide (IIH treatments — counting either
manufactures events in the IIH arm by construction), gabapentin and pregabalin
(analgesics), and midazolam, lorazepam, diazepam, clonazepam (procedural
sedation). The `9999-12-31` end-date sentinel is read as therapy active at freeze.

**Event date:** the earlier of the first qualifying code and the first
qualifying medication record.

> `report/OUTCOME_DEFINITION.md` is correct on the rule but its closing results
> table (HR 1.87) predates the re-match. Use `K_T38`.

---

## 5. The eleven negative controls

| # | Outcome | ICD-10 | ICD-9 |
|---|---|---|---|
| 1 | Herpes zoster | `B02` | `052`, `053` |
| 2 | Renal or ureteric stone | `N20`, `N23` | `592`, `594` |
| 3 | Gallstones | `K80`, `K81` | `574`, `575` |
| 4 | Acute appendicitis | `K35`, `K37` | `540`, `541` |
| 5 | Carpal tunnel syndrome | `G56.0` | `354.0` |
| 6 | Upper respiratory infection | `J00`–`J06`, `J09`–`J11`, `J20`, `J21` | `460`–`466`, `487`, `488` |
| 7 | Otitis media or externa | `H60`, `H65`–`H67` | `380.1`, `381`, `382` |
| 8 | Sprain or strain | `S13`, `S23`, `S33`, `S43`, `S53`, `S63`, `S73`, `S83`, `S93` | `840`–`848` |
| 9 | Laceration or open wound | `S41`, `S51`, `S61`, `S71`, `S81`, `S91` | `880`–`884`, `890`–`894` |
| 10 | Contact dermatitis | `L23`–`L25` | `692` |
| 11 | Fracture, excluding skull and face | `S12`, `S22`, `S32`, `S42`, `S52`, `S62`, `S72`, `S82`, `S92` | `805`–`829` |

All eleven were **more prevalent in the IIH arm at baseline** (ratios 1.6–5.0,
all p < 0.01), so none met the pre-specified balance criterion and the panel
cannot support a specificity claim. It is used for calibration and for the
directional test only. Full results: `K_T42`, `K_T45`, `K_T55`.

---

## 6. Setting, sites, study period

| Item | Value |
|---|---|
| Study period (index dates) | **7 June 2002 – 11 November 2025** |
| Median index date | 31 January 2021 (IIH), 11 November 2020 (comparators) |
| Data freeze | **3 September 2026** |
| Data source | integrated electronic health record — inpatient, outpatient, emergency, procedural and laboratory encounters, with linked diagnoses, medications, flowsheet vitals and vital status |

> **NOT AVAILABLE — you must supply this.** The **health system name and the
> number of sites** are nowhere in the extracts. The affiliation says Mayo Clinic
> but I cannot tell from the data whether this is one campus or a multi-site
> enterprise, and I will not guess. Note also that `carpal_incident` was not
> extracted for male comparators (female pairs only), which hints at a
> site/extract structure you will know and I do not.

---

## 7. Table 1 — full (`Z_T02`)

| Variable | IIH (n = 2,138) | Comparator (n = 5,743) | SMD |
|---|---|---|---|
| Person-years | 4,563.0 | 9,375.2 | — |
| Follow-up, y, median (IQR) | 2.77 (1.23–3.00) | 1.51 (0.52–3.00) | — |
| Age at index, y, mean (SD) | 34.9 (10.2) | 35.5 (9.5) | −0.065 |
| Female | 1,875 (87.7%) | 4,972 (86.6%) | 0.034 |
| BMI, kg/m², mean (SD) | 36.5 (7.3) | 36.2 (6.5) | 0.050 |
| Obese (BMI ≥ 30) | 1,712 (80.1%) | 4,478 (78.0%) | 0.052 |
| Hypertension | 473 (22.1%) | 940 (16.4%) | **0.146** |
| Obstructive sleep apnoea | 630 (29.5%) | 884 (15.4%) | **0.342** |
| Polycystic ovary syndrome | 264 (12.3%) | 418 (7.3%) | **0.171** |
| Bariatric surgery | 74 (3.5%) | 124 (2.2%) | 0.079 |
| Visits, 12 mo before index, mean (SD) | 20.6 (26.5) | 9.2 (15.2) | **0.526** |
| Visits, 12 mo before index, median (IQR) | 12 (5–26) | 4 (1–10) | — |
| Current smoker *(not comparable)* | 16 (0.7%) | 433 (7.5%) | −0.346 |
| Died during follow-up | 38 (1.8%) | 89 (1.5%) | 0.018 |
| Opening pressure, cmH₂O, mean (SD) | 29.5 (9.7), 74% available | not recorded | — |

**Four imbalances exceed |SMD| 0.10 and must be reported, not smoothed:**
hypertension 0.146, **OSA 0.342**, **PCOS 0.171**, and pre-index visits 0.526.

> **OSA at 0.342 deserves its own sentence in the Discussion.** OSA has an
> established association with epilepsy and is nearly twice as common in the IIH
> arm. It is a genuine confounding candidate, it was not matched on, and it is
> not adjusted for in the primary model. This is a stronger residual-confounding
> concern than anything currently written in the Limitations.
>
> Smoking is a **capture artefact** between the two source extracts, not a real
> difference, and is not used as a covariate.

---

## 8. Person-years

| Arm | n | Events | Person-years | Rate /1,000 py | Median follow-up (IQR), y |
|---|---|---|---|---|---|
| IIH | 2,138 | 66 | **4,563.0** | 14.46 (11.19–18.40) | 2.77 (1.23–3.00) |
| Comparator | 5,743 | 63 | **9,375.2** | 6.72 (5.16–8.60) | 1.51 (0.52–3.00) |
| Total | 7,881 | 129 | **13,938.1** | — | — |

Check: 1000 × 66 / 4563.0 = 14.46 ✓ · 1000 × 63 / 9375.2 = 6.72 ✓

Median follow-up differs between arms (2.77 vs 1.51 y) because comparators reach
their last attended encounter sooner. Rates and the Cox model both account for
person-time; this is stated in the Limitations.

---

## 9. Secondary outcome test (`Z_T03`)

| | Recurrent / epilepsy | Single seizure | % (95% CI) |
|---|---|---|---|
| IIH | 41 | 25 | 62% (49–74) |
| Comparator | 32 | 31 | 51% (38–64) |

**Fisher exact p = 0.217.** Odds ratio 1.58 (0.74–3.40). (χ² p = 0.263.)

Not significant. The manuscript already says the difference is compatible with
chance and makes no severity claim; this is the number behind that sentence.

---

## 10. Covariates in the final run

**Matched on:** sex (exact), age at index, BMI, BMI calendar year.
*(Race specified but inoperative — missing for 100% of cases.)*

**In the primary Cox model:** exposure only —
`Surv(t, ev) ~ iih + cluster(match_set)`. One parameter, 129 events (129 events
per parameter). Confounding is handled by design, not by adjustment.

**In the propensity model** (overlap weighting, `SAP_T6`):
age, female, BMI, log(1 + pre-index visits). Four parameters, 32.2 events per
parameter. c-statistic 0.72.

**In sensitivity models only:** six pre-index healthcare-contact measures
(visits 12 m, visits 24 m, months with a visit 12 m, all visits, years of
history, office visits 12 m).

**Available but deliberately unused:** OSA, PCOS, hypertension, bariatric
surgery, smoking (capture artefact), opening pressure (IIH only), encephalocele
and imaging fields (IIH only), EEG fields (IIH only), all post-index contact
counts (colliders).

> The imbalanced comorbidities (OSA, PCOS, hypertension) are **available in both
> arms and were not adjusted for**. Pre-specification says confounding is handled
> by matching, and post-hoc adjustment invites the criticism that the model was
> chosen after seeing the result — but a reviewer will ask, particularly about
> OSA. I would add a pre-stated sensitivity analysis adjusting for OSA,
> hypertension and PCOS, and report it whatever it shows. Say the word and I
> will run it.
