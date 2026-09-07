## F2_analysis_final.R --------------------------------------------------------
## All inferential statistics on the FINAL workbook.
##
## PRIMARY ESTIMAND
##   Cause-specific hazard ratio of a first incident coded seizure/epilepsy,
##   from day 180 to 3 years after index, comparing patients coded as IIH with
##   matched non-IIH patients, in the population of matchable IIH patients and
##   their matched controls.
##
##   Cause-specific because the question is aetiological. Fine-Gray is reported
##   alongside because it answers a different, prognostic question.
##   3 years because that is where proportional hazards holds (checked below).
##   t_y already starts at day 180, so Surv(t, ev) needs no delayed entry.

source("R/00_setup.R")
log_msg("=== F2 analysis (FINAL) ===")
d <- readRDS(file.path(PATH$derived, "F1_typed.rds"))
TAU <- 3

## Truncate at tau years of post-washout time.
cut_at <- function(dat, tau) {
  dat$t  <- pmin(dat$t_y, tau)
  dat$ev <- ifelse(dat$t_y > tau, 0L, as.integer(dat$event))
  dat$evc <- ifelse(dat$t_y > tau, 0L,
                    ifelse(dat$event == 1, 1L, ifelse(dat$died == 1, 2L, 0L)))
  dat
}
a <- d

## ---- 0. events available per horizon (drives how many parameters) ----------
horiz <- do.call(rbind, lapply(c(1, 2, 3, 5, Inf), function(tau) {
  s <- cut_at(a, tau)
  data.frame(horizon_y = tau,
             events_iih = sum(s$ev[s$iih == 1]), events_ctl = sum(s$ev[s$iih == 0]),
             py_iih = round(sum(s$t[s$iih == 1])), py_ctl = round(sum(s$t[s$iih == 0])),
             deaths = sum(s$evc == 2),
             max_parameters = floor(min(sum(s$ev[s$iih == 1]),
                                        sum(s$ev[s$iih == 0])) / 10))
}))
write_tab(horiz, "F_S5_events_by_horizon")
print(horiz)

## ---- 1. incidence rates, exact Poisson CIs, exact IRR ----------------------
rate_block <- function(tau, label) {
  s <- cut_at(a, tau)
  out <- do.call(rbind, lapply(c(0, 1), function(g) {
    ss <- s[s$iih == g, ]; r <- pois_rate_ci(sum(ss$ev), sum(ss$t))
    data.frame(horizon = label, cohort = ifelse(g == 1, "IIH", "Non-IIH control"),
               n = nrow(ss), events = sum(ss$ev), person_years = round(sum(ss$t), 1),
               rate_per_1000py = round(r[["rate"]], 2),
               rate_lo = round(r[["lo"]], 2), rate_hi = round(r[["hi"]], 2))
  }))
  irr <- irr_exact(sum(s$ev[s$iih == 1]), sum(s$t[s$iih == 1]),
                   sum(s$ev[s$iih == 0]), sum(s$t[s$iih == 0]))
  out$irr <- c(NA, round(irr[["irr"]], 2))
  out$irr_lo <- c(NA, round(irr[["lo"]], 2)); out$irr_hi <- c(NA, round(irr[["hi"]], 2))
  out$irr_p <- c(NA, signif(irr[["p"]], 3))
  out
}
rates <- do.call(rbind, list(rate_block(3, "3 years (primary)"),
                             rate_block(5, "5 years"),
                             rate_block(Inf, "full follow-up")))
rownames(rates) <- NULL
write_tab(rates, "F_T3_incidence_rates")
print(rates[, c("horizon", "cohort", "events", "person_years", "rate_per_1000py",
                "rate_lo", "rate_hi", "irr", "irr_lo", "irr_hi")])

## ---- 2. Cox models ---------------------------------------------------------
## Variance: matched sets are the unit of dependence, so unstratified models use
## a robust sandwich clustered on match_set. Matching is variable-ratio (mean
## 3.48 controls per case), so a fixed-ratio assumption would be wrong.
fit_cox <- function(dat, tau, rhs, label, strat = FALSE, wts = NULL, note = "") {
  s <- cut_at(dat, tau)
  f <- stats::as.formula(paste("Surv(t, ev) ~", rhs,
                               if (strat) "+ strata(match_set)" else ""))
  fit <- if (strat) survival::coxph(f, data = s, ties = "efron")
         else if (!is.null(wts)) survival::coxph(f, data = s, weights = s[[wts]],
                                cluster = s$match_set, robust = TRUE, ties = "efron")
         else survival::coxph(f, data = s, cluster = s$match_set, robust = TRUE,
                              ties = "efron")
  sm <- summary(fit)
  data.frame(model = label, horizon_y = tau, n = fit$n, events = fit$nevent,
             hr = round(sm$conf.int[1, 1], 2), lo = round(sm$conf.int[1, 3], 2),
             hi = round(sm$conf.int[1, 4], 2),
             p = signif(sm$coefficients[1, ncol(sm$coefficients)], 3),
             note = note, stringsAsFactors = FALSE)
}

## Propensity score on the matched covariates, for IPTW and as a balance check.
ps_dat <- a[stats::complete.cases(a[, c("age_index", "bmi_index", "sex", "index_year")]), ]
ps_fit <- stats::glm(iih ~ age_index + bmi_index + sex + index_year,
                     family = stats::binomial, data = ps_dat)
ps_dat$ps <- stats::fitted(ps_fit)
cstat <- { r <- rank(ps_dat$ps); n1 <- sum(ps_dat$iih == 1); n0 <- sum(ps_dat$iih == 0)
           (sum(r[ps_dat$iih == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
pm <- mean(ps_dat$iih)
ps_dat$iptw <- ifelse(ps_dat$iih == 1, pm / ps_dat$ps, (1 - pm) / (1 - ps_dat$ps))
qq <- stats::quantile(ps_dat$iptw, c(.01, .99))
ps_dat$iptw_trim <- pmin(pmax(ps_dat$iptw, qq[1]), qq[2])
log_msg("propensity c-statistic = ", sprintf("%.3f", cstat))

models <- rbind(
  fit_cox(a, 3, "iih", "Cox, 3-year (PRIMARY)", note = "robust SE clustered on match_set"),
  fit_cox(a, 3, "iih", "Cox stratified by matched set, 3 y", strat = TRUE,
          note = "conditional estimand"),
  fit_cox(ps_dat, 3, "iih", "Cox, 3 y, IPTW (stabilised, trimmed)", wts = "iptw_trim",
          note = "marginal estimand"),
  fit_cox(a, 3, "iih + age_index + bmi_index + sex", "Cox, 3 y, + age/BMI/sex",
          note = "re-adjusts matched covariates; tests residual imbalance only"),
  fit_cox(a, 5, "iih", "Cox, 5-year"),
  fit_cox(a, Inf, "iih", "Cox, full follow-up", note = "check PH before quoting"))
models$estimate <- fmt_est(models$hr, models$lo, models$hi)
write_tab(models, "F_T4a_cox_models")
print(models[, c("model", "n", "events", "estimate", "p")])

## ---- 3. proportional hazards ------------------------------------------------
ph <- do.call(rbind, lapply(c(3, 5, Inf), function(tau) {
  s <- cut_at(a, tau)
  z <- survival::cox.zph(survival::coxph(Surv(t, ev) ~ iih, data = s))
  data.frame(horizon_y = tau, chisq = round(z$table["iih", "chisq"], 2),
             df = z$table["iih", "df"], p_ph = signif(z$table["iih", "p"], 3),
             conclusion = ifelse(z$table["iih", "p"] < 0.05, "PH VIOLATED",
                                 "PH not rejected"))
}))
write_tab(ph, "F_S6_ph_assumption")
print(ph)

grDevices::pdf(file.path(PATH$diag, "F_schoenfeld.pdf"), width = 7, height = 5)
for (tau in c(3, 5, Inf)) {
  s <- cut_at(a, tau)
  plot(survival::cox.zph(survival::coxph(Surv(t, ev) ~ iih, data = s)),
       main = paste("Schoenfeld residuals, horizon", tau, "y"))
  graphics::abline(h = 0, lty = 2, col = "grey50")
}
grDevices::dev.off()

## ---- 4. competing risks -----------------------------------------------------
s3 <- cut_at(a, TAU)
s3$evf <- factor(s3$evc, levels = 0:2, labels = c("censored", "seizure", "death"))
cs_d <- survival::coxph(Surv(t, evc == 2) ~ iih, data = s3, cluster = s3$match_set,
                        robust = TRUE)
fgd <- survival::finegray(Surv(t, evf) ~ ., data = s3, etype = "seizure")
fg  <- survival::coxph(Surv(fgstart, fgstop, fgstatus) ~ iih, weights = fgwt,
                       data = fgd, cluster = fgd$match_set, robust = TRUE)
sdm <- summary(cs_d); sfg <- summary(fg)
cr <- data.frame(
  estimand = c("Cause-specific HR, seizure (PRIMARY)",
               "Cause-specific HR, death (competing event)",
               "Subdistribution HR, seizure (Fine-Gray)"),
  hr = c(models$hr[1], round(sdm$conf.int[1, 1], 2), round(sfg$conf.int[1, 1], 2)),
  lo = c(models$lo[1], round(sdm$conf.int[1, 3], 2), round(sfg$conf.int[1, 3], 2)),
  hi = c(models$hi[1], round(sdm$conf.int[1, 4], 2), round(sfg$conf.int[1, 4], 2)),
  interpretation = c(
    "Rate of seizure among those still alive and seizure-free -- aetiological",
    "Whether IIH also alters mortality; interpret the seizure estimands against it",
    "Effect on cumulative INCIDENCE with death retained in the risk set -- prognostic"))
cr$estimate <- fmt_est(cr$hr, cr$lo, cr$hi)
write_tab(cr, "F_T4b_competing_risk")
print(cr[, c("estimand", "estimate")])

## ---- 5. absolute risk (Aalen-Johansen), NOT 1 - Kaplan-Meier ---------------
aj <- survival::survfit(Surv(t, evf) ~ iih, data = s3, id = seq_len(nrow(s3)))
k  <- which(aj$states == "seizure")
sm <- summary(aj, times = c(1, 2, 3), extend = TRUE)
cif <- data.frame(
  cohort = ifelse(grepl("iih=1", as.character(sm$strata)), "IIH", "Non-IIH control"),
  time_y = sm$time,
  cif_pct = round(100 * sm$pstate[, k], 3), se_pct = round(100 * sm$std.err[, k], 3),
  lo_pct = round(100 * sm$lower[, k], 3), hi_pct = round(100 * sm$upper[, k], 3))
write_tab(cif, "F_T4c_cumulative_incidence")

rd <- local({
  i1 <- which(cif$cohort == "IIH" & cif$time_y == 3)
  i0 <- which(cif$cohort == "Non-IIH control" & cif$time_y == 3)
  est <- cif$cif_pct[i1] - cif$cif_pct[i0]
  se <- sqrt(cif$se_pct[i1]^2 + cif$se_pct[i0]^2)
  data.frame(measure = "3-year absolute risk difference (percentage points)",
             iih_risk_pct = cif$cif_pct[i1], control_risk_pct = cif$cif_pct[i0],
             estimate = round(est, 2), lo = round(est - 1.96 * se, 2),
             hi = round(est + 1.96 * se, 2),
             number_needed_to_harm = round(100 / est))
})
write_tab(rd, "F_T4d_risk_difference")
print(rd)

## ---- 6. E-value -------------------------------------------------------------
ev <- evalue_hr(models$hr[1], models$lo[1], models$hi[1])
eval_tab <- data.frame(
  quantity = c("E-value, point estimate", "E-value, CI limit nearest the null"),
  value = round(ev, 2),
  plain_language = c(
    sprintf("An unmeasured confounder would need to be associated with BOTH IIH and seizure by a risk ratio of at least %.2f each, beyond age, sex and BMI, to explain the estimate away.", ev[[1]]),
    sprintf("To pull the confidence interval to the null it would need associations of at least %.2f each.", ev[[2]])))
write_tab(eval_tab, "F_T4e_evalue")

## ---- 7. negative control outcome -------------------------------------------
## Carpal tunnel has no plausible causal link to IIH. If the design were merely
## measuring healthcare contact, it would be elevated too. Female pairs only:
## the outcome was not extracted for male controls.
nc_dat <- a[!is.na(a$carpal_incident) & a$sex == "F", ]
nc_dat$event <- nc_dat$carpal_incident
neg <- rbind(
  cbind(outcome = "Incident seizure/epilepsy (positive outcome)",
        fit_cox(a[a$sex == "F", ], 3, "iih", "3-year")[, c("n", "events", "hr", "lo", "hi", "p")]),
  cbind(outcome = "Incident carpal tunnel syndrome (NEGATIVE CONTROL)",
        fit_cox(nc_dat, 3, "iih", "3-year")[, c("n", "events", "hr", "lo", "hi", "p")]))
neg$estimate <- fmt_est(neg$hr, neg$lo, neg$hi); neg$p <- fmt_p(neg$p)
neg$verdict <- c("Elevated, as hypothesised",
  ifelse(neg$lo[2] < 1 & neg$hi[2] > 1,
    "NULL, as required. Healthcare contact alone does not produce an elevated hazard here, which materially strengthens the primary result.",
    "NOT null -- the design is measuring contact, not disease. Treat the primary estimate as confounded by ascertainment."))
write_tab(neg, "F_T5a_negative_control")
print(neg[, c("outcome", "n", "events", "estimate", "p")])

## ---- 7b. negative control: every specification, settled ---------------------
## carpal_incident carries NO event date, only a binary flag, so a Cox model
## necessarily places the event at the seizure-based censoring time. The exact
## Poisson incidence-rate ratio needs no date and is the cleaner estimate; both
## are reported and they agree.
##
## Two restrictions matter and they turn out to be the SAME restriction:
## carpal status is missing for all 1,294 male controls but present for all 345
## male cases, so "female sets only" is identical to "sets where both arms are
## covered". Including men keeps case-only sets and drags the estimate upward.
nc_row <- function(dat, label, strat = FALSE) {
  s <- cut_at(dat, TAU); s$ev <- ifelse(s$t_y > TAU, 0L, as.integer(s$carpal_incident))
  s <- s[!is.na(s$ev), ]
  e1 <- sum(s$ev[s$iih == 1]); e0 <- sum(s$ev[s$iih == 0])
  t1 <- sum(s$t[s$iih == 1]);  t0 <- sum(s$t[s$iih == 0])
  ir <- if (e1 > 0 && e0 > 0) irr_exact(e1, t1, e0, t0) else c(irr=NA, lo=NA, hi=NA, p=NA)
  f <- stats::as.formula(if (strat) "Surv(t, ev) ~ iih + strata(match_set)"
                         else "Surv(t, ev) ~ iih")
  fit <- try(if (strat) survival::coxph(f, data = s)
             else survival::coxph(f, data = s, cluster = s$match_set, robust = TRUE),
             silent = TRUE)
  hr <- if (inherits(fit, "try-error") || !is.finite(stats::coef(fit)[1])) rep(NA, 4) else {
    sm <- summary(fit); c(sm$conf.int[1,1], sm$conf.int[1,3], sm$conf.int[1,4],
                          sm$coefficients[1, ncol(sm$coefficients)]) }
  data.frame(analysis = label, model = ifelse(strat, "Cox stratified", "Cox robust"),
             n = nrow(s), events_iih = e1, events_control = e0,
             IRR_exact_poisson = ifelse(is.na(ir[["irr"]]), NA,
                                        fmt_est(ir[["irr"]], ir[["lo"]], ir[["hi"]])),
             HR = ifelse(is.na(hr[1]), "not estimable", fmt_est(hr[1], hr[2], hr[3])),
             p = fmt_p(hr[4]), stringsAsFactors = FALSE)
}
ok_sets <- intersect(a$match_set[a$iih == 1 & !is.na(a$carpal_incident)],
                     unique(a$match_set[a$iih == 0 & !is.na(a$carpal_incident)]))
both_cov <- a[a$match_set %in% ok_sets & !is.na(a$carpal_incident), ]
nc_settled <- rbind(
  nc_row(a[a$sex == "F", ], "A. Female sets only (PRIMARY)"),
  nc_row(a[a$sex == "F", ], "A. Female sets only (PRIMARY)", strat = TRUE),
  nc_row(a, "B. All sexes, complete-case (keeps 345 case-only males)"),
  nc_row(a, "B. All sexes, complete-case (keeps 345 case-only males)", strat = TRUE),
  nc_row(both_cov, "C. Sets with BOTH arms covered"),
  nc_row(both_cov, "C. Sets with BOTH arms covered", strat = TRUE))
write_tab(nc_settled, "F_T5a2_negative_control_settled")
print(nc_settled)

## Horizon dependence. The 3-year estimates agree with each other and are null.
## At full follow-up the robust and stratified models point in OPPOSITE
## directions (1.45 vs 0.61), which is a signal that the estimate is unstable
## once the known follow-up asymmetry (case median 4.9 y vs control 3.8 y) is
## allowed to act -- not evidence of a carpal tunnel effect.
nc_h <- do.call(rbind, lapply(c(3, 5, Inf), function(tau) {
  do.call(rbind, lapply(c(FALSE, TRUE), function(st) {
    s <- a[a$sex == "F", ]; s$t <- pmin(s$t_y, tau)
    s$ev <- ifelse(s$t_y > tau, 0L, as.integer(s$carpal_incident)); s <- s[!is.na(s$ev), ]
    f <- stats::as.formula(if (st) "Surv(t, ev) ~ iih + strata(match_set)" else "Surv(t, ev) ~ iih")
    fit <- try(if (st) survival::coxph(f, data = s)
               else survival::coxph(f, data = s, cluster = s$match_set, robust = TRUE), silent = TRUE)
    if (inherits(fit, "try-error")) return(NULL)
    sm <- summary(fit)
    data.frame(horizon_y = tau, model = ifelse(st, "stratified", "robust"),
               events = fit$nevent,
               estimate = fmt_est(sm$conf.int[1,1], sm$conf.int[1,3], sm$conf.int[1,4]))
  }))
}))
write_tab(nc_h, "F_T5a3_negative_control_by_horizon")
print(nc_h)

## ---- 8. timing of risk ------------------------------------------------------
sp <- survival::survSplit(Surv(t, ev) ~ ., data = cut_at(a, Inf), cut = c(2, 5),
                          episode = "period")
sp$period <- factor(sp$period, labels = c("0.5-2 y", "2-5 y", ">5 y"))
tsplit <- do.call(rbind, lapply(levels(sp$period), function(p) {
  ss <- sp[sp$period == p, ]
  fit <- survival::coxph(Surv(tstart, t, ev) ~ iih, data = ss, cluster = ss$match_set,
                         robust = TRUE)
  sm2 <- summary(fit)
  data.frame(period = p, events = fit$nevent, hr = round(sm2$conf.int[1, 1], 2),
             lo = round(sm2$conf.int[1, 3], 2), hi = round(sm2$conf.int[1, 4], 2),
             p = signif(sm2$coefficients[1, ncol(sm2$coefficients)], 3))
}))
tsplit$estimate <- fmt_est(tsplit$hr, tsplit$lo, tsplit$hi)
write_tab(tsplit, "F_T5b_time_split")
print(tsplit[, c("period", "events", "estimate")])

## ---- 9. balance -------------------------------------------------------------
bal_rows <- list()
addc <- function(v, lab) { x <- a[[v]]; g <- a$iih
  bal_rows[[lab]] <<- data.frame(variable = lab, type = "continuous",
    iih = sprintf("%.1f (%.1f)", mean(x[g==1], na.rm=TRUE), stats::sd(x[g==1], na.rm=TRUE)),
    control = sprintf("%.1f (%.1f)", mean(x[g==0], na.rm=TRUE), stats::sd(x[g==0], na.rm=TRUE)),
    smd = round(smd_cont(x, g), 3)) }
addb <- function(v, lab, pos = 1) { x <- as.numeric(a[[v]] == pos); g <- a$iih
  bal_rows[[lab]] <<- data.frame(variable = lab, type = "binary",
    iih = sprintf("%d (%.1f%%)", sum(x[g==1], na.rm=TRUE), 100*mean(x[g==1], na.rm=TRUE)),
    control = sprintf("%d (%.1f%%)", sum(x[g==0], na.rm=TRUE), 100*mean(x[g==0], na.rm=TRUE)),
    smd = round(smd_bin(x, g), 3)) }
addc("age_index", "Age at index, y"); addc("bmi_index", "BMI, kg/m2")
addb("sex", "Female", "F"); addc("index_year", "Index year")
addb("osa", "Obstructive sleep apnoea"); addb("htn", "Hypertension"); addb("pcos", "PCOS")
addc("enc_pre12", "Encounters, 12 mo pre-index")
addc("enc_post", "Encounters post-index (POST-EXPOSURE)")
addc("t_y", "Post-washout follow-up, y (POST-EXPOSURE)")
bal <- do.call(rbind, bal_rows); rownames(bal) <- NULL
bal$balance <- ifelse(abs(bal$smd) < 0.1, "balanced (|SMD|<0.1)", "IMBALANCED")
bal$note <- ifelse(grepl("POST-EXPOSURE", bal$variable),
                   "post-index; not a matching target; imbalance expected", "")
write_tab(bal, "F_T1_baseline_balance")
print(bal[, c("variable", "iih", "control", "smd", "balance")])

## ---- 10. subgroups, tested by interaction -----------------------------------
a$grp_sex <- ifelse(a$sex == "F", "Female", "Male")
a$grp_age <- ifelse(a$age_index < 35, "Age <35 y", "Age >=35 y")
a$grp_bmi <- ifelse(a$bmi_index < 35, "BMI <35", "BMI >=35")
a$grp_era <- ifelse(a$index_year < 2015, "Index <2015", "Index >=2015")
mp <- stats::median(a$enc_pre12, na.rm = TRUE)
a$grp_surv <- ifelse(a$enc_pre12 < mp, sprintf("Pre-index enc <%g", mp),
                     sprintf("Pre-index enc >=%g", mp))
sg_row <- function(dat, lab) {
  s <- cut_at(dat, TAU)
  if (sum(s$ev) < 8 || length(unique(s$iih)) < 2)
    return(data.frame(subgroup = lab, n = nrow(s), events = sum(s$ev),
                      hr = NA, lo = NA, hi = NA))
  fit <- try(survival::coxph(Surv(t, ev) ~ iih, data = s, cluster = s$match_set,
                             robust = TRUE), silent = TRUE)
  if (inherits(fit, "try-error") || !is.finite(stats::coef(fit)[1]))
    return(data.frame(subgroup = lab, n = nrow(s), events = sum(s$ev),
                      hr = NA, lo = NA, hi = NA))
  sm2 <- summary(fit)
  data.frame(subgroup = lab, n = fit$n, events = fit$nevent,
             hr = sm2$conf.int[1, 1], lo = sm2$conf.int[1, 3], hi = sm2$conf.int[1, 4])
}
int_p <- function(v) {
  s <- cut_at(a, TAU); s$mod <- factor(s[[v]])
  fit <- try(survival::coxph(Surv(t, ev) ~ iih * mod, data = s,
                             cluster = s$match_set, robust = TRUE), silent = TRUE)
  if (inherits(fit, "try-error")) return(NA_real_)
  b <- stats::coef(fit); kk <- grep("^iih:", names(b))
  if (!length(kk) || any(!is.finite(b[kk]))) return(NA_real_)
  V <- fit$var[kk, kk, drop = FALSE]
  if (abs(det(V)) < 1e-12) return(NA_real_)
  signif(stats::pchisq(as.numeric(t(b[kk]) %*% solve(V) %*% b[kk]),
                       df = length(kk), lower.tail = FALSE), 3)
}
sgv <- c(grp_sex = "Sex", grp_age = "Age at index", grp_bmi = "BMI at index",
         grp_era = "Calendar period", grp_surv = "Baseline surveillance")
sub <- do.call(rbind, lapply(names(sgv), function(v) {
  lv <- sort(unique(stats::na.omit(a[[v]])))
  r <- do.call(rbind, lapply(lv, function(l) sg_row(a[which(a[[v]] == l), ], l)))
  r$modifier <- sgv[[v]]; r$interaction_p <- c(int_p(v), rep(NA, nrow(r) - 1)); r
}))
ov <- sg_row(a, "Overall"); ov$modifier <- "Overall"; ov$interaction_p <- NA
sub <- rbind(ov, sub)
sub$estimate <- ifelse(is.na(sub$hr), "not estimated", fmt_est(sub$hr, sub$lo, sub$hi))
write_tab(sub[, c("modifier", "subgroup", "n", "events", "estimate", "interaction_p")],
          "F_T8_subgroup_interactions")
print(sub[, c("modifier", "subgroup", "events", "estimate", "interaction_p")])

## ---- 11. sensitivity analyses ----------------------------------------------
res <- list()
addS <- function(lab, status, dat, tau = TAU, rhs = "iih", strat = FALSE,
                 wts = NULL, note = "") {
  s <- cut_at(dat, tau)
  if (sum(s$ev) < 8) { res[[lab]] <<- data.frame(analysis = lab, status = status,
      n = nrow(s), events = sum(s$ev), estimate = "too few events", p = NA, note = note)
    return(invisible()) }
  f <- stats::as.formula(paste("Surv(t, ev) ~", rhs, if (strat) "+ strata(match_set)" else ""))
  fit <- try(if (strat) survival::coxph(f, data = s)
             else if (!is.null(wts)) survival::coxph(f, data = s, weights = s[[wts]],
                          cluster = s$match_set, robust = TRUE)
             else survival::coxph(f, data = s, cluster = s$match_set, robust = TRUE),
             silent = TRUE)
  if (inherits(fit, "try-error") || !is.finite(stats::coef(fit)[1])) {
    res[[lab]] <<- data.frame(analysis = lab, status = status, n = nrow(s),
      events = sum(s$ev), estimate = "did not converge", p = NA, note = note)
    return(invisible()) }
  sm2 <- summary(fit)
  res[[lab]] <<- data.frame(analysis = lab, status = status, n = fit$n,
    events = fit$nevent,
    estimate = fmt_est(sm2$conf.int[1,1], sm2$conf.int[1,3], sm2$conf.int[1,4]),
    p = fmt_p(sm2$coefficients[1, ncol(sm2$coefficients)]), note = note)
}
addS("Primary: Cox, 3-year", "PRE-SPECIFIED", a)
for (L in c(1, 2)) {
  la <- a[a$t_y > L, ]; la$t_y <- la$t_y - L
  addS(sprintf("Landmark: further %g year(s) after washout", L), "PRE-SPECIFIED", la,
       note = "Probes reverse causation and work-up detection.")
}
addS("Female sets only", "PRE-SPECIFIED", a[a$sex == "F", ])
addS("Male sets only", "PRE-SPECIFIED", a[a$sex == "M", ],
     note = "Male matching used no calendar-year constraint (protocol v2.0 change #6).")
addS("Stratified by matched set", "PRE-SPECIFIED", a, strat = TRUE)
addS("IPTW on propensity score", "PRE-SPECIFIED", ps_dat, wts = "iptw_trim")
addS("Adjusted for pre-index encounters (valid confounder)", "PROTOCOL-DERIVED", a,
     rhs = "iih + log1p(enc_pre12)")
addS("Adjusted for post-index encounters (CONSERVATIVE BOUND ONLY)", "PRE-SPECIFIED", a,
     rhs = "iih + log1p(enc_post)",
     note = "Mediator adjustment; NOT a causal estimate. A lower bound only.")
q3 <- stats::quantile(a$enc_post[a$iih == 0], 0.75, na.rm = TRUE)
addS("Controls restricted to top quartile of post-index encounters", "PRE-SPECIFIED",
     a[which(a$iih == 1 | a$enc_post >= q3), ])
addS("Full 1:4 sets only", "POST HOC",
     a[a$match_set %in% names(which(table(a$match_set[a$iih == 0]) == 4)), ])
addS("Index year >= 2010", "POST HOC", a[a$index_year >= 2010, ])
addS("5-year horizon", "PRE-SPECIFIED", a, tau = 5)
addS("Full follow-up", "PRE-SPECIFIED", a, tau = Inf, note = "Check PH first.")
sens <- do.call(rbind, res); rownames(sens) <- NULL
write_tab(sens, "F_T6_sensitivity_analyses")
print(sens[, c("analysis", "n", "events", "estimate", "p")])

## ---- 12. tipping point ------------------------------------------------------
## How much unrecorded seizure among censored CONTROLS would erase the result?
## Events are added only to controls, which is the worst case by construction.
base <- cut_at(a, TAU)
tip <- do.call(rbind, lapply(c(0, 0.005, 0.01, 0.02, 0.05, 0.10), function(fr) {
  set.seed(SEED)
  ss <- base; cc <- which(ss$iih == 0 & ss$ev == 0)
  k <- round(fr * length(cc))
  if (k > 0) { hit <- sample(cc, k); ss$ev[hit] <- 1L
               ss$t[hit] <- stats::runif(k) * ss$t[hit] }
  fit <- survival::coxph(Surv(t, ev) ~ iih, data = ss, cluster = ss$match_set,
                         robust = TRUE)
  sm2 <- summary(fit)
  data.frame(pct_censored_controls_with_hidden_seizure = 100 * fr,
             hidden_events_added = k, hr = round(sm2$conf.int[1,1], 2),
             lo = round(sm2$conf.int[1,3], 2), hi = round(sm2$conf.int[1,4], 2),
             crosses_null = sm2$conf.int[1,3] < 1)
}))
write_tab(tip, "F_T6b_tipping_point")
print(tip)

## ---- 13. outcome misclassification -----------------------------------------
mis <- do.call(rbind, lapply(list(c(1,1), c(.9,.9), c(.8,.8), c(.9,.7), c(.9,.6)),
  function(z) {
    s <- cut_at(a, TAU)
    e1 <- sum(s$ev[s$iih==1]); t1 <- sum(s$t[s$iih==1])
    e0 <- sum(s$ev[s$iih==0]); t0 <- sum(s$t[s$iih==0])
    data.frame(sensitivity_iih = z[1], sensitivity_control = z[2],
               scenario = ifelse(z[1] == z[2], "non-differential",
                                 "DIFFERENTIAL (favours exposed detection)"),
               corrected_IRR = round((e1/z[1]/t1) / (e0/z[2]/t0), 2))
  }))
write_tab(mis, "F_T6c_outcome_misclassification")
print(mis)

## ---- 14. restricted mean time lost to seizure -------------------------------
rmtl <- function(dat) {
  s <- dat; s$evf <- factor(s$evc, levels = 0:2,
                            labels = c("censored", "seizure", "death"))
  f <- survival::survfit(Surv(t, evf) ~ iih, data = s, id = seq_len(nrow(s)))
  g <- seq(0, TAU, by = 0.01); sm2 <- summary(f, times = g, extend = TRUE)
  kk <- which(f$states == "seizure"); st <- as.character(sm2$strata)
  vapply(c("iih=0", "iih=1"), function(z) {
    y <- sm2$pstate[st == z, kk]
    sum((utils::head(y, -1) + utils::tail(y, -1)) / 2 * diff(g))
  }, numeric(1))
}
obs <- rmtl(s3)
set.seed(SEED)
sets <- unique(s3$match_set); idx <- split(seq_len(nrow(s3)), s3$match_set)
boot <- vapply(seq_len(400), function(b) {
  pick <- sample(sets, length(sets), replace = TRUE)
  d2 <- s3[unlist(idx[pick], use.names = FALSE), ]
  d2$match_set <- rep(seq_along(pick), lengths(idx[pick]))
  o <- try(rmtl(d2), silent = TRUE)
  if (inherits(o, "try-error") || length(o) != 2) return(c(NA, NA, NA))
  c(o, o[2] - o[1])
}, numeric(3))
rm_tab <- data.frame(
  quantity = c("Non-IIH control", "IIH", "Difference (IIH - control)"),
  days_lost_over_3y = round(c(obs[1], obs[2], obs[2] - obs[1]) * 365.25, 2),
  lo = round(apply(boot, 1, stats::quantile, .025, na.rm = TRUE) * 365.25, 2),
  hi = round(apply(boot, 1, stats::quantile, .975, na.rm = TRUE) * 365.25, 2))
rm_tab$estimate <- fmt_est(rm_tab$days_lost_over_3y, rm_tab$lo, rm_tab$hi)
write_tab(rm_tab, "F_T9_restricted_mean_time_lost")
print(rm_tab[, c("quantity", "estimate")])

## ---- 15. within-IIH exploratory --------------------------------------------
iih <- a[a$iih == 1, ]
iih$surg <- factor(ifelse(iih$shunt == 1 | iih$stent == 1, "Surgical", "No procedure"),
                   levels = c("No procedure", "Surgical"))
sv <- cut_at(iih, TAU)
f_surg <- survival::coxph(Surv(t, ev) ~ surg, data = sv)
f_op <- survival::coxph(Surv(t, ev) ~ op_cmh2o, data = cut_at(iih[!is.na(iih$op_cmh2o), ], TAU))
ss1 <- summary(f_surg); ss2 <- summary(f_op)
expl <- data.frame(
  analysis = c("Surgical (shunt/stent) vs none, within IIH",
               "Opening pressure, per 10 cmH2O, within IIH"),
  n = c(f_surg$n, f_op$n), events = c(f_surg$nevent, f_op$nevent),
  estimate = c(fmt_est(ss1$conf.int[1,1], ss1$conf.int[1,3], ss1$conf.int[1,4]),
               fmt_est(ss2$conf.int[1,1]^10, ss2$conf.int[1,3]^10, ss2$conf.int[1,4]^10)),
  p = fmt_p(c(ss1$coefficients[1,5], ss2$coefficients[1,5])),
  status = "POST HOC EXPLORATORY",
  caveat = c(paste("Shunt/stent is a POST-INDEX decision taken while the outcome accrues.",
                   "It creates immortal time and conditions on a post-exposure variable.",
                   "No causal reading is available."),
             paste("Recorded in", f_op$n, "of", nrow(iih), "cases;",
                   sum(iih$op_cmh2o < 25, na.rm = TRUE),
                   "measured values fall below the 25 cmH2O diagnostic threshold, so this",
                   "variable indexes diagnostic accuracy as well as severity.",
                   "Splines were not fitted: too few events to place knots.")))
write_tab(expl, "F_T5d_exploratory_within_iih")

## Encephalocele: descriptive only. Suspended aim (protocol v2.0 change #8).
enc <- data.frame(
  encephalocele_status = c("Present", "Absent", "Not assessable (88)",
                           "Unknown after search (99)", "Not extracted"),
  n = c(sum(iih$enceph_index == 1, na.rm = TRUE), sum(iih$enceph_index == 0, na.rm = TRUE),
        sum(iih$enceph_index_status == "not_assessable"),
        sum(iih$enceph_index_status == "unknown_after_search"),
        sum(iih$enceph_index_status == "not_extracted")),
  incident_seizures = c(
    sum(iih$enceph_index == 1 & iih$event == 1, na.rm = TRUE),
    sum(iih$enceph_index == 0 & iih$event == 1, na.rm = TRUE),
    sum(iih$enceph_index_status == "not_assessable" & iih$event == 1),
    sum(iih$enceph_index_status == "unknown_after_search" & iih$event == 1),
    sum(iih$enceph_index_status == "not_extracted" & iih$event == 1)))
write_tab(enc, "F_T5e_encephalocele_descriptive")

saveRDS(list(rates = rates, models = models, ph = ph, cr = cr, cif = cif, rd = rd,
             evalue = eval_tab, neg = neg, tsplit = tsplit, bal = bal, sub = sub,
             sens = sens, tip = tip, mis = mis, rmtl = rm_tab, expl = expl, enc = enc,
             s3 = s3, aj = aj, cstat = cstat, horiz = horiz),
        file.path(PATH$derived, "F2_results.rds"))
log_msg("F2 complete")
