## G2_analysis.R --------------------------------------------------------------
## Complete re-analysis on the rebuilt data, run on TWO cohorts in parallel:
##   FULL         every matched patient
##   ENGAGED      controls with >=1 pre-index encounter, as protocol v2.0 v3
##                intended but did not achieve (55.7% of controls had zero)
##
## Every outcome is analysed on its own at-risk window. The earlier build used
## the seizure window for the carpal outcome, which discarded carpal diagnoses
## occurring after a patient's seizure.

source("R/00_setup.R")
log_msg("=== G2 analysis ===")
d <- readRDS(file.path(PATH$derived, "G1_master.rds"))
TAU <- 3

COH <- list(FULL = d, ENGAGED = d[d$engaged, ])

## Generic fitter: OUT selects the outcome and its own clock.
prep <- function(dat, out, tau) {
  if (out == "seizure") { dat$T <- dat$t_y; dat$E <- as.integer(dat$event) }
  else { dat <- dat[!dat$cp_prevalent, ]; dat$T <- dat$cp_t_y; dat$E <- dat$cp_event }
  dat$t <- pmin(dat$T, tau); dat$ev <- ifelse(dat$T > tau, 0L, dat$E)
  dat[!is.na(dat$t) & dat$t > 0 & !is.na(dat$ev), ]
}
fit1 <- function(dat, out, tau, rhs = "iih", strat = FALSE, label = "") {
  s <- prep(dat, out, tau)
  e1 <- sum(s$ev[s$iih == 1]); e0 <- sum(s$ev[s$iih == 0])
  f <- stats::as.formula(paste("Surv(t, ev) ~", rhs, if (strat) "+ strata(match_set)" else ""))
  fit <- try(if (strat) survival::coxph(f, data = s)
             else survival::coxph(f, data = s, cluster = s$match_set, robust = TRUE),
             silent = TRUE)
  bad <- inherits(fit, "try-error") || !is.finite(stats::coef(fit)[1]) ||
         e1 == 0 || e0 == 0 || abs(stats::coef(fit)[1]) > 5
  sm <- if (!bad) summary(fit)
  data.frame(outcome = out, model = label, n = nrow(s), events_iih = e1, events_ctl = e0,
             estimate = if (bad) "not estimable" else
                        fmt_est(sm$conf.int[1,1], sm$conf.int[1,3], sm$conf.int[1,4]),
             hr = if (bad) NA else sm$conf.int[1,1],
             lo = if (bad) NA else sm$conf.int[1,3], hi = if (bad) NA else sm$conf.int[1,4],
             p = if (bad) NA else fmt_p(sm$coefficients[1, ncol(sm$coefficients)]),
             stringsAsFactors = FALSE)
}
rate1 <- function(dat, out, tau) {
  s <- prep(dat, out, tau)
  do.call(rbind, lapply(c(1, 0), function(g) {
    ss <- s[s$iih == g, ]; r <- pois_rate_ci(sum(ss$ev), sum(ss$t))
    data.frame(outcome = out, cohort = ifelse(g == 1, "IIH", "Control"),
               n = nrow(ss), events = sum(ss$ev), py = round(sum(ss$t)),
               rate = round(r[["rate"]], 2), lo = round(r[["lo"]], 2), hi = round(r[["hi"]], 2))
  }))
}

## ---- headline comparison ----------------------------------------------------
main <- do.call(rbind, lapply(names(COH), function(k) {
  x <- rbind(
    fit1(COH[[k]], "seizure", TAU, label = "Cox, 3-year"),
    fit1(COH[[k]], "seizure", TAU, strat = TRUE, label = "Cox, stratified"),
    fit1(COH[[k]], "seizure", TAU, rhs = "iih + age_index + bmi_index + sex + osa + htn + pcos",
         label = "Cox, adjusted"),
    fit1(COH[[k]], "seizure", TAU, rhs = "iih + age_index + bmi_index + sex + osa + htn + pcos + smoking_final",
         label = "Cox, adjusted + smoking"),
    fit1(COH[[k]], "carpal", TAU, label = "NEGATIVE CONTROL, 3-year"),
    fit1(COH[[k]], "carpal", TAU, strat = TRUE, label = "NEGATIVE CONTROL, stratified"))
  x$cohort <- k; x
}))
main <- main[, c("cohort","outcome","model","n","events_iih","events_ctl","estimate","p","hr","lo","hi")]
write_tab(main, "G_T03_main_results")
print(main[, c("cohort","outcome","model","events_iih","events_ctl","estimate","p")])

rates <- do.call(rbind, lapply(names(COH), function(k) {
  x <- rbind(rate1(COH[[k]], "seizure", TAU), rate1(COH[[k]], "carpal", TAU)); x$cohort <- k; x }))
write_tab(rates, "G_T04_incidence_rates")
print(rates)

## ---- baseline carpal prevalence: why the negative control was misleading ----
prev <- do.call(rbind, lapply(names(COH), function(k) {
  dd <- COH[[k]]
  do.call(rbind, lapply(c(1, 0), function(g) {
    s <- dd[dd$iih == g, ]
    data.frame(cohort = k, arm = ifelse(g == 1, "IIH", "Control"), n = nrow(s),
               prevalent_carpal = sum(s$cp_prevalent),
               pct = round(100 * mean(s$cp_prevalent), 2))
  }))
}))
prev$note <- "Carpal tunnel present BEFORE index. A negative control must be balanced here."
write_tab(prev, "G_T05_carpal_prevalence_baseline")
print(prev)

## ---- balance in both cohorts ------------------------------------------------
bal <- do.call(rbind, lapply(names(COH), function(k) {
  dd <- COH[[k]]
  rows <- list()
  add <- function(v, lab, bin = FALSE, pos = 1) {
    x <- if (bin) as.numeric(dd[[v]] == pos) else dd[[v]]
    rows[[lab]] <<- data.frame(cohort = k, variable = lab,
      iih = round(mean(x[dd$iih == 1], na.rm = TRUE), 2),
      control = round(mean(x[dd$iih == 0], na.rm = TRUE), 2),
      smd = round(if (bin) smd_bin(x, dd$iih) else smd_cont(x, dd$iih), 3)) }
  add("age_index","Age"); add("bmi_index","BMI"); add("sex","Female",TRUE,"F")
  add("osa","OSA",TRUE); add("htn","Hypertension",TRUE); add("pcos","PCOS",TRUE)
  add("enc_pre12","Pre-index encounters")
  do.call(rbind, rows)
}))
bal$balanced <- ifelse(abs(bal$smd) < 0.1, "yes", "NO")
write_tab(bal, "G_T06_balance")
print(bal)

## ---- negative-control calibration in both cohorts --------------------------
calib <- do.call(rbind, lapply(names(COH), function(k) {
  sz <- main[main$cohort == k & main$outcome == "seizure" & main$model == "Cox, 3-year", ]
  nc <- main[main$cohort == k & main$outcome == "carpal" & main$model == "NEGATIVE CONTROL, 3-year", ]
  if (is.na(sz$hr) || is.na(nc$hr)) return(NULL)
  se_s <- (log(sz$hi) - log(sz$lo)) / (2*1.96); se_n <- (log(nc$hi) - log(nc$lo)) / (2*1.96)
  lr <- log(sz$hr) - log(nc$hr); se <- sqrt(se_s^2 + se_n^2)
  data.frame(cohort = k, seizure = sz$estimate, negative_control = nc$estimate,
             calibrated = fmt_est(exp(lr), exp(lr-1.96*se), exp(lr+1.96*se)))
}))
write_tab(calib, "G_T07_calibration")
print(calib)

## ---- PH, absolute risk, subgroups on the engagement-restricted cohort ------
dd <- COH$ENGAGED
ph <- do.call(rbind, lapply(c(3, 5, Inf), function(tau) {
  s <- prep(dd, "seizure", tau)
  z <- survival::cox.zph(survival::coxph(Surv(t, ev) ~ iih, data = s))
  data.frame(horizon = tau, chisq = round(z$table["iih","chisq"],2),
             p = signif(z$table["iih","p"],3),
             conclusion = ifelse(z$table["iih","p"] < .05, "PH VIOLATED","PH not rejected")) }))
write_tab(ph, "G_T08_ph")
print(ph)

s3 <- prep(dd, "seizure", TAU)
s3$evc <- ifelse(s3$ev == 1, 1L, ifelse(s3$died == 1, 2L, 0L))
s3$evf <- factor(s3$evc, 0:2, c("censored","seizure","death"))
aj <- survival::survfit(Surv(t, evf) ~ iih, data = s3, id = seq_len(nrow(s3)))
ks <- which(aj$states == "seizure"); sm <- summary(aj, times = 3, extend = TRUE)
st <- as.character(sm$strata)
r1 <- 100*sm$pstate[grepl("iih=1",st),ks]; r0 <- 100*sm$pstate[grepl("iih=0",st),ks]
e1 <- 100*sm$std.err[grepl("iih=1",st),ks]; e0 <- 100*sm$std.err[grepl("iih=0",st),ks]
rd <- data.frame(cohort = "ENGAGED", iih_risk_pct = round(r1,2), control_risk_pct = round(r0,2),
                 diff_pp = round(r1-r0,2), lo = round(r1-r0-1.96*sqrt(e1^2+e0^2),2),
                 hi = round(r1-r0+1.96*sqrt(e1^2+e0^2),2), nnh = round(100/(r1-r0)))
write_tab(rd, "G_T09_absolute_risk")
print(rd)

saveRDS(list(main=main, rates=rates, prev=prev, bal=bal, calib=calib, ph=ph, rd=rd,
             s3=s3, aj=aj), file.path(PATH$derived, "G2_results.rds"))
log_msg("G2 complete")
