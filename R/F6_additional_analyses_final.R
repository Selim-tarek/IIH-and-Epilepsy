## F6_additional_analyses_final.R ---------------------------------------------
## Analyses the earlier scripts did not run, chosen from what this dataset can
## actually support. Each answers a question a reviewer or a clinician will ask.
##
##  A. External benchmark: is the control rate plausible for a general population?
##  B. Latency: WHEN do seizures happen, and does timing differ by cohort?
##  C. Continuous effect modification by BMI (follows up the significant interaction)
##  D. Absolute risk by subgroup -- clinicians need risks, not only ratios
##  E. Attributable fraction among the exposed
##  F. Calendar-period trend and the ICD-9 to ICD-10 transition
##  G. Design effect: robust vs naive SE, and an exact permutation test
##  H. Smooth time-varying hazard ratio
##  I. Minimum detectable effect -- what the study could and could not have seen
##  J. Missingness in the final workbook

source("R/00_setup.R")
log_msg("=== F6 additional analyses ===")
d <- readRDS(file.path(PATH$derived, "F1_typed.rds"))
TAU <- 3
cut_at <- function(dat, tau) {
  dat$t   <- pmin(dat$t_y, tau)
  dat$ev  <- ifelse(dat$t_y > tau, 0L, as.integer(dat$event))
  dat$evc <- ifelse(dat$t_y > tau, 0L,
                    ifelse(dat$event == 1, 1L, ifelse(dat$died == 1, 2L, 0L)))
  dat
}
s3 <- cut_at(d, TAU)

## ---- A. external benchmark of the control rate -----------------------------
## A matched "control" drawn from a clinical population is not a general
## population. Comparing the observed control rate against published incidence
## of epilepsy in adults is a cheap, powerful check on how transportable this
## comparison is. The published figure is NOT asserted here -- the observed
## numbers are given so they can be benchmarked against whatever source the
## authors choose.
bench <- do.call(rbind, lapply(list(c(3, "3 years"), c(Inf, "full follow-up")),
  function(z) {
    s <- cut_at(d, as.numeric(z[1]))
    do.call(rbind, lapply(c(0, 1), function(g) {
      ss <- s[s$iih == g, ]; r <- pois_rate_ci(sum(ss$ev), sum(ss$t))
      data.frame(horizon = z[2], cohort = ifelse(g == 1, "IIH", "Non-IIH control"),
                 rate_per_1000py = round(r[["rate"]], 2),
                 rate_per_100k_py = round(r[["rate"]] * 100, 0),
                 lo_per_100k = round(r[["lo"]] * 100, 0),
                 hi_per_100k = round(r[["hi"]] * 100, 0))
    }))
  }))
bench$note <- "Benchmark against published adult epilepsy incidence for your setting; a control rate far above it indicates a clinical, not general, comparison population."
write_tab(bench, "F_T15_external_benchmark")
print(bench)

## ---- B. latency to event ----------------------------------------------------
lat <- d[d$event == 1, c("cohort", "lat_days")]
lat$years <- lat$lat_days / 365.25
lat_tab <- do.call(rbind, lapply(levels(lat$cohort), function(k) {
  x <- lat$years[lat$cohort == k]
  data.frame(cohort = k, n = length(x),
             median_y = round(stats::median(x), 2),
             q1 = round(stats::quantile(x, .25), 2), q3 = round(stats::quantile(x, .75), 2),
             pct_within_1y = round(100 * mean(x <= 1), 1),
             pct_within_3y = round(100 * mean(x <= 3), 1))
}))
## Do the two latency distributions differ in shape? A Wilcoxon test on latency
## among cases only is descriptive: it conditions on having had an event, so it
## must not be read as an effect estimate.
wt <- stats::wilcox.test(years ~ cohort, data = lat)
lat_tab$wilcoxon_p <- c(signif(wt$p.value, 3), NA)
write_tab(lat_tab, "F_T16_latency_to_event")
print(lat_tab)

## ---- C. continuous effect modification by BMI ------------------------------
## The categorical subgroup analysis found a BMI interaction (p = 0.028). A
## dichotomy at 35 discards information and can manufacture or hide a gradient,
## so here BMI enters continuously and the hazard ratio is traced across its
## range with a confidence band.
fit_int <- survival::coxph(Surv(t, ev) ~ iih * bmi_index, data = s3,
                           cluster = s3$match_set, robust = TRUE)
b <- stats::coef(fit_int); V <- fit_int$var
i_m <- which(names(b) == "iih"); i_x <- which(names(b) == "iih:bmi_index")
bmi_grid <- seq(stats::quantile(s3$bmi_index, .02, na.rm = TRUE),
                stats::quantile(s3$bmi_index, .98, na.rm = TRUE), length.out = 120)
loghr <- b[i_m] + b[i_x] * bmi_grid
se <- sqrt(V[i_m, i_m] + bmi_grid^2 * V[i_x, i_x] + 2 * bmi_grid * V[i_m, i_x])
bmi_curve <- data.frame(bmi = bmi_grid, hr = exp(loghr),
                        lo = exp(loghr - 1.96 * se), hi = exp(loghr + 1.96 * se))
write_tab(bmi_curve[seq(1, nrow(bmi_curve), length.out = 12), ], "F_T17_bmi_interaction_curve")
int_p <- summary(fit_int)$coefficients[i_x, ncol(summary(fit_int)$coefficients)]
log_msg("continuous BMI x IIH interaction p = ", signif(int_p, 3),
        " | HR per 5 BMI units: ", sprintf("%.2f", exp(5 * b[i_x])))

## Same for age, for symmetry.
fit_age <- survival::coxph(Surv(t, ev) ~ iih * age_index, data = s3,
                           cluster = s3$match_set, robust = TRUE)
sa <- summary(fit_age)
mod_tab <- data.frame(
  modifier = c("BMI (continuous)", "Age (continuous)"),
  interaction_hr_per_unit = c(round(exp(b[i_x]), 4),
                              round(exp(stats::coef(fit_age)["iih:age_index"]), 4)),
  interaction_hr_per_10_units = c(round(exp(10 * b[i_x]), 3),
                              round(exp(10 * stats::coef(fit_age)["iih:age_index"]), 3)),
  interaction_p = c(signif(int_p, 3),
                    signif(sa$coefficients["iih:age_index", ncol(sa$coefficients)], 3)))
write_tab(mod_tab, "F_T17b_continuous_interactions")
print(mod_tab)

## ---- D. absolute risk by subgroup ------------------------------------------
## Hazard ratios do not tell a patient what to expect. These are 3-year
## cumulative incidences with death as a competing event, within subgroup.
cif_sub <- function(dat, label) {
  dat$evf <- factor(dat$evc, levels = 0:2, labels = c("censored", "seizure", "death"))
  if (length(unique(dat$iih)) < 2 || sum(dat$ev) < 5) return(NULL)
  f <- survival::survfit(Surv(t, evf) ~ iih, data = dat, id = seq_len(nrow(dat)))
  k <- which(f$states == "seizure")
  sm <- summary(f, times = TAU, extend = TRUE)
  st <- as.character(sm$strata)
  r1 <- 100 * sm$pstate[grepl("iih=1", st), k]; r0 <- 100 * sm$pstate[grepl("iih=0", st), k]
  e1 <- 100 * sm$std.err[grepl("iih=1", st), k]; e0 <- 100 * sm$std.err[grepl("iih=0", st), k]
  data.frame(subgroup = label, n = nrow(dat), events = sum(dat$ev),
             iih_risk_pct = round(r1, 2), control_risk_pct = round(r0, 2),
             risk_difference_pp = round(r1 - r0, 2),
             rd_lo = round(r1 - r0 - 1.96 * sqrt(e1^2 + e0^2), 2),
             rd_hi = round(r1 - r0 + 1.96 * sqrt(e1^2 + e0^2), 2),
             nnh = ifelse(r1 - r0 > 0, round(100 / (r1 - r0)), NA))
}
s3$bmi_grp <- ifelse(s3$bmi_index < 35, "BMI <35", "BMI >=35")
s3$age_grp <- ifelse(s3$age_index < 35, "Age <35", "Age >=35")
abs_risk <- rbind(
  cif_sub(s3, "Overall"),
  cif_sub(s3[s3$sex == "F", ], "Female"), cif_sub(s3[s3$sex == "M", ], "Male"),
  cif_sub(s3[s3$bmi_grp == "BMI <35", ], "BMI <35"),
  cif_sub(s3[s3$bmi_grp == "BMI >=35", ], "BMI >=35"),
  cif_sub(s3[s3$age_grp == "Age <35", ], "Age <35"),
  cif_sub(s3[s3$age_grp == "Age >=35", ], "Age >=35"))
write_tab(abs_risk, "F_T18_absolute_risk_by_subgroup")
print(abs_risk)

## ---- E. attributable fraction among the exposed ----------------------------
## Of the seizures that occurred in IIH patients, what proportion is
## statistically attributable to the exposure? AFe = (HR - 1) / HR under the
## (strong) assumption that the adjusted HR is causal. Reported WITH that
## assumption stated, because it is exactly the number that gets over-read.
hr <- 3.66; hr_lo <- 2.55; hr_hi <- 5.25
fit_p <- survival::coxph(Surv(t, ev) ~ iih, data = s3, cluster = s3$match_set,
                         robust = TRUE)
smp <- summary(fit_p)
hr <- smp$conf.int[1, 1]; hr_lo <- smp$conf.int[1, 3]; hr_hi <- smp$conf.int[1, 4]
afe <- data.frame(
  quantity = "Attributable fraction among the exposed",
  estimate_pct = round(100 * (hr - 1) / hr, 1),
  lo_pct = round(100 * (hr_lo - 1) / hr_lo, 1),
  hi_pct = round(100 * (hr_hi - 1) / hr_hi, 1),
  assumption = paste("Valid ONLY if the hazard ratio is causal and unconfounded.",
                     "It is not: see the E-value and the ascertainment discussion.",
                     "Report it as an upper bound on clinical impact, never as a",
                     "demonstrated causal share."))
write_tab(afe, "F_T19_attributable_fraction")
print(afe[, 1:4])

## ---- F. calendar-period trend and the ICD-9 to ICD-10 transition -----------
## US coding moved from ICD-9 to ICD-10 on 1 October 2015. If the outcome
## algorithm behaves differently either side of that date, incidence will step
## rather than drift. This is a data-quality check disguised as a trend plot.
d$era5 <- cut(d$index_year, breaks = c(-Inf, 2009, 2014, 2019, Inf),
              labels = c("<=2009", "2010-2014", "2015-2019", ">=2020"))
trend <- do.call(rbind, lapply(levels(d$era5), function(e) {
  s <- cut_at(d[d$era5 == e, ], TAU)
  do.call(rbind, lapply(c(0, 1), function(g) {
    ss <- s[s$iih == g, ]
    if (!nrow(ss)) return(NULL)
    r <- pois_rate_ci(sum(ss$ev), sum(ss$t))
    data.frame(era = e, cohort = ifelse(g == 1, "IIH", "Non-IIH control"),
               n = nrow(ss), events = sum(ss$ev), py = round(sum(ss$t)),
               rate = round(r[["rate"]], 2), lo = round(r[["lo"]], 2),
               hi = round(r[["hi"]], 2))
  }))
}))
write_tab(trend, "F_T20_calendar_trend")
print(trend)

## Formal test of exposure-by-era interaction.
se <- cut_at(d, TAU); se$era5 <- d$era5
fit_era <- survival::coxph(Surv(t, ev) ~ iih * era5, data = se,
                           cluster = se$match_set, robust = TRUE)
bb <- stats::coef(fit_era); kk <- grep("^iih:", names(bb))
Vk <- fit_era$var[kk, kk, drop = FALSE]
W <- as.numeric(t(bb[kk]) %*% solve(Vk) %*% bb[kk])
era_p <- signif(stats::pchisq(W, length(kk), lower.tail = FALSE), 3)
log_msg("exposure x calendar-era interaction p = ", era_p)

## ---- G. design effect and an exact permutation test ------------------------
## How much does clustering on matched sets actually cost? And is the p-value
## robust without any large-sample assumption? Within each matched set exactly
## one member is the case, so permuting which member carries the exposure label
## gives an exact conditional test -- the randomisation analogue of the
## stratified Cox model.
naive  <- survival::coxph(Surv(t, ev) ~ iih, data = s3)
robust <- survival::coxph(Surv(t, ev) ~ iih, data = s3, cluster = s3$match_set,
                          robust = TRUE)
de <- data.frame(
  variance = c("Naive (independence)", "Robust, clustered on matched set"),
  se_log_hr = round(c(sqrt(naive$var[1, 1]), sqrt(robust$var[1, 1])), 4),
  hr = round(c(exp(stats::coef(naive)[1]), exp(stats::coef(robust)[1])), 2))
de$design_effect <- round((de$se_log_hr / de$se_log_hr[1])^2, 3)
write_tab(de, "F_T21_design_effect")
print(de)

set.seed(SEED)
obs_stat <- stats::coef(survival::coxph(Surv(t, ev) ~ iih + strata(match_set), data = s3))[1]
NPERM <- 2000
perm <- vapply(seq_len(NPERM), function(i) {
  z <- ave(s3$iih, s3$match_set, FUN = function(v) sample(v))
  f <- try(survival::coxph(Surv(s3$t, s3$ev) ~ z + strata(s3$match_set)), silent = TRUE)
  if (inherits(f, "try-error")) return(NA_real_)
  unname(stats::coef(f)[1])
}, numeric(1))
p_perm <- (1 + sum(abs(perm) >= abs(obs_stat), na.rm = TRUE)) / (1 + sum(!is.na(perm)))
permt <- data.frame(
  test = "Exact permutation test, exposure permuted within matched sets",
  observed_log_hr = round(obs_stat, 4), permutations = sum(!is.na(perm)),
  p_value = ifelse(p_perm < 1 / NPERM, paste0("<", signif(1 / NPERM, 2)), signif(p_perm, 3)),
  note = "Randomisation-based; makes no large-sample or proportional-hazards assumption.")
write_tab(permt, "F_T22_permutation_test")
print(permt[, c("test", "permutations", "p_value")])

## ---- H. smooth time-varying hazard ratio -----------------------------------
zph <- survival::cox.zph(survival::coxph(Surv(t, ev) ~ iih, data = s3),
                         transform = "identity")
tv <- local({
  x <- zph$x; y <- zph$y[, 1]
  sp <- stats::smooth.spline(x, y, df = 3)
  pr <- stats::predict(sp, sort(unique(x)))
  sres <- stats::sd(y - stats::predict(sp, x)$y)
  data.frame(time_y = pr$x, hr = exp(pr$y),
             lo = exp(pr$y - 1.96 * sres / sqrt(length(x) / 4)),
             hi = exp(pr$y + 1.96 * sres / sqrt(length(x) / 4)))
})
write_tab(tv[seq(1, nrow(tv), length.out = 15), ], "F_T23_time_varying_hr")

## ---- I. minimum detectable effect ------------------------------------------
## The right way to express what a null subgroup result means. Uses Schoenfeld's
## variance for a two-group Cox comparison: se(log HR) ~ 1/sqrt(d p (1-p)).
mde <- function(events, p_exposed, power = 0.8, alpha = 0.05) {
  if (events < 3) return(NA_real_)
  se <- 1 / sqrt(events * p_exposed * (1 - p_exposed))
  exp((stats::qnorm(1 - alpha / 2) + stats::qnorm(power)) * se)
}
grp_mde <- function(dat, lab) {
  s <- cut_at(dat, TAU)
  data.frame(analysis = lab, events = sum(s$ev),
             pct_exposed = round(100 * mean(s$iih == 1), 1),
             min_detectable_hr = round(mde(sum(s$ev), mean(s$iih == 1)), 2))
}
mde_tab <- rbind(
  grp_mde(d, "Overall"),
  grp_mde(d[d$sex == "F", ], "Female"), grp_mde(d[d$sex == "M", ], "Male"),
  grp_mde(d[d$bmi_index < 35, ], "BMI <35"), grp_mde(d[d$bmi_index >= 35, ], "BMI >=35"),
  grp_mde(d[!is.na(d$carpal_incident) & d$sex == "F", ], "Negative control (carpal, female)"))
mde_tab$interpretation <- ifelse(
  is.na(mde_tab$min_detectable_hr), "not estimable",
  paste0("80% power to detect HR >= ", mde_tab$min_detectable_hr,
         "; smaller true effects would likely be missed"))
write_tab(mde_tab, "F_T24_minimum_detectable_effect")
print(mde_tab)

## ---- J. missingness in the final workbook ----------------------------------
vars <- c("age_index", "bmi_index", "sex", "op_cmh2o", "enc_pre12", "enc_post",
          "osa", "htn", "pcos", "smoking", "carpal_incident", "t_y", "event")
miss <- do.call(rbind, lapply(vars, function(v) {
  data.frame(variable = v,
             pct_missing_iih = round(100 * mean(is.na(d[[v]][d$iih == 1])), 2),
             pct_missing_control = round(100 * mean(is.na(d[[v]][d$iih == 0])), 2))
}))
miss$difference <- round(abs(miss$pct_missing_iih - miss$pct_missing_control), 2)
miss$assessment <- ifelse(miss$difference > 50, "STRUCTURAL -- one cohort only, never impute",
                   ifelse(miss$difference > 5, "differential -- handle with care", "comparable"))
write_tab(miss, "F_T25_missingness")
print(miss)

saveRDS(list(bench = bench, lat = lat_tab, lat_raw = lat, bmi_curve = bmi_curve,
             mod = mod_tab, abs_risk = abs_risk, afe = afe, trend = trend,
             era_p = era_p, de = de, permt = permt, tv = tv, mde = mde_tab,
             miss = miss, int_p = int_p),
        file.path(PATH$derived, "F6_extra.rds"))
log_msg("F6 complete")
