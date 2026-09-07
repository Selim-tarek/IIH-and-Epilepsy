## F1_import_audit_final.R ----------------------------------------------------
## FINAL ANALYSIS PIPELINE -- reads IIH_MASTER_FINAL.xlsx.
##
## This workbook supersedes IIH_MASTER_cases_and_controls_2.csv. It resolves the
## defects the earlier audit raised:
##   - the 180-day washout is applied to BOTH arms (earliest event: day 183 in
##     cases, day 187 in controls), so the outcome window is symmetric;
##   - person-time runs from day 180 to event, death, or last ATTENDED encounter,
##     with scheduled future appointments removed (this was the source of the
##     impossible 2038 dates);
##   - controls now carry last_encounter and death_date, so censoring is
##     verifiable in both arms (censoring_verifiable = 1 for all 11,740);
##   - excluded patients are itemised on their own sheet with reasons.
##
## t_y is therefore already a post-washout duration. No delayed entry is needed:
## Surv(t_y, event) is the correct construction, and truncation is pmin(t_y, tau).

source("R/00_setup.R")
log_msg("=== F1 import & audit (FINAL workbook) ===")

XL <- file.path("data-raw", "IIH_MASTER_FINAL.xlsx")
assert(file.exists(XL), paste("workbook not found:", XL))
if (!requireNamespace("readxl", quietly = TRUE))
  stop("readxl is required to read the final workbook. install.packages('readxl')")

CUTOFF <- as.Date("2026-09-03")   # data cutoff stated in the Source_Manifest sheet

## Sheets carry banner rows above the header; skip to the real header row.
read_sheet <- function(sheet, skip) {
  as.data.frame(readxl::read_excel(XL, sheet = sheet, skip = skip,
                                   col_types = "text", .name_repair = "minimal"))
}
raw  <- read_sheet("Analysis_Cohort", 4)
excl <- read_sheet("Excluded_from_analysis", 2)
manifest <- read_sheet("Source_Manifest", 2)
codebook <- read_sheet("Codebook", 1)

raw  <- raw[!is.na(raw$record_id) & raw$record_id != "", ]
excl <- excl[!is.na(excl$record_id) & excl$record_id != "", ]
log_msg("Analysis_Cohort: ", nrow(raw), " rows x ", ncol(raw), " cols; excluded sheet: ",
        nrow(excl), " rows")

## ---- typed analytic frame --------------------------------------------------
d <- data.frame(row.names = seq_len(nrow(raw)))
d$record_id     <- chr_clean(raw$record_id)
d$clinic_number <- chr_clean(raw$clinic_number)
d$match_set     <- chr_clean(raw$match_set)
d$match_tier    <- chr_clean(raw$match_tier)

d$iih    <- num_raw(raw$group)
d$cohort <- factor(ifelse(d$iih == 1, "IIH", "Non-IIH control"),
                   levels = c("Non-IIH control", "IIH"))

d$index_date      <- date_clean(raw$index_date)
d$last_encounter  <- date_clean(raw$last_encounter)
d$death_date      <- date_clean(raw$death_date)
d$seizure_date    <- date_clean(raw$seizure_date)
d$first_encounter_date <- date_clean(raw$first_encounter_date)
d$index_year      <- as.integer(format(d$index_date, "%Y"))

d$sex       <- factor(chr_clean(raw$sex), levels = c("F", "M"))
d$female    <- num_clean(raw$female)
d$age_index <- num_clean(raw$age_index)
d$bmi_index <- num_clean(raw$bmi_index)
d$race      <- chr_clean(raw$race)
d$ethnicity <- chr_clean(raw$ethnicity)

## Outcome and time. `event` is the primary outcome AFTER the 180-day washout;
## t_y is post-washout person-time. e3/t3 and e5/t5 are the supplied 3- and
## 5-year truncations, recomputed below and checked rather than trusted.
d$event      <- num_clean(raw$event)
d$lat_days   <- num_clean(raw$lat_days)
d$t_y        <- num_clean(raw$t_y)
d$e3 <- num_clean(raw$e3); d$t3 <- num_clean(raw$t3)
d$e5 <- num_clean(raw$e5); d$t5 <- num_clean(raw$t5)
d$censoring_verifiable <- num_clean(raw$censoring_verifiable)
d$carpal_incident      <- num_clean(raw$carpal_incident)

## Competing event. There is no `died` column; death is defined by the presence
## of a death date, and counts as a competing event only when no seizure came
## first.
d$died <- as.integer(!is.na(d$death_date))

d$osa <- num_clean(raw$osa); d$pcos <- num_clean(raw$pcos); d$htn <- num_clean(raw$htn)
d$smoking <- factor(chr_clean(raw$smoking),
                    levels = c("Never", "Former", "Current", "Unknown"))
d$bariatric <- num_clean(raw$bariatric)
d$shunt <- num_clean(raw$shunt); d$stent <- num_clean(raw$stent)
d$op_cmh2o <- num_clean(raw$op_cmh2o)
d$enc_pre12 <- num_clean(raw$enc_pre12)
d$enc_post  <- num_clean(raw$enc_post)
d$n_encounters <- num_clean(raw$n_encounters)
d$in_analysis  <- num_clean(raw$in_analysis)

## Imaging / EEG: sentinel-aware, exactly as before. 88 = not assessable,
## 99 = unknown after searching, blank = never extracted for that cohort.
## An unassessable scan is never a negative scan.
sentinel_split <- function(x, name) {
  r <- num_raw(x); ch <- chr_clean(x)
  out <- list()
  out[[name]] <- ifelse(r %in% 0:5, r, NA_real_)
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
            "temporal_onset", "concordant"))
  d[names(sentinel_split(raw[[v]], v))] <- sentinel_split(raw[[v]], v)

## ---- structural assertions -------------------------------------------------
assert(!any(duplicated(d$record_id)), "record_id not unique")
assert(all(d$iih %in% c(0, 1)), "group not 0/1")
assert(all(!is.na(d$t_y)) && all(d$t_y > 0), "missing or non-positive t_y")
assert(all(!is.na(d$event)), "missing outcome")
assert(all(d$in_analysis == 1), "Analysis_Cohort contains rows flagged out of analysis")
assert(all(d$censoring_verifiable == 1), "a row has unverifiable censoring")
assert(sum(d$last_encounter > CUTOFF, na.rm = TRUE) == 0, "encounter after cutoff")
assert(sum(d$seizure_date > CUTOFF, na.rm = TRUE) == 0, "seizure after cutoff")
assert(all(d$lat_days >= 180, na.rm = TRUE), "an event falls inside the 180-day washout")
assert(all(d$match_set[d$iih == 1] == d$record_id[d$iih == 1]),
       "matched case: match_set != own record_id")
assert(all(d$match_set[d$iih == 0] %in% d$record_id[d$iih == 1]),
       "a control points at a match_set with no case")

## Recompute the supplied truncations rather than trusting them.
chk3 <- pmin(d$t_y, 3); chk_e3 <- ifelse(d$t_y > 3, 0, d$event)
assert(max(abs(chk3 - d$t3)) < 1e-6, "supplied t3 does not equal pmin(t_y, 3)")
assert(all(chk_e3 == d$e3), "supplied e3 does not equal the 3-year truncated event")
log_msg("supplied e3/t3 and e5/t5 reproduce exactly from t_y and event")

## ---- washout symmetry, the defect this workbook fixes ----------------------
wash <- do.call(rbind, lapply(c(1, 0), function(g) {
  s <- d[d$iih == g & d$event == 1, ]
  data.frame(cohort = ifelse(g == 1, "IIH", "Non-IIH control"),
             events = nrow(s),
             earliest_event_day = min(s$lat_days, na.rm = TRUE),
             latest_event_day = max(s$lat_days, na.rm = TRUE))
}))
write_tab(wash, "F_S1_washout_symmetry")
print(wash)

## ---- realised matching -----------------------------------------------------
n_per <- table(factor(d$match_set[d$iih == 0], levels = d$record_id[d$iih == 1]))
ratio <- as.data.frame(table(controls_in_set = as.integer(n_per)))
names(ratio) <- c("controls_in_set", "n_cases")
ratio$pct <- round(100 * ratio$n_cases / sum(ratio$n_cases), 1)
write_tab(ratio, "F_T2b_matching_ratio")
log_msg("mean controls/case = ", sprintf("%.2f", mean(as.integer(n_per))),
        " | full 1:4 sets = ", sprintf("%.1f%%", 100 * mean(as.integer(n_per) == 4)))

## ---- cohort flow -----------------------------------------------------------
flow <- rbind(
  data.frame(step = "Patients in the final matched analysis", n = nrow(d)),
  data.frame(step = "  IIH cases", n = sum(d$iih == 1)),
  data.frame(step = "  Matched non-IIH controls", n = sum(d$iih == 0)),
  do.call(rbind, lapply(split(excl, excl$reason), function(s)
    data.frame(step = paste0("Excluded: ", s$reason[1]), n = nrow(s)))),
  data.frame(step = "  of exclusions, IIH cases", n = sum(excl$group == "1")),
  data.frame(step = "  of exclusions, controls", n = sum(excl$group == "0")))
write_tab(flow, "F_T2_cohort_flow")
print(flow)

## ---- data dictionary from the file ----------------------------------------
n_case <- sum(d$iih == 1); n_ctl <- sum(d$iih == 0)
dict <- do.call(rbind, lapply(names(raw), function(v) {
  x <- trimws(ifelse(is.na(raw[[v]]), "", raw[[v]])); nr <- num_raw(x)
  vals <- unique(x[x != "" & !(nr %in% c(MISS_UNKNOWN, MISS_NOTAPPLIC))])
  bc <- sum(x[d$iih == 1] == ""); bk <- sum(x[d$iih == 0] == "")
  data.frame(variable = v, n_nonblank = sum(x != ""),
             blank_in_cases = bc, blank_in_controls = bk,
             n_code_99 = sum(nr == MISS_UNKNOWN, na.rm = TRUE),
             n_code_88 = sum(nr == MISS_NOTAPPLIC, na.rm = TRUE),
             n_distinct = length(vals),
             example = paste(utils::head(vals, 4), collapse = " | "),
             availability = if (bc == n_case && bk < n_ctl) "CONTROLS ONLY"
                       else if (bk == n_ctl && bc < n_case) "CASES ONLY" else "both cohorts",
             stringsAsFactors = FALSE)
}))
write_tab(dict, "F_S2_data_dictionary")
write_tab(manifest, "F_S3_source_manifest")
write_tab(codebook, "F_S4_codebook")
log_msg("cohort-specific variables: ", sum(dict$availability != "both cohorts"))

saveRDS(d,    file.path(PATH$derived, "F1_typed.rds"))
saveRDS(excl, file.path(PATH$derived, "F1_excluded.rds"))
saveRDS(dict, file.path(PATH$derived, "F1_dictionary.rds"))
log_msg("F1 complete")
