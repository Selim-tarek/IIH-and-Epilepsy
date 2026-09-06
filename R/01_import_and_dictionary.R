## 01_import_and_dictionary.R — import the three cohort files, verify they
## describe the same 12,584 people, and emit a data dictionary from the data.
## Raw files are read-only; nothing here writes to data-raw/.

source(file.path("R", "00_setup.R"))
check_packages(REQUIRED)

suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(janitor)
})

import_master <- function(path = PATHS$raw_master, sheet = "Master_Data") {
  read_excel(path, sheet = sheet, skip = MASTER_HEADER_SKIP,
             col_types = "text", .name_repair = "minimal") |>
    filter(!if_all(everything(), is.na))
}

## Explicit typing, so that 88/99 survive as codes rather than becoming NA.
type_master <- function(df) {
  num <- c("group", "in_matched_analysis", "age_index", "bmi_index",
           "op_cmh2o", "op_first_lp", "op_max", "followup_years", "t5", "ev5",
           "status", "died_fu", "seizure_incident", "seizure_ever",
           "presenting_seizure", "carpal_incident", "seizure_latency_days",
           "enc_pre12", "enc_post", "outcome_criterion", "pnes_ever")
  dat <- c("index_date", "dob", "seizure_date", "last_encounter_date",
           "death_date")
  df |>
    mutate(across(any_of(num), ~ suppressWarnings(as.numeric(.x))),
           across(any_of(dat), ~ as.Date(substr(.x, 1, 10))))
}

## Assertions encoding what the audit established. A failure means the inputs
## changed and docs/DATA_AUDIT.md is stale.
assert_master <- function(df) {
  stopifnot(
    nrow(df) == 13453L,
    !anyDuplicated(df$record_id),
    sum(df$group == 1) == 3601L,
    sum(df$group == 0) == 9852L,
    sum(df$in_matched_analysis == 1) == 12584L
  )
  matched <- filter(df, in_matched_analysis == 1)
  stopifnot(
    n_distinct(matched$match_set[matched$group == 0]) == 2732L,
    sum(matched$seizure_incident[matched$group == 1]) == 102L,
    sum(matched$seizure_incident[matched$group == 0]) == 83L
  )
  invisible(df)
}

## Cross-file check: the CSV and the FINAL workbook must contain exactly the
## matched record_ids and nothing else.
assert_files_agree <- function(master) {
  matched_ids <- master$record_id[master$in_matched_analysis == 1]
  csv_ids <- as.character(read.csv(PATHS$raw_csv)$record_id)
  fin_ids <- as.character(
    read_excel(PATHS$raw_final, sheet = "Analysis_Dataset",
               skip = MASTER_HEADER_SKIP)$record_id)
  stopifnot(setequal(matched_ids, csv_ids), setequal(matched_ids, fin_ids))
  invisible(TRUE)
}

## Availability is arm-specific (see docs/DATA_AUDIT.md §3), so missingness is
## reported separately for cases and controls; a column that is blank for one
## whole arm is structural and must not be imputed.
build_dictionary <- function(df) {
  matched <- filter(df, in_matched_analysis == 1)
  ca <- filter(matched, group == 1); co <- filter(matched, group == 0)
  tibble(
    variable = names(df),
    n_nonmissing = vapply(df, function(x) sum(!is.na(x)), integer(1)),
    pct_missing_cases = vapply(ca, function(x) round(100 * mean(is.na(x)), 1), numeric(1))[names(df)],
    pct_missing_controls = vapply(co, function(x) round(100 * mean(is.na(x)), 1), numeric(1))[names(df)],
    n_distinct = vapply(df, function(x) n_distinct(x, na.rm = TRUE), integer(1)),
    uses_88 = vapply(df, function(x) any(as.character(x) == "88", na.rm = TRUE), logical(1)),
    uses_99 = vapply(df, function(x) any(as.character(x) == "99", na.rm = TRUE), logical(1)),
    arm_specific = pct_missing_cases == 100 | pct_missing_controls == 100
  )
}

if (sys.nframe() == 0L) {
  master <- import_master() |> type_master() |> assert_master()
  assert_files_agree(master)
  dict <- build_dictionary(master)
  write.csv(dict, file.path(PATHS$diagnostics, "data_dictionary_R.csv"),
            row.names = FALSE)
  log_session()
  message(sum(dict$arm_specific), " of ", nrow(dict),
          " variables are available for only one arm — see docs/DATA_AUDIT.md")
}
