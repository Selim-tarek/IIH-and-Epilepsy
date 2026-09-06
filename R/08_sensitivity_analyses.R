## 08_sensitivity_analyses.R --------------------------------------------------
## Every analysis is labelled PRE-SPECIFIED (named in protocol v2.0),
## PROTOCOL-DERIVED (a direct implication of a v2.0 rule) or POST HOC.

source("R/00_setup.R")
log_msg("=== 08 sensitivity ===")
a  <- readRDS(file.path(PATH$derived, "05_analytic.rds"))
tr <- readRDS(file.path(PATH$derived, "05_truncate_fn.rds"))
ps <- readRDS(file.path(PATH$derived, "04_ps.rds"))

res <- list()
add <- function(label, status, dat, tau, rhs = "iih", strat = FALSE,
                wts = NULL, landmark = 0, note = "") {
  s <- tr(dat, tau)
  s <- s[!is.na(s$t) & !is.na(s$ev), ]
  if (landmark > 0) {                      # delayed entry at the landmark
    s <- s[s$t > landmark, ]
    s$t0 <- landmark
    f <- stats::as.formula(paste("Surv(t0, t, ev) ~", rhs,
                                 if (strat) "+ strata(match_set)" else ""))
  } else {
    f <- stats::as.formula(paste("Surv(t, ev) ~", rhs,
                                 if (strat) "+ strata(match_set)" else ""))
  }
  if (sum(s$ev) < 8) {
    res[[label]] <<- data.frame(analysis = label, status = status, n = nrow(s),
      events = sum(s$ev), estimate = "not estimated", p = NA,
      note = paste("fewer than 8 events;", note), stringsAsFactors = FALSE)
    return(invisible())
  }
  fit <- tryCatch({
    if (strat) survival::coxph(f, data = s)
    else if (!is.null(wts)) survival::coxph(f, data = s, weights = s[[wts]],
                                            cluster = s$match_set, robust = TRUE)
    else survival::coxph(f, data = s, cluster = s$match_set, robust = TRUE)
  }, error = function(e) NULL)
  if (is.null(fit) || !is.finite(stats::coef(fit)[1])) {
    res[[label]] <<- data.frame(analysis = label, status = status, n = nrow(s),
      events = sum(s$ev), estimate = "did not converge / separation", p = NA,
      note = note, stringsAsFactors = FALSE); return(invisible())
  }
  sm <- summary(fit)
  res[[label]] <<- data.frame(analysis = label, status = status,
    n = fit$n, events = fit$nevent,
    estimate = fmt_est(sm$conf.int[1, 1], sm$conf.int[1, 3], sm$conf.int[1, 4]),
    p = fmt_p(sm$coefficients[1, ncol(sm$coefficients)]),
    note = note, stringsAsFactors = FALSE)
}

## ---- 0. CORRECTED PRIMARY: symmetric 180-day outcome window ----------------
## Protocol v2.0 s2.1 excludes a seizure within 180 days of index in CASES as a
## presenting rather than incident event. That rule was NOT applied to controls:
## the earliest event in an IIH case is day 183, the earliest in a control is
## day 16, and 14 control events fall in a window where a case is ineligible by
## construction. Comparing the arms over 0-3 years therefore compares a case arm
## with a 180-day blanking period against a control arm without one.
##
## Direction of the bias: controls accrue events cases cannot have, so the
## uncorrected HR is biased TOWARD the null. The fix is to impose the same
## 180-day window on both arms via delayed entry, which is the estimand the
## protocol's own eligibility rule actually defines.
add("Cox, 3 y, symmetric 180-day landmark (CORRECTED PRIMARY)",
    "PROTOCOL-DERIVED", a, 3, landmark = 180 / 365.25,
    note = paste("Both arms enter at day 180. This is the only specification in",
                 "which the outcome-eligibility window is identical in the two",
                 "cohorts, and it is the estimate that should be reported."))
add("Cox, 3 y, no landmark (protocol as written)", "PRE-SPECIFIED", a, 3,
    note = "Asymmetric outcome window; biased toward the null. Retained for comparison.")

## ---- 1. landmark analyses (pre-specified in v1.0, retained) ----------------
for (L in c(0.5, 1, 2)) {
  add(sprintf("Landmark: excluding events before %.0f months", L * 12),
      "PRE-SPECIFIED", a, 3, landmark = L,
      note = "Probes reverse causation and diagnostic-workup detection.")
}

## ---- 2. sex-stratified (pre-specified s5.2) --------------------------------
for (sx in c("F", "M")) {
  add(paste0("Restricted to ", ifelse(sx == "F", "female", "male"), " sets"),
      "PRE-SPECIFIED", a[a$sex == sx, ], 3, landmark = 180 / 365.25,
      note = ifelse(sx == "M", "Male matching used no calendar-year constraint (v2.0 change #6).", ""))
}

## ---- 3. PNES exclusion (pre-specified s5.2) --------------------------------
add("Excluding PNES-coded participants", "PRE-SPECIFIED",
    a[!(a$pnes_ever %in% 1), ], 3, landmark = 180 / 365.25,
    note = "pnes_ever is recorded for controls only; the exclusion is one-sided in this export.")

## ---- 4. stricter outcome definition (pre-specified s5.2) -------------------
## outcome_criterion is populated for CONTROLS ONLY (blank in all 3,601 cases),
## so criterion-1-only cannot be applied symmetrically. Attempting it would
## remove control events while leaving all case events in place, which would
## inflate the HR. Deliberately NOT run.
res[["strict"]] <- data.frame(
  analysis = "Stricter outcome (criterion 1: two codes >=30 d apart, only)",
  status = "PRE-SPECIFIED", n = NA, events = NA,
  estimate = "NOT ESTIMABLE", p = NA,
  note = paste("outcome_criterion is recorded for controls only. Applying it would",
               "drop control events while retaining every case event and would",
               "inflate the hazard ratio by construction. Requires the criterion",
               "flag to be extracted for cases before this analysis can be run."))

## ---- 5. surveillance / healthcare contact ----------------------------------
## Protocol s5.3: reported as a CONSERVATIVE BOUND, never as the primary.
## enc_post is measured after index and is a consequence of both the exposure
## and the outcome; conditioning on it is adjustment for a mediator and can
## push the estimate past the null.
add("Adjusted for post-index encounters (CONSERVATIVE BOUND ONLY)", "PRE-SPECIFIED",
    a, 3, rhs = "iih + log1p(enc_post)", landmark = 180 / 365.25,
    note = "Mediator adjustment. NOT a valid causal estimate; a lower bound on the association.")
q3 <- stats::quantile(a$enc_post[a$iih == 0], 0.75, na.rm = TRUE)
add("Controls restricted to top quartile of post-index encounters", "PRE-SPECIFIED",
    a[which(a$iih == 1 | a$enc_post >= q3), ], 3, landmark = 180 / 365.25,
    note = sprintf("Controls with >= %.0f post-index encounters. Design-stage analogue of the above.", q3))
add("Adjusted for pre-index encounters (legitimate confounder)", "PROTOCOL-DERIVED",
    a, 3, rhs = "iih + log1p(enc_pre12)", landmark = 180 / 365.25,
    note = "enc_pre12 is measured BEFORE index and is a genuine confounder; this adjustment is causally valid.")

## ---- 6. design and model alternatives --------------------------------------
add("Stratified by matched set", "PRE-SPECIFIED", a[a$set_informative, ], 3,
    strat = TRUE, landmark = 180 / 365.25,
    note = "Conditional estimand; matched sets with no event contribute no information.")
aw <- merge(a, ps, by = "record_id")
add("IPTW on the propensity score", "PRE-SPECIFIED", aw, 3, wts = "iptw_trim",
    landmark = 180 / 365.25, note = "Marginal estimand.")
add("Full follow-up (no truncation)", "PRE-SPECIFIED", a, Inf,
    landmark = 180 / 365.25,
    note = "PH violated (p=0.031) and case person-time includes impossible dates. Least reliable.")
add("5-year truncation", "PRE-SPECIFIED", a, 5, landmark = 180 / 365.25)
add("Full-ratio sets only (1:4 complete)", "POST HOC",
    a[a$match_set %in% names(which(table(a$match_set[a$iih == 0]) == 4)), ], 3,
    landmark = 180 / 365.25,
    note = "Tests whether variable-ratio matching distorts the estimate.")
add("Index year >= 2010", "POST HOC", a[a$index_year >= 2010, ], 3,
    landmark = 180 / 365.25,
    note = "Restricts to the period of consistent electronic capture and coding.")

sens <- do.call(rbind, res); rownames(sens) <- NULL
write_tab(sens, "T6_sensitivity_analyses")
print(sens[, c("analysis", "n", "events", "estimate", "p")])

## ---- 7. tipping-point analysis for unrecorded outcomes ---------------------
## Protocol-required. Question: how many censored IIH patients would need an
## unrecorded seizure before the association disappears? This is the direct
## quantitative counterpart to "absence of records is not absence of seizures".
s <- tr(a, 3); s <- s[s$t > 180 / 365.25, ]; s$t0 <- 180 / 365.25
tip <- do.call(rbind, lapply(c(0, 0.01, 0.02, 0.05, 0.10, 0.20), function(frac) {
  set.seed(SEED)
  cens_iih <- which(s$iih == 1 & s$ev == 0)
  k <- round(frac * length(cens_iih))
  ss <- s
  if (k > 0) {
    ## Conservative direction: assume the UNEXPOSED arm has the hidden events,
    ## since the concern is that IIH patients are watched more closely, so it is
    ## the CONTROLS whose seizures would go unrecorded.
    cens_ctl <- which(ss$iih == 0 & ss$ev == 0)
    hit <- sample(cens_ctl, min(round(frac * length(cens_ctl)), length(cens_ctl)))
    ss$ev[hit] <- 1L
    ss$t[hit]  <- ss$t0[hit] + stats::runif(length(hit)) * (ss$t[hit] - ss$t0[hit])
  }
  fit <- survival::coxph(Surv(t0, t, ev) ~ iih, data = ss, cluster = ss$match_set,
                         robust = TRUE)
  sm <- summary(fit)
  data.frame(pct_censored_controls_with_hidden_seizure = 100 * frac,
             hidden_events_added = if (frac > 0) round(frac * length(cens_ctl)) else 0,
             hr = round(sm$conf.int[1, 1], 2), lo = round(sm$conf.int[1, 3], 2),
             hi = round(sm$conf.int[1, 4], 2),
             crosses_null = sm$conf.int[1, 3] < 1)
}))
write_tab(tip, "T6b_tipping_point")
print(tip)

## ---- 8. outcome-misclassification bias analysis ----------------------------
## No validation sample exists (audit H3), so the algorithm's PPV is unknown.
## Rather than assert a PPV, the HR is recomputed under a range of assumed
## NON-DIFFERENTIAL sensitivities, and under DIFFERENTIAL sensitivity favouring
## the exposed (the scenario that surveillance bias would produce).
mis <- do.call(rbind, lapply(list(c(1, 1), c(0.9, 0.9), c(0.8, 0.8),
                                  c(0.9, 0.7), c(0.9, 0.6)), function(z) {
  se_iih <- z[1]; se_ctl <- z[2]
  s2 <- tr(a, 3)
  e1 <- sum(s2$ev[s2$iih == 1]); t1 <- sum(s2$t[s2$iih == 1])
  e0 <- sum(s2$ev[s2$iih == 0]); t0 <- sum(s2$t[s2$iih == 0])
  ## True events = observed / sensitivity, under the stated sensitivities.
  irr <- (e1 / se_iih / t1) / (e0 / se_ctl / t0)
  data.frame(sensitivity_iih = se_iih, sensitivity_control = se_ctl,
             scenario = ifelse(se_iih == se_ctl, "non-differential",
                               "DIFFERENTIAL (favours exposed detection)"),
             corrected_IRR = round(irr, 2))
}))
write_tab(mis, "T6c_outcome_misclassification")
print(mis)

saveRDS(list(sens = sens, tip = tip, mis = mis), file.path(PATH$derived, "08_sens.rds"))
log_msg("08 complete")
