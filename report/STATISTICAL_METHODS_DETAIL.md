# Statistical methods in full — estimators, formulas, implementations and results

Companion to `report/FINAL_RESULTS.md` (results), `report/STATISTICAL_ANALYSIS_PLAN.md`
(pre-specification) and `report/MANUSCRIPT.md` (manuscript text).

This document states, for every quantity reported, **the estimator as a formula**,
**the exact code that computed it**, **the table it was written to**, and **the
value obtained**. Formulas are given in plain notation, readable as text.

Software: R, package `survival`. Seed 20250906. Data freeze 3 September 2026.
Full reproduction: `./run_final.sh`.

---

## 1. Notation

| Symbol | Meaning |
|---|---|
| `i` | patient |
| `s(i)` | matched set containing patient `i` |
| `Z_i` | exposure; 1 = IIH, 0 = comparator |
| `d_i` | index date (comparators **inherit** the index date of their matched case) |
| `W` | washout, 180 days |
| `τ` | administrative horizon, 3 years |
| `C_i` | censoring date = min(last attended encounter, death, freeze) |
| `T_i` | time from end of washout to event or censoring, in years |
| `δ_i` | event indicator, 1 = incident seizure/epilepsy |

Follow-up starts at `d_i + W`, not at `d_i`: all analyses are post-washout, so no
delayed entry is needed.

```
open_i = min(C_i − d_i, W + 365.25τ)          # at-risk window, days
T_i    = (min(event_day_i, open_i) − W) / 365.25
```

`open_i` depends only on attendance, death and the freeze — **never on the
outcome**. An outcome-censored clock makes recurrence unobservable, and an
earlier version of this analysis that used one was corrected.

---

## 2. Covariate balance — standardised mean difference

Continuous covariate:

```
SMD = (x̄₁ − x̄₀) / sqrt( (s₁² + s₀²) / 2 )
```

Binary covariate:

```
SMD = (p₁ − p₀) / sqrt( ( p₁(1−p₁) + p₀(1−p₀) ) / 2 )
```

Pooled (not exposure-specific) denominator, so the statistic does not depend on
which arm is labelled 1. **Balance is judged on the SMD, not on a p-value**: a
p-value confounds imbalance with sample size and is not reported for Table 1.
Threshold for concern: |SMD| > 0.10.

Implementation: `smd_cont()`, `smd_bin()` in `R/00_setup.R`.
Result (`SAP_T1`, `K_T41`): age −0.065, sex 0.034, BMI 0.050 — all below 0.10.
Hypertension 0.146 and pre-index visits 0.526 exceed it and are reported as
residual imbalance.

---

## 3. Incidence rate and its confidence interval

Rate per 1,000 person-years:

```
rate = 1000 × D / PT          D = Σδ_i ,  PT = ΣT_i
```

Exact (Garwood) Poisson interval, inverting the chi-square relationship — used
rather than a normal approximation because event counts are small:

```
lower = 1000 × χ²(α/2 ; 2D) / 2 / PT
upper = 1000 × χ²(1−α/2 ; 2(D+1)) / 2 / PT
```

Implementation: `pois_rate_ci()` in `R/00_setup.R` (`qchisq`).
Result (`K_T38`): IIH 14.46 (11.19–18.40); comparator 6.72 (5.16–8.60) per 1,000 py.

## 3b. Incidence rate ratio — exact conditional test

Conditional on the total events `D₁+D₀`, the count `D₁` is binomial, which gives
an exact test and interval for the rate ratio:

```
D₁ | D₁+D₀  ~  Binomial( D₁+D₀ ,  π )      π = PT₁ / (PT₁+PT₀)  under H₀
IRR = [ p/(1−p) ] × (PT₀/PT₁)              p = D₁/(D₁+D₀)
```

Implementation: `irr_exact()` (`binom.test`). Result (`K_T55`): 2.15 (1.52–3.04).

---

## 4. Primary model — Cox cause-specific hazards

Model:

```
h(t | Z) = h₀(t) · exp(β Z)          HR = exp(β)
```

`β` estimated by maximising the partial likelihood, with Efron's handling of ties:

```
L(β) = Π over event times t_j  [  exp(β Z_j)  /  ( Σ_{k ∈ R(t_j)} exp(β Z_k) )  ]
```

where `R(t_j)` is the risk set at `t_j`.

**Variance.** Matched sets are not independent observations, so the model-based
variance is wrong. A robust sandwich (Lin–Wei) variance clustered on the matched
set is used throughout:

```
V_robust = I(β)⁻¹ [ Σ_clusters ( Σ_{i ∈ cluster} U_i )( · )ᵀ ] I(β)⁻¹
```

`U_i` = score (dfbeta) residual for patient `i`; `I(β)` = observed information.
Every hazard ratio in this paper uses this variance.

Code:

```r
coxph(Surv(t, ev) ~ iih + cluster(match_set), data = a)
```

This is a **cause-specific** hazard: patients who die are censored. Death is
analysed separately as a competing event (§7).

Result (`K_T38`): **HR 2.28 (95% CI 1.62–3.22), p = 2.6 × 10⁻⁶**, from 66/2,138
versus 63/5,743.

---

## 5. Proportional hazards

Tested on scaled Schoenfeld residuals. For covariate `Z` at event time `t_j`:

```
r_j = Z_j − E[Z | R(t_j)]          (Schoenfeld residual)
r*_j = r_j / Var(Z | R(t_j))       (scaled)
```

Under proportional hazards `E[r*_j] = β` and is flat in `t`; the test regresses
`r*_j` on transformed time and tests zero slope.

Code: `cox.zph(f)`. Result (`K_T38`): **p = 0.94** — no evidence against
proportionality, so a single hazard ratio is an adequate summary.

---

## 6. Cumulative incidence — Aalen–Johansen

With death as a competing event, `1 − Kaplan–Meier` overstates risk. The
cause-specific cumulative incidence function is used:

```
CIF_1(t) = Σ over event times t_j ≤ t   S(t_{j−1}) · [ d_{1j} / n_j ]
```

where `S(·)` is the overall (all-cause) survival, `d_{1j}` the seizure events at
`t_j` and `n_j` the number at risk. `1 − KM` is **not** used anywhere.

Code: `survfit(Surv(t, cr) ~ iih)` with `cr` a factor coding
(censored, seizure, death).

Result (`K_T38`, Figure 1): three-year CIF **3.83%** (IIH) versus **1.71%**
(comparator).

### Risk difference and number needed to harm

```
RD   = CIF₁(3) − CIF₀(3) = 3.83 − 1.71 = 2.12 percentage points
NNH  = 1 / (RD/100) = 1 / 0.0212 ≈ 47
```

NNH is over the three-year horizon and is not annualised.

---

## 7. Competing risks — Fine–Gray subdistribution hazard

The cause-specific hazard answers "among those still event-free and alive"; the
subdistribution hazard answers "what happens to absolute risk". Both are
reported because they answer different questions.

```
h₁^sub(t | Z) = h₁₀^sub(t) · exp(γ Z)
```

The subdistribution risk set keeps patients who have died of the competing cause,
with time-decaying weights `w_i(t) = Ĝ(t)/Ĝ(min(T_i,t))`, `Ĝ` the Kaplan–Meier
estimate of the censoring distribution.

Code:

```r
fg <- finegray(Surv(t, cr) ~ ., data = a)
coxph(Surv(fgstart, fgstop, fgstatus) ~ iih + cluster(match_set),
      weights = fgwt, data = fg)
```

Result (`SAP_T4`): subdistribution HR **2.28 (1.62–3.22)** — identical to the
cause-specific estimate, because the competing risk is rare and runs the other
way: cause-specific HR for death **0.61 (0.29–1.29)**.

---

## 8. Propensity score and overlap weighting

Propensity model:

```
logit P(Z=1 | X) = α₀ + α₁·age + α₂·female + α₃·BMI + α₄·pre-index visits
```

Code: `glm(iih ~ age_index + I(sex=="F") + bmi_index + visits12, family = binomial)`.

**Overlap weights** (Li, Morgan & Zaslavsky) rather than inverse-probability
weights, because they are bounded and cannot be destabilised by an extreme
propensity:

```
w_i = 1 − e_i    if Z_i = 1
w_i = e_i        if Z_i = 0
```

These weight each patient by their probability of belonging to the *other* arm,
giving exact mean balance on every covariate in the model by construction.

Result (`SAP_T6`): c-statistic 0.72; propensity ranges overlap (IIH 0.069–0.862,
comparator 0.063–0.855), so positivity holds. Pre-index visits SMD moves
0.526 → −0.073. Overlap-weighted **HR 2.31 (1.56–3.43)**.

---

## 9. Landmark analyses

To test whether the association is driven by events clustered immediately after
the washout (the pattern prevalent disease or work-up bias would produce),
follow-up is restarted at `L` days after the washout, excluding anyone with an
event before `L`:

```
analysis set: { i : open_i > L }     T_i^L = T_i − L/365.25
```

Code: `coxph(Surv(t2, ev2) ~ iih + cluster(match_set))`.

Result (`SAP_T3b`): L = 30 → 2.49 (1.73–3.58); L = 90 → 2.29 (1.54–3.41);
L = 180 → 2.22 (1.40–3.51). Stable, so the effect is not front-loaded.

---

## 10. Subgroups — interaction, not subgroup significance

A subgroup effect is claimed only from a formal interaction test. Comparing
whether one subgroup is significant and another is not is **not** a test of
effect modification and is not used.

```
h(t | Z, G) = h₀(t) · exp( β₁Z + β₂G + β₃(Z×G) )
Wald: χ² = β̂₃² / Var_robust(β̂₃),  1 df
```

Result (`SAP_T5`): age p = 0.31, BMI p = 0.26, sex p = 0.055. No interaction.
The male stratum (13 and 7 events) is not interpreted.

---

## 11. Proportions — exact binomial

For the secondary outcome (proportion of events that were recurrent/epilepsy),
Clopper–Pearson intervals, which invert the exact binomial test:

```
lower = BetaInv(α/2 ; k, n−k+1)
upper = BetaInv(1−α/2 ; k+1, n−k)
```

Code: `binom.test(k, n)`. Result (`K_T39`): IIH 41/66 = 62% (49–74);
comparator 32/63 = 51% (38–64). Compared by Fisher's exact test.

---

## 12. Negative controls and empirical calibration

**Screen.** A control is admitted only if baseline prevalence does not differ
between arms (p ≥ 0.05) and there are ≥25 events per arm. Baseline balance is
evaluated **first** and decides admission; the post-index hazard ratio is computed
for every candidate so the screen is auditable.

**Calibration.** For eleven controls indexed `c`, regress the observed log hazard
ratio on the log baseline prevalence ratio:

```
log HR_c = a + b · log R_c + ε_c          R_c = baseline prevalence ratio
```

The fitted value at perfect baseline balance (`log R = 0`) estimates the hazard
ratio that differential detection alone would produce:

```
HR_detection = exp(â)        with a prediction interval from the fit
```

Code: `lm(log(hr) ~ log(baseline_ratio))`, prediction interval at `log R = 0`.

Result (`K_T48`): r = 0.663 (p = 0.026), slope 0.84 (SE 0.31),
**HR_detection = 1.04 (0.37–2.90)**.

> **This interval contains the observed estimate of 2.28.** On this analysis
> alone the association cannot be formally distinguished from a detection
> artefact. This is stated in the Limitations, not omitted.

**Directional test.** Each outcome is re-estimated adjusting for each of six
pre-index contact measures, and the *direction* of movement recorded. A pure
detection artefact should move toward the null, as the controls do.

Result (`K_T50`): 66 of 66 control-by-measure combinations move toward the null
(median −29%); seizure moves **away** on all six (+7.8% to +28.6%).

---

## 13. Why post-index contact is not adjusted for

Post-index healthcare contact `V` lies on the path `Z → V` **and** `outcome → V`:
a seizure causes visits. Conditioning on a common effect of exposure and outcome
opens a non-causal path — collider stratification bias.

```
Z ──────────────→ outcome
 \                  /
  \→   V (post)  ←/         conditioning on V induces association
```

Demonstrated rather than asserted (`K_T52`): adjusting for post-index contact
drives seizure to 1.25 (0.85–1.85), but also drives upper respiratory infection
to 0.75 (0.61–0.92) and fracture to 0.39 (0.23–0.67) — implausibly protective.
An adjustment that makes IIH appear to protect against fractures is introducing
bias, not removing it.

Pre-index contact is **not** a collider (it precedes the outcome) and is used
freely for adjustment.

---

## 14. Quantitative bias analysis — E-value

For an observed risk ratio `RR`, the minimum strength of association (on the risk
ratio scale) that an unmeasured factor must have with **both** exposure and
outcome, conditional on measured covariates, to explain the estimate away:

```
E = RR + sqrt( RR × (RR − 1) )
```

The outcome is rare (3.83% and 1.71% at three years), so `HR ≈ RR` and the
approximation is appropriate.

```
point : E = 2.28 + sqrt(2.28 × 1.28) = 2.28 + 1.71 = 3.99
CI    : E = 1.62 + sqrt(1.62 × 0.62) = 1.62 + 1.00 = 2.62
```

Implementation: `evalue_hr()` in `R/00_setup.R`; `R/K27_evalue.R` (`K_T56`).

Interpretation is a **threshold on conditional associations**, not on marginal
ones. Measured surveillance channels: laboratory 1.14, hospital 2.27, procedural
2.32, visits 2.70, office 2.92 — all below 3.99; **emergency department 5.74
exceeds it**, and that is reported as a caveat rather than reconciled.

---

## 15. Power

Schoenfeld's approximation for the number of events required:

```
D = ( z_{1−α/2} + z_{1−power} )² / ( p(1−p) · (log HR)² )
```

with `p` the proportion of the analysis set in the exposed arm. Used only to size
the proposed active-comparator arm (`report/ACTIVE_COMPARATOR_REQUEST.md`); no
post-hoc power is computed for the observed result, which would be uninformative.

---

## 16. Multiplicity

The primary outcome is a single pre-specified comparison and is not adjusted.
Sensitivity analyses are re-expressions of that same comparison, not independent
tests, so adjusting across them would be incorrect. Subgroups and negative
controls are explicitly exploratory and are reported with unadjusted intervals
and labelled as such. No outcome was selected on the basis of its p-value.

---

## 17. Events per parameter

```
EPP = total events / parameters estimated
```

Primary model: 129 events, 1 parameter → 129 EPP. Propensity model: 4 parameters
→ 32.2 EPP (`SAP_T8`). Both well above the conventional minimum of 10, so the
models are not overfitted.

---

## 18. What was deliberately not done

- **1 − Kaplan–Meier** for cumulative incidence (overstates risk under competing risks).
- **Model-based standard errors** (ignore matched-set correlation).
- **Adjustment for post-index variables** in the primary model (collider, §13).
- **p-values for baseline balance** (confound imbalance with sample size).
- **Subgroup significance comparison** in place of an interaction test (§10).
- **Post-hoc power.**
- **Stepwise or data-driven covariate selection.**

---

## 19. Traceability

| Quantity | Formula section | Script | Table |
|---|---|---|---|
| Balance (SMD) | §2 | `K15` | `SAP_T1`, `K_T41` |
| Incidence rates | §3 | `K15` | `K_T38` |
| Rate ratio (exact) | §3b | `K26` | `K_T55` |
| Primary HR | §4 | `K15` | `K_T38` |
| Proportional hazards | §5 | `K15` | `K_T38` |
| Cumulative incidence, RD, NNH | §6 | `K15` | `K_T38` |
| Fine–Gray | §7 | `K24` | `SAP_T4` |
| Propensity, overlap | §8 | `K24` | `SAP_T6` |
| Landmarks | §9 | `K24` | `SAP_T3b` |
| Subgroup interactions | §10 | `K24` | `SAP_T5` |
| Exact proportions | §11 | `K15` | `K_T39` |
| Negative controls | §12 | `K17`, `K19` | `K_T42`, `K_T45` |
| Calibration | §12 | `K22` | `K_T48` |
| Directional adjustment | §12 | `K22` | `K_T50` |
| Collider demonstration | §13 | `K23` | `K_T52` |
| Surveillance rates | §14 | `K26` | `K_T54` |
| E-values | §14 | `K27` | `K_T56` |
| Orphaned-set sensitivity | — | `Z3` | `Z_T01` |
| Events per parameter | §17 | `K24` | `SAP_T8` |
