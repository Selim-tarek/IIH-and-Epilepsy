# Audit: did the stale `enc_pre12` variable contaminate any reported result?

Prompted by an error I made while building the full Table 1: I used
`enc_pre12` from the master workbook, which is computed on the comparators'
**original** index dates and is therefore stale after the re-match. The question
is whether that variable, or the `engaged` flag derived from it, reached any
published number.

**Answer: no. No reported result depends on it.** Evidence below, including the
case where it *would* have mattered.

---

## 1. The variables genuinely differ — this is not a cosmetic issue

| | Stale `enc_pre12` | Correct, recomputed at inherited index |
|---|---|---|
| Mean pre-index visits, whole cohort | 16.5 | 12.3 |
| IIH vs comparator | 30.5 vs 11.3 | **20.6 vs 9.2** |
| SMD | 0.607 | **0.526** |
| Correlation between the two | \multicolumn{2}{c}{0.743} |
| Patients where they differ | \multicolumn{2}{c}{**7,421 of 7,881**} |

---

## 2. Every use of the stale variables, and whether it is live

`enc_pre12`, `enc_post` and `n_encounters` appear in 24 scripts. All but two are
in **superseded pipelines** (`01`–`14`, `F`, `G2`–`G5`, `H`, `K1`–`K14`), whose
outputs are not in the final results.

| Script | Use | Live? |
|---|---|---|
| `F1_import_audit_final` | reads the columns into the typed dataset | defines only; never analysed |
| `G1_build_master` | `d$engaged <- enc_pre12 >= 1` | **used only for a descriptive count inside G1** (`G_T02`, 6,643) |
| `K15_final_analysis` | — | builds its own engagement (line 126) from dated encounters |
| `K17, K19, K20, K22, K23, K24, K25, K26, K27` | — | no reference at all |

`K24` computes its own `pre12` from the dated encounter files relative to the
inherited index date (line 66), and that is what the propensity and
contact-adjustment models use.

## 3. Proof that K15 did not use the `engaged` flag

If K15 had filtered on `G1`'s flag, every row in the analysis set would carry
`engaged == TRUE`. It does not:

```
rows with engaged == TRUE : 5,439 of 7,881
```

K15 recomputes engagement independently, requiring a dated clinical encounter in
`[case index − 365, case index − 1]` for **both** arms.

## 4. The primary estimate cannot be affected

The primary model contains **no covariates**:

```r
coxph(Surv(t, ev) ~ iih + cluster(match_set))
```

No visit variable can enter it. Refitted directly during this audit:

```
HR 2.28 (1.62 to 3.22), p = 2.62e-06      — identical to the published value
```

## 5. The one place it would have mattered — and the published value is correct

Two models do use a pre-index visit count. Both were refitted under each version:

| Model | With stale variable | With correct variable | **Published** |
|---|---|---|---|
| Overlap-weighted HR | 1.80 (1.21–2.68) | **2.31 (1.56–3.43)** | **2.31 (1.56–3.43)** ✓ |
| Contact-adjusted HR (visits 12 m) | 2.32 (1.53–3.52) | **2.46 (1.67–3.62)** | **2.46** ✓ |

The published figures match the **correct** variable in both cases
(`SAP_T6`, `K_T50`).

> **This was a real near-miss, not a trivial one.** Had the stale column fed the
> propensity model, the overlap-weighted estimate would have been **1.80 instead
> of 2.31** — a materially different number that would have looked like evidence
> the effect weakens under weighting. It did not happen, because `K24` builds its
> own variable from the dated encounter files rather than reading the workbook
> column. The error was confined to my first pass at Table 1 and was caught
> before it entered any document.

## 6. The stale descriptive count is not cited

`G_T02` reports 6,643 "engagement-restricted" patients, derived from the stale
flag. That number appears in **no** current document — not in
`FINAL_RESULTS.md`, `MANUSCRIPT.md` or `METHODS_SPECIFICATION.md`, which use
K15's own flow (2,520 engaged → 2,490 matched).

---

## Conclusion

| Result | Status |
|---|---|
| Primary HR 2.28 (1.62–3.22) | **unaffected** — no covariates in the model |
| All sensitivity analyses in `K_T38` | **unaffected** — same uncovariated model |
| Landmarks, Fine–Gray | **unaffected** |
| Overlap-weighted 2.31 | **correct variable used** (verified by refit) |
| Contact adjustment, all six measures | **correct variable used** (verified by refit) |
| Negative controls, calibration, E-values | **unaffected** — do not use the variable |
| Table 1 pre-index visits | **was wrong in my first pass; corrected to 20.6 vs 9.2 before publication** |

## Guard added

`R/Z4_table1_full.R` now takes the recomputed value from `K24` and asserts the
join, with a comment stating why `enc_pre12` must not be used. The column remains
in the typed dataset because superseded scripts reference it; it is not read by
any current analysis.
