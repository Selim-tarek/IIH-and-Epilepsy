## 01_import_and_dictionary.R -------------------------------------------------
## Reads the raw export EXACTLY as character, builds the typed analytic frame,
## and generates a data dictionary from the file itself (not from assumptions
## about what the column names mean).
##
## Raw data is opened read-only and never written back.

source("R/00_setup.R")
log_msg("=== 01 import ===")

assert(file.exists(PATH$raw), paste("raw file not found:", PATH$raw))

## Read everything as character so that no sentinel (88/99) is silently
## coerced, and no ID is mangled by type guessing.
raw <- utils::read.csv(PATH$raw, colClasses = "character", check.names = FALSE,
                       na.strings = NULL, encoding = "UTF-8")
names(raw) <- sub("^﻿", "", names(raw))
log_msg("raw: ", nrow(raw), " rows x ", ncol(raw), " cols")

## ---- analytic role assignment ----------------------------------------------
## Roles drive both the dictionary and what each analysis is permitted to use.
ROLE <- c(
  record_id = "id", clinic_number = "id", match_set = "id",
  group = "exposure", group_label = "exposure",
  in_matched_analysis = "design", match_tier = "design",
  index_date = "design", dob = "design",
  sex = "matching", age_index = "matching", bmi_index = "matching",
  race = "matching", ethnicity = "matching",
  osa = "confounder", htn = "confounder", pcos = "confounder",
  smoking = "confounder", alcohol = "confounder", pregnant_index = "confounder",
  op_cmh2o = "severity", op_first_lp = "severity", op_max = "severity",
  shunt = "severity/treatment", stent = "severity/treatment",
  bariatric = "treatment", bariatric_date = "treatment",
  enceph_index = "mediator", enceph_side = "mediator", enceph_site = "mediator",
  empty_sella = "imaging", globe_flat = "imaging", onsd_distend = "imaging",
  sinus_sten = "imaging", skullbase_thin = "imaging", csf_leak = "imaging",
  mrv_done = "imaging", mri_brain_ever = "imaging",
  mri_brain_first_date = "imaging", mri_brain_n = "imaging/surveillance",
  eeg_done = "outcome-support", eeg_epileptiform = "outcome-support",
  eeg_side = "outcome-support", temporal_onset = "outcome-support",
  concordant = "outcome-support",
  seizure_ever = "outcome", seizure_incident = "outcome",
  seizure_date = "outcome", presenting_seizure = "outcome",
  outcome_criterion = "outcome", seizure_latency_days = "outcome",
  pnes_ever = "outcome", carpal_incident = "negative-control",
  excl_prior_seizure = "eligibility", excl_prior_asm = "eligibility",
  followup_years = "time", t5 = "time", ev5 = "outcome", status = "outcome",
  died_fu = "competing", death_date = "competing",
  last_encounter_date = "censoring", first_encounter_date = "censoring",
  enc_pre12 = "surveillance", enc_post = "surveillance",
  n_encounters_total = "surveillance"
)

## ---- typed analytic frame --------------------------------------------------
d <- data.frame(row.names = seq_len(nrow(raw)))

d$record_id     <- chr_clean(raw$record_id)
d$clinic_number <- chr_clean(raw$clinic_number)
d$match_set     <- chr_clean(sub("\\.0$", "", raw$match_set))

## Exposure. group: 1 = IIH (ICD-coded, NOT Friedman-adjudicated -- protocol
## v2.0 change #1), 0 = non-IIH matched control.
d$iih    <- num_raw(raw$group)
d$cohort <- factor(ifelse(d$iih == 1, "IIH", "Non-IIH control"),
                   levels = c("Non-IIH control", "IIH"))
d$in_matched <- num_raw(raw$in_matched_analysis) == 1
d$match_tier <- chr_clean(raw$match_tier)

## Dates
d$index_date          <- date_clean(raw$index_date)
d$dob                 <- date_clean(raw$dob)
d$seizure_date        <- date_clean(raw$seizure_date)
d$death_date          <- date_clean(raw$death_date)
d$last_encounter_date <- date_clean(raw$last_encounter_date)
d$first_encounter_date<- date_clean(raw$first_encounter_date)
d$mri_brain_first_date<- date_clean(raw$mri_brain_first_date)
d$bariatric_date      <- date_clean(raw$bariatric_date)

## Matching covariates
d$sex       <- factor(chr_clean(raw$sex), levels = c("F", "M"))
d$age_index <- num_clean(raw$age_index)
d$bmi_index <- num_clean(raw$bmi_index)
d$race      <- chr_clean(raw$race)
d$ethnicity <- chr_clean(raw$ethnicity)
d$index_year<- as.integer(format(d$index_date, "%Y"))

## Comorbidity. These are 0/1 with no sentinel in this export; a 0 therefore
## means "no code found", which is not the same as "absent". Flagged in audit.
for (v in c("osa", "htn", "pcos")) d[[v]] <- num_clean(raw[[v]])

## smoking is encoded DIFFERENTLY in the two groups (text in cases, 0/1/2 in
## controls). Harmonised to a common factor; the mismatch is reported in the
## audit because it makes smoking non-comparable across cohorts.
smoke_raw <- chr_clean(raw$smoking)
d$smoking <- factor(dplyr_case <- ifelse(
  smoke_raw %in% c("Never", "0.0", "0"), "Never",
  ifelse(smoke_raw %in% c("Former", "2.0", "2"), "Former",
  ifelse(smoke_raw %in% c("Current", "1.0", "1"), "Current",
  ifelse(smoke_raw == "Unknown", "Unknown", NA_character_)))),
  levels = c("Never", "Former", "Current", "Unknown"))
d$smoking_src <- ifelse(smoke_raw %in% c("0.0","1.0","2.0","0","1","2"),
                        "numeric_extract", ifelse(is.na(smoke_raw), NA, "text_extract"))
d$alcohol <- chr_clean(raw$alcohol)

## Severity / treatment
d$op_cmh2o    <- num_clean(raw$op_cmh2o)
d$op_first_lp <- num_clean(raw$op_first_lp)
d$op_max      <- num_clean(raw$op_max)
d$shunt     <- num_clean(raw$shunt)
d$stent     <- num_clean(raw$stent)
d$bariatric <- num_clean(raw$bariatric)

## Imaging / mediator. Sentinels are kept as separate indicator columns so that
## "not assessable" (88) can never be read as "negative" (0).
sentinel_split <- function(x, name) {
  r <- num_raw(x); ch <- chr_clean(x)
  out <- list()
  out[[name]]                    <- ifelse(r %in% c(0, 1, 2, 3, 4, 5) , r, NA_real_)
  out[[paste0(name, "_status")]] <- factor(ifelse(
    is.na(ch), "not_extracted",
    ifelse(r == MISS_NOTAPPLIC, "not_assessable",
    ifelse(r == MISS_UNKNOWN,   "unknown_after_search", "assessed"))),
    levels = c("assessed", "unknown_after_search", "not_assessable", "not_extracted"))
  out
}
for (v in c("enceph_index", "enceph_side", "enceph_site", "empty_sella",
            "globe_flat", "onsd_distend", "sinus_sten", "skullbase_thin",
            "csf_leak", "mrv_done", "eeg_done", "eeg_epileptiform", "eeg_side",
            "temporal_onset", "concordant")) {
  d[names(sentinel_split(raw[[v]], v))] <- sentinel_split(raw[[v]], v)
}
d$mri_brain_ever <- num_clean(raw$mri_brain_ever)
d$mri_brain_n    <- num_clean(raw$mri_brain_n)

## Outcomes
d$seizure_ever         <- num_clean(raw$seizure_ever)
d$seizure_incident     <- num_clean(raw$seizure_incident)
d$presenting_seizure   <- num_clean(raw$presenting_seizure)
d$outcome_criterion    <- num_clean(raw$outcome_criterion)   # 1 = two codes; 2 = code+ASM
d$seizure_latency_days <- num_clean(raw$seizure_latency_days)
d$pnes_ever            <- num_clean(raw$pnes_ever)
d$carpal_incident      <- num_clean(raw$carpal_incident)

## Eligibility flags (as supplied)
d$excl_prior_seizure <- num_clean(raw$excl_prior_seizure)
d$excl_prior_asm     <- num_clean(raw$excl_prior_asm)

## Time / competing event
d$followup_years <- num_clean(raw$followup_years)
d$t5             <- num_clean(raw$t5)
d$ev5            <- num_clean(raw$ev5)
d$status_src     <- num_clean(raw$status)   # AS SUPPLIED -- see audit, do not use
d$died_fu        <- num_clean(raw$died_fu)

## Surveillance intensity
d$enc_pre12          <- num_clean(raw$enc_pre12)
d$enc_post           <- num_clean(raw$enc_post)
d$n_encounters_total <- num_clean(raw$n_encounters_total)

## ---- structural assertions -------------------------------------------------
assert(!any(duplicated(d$record_id)), "record_id is not unique")
assert(all(d$iih %in% c(0, 1)), "group is not 0/1")
assert(all(!is.na(d$index_date)), "missing index_date")
assert(all(d$match_set[d$in_matched & d$iih == 1] ==
             d$record_id[d$in_matched & d$iih == 1], na.rm = TRUE),
       "matched cases: match_set does not equal own record_id")

log_msg("typed frame: ", nrow(d), " x ", ncol(d))

## ---- data dictionary generated FROM THE FILE -------------------------------
dict <- do.call(rbind, lapply(names(raw), function(v) {
  x  <- trimws(raw[[v]]); nr <- num_raw(x)
  vals <- x[x != "" & !(nr %in% c(MISS_UNKNOWN, MISS_NOTAPPLIC))]
  uv <- unique(vals)
  data.frame(
    variable        = v,
    analytic_role   = if (!is.na(ROLE[v])) ROLE[v] else "unassigned",
    storage_raw     = "character (as read)",
    inferred_type   = if (grepl("date", v)) "date"
                      else if (all(!is.na(suppressWarnings(as.numeric(uv)))) && length(uv))
                        "numeric" else "categorical/text",
    n_nonblank      = sum(x != ""),
    n_blank_structural = sum(x == ""),
    n_code_99_unknown  = sum(nr == MISS_UNKNOWN, na.rm = TRUE),
    n_code_88_na       = sum(nr == MISS_NOTAPPLIC, na.rm = TRUE),
    n_distinct_values  = length(uv),
    example_values     = paste(utils::head(uv, 5), collapse = " | "),
    blank_in_cases     = sum(x[d$iih == 1] == ""),
    blank_in_controls  = sum(x[d$iih == 0] == ""),
    stringsAsFactors = FALSE)
}))
## Flag variables that exist for one cohort only -- these can never support a
## case-control comparison, only within-cohort description.
dict$availability <- with(dict, ifelse(
  blank_in_cases == sum(d$iih == 1) & blank_in_controls < sum(d$iih == 0), "CONTROLS ONLY",
  ifelse(blank_in_controls == sum(d$iih == 0) & blank_in_cases < sum(d$iih == 1),
         "CASES ONLY", "both cohorts")))

write_tab(dict, "S1_data_dictionary")

saveRDS(d,    file.path(PATH$derived, "01_typed.rds"))
saveRDS(dict, file.path(PATH$derived, "01_dictionary.rds"))
log_msg("01 complete")
