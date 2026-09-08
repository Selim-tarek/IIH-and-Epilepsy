## F9_carpal_rebuild_final.R --------------------------------------------------
## Rebuilds the negative-control outcome from the diagnosis-level extract.
##
## The workbook carried carpal tunnel as a bare 0/1 flag with no date and with
## every male control blank. This extract supplies dated ICD-9/ICD-10 records
## for the whole cohort, which fixes three problems at once:
##   - the outcome can now be defined as INCIDENT rather than ever-present,
##     using exactly the rules already applied to the seizure outcome;
##   - prevalent carpal tunnel can be excluded instead of counted;
##   - the male-control blanks are resolved by data rather than by assumption.
##
## It also overturns the recode applied in F2: 14 male controls DO have carpal
## tunnel records, so treating the male-control blanks as true negatives was
## wrong. The plausibility check (F_T5a4) flagged exactly this.

source("R/00_setup.R")
log_msg("=== F9 rebuild carpal tunnel from diagnosis extract ===")
d  <- readRDS(file.path(PATH$derived, "F1_typed.rds"))
TAU <- 3; WASHOUT_D <- 180

cp <- utils::read.csv(file.path("data-raw", "MDE_Diagnosis_carpal_12.csv"),
                      colClasses = "character", check.names = FALSE)
names(cp) <- c("mrn", "system", "code", "desc", "dx_date")
cp$mrn <- trimws(cp$mrn)
cp$dx_date <- as.Date(substr(cp$dx_date, 1, 10))

## Keep only genuine carpal tunnel codes. The extract also contains HIC codes,
## which are a local vocabulary; they are retained only where the description
## confirms carpal tunnel, so the definition stays code-based and auditable.
cp$is_ctt <- grepl("^354\\.0|^G56\\.0", cp$code) |
             grepl("carpal tunnel", cp$desc, ignore.case = TRUE)
code_tab <- as.data.frame(table(system = cp$system, code = cp$code,
                                counted = cp$is_ctt))
code_tab <- code_tab[code_tab$Freq > 0, ]
write_tab(code_tab, "F_T5b1_carpal_codes_used")
cp <- cp[cp$is_ctt, ]
log_msg("carpal records kept: ", nrow(cp), " across ", length(unique(cp$mrn)), " patients")

## ---- link and date ---------------------------------------------------------
d$mrn <- ifelse(d$iih == 1, d$record_id, d$clinic_number)
assert(!any(duplicated(d$mrn)), "MRN not unique in cohort")
assert(all(unique(cp$mrn) %in% d$mrn), "a carpal record does not link to the cohort")

first_dx <- tapply(cp$dx_date, cp$mrn, min)
d$cp_first_day <- as.numeric(as.Date(first_dx[d$mrn], origin = "1970-01-01") - d$index_date)
d$end_fu_day   <- WASHOUT_D + d$t_y * 365.25

## Same three-way rule as the seizure outcome, applied identically in both arms.
d$cp_prevalent <- !is.na(d$cp_first_day) & d$cp_first_day <= WASHOUT_D
## First carpal record strictly after the washout, within observed follow-up.
after_wash <- vapply(seq_len(nrow(d)), function(i) {
  if (is.na(d$mrn[i])) return(NA_real_)
  dts <- cp$dx_date[cp$mrn == d$mrn[i]]
  if (!length(dts)) return(NA_real_)
  dy <- as.numeric(dts - d$index_date[i])
  dy <- dy[dy > WASHOUT_D]
  if (!length(dy)) NA_real_ else min(dy)
}, numeric(1))
d$cp_event_day <- after_wash
TOL <- 1e-6
d$cp_event <- as.integer(!is.na(d$cp_event_day) & d$cp_event_day <= d$end_fu_day + TOL)
d$cp_t_y   <- ifelse(d$cp_event == 1,
                     (pmin(d$cp_event_day, d$end_fu_day) - WASHOUT_D) / 365.25, d$t_y)
assert(all(d$cp_t_y > 0), "non-positive follow-up for the carpal outcome")

## ---- what the extract changes ----------------------------------------------
old_flag <- d$carpal_incident
comp <- data.frame(
  quantity = c("Male controls with a carpal record (workbook said 0)",
               "Patients with any carpal record",
               "Prevalent at or before day 180 (now EXCLUDED)",
               "Incident after day 180, within follow-up",
               "  of which IIH", "  of which control",
               "Workbook flag = 1 but no dated record",
               "Dated incident record but workbook flag = 0 or blank"),
  n = c(sum(!is.na(d$cp_first_day) & d$sex == "M" & d$iih == 0),
        sum(!is.na(d$cp_first_day)),
        sum(d$cp_prevalent),
        sum(d$cp_event), sum(d$cp_event == 1 & d$iih == 1),
        sum(d$cp_event == 1 & d$iih == 0),
        sum(old_flag == 1 & is.na(d$cp_first_day), na.rm = TRUE),
        sum(d$cp_event == 1 & (is.na(old_flag) | old_flag == 0))))
write_tab(comp, "F_T5b2_carpal_rebuild_vs_workbook")
print(comp)

## ---- negative control on the rebuilt outcome -------------------------------
## Prevalent cases are dropped, exactly as a prior seizure would be.
nc <- d[!d$cp_prevalent, ]
log_msg("analysis set after dropping prevalent carpal tunnel: ", nrow(nc),
        " (", sum(nc$iih == 1), " IIH, ", sum(nc$iih == 0), " control)")

nc_fit <- function(dat, tau, strat, label) {
  s <- dat; s$t <- pmin(s$cp_t_y, tau)
  s$ev <- ifelse(s$cp_t_y > tau, 0L, s$cp_event)
  e1 <- sum(s$ev[s$iih == 1]); e0 <- sum(s$ev[s$iih == 0])
  t1 <- sum(s$t[s$iih == 1]);  t0 <- sum(s$t[s$iih == 0])
  ir <- if (e1 > 0 && e0 > 0) irr_exact(e1, t1, e0, t0) else c(irr=NA, lo=NA, hi=NA, p=NA)
  f <- stats::as.formula(if (strat) "Surv(t, ev) ~ iih + strata(match_set)"
                         else "Surv(t, ev) ~ iih")
  fit <- try(if (strat) survival::coxph(f, data = s)
             else survival::coxph(f, data = s, cluster = s$match_set, robust = TRUE),
             silent = TRUE)
  bad <- inherits(fit, "try-error") || !is.finite(stats::coef(fit)[1]) ||
         e1 == 0 || e0 == 0 || abs(stats::coef(fit)[1]) > 5
  sm <- if (!bad) summary(fit) else NULL
  data.frame(analysis = label, model = ifelse(strat, "stratified", "robust"),
             horizon_y = tau, n = nrow(s), events_iih = e1, events_control = e0,
             IRR = ifelse(is.na(ir[["irr"]]), NA, fmt_est(ir[["irr"]], ir[["lo"]], ir[["hi"]])),
             HR = if (bad) "not estimable" else
                  fmt_est(sm$conf.int[1,1], sm$conf.int[1,3], sm$conf.int[1,4]),
             p = if (bad) NA else fmt_p(sm$coefficients[1, ncol(sm$coefficients)]),
             stringsAsFactors = FALSE)
}
nc_new <- do.call(rbind, list(
  nc_fit(nc, 3, FALSE, "All sexes, dated incident outcome (PRIMARY)"),
  nc_fit(nc, 3, TRUE,  "All sexes, dated incident outcome (PRIMARY)"),
  nc_fit(nc[nc$sex == "F", ], 3, FALSE, "Female only"),
  nc_fit(nc[nc$sex == "F", ], 3, TRUE,  "Female only"),
  nc_fit(nc[nc$sex == "M", ], 3, FALSE, "Male only"),
  nc_fit(nc, 5, FALSE, "All sexes, 5-year"),
  nc_fit(nc, Inf, FALSE, "All sexes, full follow-up"),
  nc_fit(nc, Inf, TRUE,  "All sexes, full follow-up")))
write_tab(nc_new, "F_T5b3_negative_control_rebuilt")
print(nc_new[, c("analysis", "model", "horizon_y", "events_iih", "events_control", "IRR", "HR", "p")])

## ---- what drives the carpal excess? ----------------------------------------
## A negative control that is elevated tells us the design is capturing
## something other than the disease. This asks WHAT, by adding covariates in
## blocks. The post-index encounter model is mediator/collider adjustment and is
## NOT a valid causal estimate -- it is included because its direction is
## diagnostic: if conditioning on healthcare contact removes (or reverses) the
## excess, contact is what the excess was made of.
s3 <- nc; s3$t <- pmin(s3$cp_t_y, TAU)
s3$ev <- ifelse(s3$cp_t_y > TAU, 0L, s3$cp_event)
drv <- do.call(rbind, lapply(list(
    c("iih", "unadjusted"),
    c("iih + bmi_index", "+ BMI"),
    c("iih + bmi_index + osa + htn + pcos", "+ BMI, OSA, HTN, PCOS"),
    c("iih + bmi_index + osa + htn + pcos + age_index + sex", "+ full covariates"),
    c("iih + log1p(enc_pre12)", "+ pre-index encounters"),
    c("iih + log1p(enc_post)", "+ POST-index encounters (contact proxy; NOT causal)")),
  function(z) {
    fit <- survival::coxph(stats::as.formula(paste("Surv(t, ev) ~", z[1])),
                           data = s3, cluster = s3$match_set, robust = TRUE)
    sm <- summary(fit)
    data.frame(model = z[2],
               HR = fmt_est(sm$conf.int[1,1], sm$conf.int[1,3], sm$conf.int[1,4]),
               p = fmt_p(sm$coefficients[1, ncol(sm$coefficients)]))
  }))
write_tab(drv, "F_T5b4_carpal_excess_drivers")
print(drv)

## ---- negative-control calibration -------------------------------------------
## If the same bias inflates both outcomes multiplicatively and to the same
## degree, dividing the seizure hazard ratio by the negative-control hazard
## ratio removes it. That equal-bias assumption is strong and unverifiable, so
## this is a bias-corrected BOUND, not a replacement estimate.
R0 <- readRDS(file.path(PATH$derived, "F2_results.rds"))
hs <- R0$models$hr[1]; hsl <- R0$models$lo[1]; hsh <- R0$models$hi[1]
fitn <- survival::coxph(Surv(t, ev) ~ iih, data = s3, cluster = s3$match_set, robust = TRUE)
hn <- exp(stats::coef(fitn)[1]); se_n <- sqrt(fitn$var[1,1])
se_s <- (log(hsh) - log(hsl)) / (2 * 1.96)
lr <- log(hs) - log(hn); se_r <- sqrt(se_s^2 + se_n^2)
calib <- data.frame(
  quantity = c("Seizure/epilepsy hazard ratio",
               "Carpal tunnel (negative control) hazard ratio",
               "Calibrated ratio (seizure / negative control)"),
  estimate = c(fmt_est(hs, hsl, hsh), fmt_est(hn, exp(log(hn)-1.96*se_n), exp(log(hn)+1.96*se_n)),
               fmt_est(exp(lr), exp(lr-1.96*se_r), exp(lr+1.96*se_r))),
  interpretation = c("As reported", "Should be ~1 if the design is specific. It is not.",
    "What remains of the seizure association if the shared bias is fully removed. Crosses the null."))
write_tab(calib, "F_T5b5_negative_control_calibration")
print(calib)

saveRDS(list(comp = comp, nc = nc_new, codes = code_tab, drivers = drv, calib = calib),
        file.path(PATH$derived, "F9_carpal.rds"))
log_msg("F9 complete")
