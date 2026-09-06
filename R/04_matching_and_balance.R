## 04_matching_and_balance.R --------------------------------------------------
## Verifies the realised match (not the intended one) and quantifies balance
## with standardised mean differences rather than p-values, which are a
## function of sample size and are meaningless in a matched design.

source("R/00_setup.R")
log_msg("=== 04 matching & balance ===")
d <- readRDS(file.path(PATH$derived, "01_typed.rds"))
m <- d[d$in_matched, ]

## ---- within-pair verification of the stated tolerances ---------------------
## Sex exact; age +/-3 y; BMI +/-3 kg/m2 (relaxable per match_tier).
cases <- m[m$iih == 1, c("record_id", "sex", "age_index", "bmi_index", "index_year")]
names(cases) <- paste0("case_", names(cases))
mm <- merge(m[m$iih == 0, ], cases, by.x = "match_set", by.y = "case_record_id")
mm$d_age <- mm$age_index - mm$case_age_index
mm$d_bmi <- mm$bmi_index - mm$case_bmi_index
mm$d_year<- mm$index_year - mm$case_index_year

tol <- data.frame(
  criterion = c("Sex exact", "|age difference| <= 3 y", "|BMI difference| <= 3 kg/m2",
                "|index-year difference| <= 2 (female sets only)"),
  n_pairs_evaluable = c(sum(!is.na(mm$sex) & !is.na(mm$case_sex)),
                        sum(!is.na(mm$d_age)), sum(!is.na(mm$d_bmi)),
                        sum(!is.na(mm$d_year) & mm$case_sex == "F")),
  n_satisfied = c(sum(mm$sex == mm$case_sex, na.rm = TRUE),
                  sum(abs(mm$d_age) <= 3, na.rm = TRUE),
                  sum(abs(mm$d_bmi) <= 3, na.rm = TRUE),
                  sum(abs(mm$d_year) <= 2 & mm$case_sex == "F", na.rm = TRUE)))
tol$pct_satisfied <- round(100 * tol$n_satisfied / tol$n_pairs_evaluable, 1)
write_tab(tol, "S12_matching_tolerance_check")
log_msg("sex exact: ", tol$pct_satisfied[1], "% | age +/-3: ", tol$pct_satisfied[2],
        "% | BMI +/-3: ", tol$pct_satisfied[3], "%")

## Index year is inherited by construction, so a control's own index_year is
## the case's; the year tolerance refers to the BMI MEASUREMENT year, which is
## not in this export. Recorded as unverifiable rather than as a pass.
saveRDS(mm[, c("match_set", "record_id", "d_age", "d_bmi", "sex", "case_sex")],
        file.path(PATH$derived, "04_pair_diffs.rds"))

## ---- balance table with SMDs ----------------------------------------------
bal_rows <- list()
add_cont <- function(var, label, data = m) {
  x <- data[[var]]; g <- data$iih
  bal_rows[[label]] <<- data.frame(
    variable = label, type = "continuous",
    iih = sprintf("%.1f (%.1f)", mean(x[g == 1], na.rm = TRUE), stats::sd(x[g == 1], na.rm = TRUE)),
    control = sprintf("%.1f (%.1f)", mean(x[g == 0], na.rm = TRUE), stats::sd(x[g == 0], na.rm = TRUE)),
    n_missing_iih = sum(is.na(x[g == 1])), n_missing_control = sum(is.na(x[g == 0])),
    smd = round(smd_cont(x, g), 3), stringsAsFactors = FALSE)
}
add_bin <- function(var, label, data = m, positive = 1) {
  x <- as.numeric(data[[var]] == positive); g <- data$iih
  bal_rows[[label]] <<- data.frame(
    variable = label, type = "binary",
    iih = sprintf("%d (%.1f%%)", sum(x[g == 1], na.rm = TRUE), 100 * mean(x[g == 1], na.rm = TRUE)),
    control = sprintf("%d (%.1f%%)", sum(x[g == 0], na.rm = TRUE), 100 * mean(x[g == 0], na.rm = TRUE)),
    n_missing_iih = sum(is.na(x[g == 1])), n_missing_control = sum(is.na(x[g == 0])),
    smd = round(smd_bin(x, g), 3), stringsAsFactors = FALSE)
}
add_cont("age_index", "Age at index, y")
add_cont("bmi_index", "BMI at index, kg/m2")
add_bin("sex", "Female", positive = "F")
add_cont("index_year", "Index year")
add_bin("osa", "Obstructive sleep apnoea (coded)")
add_bin("htn", "Hypertension (coded)")
add_bin("pcos", "PCOS (coded)")
add_cont("enc_pre12", "Encounters, 12 mo before index")
add_cont("enc_post", "Encounters after index (POST-EXPOSURE)")
add_cont("followup_years", "Follow-up, y (POST-EXPOSURE)")

bal <- do.call(rbind, bal_rows)
bal$balance <- ifelse(is.na(bal$smd), NA,
               ifelse(abs(bal$smd) < 0.1, "balanced (|SMD|<0.1)", "IMBALANCED"))
## Mark the variables that are consequences of exposure: they are shown for
## transparency but balance on them is neither expected nor desirable.
bal$note <- ifelse(grepl("POST-EXPOSURE", bal$variable),
                   "post-index; not a matching target; imbalance expected", "")
write_tab(bal, "T1_baseline_balance")
print(bal[, c("variable", "iih", "control", "smd", "balance")])

## ---- propensity score for diagnostics and IPTW (protocol s5.2) -------------
## Fitted on MATCHED covariates only. A c-statistic near 0.5 confirms the match;
## it does not mean unmeasured confounding is absent.
ps_dat <- m[stats::complete.cases(m[, c("age_index", "bmi_index", "sex", "index_year")]), ]
ps_fit <- stats::glm(iih ~ age_index + bmi_index + sex + index_year,
                     family = stats::binomial, data = ps_dat)
ps_dat$ps <- stats::fitted(ps_fit)
cstat <- {
  r <- rank(ps_dat$ps); n1 <- sum(ps_dat$iih == 1); n0 <- sum(ps_dat$iih == 0)
  (sum(r[ps_dat$iih == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}
## Stabilised IPTW, trimmed at the 1st/99th percentile to control variance.
p_marg <- mean(ps_dat$iih)
ps_dat$iptw <- ifelse(ps_dat$iih == 1, p_marg / ps_dat$ps, (1 - p_marg) / (1 - ps_dat$ps))
qtr <- stats::quantile(ps_dat$iptw, c(.01, .99))
ps_dat$iptw_trim <- pmin(pmax(ps_dat$iptw, qtr[1]), qtr[2])

ps_summary <- data.frame(
  metric = c("c-statistic (AUC)", "n in PS model", "median stabilised weight",
             "max stabilised weight (untrimmed)", "trim bounds (1st, 99th pct)"),
  value = c(sprintf("%.3f", cstat), nrow(ps_dat),
            sprintf("%.3f", stats::median(ps_dat$iptw)),
            sprintf("%.2f", max(ps_dat$iptw)),
            sprintf("%.3f, %.3f", qtr[1], qtr[2])))
write_tab(ps_summary, "S13_propensity_diagnostics")
log_msg("PS c-statistic = ", sprintf("%.3f", cstat))

saveRDS(ps_dat[, c("record_id", "ps", "iptw", "iptw_trim")],
        file.path(PATH$derived, "04_ps.rds"))
saveRDS(bal, file.path(PATH$derived, "04_balance.rds"))
log_msg("04 complete")
