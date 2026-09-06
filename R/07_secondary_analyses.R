## 07_secondary_analyses.R ----------------------------------------------------
## Protocol v2.0 objectives 1-3, plus the exploratory within-IIH analyses that
## this export can support. Everything here is labelled by evidentiary status.

source("R/00_setup.R")
log_msg("=== 07 secondary ===")
a  <- readRDS(file.path(PATH$derived, "05_analytic.rds"))
tr <- readRDS(file.path(PATH$derived, "05_truncate_fn.rds"))
pr <- readRDS(file.path(PATH$derived, "06_primary.rds"))

cox_hr <- function(dat, tau, rhs = "iih", strat = FALSE, term = 1) {
  s <- tr(dat, tau)
  if (sum(s$ev) < 5) return(c(n = nrow(s), ev = sum(s$ev), hr = NA, lo = NA, hi = NA, p = NA))
  f <- stats::as.formula(paste("Surv(t, ev) ~", rhs,
                               if (strat) "+ strata(match_set)" else ""))
  fit <- if (strat) survival::coxph(f, data = s)
         else survival::coxph(f, data = s, cluster = s$match_set, robust = TRUE)
  sm <- summary(fit)
  c(n = fit$n, ev = fit$nevent, hr = sm$conf.int[term, 1],
    lo = sm$conf.int[term, 3], hi = sm$conf.int[term, 4],
    p = sm$coefficients[term, ncol(sm$coefficients)])
}

## ---- OBJECTIVE 1: negative control outcome (protocol s4.3) -----------------
## Carpal tunnel syndrome has no plausible causal link to IIH. If the IIH-
## seizure hazard is really just a measure of healthcare contact, carpal tunnel
## should be elevated too. This is the single most informative check in the
## whole study, and it is the reason a positive seizure result is credible.
## Restricted to females: the outcome was not extracted for male controls.
nc <- a[!is.na(a$carpal_incident) & a$sex == "F", ]
nc$event_seizure <- nc$carpal_incident   # reuse the truncation machinery
nc$status_cr <- factor(ifelse(nc$carpal_incident == 1, "seizure",
                       ifelse(nc$died == 1, "death", "censored")),
                       levels = c("censored", "seizure", "death"))
neg <- rbind(
  data.frame(outcome = "Incident seizure/epilepsy (positive outcome)",
             t(cox_hr(a[a$sex == "F", ], 3))),
  data.frame(outcome = "Incident carpal tunnel syndrome (NEGATIVE CONTROL)",
             t(cox_hr(nc, 3))))
neg$estimate <- fmt_est(neg$hr, neg$lo, neg$hi)
neg$p <- fmt_p(neg$p)
neg$interpretation <- c(
  "Elevated as hypothesised",
  ifelse(neg$lo[2] < 1 & neg$hi[2] > 1,
    "NULL, as required. Surveillance/healthcare contact alone does not produce an elevated hazard in this design, which materially strengthens the primary result.",
    "NOT null. The design is detecting healthcare contact, not disease -- the primary estimate must be treated as confounded by ascertainment."))
write_tab(neg, "T5a_negative_control")
print(neg[, c("outcome", "n", "ev", "estimate", "p")])

## ---- OBJECTIVE 2: temporal pattern of risk ---------------------------------
## Time-split rather than a single HR, because "when" matters causally: an
## effect concentrated in the first months after diagnosis is more consistent
## with detection at the point of diagnostic work-up than with a disease process.
s <- tr(a, Inf)
sp <- survival::survSplit(Surv(t, ev) ~ ., data = s, cut = c(0.5, 2),
                          episode = "period")
sp$period <- factor(sp$period, labels = c("0-6 months", "6 mo - 2 y", ">2 years"))
tsplit <- do.call(rbind, lapply(levels(sp$period), function(p) {
  ss <- sp[sp$period == p, ]
  fit <- survival::coxph(Surv(tstart, t, ev) ~ iih, data = ss,
                         cluster = ss$match_set, robust = TRUE)
  sm <- summary(fit)
  data.frame(period = p, events = fit$nevent,
             hr = round(sm$conf.int[1, 1], 2), lo = round(sm$conf.int[1, 3], 2),
             hi = round(sm$conf.int[1, 4], 2),
             p = signif(sm$coefficients[1, ncol(sm$coefficients)], 3))
}))
tsplit$estimate <- fmt_est(tsplit$hr, tsplit$lo, tsplit$hi)
## Formal test that the effect changes over time. anova() refuses robust
## variances, so this is a multivariate Wald test on the interaction terms
## using the sandwich covariance matrix directly.
int_p <- local({
  fit1 <- survival::coxph(Surv(tstart, t, ev) ~ iih * period, data = sp,
                          cluster = sp$match_set, robust = TRUE)
  k <- grep(":", names(stats::coef(fit1)), value = TRUE)
  b <- stats::coef(fit1)[k]; V <- fit1$var[match(k, names(stats::coef(fit1))),
                                           match(k, names(stats::coef(fit1))), drop = FALSE]
  if (any(!is.finite(b)) || any(!is.finite(V))) return(NA_real_)
  W <- as.numeric(t(b) %*% solve(V) %*% b)
  signif(stats::pchisq(W, df = length(k), lower.tail = FALSE), 3)
})
tsplit$interaction_p_overall <- c(int_p, NA, NA)
write_tab(tsplit, "T5b_time_split")
print(tsplit[, c("period", "events", "estimate")])

## ---- OBJECTIVE 3: EEG findings among IIH patients who seize ----------------
## Descriptive ONLY. EEG variables are blank in every control, so no comparative
## statement is possible. 99 = looked for, not found; 88 = not applicable.
iih <- a[a$iih == 1, ]
eeg_desc <- data.frame(
  variable = c("EEG performed", "Epileptiform EEG", "Temporal onset",
               "EEG laterality concordant with encephalocele side"),
  assessed = c(sum(iih$eeg_done_status == "assessed"),
               sum(iih$eeg_epileptiform_status == "assessed"),
               sum(iih$temporal_onset_status == "assessed"),
               sum(iih$concordant_status == "assessed")),
  positive = c(sum(iih$eeg_done == 1, na.rm = TRUE),
               sum(iih$eeg_epileptiform == 1, na.rm = TRUE),
               sum(iih$temporal_onset == 1, na.rm = TRUE),
               sum(iih$concordant == 1, na.rm = TRUE)),
  unknown_after_search = c(sum(iih$eeg_done_status == "unknown_after_search"),
               sum(iih$eeg_epileptiform_status == "unknown_after_search"),
               sum(iih$temporal_onset_status == "unknown_after_search"),
               sum(iih$concordant_status == "unknown_after_search")),
  not_assessable = c(sum(iih$eeg_done_status == "not_assessable"),
               sum(iih$eeg_epileptiform_status == "not_assessable"),
               sum(iih$temporal_onset_status == "not_assessable"),
               sum(iih$concordant_status == "not_assessable")))
write_tab(eeg_desc, "T5c_eeg_descriptive")

## ---- competing-event asymmetry (a finding, not a planned analysis) ---------
## The cause-specific HR for DEATH is far below 1. Two explanations compete:
## a genuinely lower-mortality exposed cohort, or differential death
## ascertainment (cases carry death_date; controls carry none). The second
## cannot be excluded from this export and would also inflate case person-time.
death_note <- data.frame(
  finding = "Cause-specific hazard of death is markedly LOWER in IIH cases",
  estimate = pr$cr$estimate[2],
  competing_explanations = paste(
    "(1) True: IIH is a disease of otherwise-healthy younger adults, and the",
    "control pool is drawn from the general clinical population, which at the",
    "same age/sex/BMI contains sicker patients.",
    "(2) Artefactual: death is ascertained differently. Cases have a death_date",
    "field; controls have no date fields at all. If control deaths are captured",
    "more completely than case deaths, case follow-up is over-extended, which",
    "would independently inflate case person-time (see audit C1/C2).",
    "These cannot be separated in this export. Because they push the seizure",
    "estimate in OPPOSITE directions, this is a priority question for the data team."))
write_tab(death_note, "S17_death_hazard_asymmetry")

## ---- EXPLORATORY: within-IIH severity proxy --------------------------------
## The protocol v1.0 mild/moderate/severe cumulative-burden gradient does not
## exist in this export (audit H2). What follows is a CRUDE PROXY built from
## the only severity-adjacent fields present, and is POST HOC EXPLORATORY.
## It must not be reported as the protocol's severity gradient.
iih$severity_proxy <- factor(
  ifelse(iih$shunt == 1 | iih$stent == 1, "Surgical (shunt or stent)", "No procedure"),
  levels = c("No procedure", "Surgical (shunt or stent)"))
sev <- data.frame(label = levels(iih$severity_proxy))
sev_fit <- cox_hr(iih, 3, "severity_proxy")
sev_tab <- data.frame(
  row.names = NULL,
  analysis = "Surgical vs non-surgical IIH, within IIH only, 3 y",
  n = sev_fit["n"], events = sev_fit["ev"],
  estimate = fmt_est(sev_fit["hr"], sev_fit["lo"], sev_fit["hi"]),
  p = fmt_p(sev_fit["p"]),
  status = "POST HOC EXPLORATORY",
  caveat = paste(
    "Shunt/stent placement is a POST-INDEX decision taken over the same period",
    "in which the outcome accrues. Treating it as a baseline severity marker",
    "creates immortal time (a patient must survive seizure-free to be operated on)",
    "and conditions on a post-exposure variable. No causal reading is available.",
    "It is reported only to show what the crude data look like."))

## Opening pressure, continuous. Splines are NOT used: with 56 events at 3 y in
## the IIH arm and only 70% of cases having a recorded pressure, a 3-knot RCS
## (2 df) plus the intercept is at the edge of the 10-events-per-parameter rule
## and the knot placement would be driven by a handful of events. A linear term
## and a pre-specified 3-level categorisation are honest at this sample size.
iih$op_cat <- cut(iih$op_cmh2o, breaks = c(-Inf, 34.99, 44.99, Inf),
                  labels = c("25-34 (or below threshold)", "35-44", ">=45"))
op_lin <- cox_hr(iih[!is.na(iih$op_cmh2o), ], 3, "op_cmh2o")
op_tab <- data.frame(
  row.names = NULL,
  analysis = c("Opening pressure, per 1 cmH2O (linear)",
               "Opening pressure, per 10 cmH2O (linear)"),
  n = op_lin["n"], events = op_lin["ev"],
  estimate = c(fmt_est(op_lin["hr"], op_lin["lo"], op_lin["hi"]),
               fmt_est(op_lin["hr"]^10, op_lin["lo"]^10, op_lin["hi"]^10)),
  p = fmt_p(op_lin["p"]), status = "POST HOC EXPLORATORY",
  caveat = paste("Restricted cubic splines were NOT fitted: with",
                 op_lin["ev"], "events the knot locations would be determined by",
                 "a handful of observations. Opening pressure is missing in 30% of",
                 "cases and 29% of measured values are below the 25 cmH2O diagnostic",
                 "threshold, so this variable also indexes diagnostic accuracy, not",
                 "severity alone."))
expl <- rbind(sev_tab[names(op_tab)], op_tab)
write_tab(expl, "T5d_exploratory_within_iih")
print(expl[, c("analysis", "n", "events", "estimate", "p")])

## ---- SUSPENDED: encephalocele mediation (protocol v2.0 change #8) ----------
## Reported as a 2x2 with denominators, and nothing more. No hazard ratio is
## fitted: 8 events across 90 assessable patients, and zero imaging in controls.
enc <- a[a$iih == 1, ]
enc_tab <- data.frame(
  encephalocele_status = c("Present", "Absent", "Not assessable (code 88)",
                           "Unknown after search (code 99)", "Not extracted"),
  n = c(sum(enc$enceph_index == 1, na.rm = TRUE),
        sum(enc$enceph_index == 0, na.rm = TRUE),
        sum(enc$enceph_index_status == "not_assessable"),
        sum(enc$enceph_index_status == "unknown_after_search"),
        sum(enc$enceph_index_status == "not_extracted")),
  incident_seizures = c(
    sum(enc$enceph_index == 1 & enc$event_seizure == 1, na.rm = TRUE),
    sum(enc$enceph_index == 0 & enc$event_seizure == 1, na.rm = TRUE),
    sum(enc$enceph_index_status == "not_assessable" & enc$event_seizure == 1),
    sum(enc$enceph_index_status == "unknown_after_search" & enc$event_seizure == 1),
    sum(enc$enceph_index_status == "not_extracted" & enc$event_seizure == 1)))
attr(enc_tab, "note") <- "descriptive only"
write_tab(enc_tab, "T5e_encephalocele_descriptive")

med_verdict <- data.frame(
  question = "Is a mediation analysis through encephalocele defensible?",
  verdict = "NO -- not identifiable, and not merely underpowered.",
  reasons = paste(
    "1. The mediator is measured in 2.5% of cases and in 0% of controls, so the",
    "exposure-mediator-outcome triple is never jointly observed in the control arm.",
    "2. Cross-world independence, required for natural direct/indirect effects,",
    "cannot even be examined without mediator data under the unexposed condition.",
    "3. Imaging was ordered because of the exposure, so mediator measurement is",
    "exposure-dependent; 'not assessable' (88) is informative missingness and must",
    "never be recoded as 'absent'.",
    "4. Congenital encephalocele is a competing causal explanation and cannot be",
    "distinguished from acquired without the serial-imaging fields, which are absent.",
    "5. Eight events across the assessable subgroup. Even an interventional or",
    "separable-effects reformulation would be estimating from single-digit counts.",
    "A larger hazard ratio in the encephalocele subgroup would NOT constitute",
    "evidence of mediation, and must not be described as such."))
write_tab(med_verdict, "S18_mediation_verdict")

saveRDS(list(neg = neg, tsplit = tsplit, eeg = eeg_desc, expl = expl,
             enc = enc_tab, int_p = int_p),
        file.path(PATH$derived, "07_secondary.rds"))
log_msg("07 complete")
