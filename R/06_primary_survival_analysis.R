## 06_primary_survival_analysis.R ---------------------------------------------
## PRIMARY ESTIMAND (protocol v2.0 s5.1)
##   The cause-specific hazard ratio of a first incident coded seizure/epilepsy
##   comparing patients coded as IIH with matched non-IIH patients, over the
##   3 years following the index date, in the population of matchable IIH
##   patients and their matched controls.
##
## Why 3 years and not full follow-up: proportional hazards fails over full
## follow-up (checked below), and case follow-up is both longer and of impossible
## length in 2,087 records (audit C1). Truncation removes the region where the
## denominator is least trustworthy and the PH assumption is violated.
##
## Why cause-specific and not subdistribution as the primary: the question is
## aetiological ("does IIH raise the rate at which seizures occur among those
## still at risk?"), which is the cause-specific estimand. The Fine-Gray
## subdistribution model answers a prognostic question about absolute risk in
## the presence of death and is reported alongside, not instead.

source("R/00_setup.R")
log_msg("=== 06 primary analysis ===")
a <- readRDS(file.path(PATH$derived, "05_analytic.rds"))
truncate_at <- readRDS(file.path(PATH$derived, "05_truncate_fn.rds"))

TAU_PRIMARY <- 3

## ---- 1. incidence rates with exact Poisson CIs -----------------------------
rate_table <- function(dat, tau, label) {
  s <- truncate_at(dat, tau)
  out <- do.call(rbind, lapply(c(0, 1), function(g) {
    ss <- s[s$iih == g, ]
    r <- pois_rate_ci(sum(ss$ev), sum(ss$t))
    data.frame(horizon = label,
               cohort = ifelse(g == 1, "IIH", "Non-IIH control"),
               n = nrow(ss), events = sum(ss$ev), person_years = round(sum(ss$t), 1),
               rate_per_1000py = round(r["rate"], 2),
               lo = round(r["lo"], 2), hi = round(r["hi"], 2))
  }))
  irr <- irr_exact(sum(s$ev[s$iih == 1]), sum(s$t[s$iih == 1]),
                   sum(s$ev[s$iih == 0]), sum(s$t[s$iih == 0]))
  out$irr <- c(NA, round(irr["irr"], 2))
  out$irr_lo <- c(NA, round(irr["lo"], 2)); out$irr_hi <- c(NA, round(irr["hi"], 2))
  out$irr_p <- c(NA, signif(irr["p"], 3))
  out
}
rates <- do.call(rbind, lapply(list(c(3, "3 years (primary)"), c(5, "5 years"),
                                    c(Inf, "full follow-up")),
  function(z) rate_table(a, as.numeric(z[1]), z[2])))
rownames(rates) <- NULL
write_tab(rates, "T3_incidence_rates")
print(rates)

## ---- 2. Cox models ---------------------------------------------------------
## Variance: matched sets are the unit of dependence (a control appears once,
## but controls within a set share a case's index date and matched covariates),
## so every unstratified model uses a robust sandwich variance clustered on
## match_set. The stratified model conditions on the set instead.
fit_cox <- function(dat, tau, formula_rhs, label, strata_set = FALSE,
                    weights = NULL, data_note = "") {
  s <- truncate_at(dat, tau)
  rhs <- if (strata_set) paste(formula_rhs, "+ strata(match_set)") else formula_rhs
  cl  <- if (strata_set) NULL else s$match_set
  f <- stats::as.formula(paste("Surv(t, ev) ~", rhs))
  fit <- if (is.null(weights)) {
    if (strata_set) survival::coxph(f, data = s, ties = "efron")
    else survival::coxph(f, data = s, cluster = cl, robust = TRUE, ties = "efron")
  } else {
    survival::coxph(f, data = s, weights = s[[weights]], cluster = s$match_set,
                    robust = TRUE, ties = "efron")
  }
  sm <- summary(fit)
  i <- 1  # exposure is always the first term
  data.frame(
    model = label, horizon_y = tau,
    n = fit$n, events = fit$nevent,
    hr = round(sm$conf.int[i, 1], 2),
    lo = round(sm$conf.int[i, 3], 2), hi = round(sm$conf.int[i, 4], 2),
    p  = signif(sm$coefficients[i, ncol(sm$coefficients)], 3),
    note = data_note, stringsAsFactors = FALSE)
}

models <- list()
models$primary <- fit_cox(a, 3, "iih", "Cox, 3-y truncated (PRIMARY)", FALSE,
  data_note = "robust SE clustered on match_set")
models$strat3  <- fit_cox(a[a$set_informative, ], 3, "iih",
  "Cox stratified by matched set, 3 y", TRUE,
  data_note = "conditional; sets with no event contribute nothing")
models$y5      <- fit_cox(a, 5, "iih", "Cox, 5-y truncated", FALSE)
models$full    <- fit_cox(a, Inf, "iih", "Cox, full follow-up", FALSE,
  data_note = "PH violated; denominator includes impossible dates -- least reliable")
models$adj     <- fit_cox(a, 3, "iih + age_index + bmi_index + sex",
  "Cox, 3 y, + age/BMI/sex", FALSE,
  data_note = "matched covariates re-adjusted; tests residual imbalance only")

## IPTW (protocol s5.2)
ps <- readRDS(file.path(PATH$derived, "04_ps.rds"))
aw <- merge(a, ps, by = "record_id")
models$iptw <- fit_cox(aw, 3, "iih", "Cox, 3 y, IPTW (stabilised, trimmed)",
  FALSE, weights = "iptw_trim",
  data_note = "marginal estimand over the matched population")

cox_tab <- do.call(rbind, models); rownames(cox_tab) <- NULL
cox_tab$estimate <- fmt_est(cox_tab$hr, cox_tab$lo, cox_tab$hi)
write_tab(cox_tab, "T4a_cox_models")
print(cox_tab[, c("model", "n", "events", "estimate", "p")])

## ---- 3. proportional-hazards diagnostics -----------------------------------
ph <- do.call(rbind, lapply(c(3, 5, Inf), function(tau) {
  s <- truncate_at(a, tau)
  fit <- survival::coxph(Surv(t, ev) ~ iih, data = s, cluster = s$match_set,
                         robust = TRUE)
  z <- survival::cox.zph(fit)
  data.frame(horizon_y = tau, chisq = round(z$table["iih", "chisq"], 2),
             df = z$table["iih", "df"],
             p_ph = signif(z$table["iih", "p"], 3),
             conclusion = ifelse(z$table["iih", "p"] < 0.05,
                                 "PH VIOLATED", "PH not rejected"))
}))
write_tab(ph, "S16_ph_assumption")
print(ph)

grDevices::pdf(file.path(PATH$diag, "schoenfeld_residuals.pdf"), width = 7, height = 5)
for (tau in c(3, 5, Inf)) {
  s <- truncate_at(a, tau)
  z <- survival::cox.zph(survival::coxph(Surv(t, ev) ~ iih, data = s))
  plot(z, main = paste("Schoenfeld residuals, horizon =", tau, "y"))
  graphics::abline(h = 0, lty = 2, col = "grey50")
}
grDevices::dev.off()

## ---- 4. competing risks -----------------------------------------------------
s3 <- truncate_at(a, TAU_PRIMARY)
s3$evf <- factor(s3$evc, levels = 0:2, labels = c("censored", "seizure", "death"))

## Cause-specific hazard for death (the competing event) -- reported because a
## cause-specific HR for the outcome is only interpretable alongside it.
cs_death <- survival::coxph(Surv(t, evc == 2) ~ iih, data = s3,
                            cluster = s3$match_set, robust = TRUE)
sd <- summary(cs_death)

## Fine-Gray subdistribution hazard.
fg_dat <- survival::finegray(Surv(t, evf) ~ ., data = s3, etype = "seizure")
fg <- survival::coxph(Surv(fgstart, fgstop, fgstatus) ~ iih,
                      weights = fgwt, data = fg_dat,
                      cluster = fg_dat$match_set, robust = TRUE)
sf <- summary(fg)

cr_tab <- data.frame(
  estimand = c("Cause-specific HR, seizure (PRIMARY)",
               "Cause-specific HR, death (competing event)",
               "Subdistribution HR, seizure (Fine-Gray)"),
  hr = c(models$primary$hr, round(sd$conf.int[1, 1], 2), round(sf$conf.int[1, 1], 2)),
  lo = c(models$primary$lo, round(sd$conf.int[1, 3], 2), round(sf$conf.int[1, 3], 2)),
  hi = c(models$primary$hi, round(sd$conf.int[1, 4], 2), round(sf$conf.int[1, 4], 2)),
  interpretation = c(
    "Rate of seizure among those still alive and seizure-free -- aetiological question",
    "Whether IIH also changes mortality; if ~1, the two seizure estimands should agree closely",
    "Effect on the cumulative INCIDENCE of seizure with death held in the risk set -- prognostic question"))
cr_tab$estimate <- fmt_est(cr_tab$hr, cr_tab$lo, cr_tab$hi)
write_tab(cr_tab, "T4b_competing_risk")
print(cr_tab[, c("estimand", "estimate")])

## ---- 5. absolute risk (Aalen-Johansen) -------------------------------------
## Cumulative incidence, NOT 1 - Kaplan-Meier: KM would overstate absolute risk
## by treating death as if those patients could still have a seizure.
aj <- survival::survfit(Surv(t, evf) ~ iih, data = s3, id = seq_len(nrow(s3)))
aj_sum <- summary(aj, times = c(1, 2, 3), extend = TRUE)
## pstate is an n_time x n_state matrix; column 2 is the "seizure" state.
k_seizure <- which(aj$states == "seizure")
cif <- data.frame(
  cohort  = ifelse(grepl("iih=1", as.character(aj_sum$strata)), "IIH", "Non-IIH control"),
  time_y  = aj_sum$time,
  cif_pct = round(100 * aj_sum$pstate[, k_seizure], 3),
  se_pct  = round(100 * aj_sum$std.err[, k_seizure], 3),
  lo_pct  = round(100 * aj_sum$lower[, k_seizure], 3),
  hi_pct  = round(100 * aj_sum$upper[, k_seizure], 3))

## Risk difference at 3 years. The CI uses a delta-method combination of the
## two group standard errors; it is approximate and is reported as such.
rd <- local({
  i1 <- which(cif$cohort == "IIH" & cif$time_y == 3)
  i0 <- which(cif$cohort == "Non-IIH control" & cif$time_y == 3)
  assert(length(i1) == 1 && length(i0) == 1, "could not locate 3-year CIF rows")
  est <- cif$cif_pct[i1] - cif$cif_pct[i0]
  se  <- sqrt(cif$se_pct[i1]^2 + cif$se_pct[i0]^2)
  data.frame(measure = "3-year absolute risk difference (percentage points)",
             iih_risk_pct = cif$cif_pct[i1], control_risk_pct = cif$cif_pct[i0],
             estimate = round(est, 2), lo = round(est - 1.96 * se, 2),
             hi = round(est + 1.96 * se, 2),
             number_needed_to_harm = round(100 / est, 0))
})
write_tab(cif, "T4c_cumulative_incidence")
write_tab(rd,  "T4d_risk_difference")
print(rd)

## ---- 6. E-value ------------------------------------------------------------
ev <- evalue_hr(models$primary$hr, models$primary$lo, models$primary$hi)
eval_tab <- data.frame(
  quantity = c("E-value, point estimate", "E-value, CI limit nearest the null"),
  value = round(ev, 2),
  plain_language = c(
    sprintf(paste0("An unmeasured confounder would have to be associated with BOTH IIH ",
                   "status AND seizure by a risk ratio of at least %.2f each, above and ",
                   "beyond age, sex and BMI, to explain away the observed HR."), ev[1]),
    sprintf(paste0("To move the confidence interval to include the null, such a ",
                   "confounder would need associations of at least %.2f each."), ev[2])))
write_tab(eval_tab, "T4e_evalue")

saveRDS(list(models = cox_tab, ph = ph, cr = cr_tab, cif = cif, rd = rd,
             rates = rates, evalue = eval_tab, s3 = s3, aj = aj),
        file.path(PATH$derived, "06_primary.rds"))
log_msg("06 complete")
