## 11_tables.R ----------------------------------------------------------------
## Assembles the manuscript tables. All component CSVs are already written by
## the analysis scripts; this script produces the combined, labelled versions
## and a manifest so every number in the report is traceable to a file.

source("R/00_setup.R")
log_msg("=== 11 tables ===")

pr  <- readRDS(file.path(PATH$derived, "06_primary.rds"))
sec <- readRDS(file.path(PATH$derived, "07_secondary.rds"))
sn  <- readRDS(file.path(PATH$derived, "08_sens.rds"))

## Table 4: primary and competing-risk models in one place.
t4 <- rbind(
  data.frame(section = "Cox models", quantity = pr$models$model,
             n = pr$models$n, events = pr$models$events,
             estimate = pr$models$estimate, p = fmt_p(pr$models$p)),
  data.frame(section = "Competing risk (3 y)", quantity = pr$cr$estimand,
             n = NA, events = NA, estimate = pr$cr$estimate, p = NA),
  data.frame(section = "Absolute risk (3 y)",
             quantity = c("IIH cumulative incidence, %", "Control cumulative incidence, %",
                          pr$rd$measure, "Number needed to harm"),
             n = NA, events = NA,
             estimate = c(sprintf("%.2f", pr$rd$iih_risk_pct),
                          sprintf("%.2f", pr$rd$control_risk_pct),
                          fmt_est(pr$rd$estimate, pr$rd$lo, pr$rd$hi),
                          as.character(pr$rd$number_needed_to_harm)), p = NA),
  data.frame(section = "Unmeasured confounding", quantity = pr$evalue$quantity,
             n = NA, events = NA, estimate = sprintf("%.2f", pr$evalue$value), p = NA))
write_tab(t4, "T4_primary_models_combined")

## Table 7: what the protocol asked for on validation and reliability, and why
## none of it is computable from this export. Reporting the absence explicitly
## is the honest substitute for reporting a number.
t7 <- data.frame(
  planned_analysis = c(
    "Algorithm positive predictive value",
    "Algorithm sensitivity (2-phase corrected)",
    "Confusion matrix vs blinded chart review",
    "Cohen's kappa, IIH adjudication (20% overlap)",
    "Weighted kappa, imaging double-read (15%)",
    "Calibration of the outcome algorithm"),
  required_input = c(
    "Blinded review of all algorithm-positive records",
    "Blinded review of a random sample of 200 algorithm-negative records",
    "Both of the above, with sampling fractions",
    "Two independent adjudications on 20% of cases",
    "Two independent image reads on 15% of scans",
    "Predicted probabilities plus a validated reference standard"),
  status = "NOT COMPUTABLE FROM THIS EXPORT",
  reason = c(
    rep("Protocol v2.0 change #7 descoped blinded chart confirmation; no review results are present.", 3),
    "Protocol v2.0 change #1 dropped Friedman adjudication; there is no second reader.",
    "Protocol v2.0 change #8 suspended the imaging aim; there is no double-read sample.",
    "No reference standard exists against which to calibrate."),
  consequence = c(
    rep("The PPV of the outcome algorithm is unknown (protocol limitation 7). Bias analysis under assumed misclassification is provided instead (T6c).", 3),
    "Exposure is 'coded as IIH', not verified IIH; misclassification is likely non-differential and attenuating.",
    "Encephalocele status cannot support any inference.",
    "No calibration claim is made."))
write_tab(t7, "T7_validation_and_reliability")

## Manifest: which file backs which claim.
manifest <- data.frame(
  table = c("T1", "T2", "T3", "T4", "T4b", "T4c", "T4d", "T4e", "T5a", "T5b",
            "T5c", "T5d", "T5e", "T6", "T6b", "T6c", "T7"),
  contents = c("Baseline characteristics and SMDs", "Cohort flow",
               "Incidence rates with exact Poisson CIs", "Primary models combined",
               "Cause-specific and Fine-Gray", "Cumulative incidence",
               "Risk difference and NNH", "E-value",
               "Negative control outcome", "Time-split hazard",
               "EEG descriptive (IIH only)", "Exploratory within-IIH",
               "Encephalocele descriptive", "Sensitivity analyses",
               "Tipping point", "Outcome misclassification bias analysis",
               "Validation and reliability (not computable)"),
  file = paste0(c("T1_baseline_balance", "T2_cohort_flow", "T3_incidence_rates",
                  "T4_primary_models_combined", "T4b_competing_risk",
                  "T4c_cumulative_incidence", "T4d_risk_difference", "T4e_evalue",
                  "T5a_negative_control", "T5b_time_split", "T5c_eeg_descriptive",
                  "T5d_exploratory_within_iih", "T5e_encephalocele_descriptive",
                  "T6_sensitivity_analyses", "T6b_tipping_point",
                  "T6c_outcome_misclassification", "T7_validation_and_reliability"), ".csv"))
write_tab(manifest, "T0_table_manifest")
log_msg("11 complete")
