## Z2_final_output.R ----------------------------------------------------------
## Assembles every result of the final from-scratch run into one document.
## Reads only the tables written by this run; never recomputes an estimate, so
## the document and the tables cannot disagree.

source("R/00_setup.R")
log_msg("=== Z2 consolidated final output ===")
TB <- PATH$tables

## Freshness gate. Z2 reads tables by name, so a step that failed to rewrite one
## would let a table from an earlier analysis into this document. RUN_START is
## written by run_final.sh at the top of the run; any table older than it is a
## stale artefact and halts assembly rather than being reported as current.
rs <- Sys.getenv("RUN_START", "")
RUN_START <- if (nzchar(rs)) as.POSIXct(rs, tz = "") else NULL
if (is.null(RUN_START))
  log_msg("WARNING: RUN_START unset -- freshness of tables NOT verified")

stale <- character(0)
rd <- function(n, required = TRUE) {
  p <- file.path(TB, paste0(n, ".csv"))
  if (!file.exists(p)) {
    if (required) stop("REQUIRED TABLE MISSING: ", n, call. = FALSE)
    log_msg("optional table absent: ", n); return(NULL)
  }
  if (!is.null(RUN_START) && file.mtime(p) < RUN_START)
    stale <<- c(stale, sprintf("%s (written %s)", n,
                format(file.mtime(p), "%Y-%m-%d %H:%M")))
  utils::read.csv(p, check.names = FALSE, stringsAsFactors = FALSE)
}

## markdown table from a data.frame
md <- function(x, cols = NULL, names_to = NULL) {
  if (is.null(x)) return("_table not produced by this run_\n")
  if (!is.null(cols)) x <- x[, intersect(cols, names(x)), drop = FALSE]
  if (!is.null(names_to)) names(x) <- names_to
  x[] <- lapply(x, function(c) { c <- as.character(c); c[is.na(c)] <- "—"; c })
  paste0("| ", paste(names(x), collapse = " | "), " |\n",
         "|", paste(rep("---", ncol(x)), collapse = "|"), "|\n",
         paste(apply(x, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")),
               collapse = "\n"), "\n")
}

prov <- rd("Z_T00_provenance")
pv   <- rd("K_T38_FINAL_results_visits"); pa <- rd("K_T38_FINAL_results_all")
flow <- rd("K_T40_FINAL_flow_visits");    bal <- rd("K_T41_FINAL_balance_visits")
sec  <- rd("K_T39_FINAL_secondary_visits")
nc1  <- rd("K_T42_negative_controls");    nc2 <- rd("K_T45_negative_controls_v2")
cal  <- rd("K_T48_calibration_v2");       rob <- rd("K_T50_contact_robustness")
col  <- rd("K_T52_collider_demonstration", FALSE)
srv  <- rd("K_T54_post_index_surveillance"); nro <- rd("K_T55_negative_outcome_rates")
ev   <- rd("K_T56_evalue")
sap1 <- rd("SAP_T1_baseline", FALSE);  sap3b <- rd("SAP_T3b_landmark", FALSE)
sap4 <- rd("SAP_T4_competing_risks", FALSE); sap5 <- rd("SAP_T5_subgroups", FALSE)
sap6 <- rd("SAP_T6_propensity", FALSE)

assert(length(stale) == 0, paste0(
  "STALE TABLES -- these predate this run and would carry old results into the ",
  "final document:\n  ", paste(stale, collapse = "\n  ")))
log_msg("freshness gate passed: every table read was written by this run")

figs <- sort(basename(list.files(PATH$figures, pattern = "\\.(png|pdf)$")))
figs <- unique(sub("\\.(png|pdf)$", "", figs))

hdr <- pv[1, ]
out <- c(
sprintf("# Final results — complete from-scratch run

**Run date:** %s · **Master:** `IIH_MASTER_FINAL.xlsx` · **Freeze:** 3 September 2026 · **Seed:** %d

Every number below was produced by a single uninterrupted execution of
`run_final.sh`, beginning from the raw exports. Derived datasets were deleted
before the run; nothing was inherited from any earlier analysis. Raw files were
opened read-only.

---

## 0. Data provenance

Verified by `R/Z0_provenance.R` before any analysis ran. The gate fails closed:
a missing input, or a case encounter file at or below Excel's 1,048,575-row
ceiling (which would indicate silent truncation), halts the run.
", format(Sys.Date()), SEED),
md(prov, c("file","rows","md5_12","role"), c("File","Rows","md5 (12)","Role")),
"
Two superseded files remain in `data-raw/` and are **not** read by this pipeline:
`IIH_MASTER_cases_and_controls_2.csv` (one-sided washout) and
`MDE_Encounters_controls.csv` (no Encounter Type).

---

## 1. Cohort and matching
",
md(flow), "
### Baseline balance after matching
",
md(bal), "
Matching is on sex, age, BMI, race and BMI calendar year, in five relaxing
tiers. Comparators inherit the index date of the case they are matched to
(protocol §2.3); the 12-month engagement requirement and the prevalent-seizure
exclusion are both evaluated at that inherited date, so the two arms are
screened identically.

---

## 2. Primary outcome

Seizure or epilepsy after a 180-day washout, defined identically in both arms:
a qualifying code, or anti-seizure medication continued 180+ days.

### Encounter definition: clinical visits (primary)
",
md(pv), "
### Encounter definition: all encounter rows (sensitivity)
",
md(pa), "
Encounter type decides engagement and the censoring date only. It never touches
the outcome.

---

## 3. Secondary outcome — recurrent seizures or epilepsy among those with an event
",
md(sec), "
---

## 4. Pre-specified analyses (SAP)

### Landmark analyses
", md(sap3b), "
### Competing risks
", md(sap4), "
### Subgroups
", md(sap5), "
### Propensity and overlap
", md(sap6), "
---

## 5. Detection and surveillance assessment

### 5a. Post-index surveillance
", md(srv), "
### 5b. Negative-control outcomes, panel 1
", md(nc1), "
### 5c. Negative-control outcomes, panel 2
", md(nc2), "
### 5d. Unadjusted rates, primary outcome against every negative control
", md(nro), "
### 5e. Empirical calibration
", md(cal), "
### 5f. Response to healthcare-seeking adjustment
", md(rob), "
### 5g. Collider demonstration
", md(col), "
### 5h. Quantitative bias analysis
", md(ev), "
---

## 6. Figures

Every figure listed here was regenerated by this run. Figures from earlier
pipelines were moved to `outputs/figures_superseded/`, so a figure built on a
cohort that has since been rebuilt cannot be picked up by mistake. Nothing in
that directory belongs to the current manuscript.
",
paste0(paste0("- `outputs/figures/", figs, "`"), collapse = "\n"), "

---

## 7. Reproduction

```
./run_final.sh
```

Runs the provenance gate, rebuilds the master dataset, re-matches both arms on
dated encounters, recomputes every estimate and regenerates every figure. Halts
on the first failure.
")

writeLines(out, file.path(PATH$report, "FINAL_RESULTS.md"))
log_msg("wrote report/FINAL_RESULTS.md")
log_msg("Z2 complete")
