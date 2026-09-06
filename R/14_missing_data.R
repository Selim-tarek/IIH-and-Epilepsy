## 14_missing_data.R ----------------------------------------------------------
## Missingness report and the complete-case / missing-indicator / multiple-
## imputation comparison requested for the covariate-adjusted model.
##
## Multiple imputation is applied ONLY to variables that are plausibly missing
## at random. It is NOT applied to:
##   - variables blank for an entire cohort (structural; imputing them would
##     manufacture control imaging that was never acquired);
##   - code 88 (not applicable / not technically assessable) -- an unassessable
##     scan is not a missing measurement, it is an unanswerable question.

source("R/00_setup.R")
log_msg("=== 14 missing data ===")
a  <- readRDS(file.path(PATH$derived, "05_analytic.rds"))
tr <- readRDS(file.path(PATH$derived, "05_truncate_fn.rds"))
LM <- 180 / 365.25

## ---- A. missingness in the analytic set, by the strata that matter ---------
## Note the deliberate ordering: missingness is described by exposure, calendar
## period and matched-set completeness. It is ALSO shown by outcome status, but
## only as a diagnostic -- outcome information is never used to decide how a
## variable is handled.
model_vars <- c("age_index", "bmi_index", "sex", "index_year", "enc_pre12",
                "enc_post", "osa", "htn", "pcos", "smoking", "alcohol",
                "followup_years")
a$era <- ifelse(a$index_year < 2015, "<2015", ">=2015")
a$outcome_lab <- ifelse(a$event_seizure == 1, "event", "no event")

miss_by <- function(by, label) {
  do.call(rbind, lapply(model_vars, function(v) {
    s <- split(is.na(a[[v]]), a[[by]])
    data.frame(variable = v, stratifier = label,
               stratum = names(s),
               n_missing = vapply(s, sum, integer(1)),
               pct_missing = round(100 * vapply(s, mean, numeric(1)), 2),
               row.names = NULL)
  }))
}
miss <- rbind(miss_by("cohort", "Exposure"), miss_by("era", "Calendar period"),
              miss_by("outcome_lab", "Outcome status (diagnostic only)"))
write_tab(miss, "S25_missingness_by_stratum")

## Differential missingness: variables missing at very different rates by arm
## cannot be imputed under a shared model without strong assumptions.
wide <- stats::reshape(
  miss[miss$stratifier == "Exposure", c("variable", "stratum", "pct_missing")],
  idvar = "variable", timevar = "stratum", direction = "wide")
names(wide) <- gsub("pct_missing.", "", names(wide), fixed = TRUE)
wide$abs_difference <- round(abs(wide[[2]] - wide[[3]]), 2)
wide$assessment <- ifelse(wide$abs_difference > 20,
  "STRUCTURAL / strongly differential -- do NOT impute",
  ifelse(wide$abs_difference > 5, "differential -- impute only with cohort in the model",
         "comparable across arms"))
write_tab(wide, "S26_differential_missingness")
print(wide)

## ---- B. which model inputs are actually missing? ---------------------------
prep <- function(dat) {
  s <- tr(dat, 3); s <- s[!is.na(s$t) & !is.na(s$ev) & s$t > LM, ]; s$t0 <- LM; s
}
s <- prep(a)
adj_vars <- c("age_index", "bmi_index", "sex", "enc_pre12")
miss_n <- vapply(adj_vars, function(v) sum(is.na(s[[v]])), integer(1))
log_msg("missing in adjustment set: ", paste(sprintf("%s=%d", adj_vars, miss_n),
                                             collapse = ", "))

cox_rob <- function(dat, rhs) {
  fit <- survival::coxph(stats::as.formula(paste("Surv(t0, t, ev) ~", rhs)),
                         data = dat, cluster = dat$match_set, robust = TRUE)
  sm <- summary(fit)
  c(n = fit$n, ev = fit$nevent, hr = sm$conf.int[1, 1],
    lo = sm$conf.int[1, 3], hi = sm$conf.int[1, 4])
}

rhs_adj <- "iih + age_index + bmi_index + sex + log1p(enc_pre12)"
cc <- cox_rob(s[stats::complete.cases(s[, adj_vars]), ], rhs_adj)

## Missing-indicator approach. Defensible here ONLY because the missingness is
## a property of the data extract rather than of the patient's clinical state;
## it is biased in general and is reported for comparison, not as preferred.
s2 <- s
for (v in adj_vars) {
  if (miss_n[[v]] > 0 && is.numeric(s2[[v]])) {
    s2[[paste0(v, "_miss")]] <- as.integer(is.na(s2[[v]]))
    s2[[v]][is.na(s2[[v]])] <- stats::median(s2[[v]], na.rm = TRUE)
  }
}
ind_terms <- grep("_miss$", names(s2), value = TRUE)
mi_rhs <- paste(c(rhs_adj, ind_terms), collapse = " + ")
ind <- cox_rob(s2, mi_rhs)

## Multiple imputation, if mice is available AND there is anything to impute.
mi_row <- NULL
if (requireNamespace("mice", quietly = TRUE) && sum(miss_n) > 0) {
  imp_dat <- s[, c("iih", adj_vars, "t0", "t", "ev", "match_set")]
  ## Nelson-Aalen cumulative hazard + event indicator are included so the
  ## imputation model is congenial with a survival outcome model (White & Royston).
  na_est <- survival::basehaz(survival::coxph(Surv(t0, t, ev) ~ 1, data = s))
  imp_dat$nelson_aalen <- stats::approx(na_est$time, na_est$hazard, xout = s$t,
                                        rule = 2)$y
  set.seed(SEED)
  m <- 10
  imp <- mice::mice(imp_dat[, c("iih", adj_vars, "ev", "nelson_aalen")],
                    m = m, printFlag = FALSE, method = "pmm")
  ests <- lapply(seq_len(m), function(i) {
    ci <- mice::complete(imp, i)
    ci$t0 <- s$t0; ci$t <- s$t; ci$ev <- s$ev; ci$match_set <- s$match_set
    fit <- survival::coxph(stats::as.formula(paste("Surv(t0, t, ev) ~", rhs_adj)),
                           data = ci, cluster = ci$match_set, robust = TRUE)
    c(b = unname(stats::coef(fit)[1]), se = sqrt(fit$var[1, 1]))
  })
  B <- vapply(ests, `[`, numeric(1), 1); SE <- vapply(ests, `[`, numeric(1), 2)
  qbar <- mean(B); ubar <- mean(SE^2); bvar <- stats::var(B)
  Tvar <- ubar + (1 + 1 / m) * bvar
  mi_row <- c(n = nrow(s), ev = sum(s$ev), hr = exp(qbar),
              lo = exp(qbar - 1.96 * sqrt(Tvar)), hi = exp(qbar + 1.96 * sqrt(Tvar)))
  log_msg("MI (m=", m, ") complete; FMI-relevant between-imputation variance = ",
          signif(bvar, 3))
}

comp <- rbind(
  data.frame(approach = "Complete case", t(cc)),
  data.frame(approach = "Missing indicator", t(ind)),
  if (!is.null(mi_row)) data.frame(approach = "Multiple imputation (m=10, PMM)", t(mi_row)))
comp$estimate <- fmt_est(comp$hr, comp$lo, comp$hi)
comp$note <- c(
  sprintf("Drops %d of %d rows.", nrow(s) - cc[["n"]], nrow(s)),
  "Biased in general; acceptable here only because missingness is an extract property.",
  if (!is.null(mi_row)) "Imputation model includes the Nelson-Aalen hazard and event indicator so it is congenial with the outcome model.")[seq_len(nrow(comp))]
write_tab(comp[, c("approach", "n", "ev", "estimate", "note")], "T11_missing_data_comparison")
print(comp[, c("approach", "n", "ev", "estimate")])

if (sum(miss_n) == 0) {
  log_msg("NOTE: no missingness in the adjustment set; the three approaches are identical by construction.")
}

saveRDS(list(miss = miss, wide = wide, comp = comp),
        file.path(PATH$derived, "14_missing.rds"))
log_msg("14 complete")
