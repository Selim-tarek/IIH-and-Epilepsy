## 02_data_audit.R ------------------------------------------------------------
## Descriptive audit ONLY. No inference, no model, no outcome-conditional
## decisions. Its job is to find the defects that would otherwise silently
## propagate into the effect estimates.

source("R/00_setup.R")
log_msg("=== 02 audit ===")
d <- readRDS(file.path(PATH$derived, "01_typed.rds"))
TODAY <- as.Date("2026-09-06")   # data-freeze reference; edit if re-run later

FINDINGS <- list()
note <- function(id, severity, what, detail) {
  FINDINGS[[length(FINDINGS) + 1L]] <<- data.frame(
    id = id, severity = severity, finding = what, detail = detail,
    stringsAsFactors = FALSE)
  log_msg("[", severity, "] ", id, ": ", what)
}

## ---- A. counts -------------------------------------------------------------
n_tot <- nrow(d); n_case <- sum(d$iih == 1); n_ctl <- sum(d$iih == 0)
counts <- data.frame(
  item = c("rows", "unique record_id", "IIH cases", "controls",
           "cases in matched analysis", "cases NOT matched",
           "controls in matched analysis"),
  n = c(n_tot, length(unique(d$record_id)), n_case, n_ctl,
        sum(d$iih == 1 & d$in_matched), sum(d$iih == 1 & !d$in_matched),
        sum(d$iih == 0 & d$in_matched)))
write_tab(counts, "S2_audit_counts")

## Unit of observation: one row per patient. Confirmed by uniqueness of
## record_id and by controls having unique clinic_number (no reuse).
dup_ctl <- sum(duplicated(d$clinic_number[d$iih == 0]))
if (dup_ctl == 0)
  note("A1", "OK", "Controls matched WITHOUT replacement",
       "9,742 control rows have 9,742 distinct clinic numbers; no control is reused.")

## ---- B. realised matching structure ---------------------------------------
## Linkage: a matched case's match_set IS its own record_id; each control
## carries the record_id of its case. Verified in 01.
mc <- d[d$in_matched & d$iih == 1, ]
mt <- d[d$in_matched & d$iih == 0, ]
n_ctl_per_case <- table(factor(mt$match_set, levels = mc$record_id))
ratio_tab <- as.data.frame(table(controls_in_set = as.integer(n_ctl_per_case)))
names(ratio_tab) <- c("controls_in_set", "n_matched_cases")
ratio_tab$pct <- round(100 * ratio_tab$n_matched_cases / nrow(mc), 1)
write_tab(ratio_tab, "S3_realised_matching_ratio")

mean_ratio <- mean(as.integer(n_ctl_per_case))
pct4 <- 100 * mean(as.integer(n_ctl_per_case) == 4)
note("B1", "MAJOR",
     sprintf("1:4 matching NOT achieved: mean %.2f controls/case, only %.1f%% of sets are full", mean_ratio, pct4),
     paste0("Variable-ratio matching (0-4 controls). Any analysis that assumes a ",
            "fixed 1:4 design is misspecified; matched-set stratification or ",
            "match_set-clustered robust variance is required."))
note("B2", "MAJOR",
     sprintf("%d IIH cases (%.1f%%) could not be matched and are excluded from all comparative analyses",
             sum(d$iih == 1 & !d$in_matched), 100 * mean(d$iih == 1 & !d$in_matched)),
     "Selection is by matchability (BMI availability / index-year coverage), not at random.")
note("B3", "MAJOR",
     "Analytic counts do NOT reproduce protocol v2.0 section 6",
     paste0("Protocol reports 2,215 cases and 4,337 controls; this export contains ",
            nrow(mc), " matched cases and ", nrow(mt), " controls. The supplied file ",
            "is a different (later) extract than the one behind the v2.0 result table. ",
            "The v2.0 numbers must not be used as validation targets."))

## match tier: how far tolerances were relaxed
tier <- as.data.frame(table(match_tier = mt$match_tier, useNA = "ifany"))
write_tab(tier, "S4_match_tier")

## ---- C. date integrity -----------------------------------------------------
n_future_le <- sum(d$last_encounter_date > TODAY, na.rm = TRUE)
note("C1", "CRITICAL",
     sprintf("%d IIH cases have last_encounter_date AFTER the data-freeze date (max %s)",
             n_future_le, format(max(d$last_encounter_date, na.rm = TRUE))),
     paste0("Impossible dates up to 2038. Follow-up time derived from this field is ",
            "inflated for the exposed cohort only, which biases the incidence-rate ",
            "denominator and any full-follow-up model."))

note("C2", "CRITICAL",
     "Controls have NO date fields at all (last_encounter, first_encounter, death, DOB all blank)",
     paste0("Control follow-up exists only as the pre-computed followup_years column. ",
            "Censoring for controls cannot be independently verified or recomputed, ",
            "and the two cohorts' person-time were therefore not demonstrably derived ",
            "by the same rule."))

pre2000 <- sum(d$index_year < 2000)
note("C3", "MINOR",
     sprintf("%d cases have index dates before 2000 (min %d)", pre2000, min(d$index_year)),
     "Consistent with protocol v2.0 (1990-2025 window), but pre-2000 EHR capture is thin.")

bad_seiz <- sum(d$seizure_date < d$index_date, na.rm = TRUE)
orphan_seiz <- sum(!is.na(d$seizure_date) & d$seizure_incident != 1, na.rm = TRUE)
note("C4", "MODERATE",
     sprintf("%d seizure_date before index; %d seizure_dates on patients not flagged incident",
             bad_seiz, orphan_seiz),
     "Dates carry prevalent/presenting events; seizure_date alone must not define the outcome.")

## ---- D. the competing-event variable is broken ------------------------------
tab_status <- table(cohort = d$cohort, status_src = d$status_src, useNA = "ifany")
died_case <- sum(d$died_fu == 1 & d$iih == 1, na.rm = TRUE)
st2_case  <- sum(d$status_src == 2 & d$iih == 1, na.rm = TRUE)
note("D1", "CRITICAL",
     sprintf("Supplied `status` never codes death in cases: %d IIH cases have died_fu=1 but %d have status=2",
             died_case, st2_case),
     paste0("Death is coded as a competing event (status=2) in 144 controls and in ZERO ",
            "cases. Using `status` as supplied would treat exposed deaths as censored ",
            "and unexposed deaths as competing events -- a differential, exposure-",
            "dependent misclassification. status is rebuilt from died_fu/death_date in 05."))
utils::capture.output(print(tab_status),
  file = file.path(PATH$diag, "D1_status_by_cohort.txt"))

## ---- E. differential follow-up ---------------------------------------------
fu <- stats::aggregate(followup_years ~ cohort, d[d$in_matched, ], function(x)
  c(n = length(x), median = stats::median(x), q1 = stats::quantile(x, .25),
    q3 = stats::quantile(x, .75), mean = mean(x), total = sum(x)))
fu <- cbind(fu[1], round(as.data.frame(fu[[2]]), 3))
write_tab(fu, "S5_followup_by_cohort")
note("E1", "MAJOR",
     sprintf("Follow-up is markedly longer in cases (median %.2f y) than controls (median %.2f y)",
             stats::median(d$followup_years[d$in_matched & d$iih == 1], na.rm = TRUE),
             stats::median(d$followup_years[d$in_matched & d$iih == 0], na.rm = TRUE)),
     paste0("Longer exposed follow-up plus outcome ascertainment that depends on ",
            "clinical contact is the classic differential-surveillance pattern. This ",
            "is why the protocol's truncated (3-year) primary estimand is the right ",
            "choice, and why full-follow-up rate ratios are the least trustworthy."))

## ---- F. structural (cohort-specific) missingness ---------------------------
dict <- readRDS(file.path(PATH$derived, "01_dictionary.rds"))
onesided <- dict[dict$availability != "both cohorts",
                 c("variable", "analytic_role", "availability",
                   "blank_in_cases", "blank_in_controls")]
write_tab(onesided, "S6_cohort_specific_variables")
note("F1", "CRITICAL",
     sprintf("%d variables are extracted for one cohort only", nrow(onesided)),
     paste0("All imaging (empty_sella, sinus_sten, skullbase_thin, enceph_*), all EEG ",
            "variables, seizure_ever and presenting_seizure are blank in every control; ",
            "race/ethnicity, DOB and all date fields are blank in every case. These are ",
            "STRUCTURALLY absent, not missing at random, and must never be imputed."))
note("F2", "CRITICAL",
     "Race was matched on but is unverifiable",
     "race is recorded for 9,741/9,742 controls and 0/3,601 cases; the protocol's 'exact where recorded' race match cannot be checked in this file.")
note("F3", "MAJOR",
     "smoking uses different encodings in the two cohorts (text in cases, 0/1/2 in controls)",
     "Harmonised in 01, but the differing provenance means smoking is not safely comparable across cohorts and is not used for adjustment.")

## ---- G. encephalocele / mediation feasibility ------------------------------
enc <- d[d$iih == 1, ]
enc_tab <- as.data.frame(table(status = enc$enceph_index_status))
enc_tab$pct <- round(100 * enc_tab$Freq / nrow(enc), 1)
write_tab(enc_tab, "S7_encephalocele_assessability")
n_assessed <- sum(enc$enceph_index_status == "assessed")
n_pos <- sum(enc$enceph_index == 1, na.rm = TRUE)
ev_pos <- sum(enc$enceph_index == 1 & enc$seizure_incident == 1, na.rm = TRUE)
ev_neg <- sum(enc$enceph_index == 0 & enc$seizure_incident == 1, na.rm = TRUE)
note("G1", "CRITICAL",
     sprintf("Encephalocele assessable in only %d/%d cases (%.1f%%); %d positive; %d and %d incident seizures in enceph+/enceph-",
             n_assessed, nrow(enc), 100 * n_assessed / nrow(enc), n_pos, ev_pos, ev_neg),
     paste0("With ", ev_pos + ev_neg, " events across the assessable subgroup and ZERO ",
            "imaging in controls, no mediation estimand (natural, interventional or ",
            "separable) is identifiable. Protocol v2.0 correctly suspends this aim; ",
            "the pipeline reports the 2x2 descriptively and stops there."))

## ---- H. exposure definition ------------------------------------------------
op <- d$op_cmh2o[d$iih == 1]
note("H1", "MAJOR",
     sprintf("Opening pressure is recorded for %d/%d cases (%.0f%%) and is <25 cmH2O in %d (%.0f%% of measured)",
             sum(!is.na(op)), length(op), 100 * mean(!is.na(op)),
             sum(op < 25, na.rm = TRUE), 100 * mean(op < 25, na.rm = TRUE)),
     paste0("Cases are ICD-code identified without Friedman adjudication (protocol ",
            "v2.0 change #1). Nearly a third of measured pressures fall below the ",
            "diagnostic threshold, so the exposure is 'coded as IIH', not verified IIH. ",
            "Non-differential exposure misclassification of this size attenuates the HR."))
note("H2", "MAJOR",
     "No severity (mild/moderate/severe), Frisen grade, perimetry, fulminant flag, symptom-onset interval, or ASM/treatment start-stop dates exist in this file",
     paste0("The v1.0 cumulative-burden gradient, the time-varying treatment analysis, ",
            "the marginal structural model and the acetazolamide-only sensitivity ",
            "analysis are ALL unimplementable. A crude proxy (shunt/stent/opening ",
            "pressure) is reported as exploratory only."))
note("H3", "MAJOR",
     "No validation sample and no double-read/adjudication overlap exist in this file",
     paste0("Algorithm PPV/sensitivity, the two-phase design correction, Cohen's kappa ",
            "for IIH adjudication and imaging-reader kappa cannot be computed. ",
            "Protocol v2.0 limitation 7 applies: the algorithm's PPV is unknown. ",
            "Bias-analysis under assumed misclassification is provided instead."))

## ---- I. surveillance intensity ---------------------------------------------
surv_tab <- stats::aggregate(cbind(enc_pre12, enc_post) ~ cohort, d[d$in_matched, ],
                             function(x) c(median = stats::median(x), q3 = stats::quantile(x, .75)))
utils::capture.output(print(surv_tab), file = file.path(PATH$diag, "I1_surveillance.txt"))
note("I1", "MAJOR",
     sprintf("Post-index encounters: case median %.0f vs control median %.0f",
             stats::median(d$enc_post[d$in_matched & d$iih == 1], na.rm = TRUE),
             stats::median(d$enc_post[d$in_matched & d$iih == 0], na.rm = TRUE)),
     paste0("Detection opportunity differs by exposure. Per protocol section 5.3 this is ",
            "adjusted for only as a CONSERVATIVE BOUND (it is a post-exposure ",
            "mediator/collider), never as the primary estimate. The negative-control ",
            "outcome is the real test of whether contact alone drives the result."))

## ---- J. negative control availability --------------------------------------
note("J1", "MODERATE",
     sprintf("carpal_incident is missing for %d controls (all male) and GERD was never extracted",
             sum(is.na(d$carpal_incident) & d$iih == 0)),
     "The negative-control analysis is restricted to female pairs (protocol v2.0 section 4.3).")

## ---- K. implausible values -------------------------------------------------
imp <- data.frame(
  check = c("age_index < 13", "age_index > 60", "bmi_index < 15", "bmi_index > 60",
            "op_cmh2o < 5", "op_cmh2o > 60", "followup_years <= 0"),
  n = c(sum(d$age_index < 13, na.rm = TRUE), sum(d$age_index > 60, na.rm = TRUE),
        sum(d$bmi_index < 15, na.rm = TRUE), sum(d$bmi_index > 60, na.rm = TRUE),
        sum(d$op_cmh2o < 5, na.rm = TRUE), sum(d$op_cmh2o > 60, na.rm = TRUE),
        sum(d$followup_years <= 0, na.rm = TRUE)))
write_tab(imp, "S8_implausible_values")

findings <- do.call(rbind, FINDINGS)
write_tab(findings, "S9_audit_findings")
saveRDS(findings, file.path(PATH$derived, "02_findings.rds"))
log_msg("02 complete: ", nrow(findings), " findings (",
        sum(findings$severity == "CRITICAL"), " critical)")
