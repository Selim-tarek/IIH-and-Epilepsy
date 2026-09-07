## F8_dual_channel_final.R ----------------------------------------------------
## DUAL-CHANNEL OUTCOME DATING
##
##   outcome_date = min(first seizure/epilepsy code date, first unambiguous ASM date)
##
## applied identically in both arms, and applied to the pre-index exclusion and
## the 180-day washout as well as to the event itself.
##
## Cohort, index date, matching and the 180-day washout are LOCKED and untouched.
##
## COVERAGE GATE (decides what may be primary):
##   Medication coverage is 53/2,618 cases (2.0%) and 2,657/9,122 controls (29.1%).
##   Under that asymmetry the earliest-of rule can only add events to controls,
##   which biases the hazard ratio toward the null. So, per the analysis plan:
##     - earliest-of over the whole cohort is a LABELLED SENSITIVITY analysis;
##     - the COVERAGE-RESTRICTED analysis (both arms of a matched set covered)
##       is the internally consistent comparison and carries the headline.

source("R/00_setup.R")
log_msg("=== F8 dual-channel outcome dating ===")
d  <- readRDS(file.path(PATH$derived, "F1_typed.rds"))
R0 <- readRDS(file.path(PATH$derived, "F2_results.rds"))   # coded-outcome results
ms  <- utils::read.csv(file.path("data-raw", "IIH_medications_patient_summary.csv"),
                       colClasses = "character", check.names = FALSE)
det <- utils::read.csv(file.path("data-raw", "IIH_medications_detail.csv"),
                       colClasses = "character", check.names = FALSE)
TAU <- 3; WASHOUT_D <- 180

## ---- 0. the ASM list actually counted --------------------------------------
asm_tab <- as.data.frame(table(det$asm_generic[det$asm_generic != ""]),
                         stringsAsFactors = FALSE)
names(asm_tab) <- c("asm_generic", "n_rows")
asm_tab <- asm_tab[order(-asm_tab$n_rows), ]
write_tab(asm_tab, "DC_T00_asm_drugs_counted")
excl_tab <- as.data.frame(table(det$medication_class), stringsAsFactors = FALSE)
names(excl_tab) <- c("medication_class", "n_rows")
excl_tab$counted_as_asm <- ifelse(grepl("^Antiseizure", excl_tab$medication_class),
                                  "YES", "no")
write_tab(excl_tab, "DC_T00b_medication_classes")
log_msg("ASM generics counted: ", nrow(asm_tab), " (", sum(asm_tab$n_rows), " rows)")

## ---- 1. coverage by arm ----------------------------------------------------
d$has_med <- d$record_id %in% ms$record_id
cov <- do.call(rbind, lapply(c(1, 0), function(g) {
  s <- d[d$iih == g, ]
  data.frame(cohort = ifelse(g == 1, "IIH", "Non-IIH control"),
             n = nrow(s), n_with_medication_record = sum(s$has_med),
             pct_with_medication_record = round(100 * mean(s$has_med), 1))
}))
write_tab(cov, "DC_T01_medication_coverage")
print(cov)
COVERAGE_SYMMETRIC <- min(cov$pct_with_medication_record) > 50
log_msg("coverage symmetric enough for earliest-of to be PRIMARY? ", COVERAGE_SYMMETRIC)

## ---- 2. build the dual-channel date ----------------------------------------
## Work in days since index. t_y runs from day 180, so the end of observed
## follow-up is day 180 + t_y*365.25.
d$end_fu_day <- WASHOUT_D + d$t_y * 365.25
d$code_day   <- ifelse(d$event == 1, d$lat_days, NA_real_)

asm_date <- as.Date(substr(ms$first_asm_date, 1, 10))
names(asm_date) <- ms$record_id
d$asm_day <- as.numeric(asm_date[d$record_id] - d$index_date)

## Exclusion channel: an ASM at or before index, or inside the washout, excludes
## the patient exactly as a code would. This is what makes the rule symmetric
## with the coded definition rather than a one-way event-adding device.
d$excl_asm_preindex <- !is.na(d$asm_day) & d$asm_day <= 0
d$excl_asm_washout  <- !is.na(d$asm_day) & d$asm_day > 0 & d$asm_day <= WASHOUT_D
newly_excl <- do.call(rbind, lapply(c(1, 0), function(g) {
  s <- d[d$iih == g, ]
  data.frame(cohort = ifelse(g == 1, "IIH", "Non-IIH control"),
             n_before = nrow(s),
             newly_excluded_asm_preindex = sum(s$excl_asm_preindex),
             newly_excluded_asm_in_washout = sum(s$excl_asm_washout),
             n_after = nrow(s) - sum(s$excl_asm_preindex | s$excl_asm_washout))
}))
write_tab(newly_excl, "DC_T02_new_exclusions")
print(newly_excl)

dd <- d[!(d$excl_asm_preindex | d$excl_asm_washout), ]

## Event date = earliest qualifying channel, within observed follow-up.
dd$asm_event_day  <- ifelse(!is.na(dd$asm_day) & dd$asm_day > WASHOUT_D,
                            dd$asm_day, NA_real_)
dd$dc_day <- suppressWarnings(pmin(dd$code_day, dd$asm_event_day, na.rm = TRUE))
dd$dc_day[!is.finite(dd$dc_day)] <- NA_real_

## An ASM recorded after the last attended encounter cannot be counted without
## breaking the (locked) censoring rule. Counted and reported, not silently used.
dd$asm_after_censor <- !is.na(dd$asm_event_day) & is.na(dd$code_day) &
                       dd$asm_event_day > dd$end_fu_day
log_msg("ASM-only records falling after censoring (not counted): ",
        sum(dd$asm_after_censor))

## Tolerance is essential here. end_fu_day is reconstructed as
## 180 + t_y*365.25, which reproduces a coded event's own day only to within
## ~2e-12 days of floating-point noise. A strict "<=" therefore dropped 33
## coded events (22 IIH, 11 control) purely on rounding -- and because the
## exposed arm holds more coded events, that alone halved the hazard ratio.
TOL_DAYS <- 1e-6
dd$dc_event <- as.integer(!is.na(dd$dc_day) & dd$dc_day <= dd$end_fu_day + TOL_DAYS)
dd$dc_day   <- pmin(dd$dc_day, dd$end_fu_day)   # clamp away the same noise

## A coded event must always survive: min(code, asm) <= code, and a coded event
## is inside follow-up by construction. Assert it rather than hope.
assert(all(dd$dc_event[dd$event == 1] == 1),
       "a coded event was lost under dual-channel dating")
dd$dc_t_y   <- ifelse(dd$dc_event == 1, (dd$dc_day - WASHOUT_D) / 365.25, dd$t_y)
assert(all(dd$dc_t_y > 0), "non-positive follow-up under dual-channel dating")

## Provenance of each event.
dd$dc_channel <- ifelse(dd$dc_event == 0, "no event",
                 ifelse(is.na(dd$code_day), "medication only (no code at all)",
                 ifelse(is.na(dd$asm_event_day), "code only",
                 ifelse(dd$asm_event_day < dd$code_day, "medication (earlier than code)",
                        "code (earlier than or equal to medication)"))))
chan <- as.data.frame.matrix(table(dd$dc_channel[dd$dc_event == 1],
                                   dd$cohort[dd$dc_event == 1]))
chan$channel <- rownames(chan); rownames(chan) <- NULL
chan <- chan[, c("channel", "Non-IIH control", "IIH")]
write_tab(chan, "DC_T03_event_provenance")
print(chan)

## ---- 3. code lag: the quantity being claimed --------------------------------
## Among patients with BOTH channels, how much later is the code than the ASM?
both <- dd[!is.na(dd$code_day) & !is.na(dd$asm_event_day), ]
lag_tab <- do.call(rbind, lapply(levels(both$cohort), function(k) {
  x <- both$code_day[both$cohort == k] - both$asm_event_day[both$cohort == k]
  if (!length(x)) return(data.frame(cohort = k, n = 0, median_lag_days = NA,
                                    q1 = NA, q3 = NA, pct_code_later = NA))
  data.frame(cohort = k, n = length(x),
             median_lag_days = round(stats::median(x), 1),
             q1 = round(stats::quantile(x, .25), 1), q3 = round(stats::quantile(x, .75), 1),
             pct_code_later = round(100 * mean(x > 0), 1))
}))
write_tab(lag_tab, "DC_T04_code_minus_asm_lag")
print(lag_tab)

## ---- 4. model machinery -----------------------------------------------------
cut_dc <- function(dat, tau, tvar = "dc_t_y", evar = "dc_event") {
  dat$t  <- pmin(dat[[tvar]], tau)
  dat$ev <- ifelse(dat[[tvar]] > tau, 0L, as.integer(dat[[evar]]))
  dat$evc <- ifelse(dat[[tvar]] > tau, 0L,
                    ifelse(dat[[evar]] == 1, 1L, ifelse(dat$died == 1, 2L, 0L)))
  dat
}
fitc <- function(dat, tau, rhs, label, strat = FALSE, wts = NULL,
                 tvar = "dc_t_y", evar = "dc_event") {
  s <- cut_dc(dat, tau, tvar, evar)
  f <- stats::as.formula(paste("Surv(t, ev) ~", rhs,
                               if (strat) "+ strata(match_set)" else ""))
  fit <- try(if (strat) survival::coxph(f, data = s, ties = "efron")
             else if (!is.null(wts)) survival::coxph(f, data = s, weights = s[[wts]],
                          cluster = s$match_set, robust = TRUE, ties = "efron")
             else survival::coxph(f, data = s, cluster = s$match_set, robust = TRUE,
                                  ties = "efron"), silent = TRUE)
  ## Separation guard. A coefficient can be finite and still meaningless: with
  ## zero events in one arm the partial likelihood is maximised at the boundary
  ## and coxph returns a huge but "converged" estimate. Report that as not
  ## estimable rather than printing a hazard ratio of 10^8.
  n_ev_exp <- sum(s$ev[s$iih == 1]); n_ev_unexp <- sum(s$ev[s$iih == 0])
  if (inherits(fit, "try-error") || !is.finite(stats::coef(fit)[1]) ||
      n_ev_exp == 0 || n_ev_unexp == 0 || abs(stats::coef(fit)[1]) > 5)
    return(data.frame(model = label, n = nrow(s), events = sum(s$ev),
                      hr = NA, lo = NA, hi = NA, p = NA,
                      estimate = sprintf("NOT ESTIMABLE (separation: %d exposed / %d unexposed events)",
                                         n_ev_exp, n_ev_unexp)))
  sm <- summary(fit)
  data.frame(model = label, n = fit$n, events = fit$nevent,
             hr = round(sm$conf.int[1, 1], 2), lo = round(sm$conf.int[1, 3], 2),
             hi = round(sm$conf.int[1, 4], 2),
             p = signif(sm$coefficients[1, ncol(sm$coefficients)], 3),
             estimate = fmt_est(sm$conf.int[1, 1], sm$conf.int[1, 3], sm$conf.int[1, 4]))
}

## Propensity score, refitted on the post-exclusion set, same specification.
ps <- dd[stats::complete.cases(dd[, c("age_index","bmi_index","sex","index_year")]), ]
psf <- stats::glm(iih ~ age_index + bmi_index + sex + index_year,
                  family = stats::binomial, data = ps)
ps$ps <- stats::fitted(psf); pm <- mean(ps$iih)
ps$iptw <- ifelse(ps$iih == 1, pm / ps$ps, (1 - pm) / (1 - ps$ps))
qq <- stats::quantile(ps$iptw, c(.01, .99))
ps$iptw_trim <- pmin(pmax(ps$iptw, qq[1]), qq[2])

## ---- A. primary and secondary models on the new dating ---------------------
dc_models <- rbind(
  fitc(dd, 3, "iih", "Cox, 3-year"),
  fitc(dd, 3, "iih", "Cox stratified by matched set", strat = TRUE),
  fitc(ps, 3, "iih", "Cox, IPTW (stabilised, trimmed)", wts = "iptw_trim"),
  fitc(dd, 3, "iih + age_index + bmi_index + sex", "Cox + age/BMI/sex"),
  fitc(dd, 3, "iih + age_index + bmi_index + sex + osa + htn + pcos",
       "Cox + age/BMI/sex/OSA/HTN/PCOS"),
  fitc(dd, 3, "iih + log1p(enc_pre12)", "Cox + pre-index encounters"),
  fitc(dd, 5, "iih", "Cox, 5-year"),
  fitc(dd, Inf, "iih", "Cox, full follow-up"))
## Fine-Gray on the new dating.
s3 <- cut_dc(dd, 3)
s3$evf <- factor(s3$evc, levels = 0:2, labels = c("censored", "seizure", "death"))
fgd <- survival::finegray(Surv(t, evf) ~ ., data = s3, etype = "seizure")
fg  <- survival::coxph(Surv(fgstart, fgstop, fgstatus) ~ iih, weights = fgwt,
                       data = fgd, cluster = fgd$match_set, robust = TRUE)
sfg <- summary(fg)
dc_models <- rbind(dc_models, data.frame(
  model = "Fine-Gray subdistribution, 3-year", n = nrow(s3), events = sum(s3$ev),
  hr = round(sfg$conf.int[1,1],2), lo = round(sfg$conf.int[1,3],2),
  hi = round(sfg$conf.int[1,4],2),
  p = signif(sfg$coefficients[1, ncol(sfg$coefficients)],3),
  estimate = fmt_est(sfg$conf.int[1,1], sfg$conf.int[1,3], sfg$conf.int[1,4])))
dc_models$status <- "SENSITIVITY -- asymmetric medication coverage (2.0% vs 29.1%)"
write_tab(dc_models, "DC_T05_models_dual_channel")
print(dc_models[, c("model", "n", "events", "estimate", "p")])

## ---- B. coverage-restricted analysis (the headline) ------------------------
## Matched sets in which the case AND at least one control have medication
## coverage. Within this subset the earliest-of rule is applied to both arms on
## equal footing, so it cannot manufacture a one-sided event surplus.
case_cov <- dd$match_set[dd$iih == 1 & dd$has_med]
ctl_cov  <- unique(dd$match_set[dd$iih == 0 & dd$has_med])
sets_ok  <- intersect(case_cov, ctl_cov)
cr <- dd[dd$match_set %in% sets_ok & dd$has_med, ]
log_msg("coverage-restricted: ", length(sets_ok), " matched sets | ",
        sum(cr$iih == 1), " cases, ", sum(cr$iih == 0), " controls")

cr_models <- rbind(
  fitc(cr, 3, "iih", "Coverage-restricted, dual-channel, 3-year"),
  fitc(cr, 3, "iih", "Coverage-restricted, dual-channel, stratified", strat = TRUE),
  fitc(cr, 3, "iih", "Coverage-restricted, CODED outcome only, 3-year",
       tvar = "t_y", evar = "event"))
cr_models$matched_sets <- length(sets_ok)
cr_models$status <- "HEADLINE for dual-channel dating (coverage symmetric by construction)"
write_tab(cr_models, "DC_T06_coverage_restricted")
print(cr_models[, c("model", "n", "events", "estimate", "p")])

cr_desc <- data.frame(
  quantity = c("Matched sets with case AND >=1 control covered",
               "Cases in the restricted set", "Controls in the restricted set",
               "Events, IIH", "Events, control",
               "Total events at 3 years"),
  value = c(length(sets_ok), sum(cr$iih == 1), sum(cr$iih == 0),
            sum(cut_dc(cr, 3)$ev[cr$iih == 1]), sum(cut_dc(cr, 3)$ev[cr$iih == 0]),
            sum(cut_dc(cr, 3)$ev)))
write_tab(cr_desc, "DC_T06b_coverage_restricted_composition")
print(cr_desc)

## ---- C. absolute measures on the new dating --------------------------------
aj <- survival::survfit(Surv(t, evf) ~ iih, data = s3, id = seq_len(nrow(s3)))
ks <- which(aj$states == "seizure")
smj <- summary(aj, times = c(1, 2, 3), extend = TRUE)
cif <- data.frame(
  cohort = ifelse(grepl("iih=1", as.character(smj$strata)), "IIH", "Non-IIH control"),
  time_y = smj$time, cif_pct = round(100 * smj$pstate[, ks], 3),
  se_pct = round(100 * smj$std.err[, ks], 3))
write_tab(cif, "DC_T07_cumulative_incidence")
i1 <- which(cif$cohort == "IIH" & cif$time_y == 3)
i0 <- which(cif$cohort != "IIH" & cif$time_y == 3)
est <- cif$cif_pct[i1] - cif$cif_pct[i0]
sed <- sqrt(cif$se_pct[i1]^2 + cif$se_pct[i0]^2)
rd <- data.frame(measure = "3-year absolute risk difference (percentage points)",
                 iih_risk_pct = cif$cif_pct[i1], control_risk_pct = cif$cif_pct[i0],
                 estimate = round(est, 2), lo = round(est - 1.96 * sed, 2),
                 hi = round(est + 1.96 * sed, 2),
                 number_needed_to_harm = round(100 / est))
write_tab(rd, "DC_T08_risk_difference")
print(rd)

rmtl <- function(dat) {
  dat$evf <- factor(dat$evc, levels = 0:2, labels = c("censored","seizure","death"))
  f <- survival::survfit(Surv(t, evf) ~ iih, data = dat, id = seq_len(nrow(dat)))
  g <- seq(0, TAU, by = .01); sm2 <- summary(f, times = g, extend = TRUE)
  kk <- which(f$states == "seizure"); st <- as.character(sm2$strata)
  vapply(c("iih=0","iih=1"), function(z) { y <- sm2$pstate[st == z, kk]
    sum((utils::head(y,-1) + utils::tail(y,-1))/2 * diff(g)) }, numeric(1))
}
obs <- rmtl(s3)
set.seed(SEED); sets <- unique(s3$match_set); idx <- split(seq_len(nrow(s3)), s3$match_set)
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
  days_lost_over_3y = round(c(obs[1], obs[2], obs[2]-obs[1]) * 365.25, 2),
  lo = round(apply(boot, 1, stats::quantile, .025, na.rm = TRUE) * 365.25, 2),
  hi = round(apply(boot, 1, stats::quantile, .975, na.rm = TRUE) * 365.25, 2))
rm_tab$estimate <- fmt_est(rm_tab$days_lost_over_3y, rm_tab$lo, rm_tab$hi)
write_tab(rm_tab, "DC_T09_restricted_mean_time_lost")
print(rm_tab[, c("quantity", "estimate")])

## ---- D. diagnostics ---------------------------------------------------------
sym <- do.call(rbind, lapply(c(1, 0), function(g) {
  s <- dd[dd$iih == g & dd$dc_event == 1, ]
  data.frame(cohort = ifelse(g == 1, "IIH", "Non-IIH control"),
             events = nrow(s), earliest_event_day = min(s$dc_day),
             latest_event_day = max(s$dc_day))
}))
write_tab(sym, "DC_T10_washout_symmetry")
print(sym)

ph <- do.call(rbind, lapply(c(3, 5, Inf), function(tau) {
  s <- cut_dc(dd, tau)
  z <- survival::cox.zph(survival::coxph(Surv(t, ev) ~ iih, data = s))
  data.frame(horizon_y = tau, chisq = round(z$table["iih","chisq"], 2),
             df = z$table["iih","df"], p_ph = signif(z$table["iih","p"], 3),
             conclusion = ifelse(z$table["iih","p"] < 0.05, "PH VIOLATED", "PH not rejected"))
}))
write_tab(ph, "DC_T11_ph_assumption")
print(ph)

## Negative control, unchanged (coded carpal tunnel outcome), as a check that
## nothing outside the outcome definition moved.
nc <- dd[!is.na(dd$carpal_incident) & dd$sex == "F", ]
nc$nc_ev <- nc$carpal_incident
neg <- fitc(nc, 3, "iih", "Incident carpal tunnel (NEGATIVE CONTROL, unchanged)",
            tvar = "t_y", evar = "nc_ev")
neg_ref <- R0$neg[2, ]
neg_cmp <- data.frame(
  analysis = c("Negative control, coded-outcome cohort", "Negative control, after dual-channel exclusions"),
  n = c(neg_ref$n, neg$n), events = c(neg_ref$events, neg$events),
  estimate = c(neg_ref$estimate, neg$estimate))
write_tab(neg_cmp, "DC_T12_negative_control")
print(neg_cmp)

## ---- summary: coded vs dual-channel vs coverage-restricted -----------------
pick <- function(tab, pattern) {
  i <- grep(pattern, tab$model)[1]
  if (is.na(i)) NA_character_ else tab$estimate[i]
}
summary_tab <- data.frame(
  model = c("Cox, 3-year", "Stratified by matched set", "IPTW",
            "+ age/BMI/sex", "+ age/BMI/sex/OSA/HTN/PCOS", "+ pre-index encounters",
            "Fine-Gray, 3-year", "Cox, 5-year", "Cox, full follow-up"),
  coded_outcome = c(R0$models$estimate[1], R0$models$estimate[2], R0$models$estimate[3],
                    R0$models$estimate[4], NA, NA, R0$cr$estimate[3],
                    R0$models$estimate[5], R0$models$estimate[6]),
  dual_channel = c(pick(dc_models, "^Cox, 3-year$"), pick(dc_models, "stratified"),
                   pick(dc_models, "IPTW"), pick(dc_models, "age/BMI/sex$"),
                   pick(dc_models, "OSA/HTN/PCOS"), pick(dc_models, "pre-index"),
                   pick(dc_models, "Fine-Gray"), pick(dc_models, "5-year"),
                   pick(dc_models, "full follow-up")),
  coverage_restricted = c(cr_models$estimate[1], cr_models$estimate[2],
                          rep(NA, 7)))
write_tab(summary_tab, "DC_T13_summary_comparison")
print(summary_tab)

saveRDS(list(cov = cov, newly_excl = newly_excl, chan = chan, lag = lag_tab,
             models = dc_models, cr = cr_models, cr_desc = cr_desc, rd = rd,
             rmtl = rm_tab, sym = sym, ph = ph, neg = neg_cmp, summ = summary_tab,
             asm = asm_tab, sets_ok = length(sets_ok)),
        file.path(PATH$derived, "F8_dualchannel.rds"))
log_msg("F8 complete")
