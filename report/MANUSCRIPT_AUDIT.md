# Audit of the submitted manuscript against the final analysis

`IIH_Seizures_Epilepsia_Revised_Manuscript.docx`, checked line by line against
the 18 September 2026 run. Three categories: **correct**, **wrong**,
**unverifiable**.

---

## A. RESOLVED — the exclusion is real, but one-sided (authors confirmed)

> §2.2: *"Patients with a history of ischemic stroke, intracerebral or
> subarachnoid hemorrhage, craniotomy, brain tumor, or traumatic brain injury
> were excluded because these conditions are independent risk factors for
> seizures."*

**Resolution: the authors confirm it was applied to comparators only**, at the
stage of comparator extraction — which is why no variable for these conditions
exists in the analysis set and no pipeline script references their codes. My
original finding (that the analysis never applied it) was correct; the
inference that it was never applied *at all* was not.

This is worse than a documentation error and better than a fabrication. Removing
seizure-prone patients from the comparator arm alone lowers the comparator event
rate and **biases the hazard ratio away from the null** — in the direction that
flatters the finding. Deleting the sentence would conceal a real deviation;
describing it as applied "to both groups" is false. The manuscript now states
the asymmetry, its direction of bias, and that it cannot be quantified without
an IIH-arm extract.

This is the single most damaging sentence in the manuscript. It is a specific,
checkable claim about cohort construction, and if a reviewer or editor asks for
the code it collapses. Two honest options:

1. **Delete the sentence** and state plainly that no neurologic exclusions were
   applied, adding it to the Limitations as residual confounding by
   epileptogenic comorbidity.
2. **Actually apply it** — this requires a diagnosis extract covering I60–I63,
   S06.x, C71.x, D32.x and craniotomy procedure codes for **both** arms, which
   is not in `data-raw/`. It would be a new data request and a re-run.

**Applied:** accurate disclosure in Methods §2.2 and a new Limitations
paragraph. **Outstanding data request:** an IIH-arm diagnosis extract covering
I60–I63, S06.x, C71.x, D32.x and craniotomy procedure codes with dates, to allow
a symmetric re-analysis.

## B. WRONG — numbers that do not match the data

| Manuscript says | Actual | Where |
|---|---|---|
| *"Only 30 patients in the present dataset had documented encephalocele status"* | **60 patients assessed** (43 positive, 17 negative), all in the IIH arm; comparators were never extracted | §4 Discussion |
| Abstract: *"**Adults** with IIH"* | Cohort is **13.0–59.1 years**; 106 patients are under 18. The body correctly says "Adolescents and adults", so the abstract contradicts §2.2 | Abstract, Methods |
| Matching described as **four** tiers | **Five** tiers. As written, tiers 3 and 4 are also mis-stated: the real sequence is (1) race + BMI-year + age±3 + BMI±3, (2) BMI-year + age±3 + BMI±3, (3) age±3 + BMI±3, (4) age±3 + BMI±5, (5) age±5 + BMI±5 | §2.3 |

On the encephalocele point, 43 positive of 60 assessed is a **more** interesting
number than 30, but it is 60 of 2,138 IIH patients assessed at all, so the
conclusion ("too sparse for meaningful analysis") still stands. State it as
"encephalocele status was assessed in only 60 patients with IIH (43 positive)".

## C. RESOLVED — chart review confirmed by the authors

> §2.4 and §3.2: chart review of 50 events per group; *"48 of 50 ... confirmed
> (PPV 96%; 95% CI 86%–100%), compared with 50 of 50 among comparators (PPV
> 100%; 95% CI 93%–100%)"*, and the Limitations sentence about false positives
> being 4% versus 0%.

**No chart review appears in any output I hold.** There is no table, no script
and no derived object containing it, and earlier in this project the position
was that validation had not been done ("I will review later"). The exact
binomial intervals quoted are arithmetically correct for 48/50 and 50/50, so
whoever wrote them computed them properly.

**Resolution: the authors confirm the review was performed and the figures check
out.** It is retained as written. It is recorded here only so that the audit
trail shows the claim was checked and confirmed externally rather than verified
from analysis output — no table for it exists in this repository, so if a
reviewer asks for the validation data it must come from the chart-review
records, not from `outputs/`.

## D. CORRECT — verified against the run

Everything below matches exactly. No changes needed.

Cohort: 2,520 eligible → 2,490 matched (98.8%) → 2,138 analysed; 5,743
comparators; 2.31 per case; 87% at tier 1; 4,563.0 and 9,375.2 person-years
(13,938 total); median follow-up 2.77 (1.23–3.00) and 1.51 (0.52–3.00) years.

Baseline: SMDs −0.065 age, 0.034 sex, 0.050 BMI; OSA 29.5% vs 15.4% (0.342);
PCOS 12.3% vs 7.3% (0.171); hypertension 22.1% vs 16.4% (0.146); median visits
12 vs 4 (0.526); opening pressure 1,585 (74%), 29.5 cmH₂O (SD 9.7).

Primary: 66 and 63 events; 14.46 (11.19–18.40) and 6.72 (5.16–8.60) per 1,000
py; HR 2.28 (1.62–3.22); PH p = 0.94; 3-year 3.83% vs 1.71%; difference 2.12 pp.

Sensitivities: 1.93 (1.34–2.77); 2.30 (1.35–3.92); 2.25 (1.41–3.59); 2.79
(1.98–3.93); 2.06 (1.46–2.92); landmarks 2.49 / 2.29 / 2.22; overlap 2.31
(1.56–3.43); Fine–Gray 2.28; death 0.61 (0.29–1.29). 352 sets, 789 comparators,
2 events.

Comorbidity: OSA 1.87 (1.29–2.71); hypertension 1.41 (0.95–2.08); PCOS 1.14
(0.64–2.02); adjusted 2.11 (1.48–3.01); plus pre-index visits 2.33 (1.58–3.45).

Secondary: 41/66 (62%, 49–74) vs 32/63 (51%, 38–64); Fisher p = 0.22.
Subgroups: 1.90 / 2.72 (p = 0.31); 2.86 / 1.87 (p = 0.26); 1.98 / 5.12
(p = 0.055), 20 male events.

Detection: surveillance 2.70 (2.68–2.73), 5.74 (4.96–6.65), laboratory 1.14;
11 controls, ratios 1.6–5.0, all p < 0.01; **8 of 11 with CIs excluding 1**
(verified); seizure rate ratio 2.15 **lower than 6 of 11** (verified: laceration
4.31, otitis 3.06, stone 3.00, zoster 2.92, carpal 2.90, sprain 2.44);
calibration r = 0.66, p = 0.026, predicted 1.04 (0.37–2.90); 66 of 66 controls
toward null, median −29%, range −46% to −3%; seizure 2.46–2.93; post-index
adjustment 1.25 (0.85–1.85); E-values 3.99 and 2.62.

---

## E. Wording that undersells the result

You are right that the current wording undermines the findings. The problem is
not that it is too cautious — the caution is warranted — but that it concedes
more than the evidence requires and states the concession *before* the defence.
Six specific places:

| Current | Problem | Suggested |
|---|---|---|
| Abstract Significance: *"Differential surveillance was clearly present and could not be completely excluded as an explanation."* | Reads as though surveillance might explain the whole thing. Your own analysis says it is unlikely to. | *"Differential surveillance was present and could not be excluded as a partial contributor, but several analyses argue against it explaining the association in full."* |
| Abstract: *"Empirical calibration was inconclusive."* | Bald. Omits that the point estimate for a detection-only effect was essentially null. | *"Empirical calibration estimated a detection-attributable HR of 1.04, although its confidence interval was wide and included the observed estimate."* |
| Key Point: *"Sensitivity analyses generally supported the primary association"* | "Generally" implies exceptions. There are none — every specification is above 1.9. | *"The association persisted across all outcome definitions, landmarks, and analytic models (range 1.93–2.79)."* |
| Key Point: *"…but empirical calibration did not exclude detection bias."* | Ends the list on the weakest point. | Split: keep calibration as its own point, and add one for the 66/66 directional result, which is your strongest evidence and currently appears in no Key Point. |
| Discussion: *"Several findings argue against a simple explanation based solely on surveillance."* | "A simple explanation" is vague; the three findings that follow are strong and specific. | *"Three findings argue against differential detection accounting for the association in full."* |
| Conclusion: *"Differential healthcare surveillance was clearly present and cannot be completely excluded, However it does not fully explain this assoication."* | Comma splice, capital "However", and **"assoication" is misspelt**. Also asserts more firmly than the Abstract does — the two disagree. | *"Differential healthcare surveillance was present and cannot be excluded as a partial contributor, but the available evidence argues against it explaining the association in full."* |

The substantive point: **the 66-of-66 directional result is your strongest
evidence and it is buried.** Every negative control moves toward the null under
healthcare-seeking adjustment while seizure moves away, across six independent
measures. That is a discriminating finding, it appears once in §3.5 and once in
passing in the Discussion, and it is in no Key Point and not in the Abstract.
It should be in both.

Equally, the laboratory rate ratio of 1.14 — surveillance is *not* elevated in
the one setting a clinician does not initiate — currently appears as a bare
number in §3.5 with no interpretation. It is evidence, and it should be read as
such in the Discussion.
