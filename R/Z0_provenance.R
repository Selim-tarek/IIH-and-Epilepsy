## Z0_provenance.R ------------------------------------------------------------
## Gate for the final from-scratch run. Verifies that every input is the current
## export and not a superseded one, BEFORE any analysis runs. Fails loudly.
## Raw files are opened read-only and never modified.

source("R/00_setup.R")
log_msg("=== Z0 provenance gate ===")

RAW <- "data-raw"
nrows <- function(f) as.integer(strsplit(trimws(system(
  sprintf("wc -l < %s", shQuote(file.path(RAW, f))), intern = TRUE)), " ")[[1]][1]) - 1L
md5 <- function(f) substr(system(sprintf("md5sum %s", shQuote(file.path(RAW, f))),
                                 intern = TRUE), 1, 12)

req <- c(
  "IIH_MASTER_FINAL.xlsx",              # THE master
  "MDE_Encounters_types_full.csv",      # cases, typed, untruncated
  "MDE_Encounters_controls_typed.csv",  # comparators, typed
  "MDE_Flowsheets_BMI.csv",             # dated BMI, both arms
  "SZ_dx_62.csv", "SZ_conditions_10.csv",
  "MDE_Medications_cases_22.csv", "IIH_medications_detail.csv",
  "MDE_Diagnosis_carpal_12.csv",
  "NC_dx_21.csv","NC_dx_58.csv","NC_dx_59.csv","NC_dx_60.csv","NC_dx_61.csv",
  "NC2_dx_13.csv","NC2_dx_14.csv","NC2_dx_16.csv","NC2_dx_17.csv","NC2_dx_18.csv",
  "NC2_dx_20.csv")
miss <- req[!file.exists(file.path(RAW, req))]
assert(length(miss) == 0, paste("MISSING INPUTS:", paste(miss, collapse = ", ")))

## Superseded files that must NOT feed the final run.
SUPERSEDED <- c("IIH_MASTER_cases_and_controls_2.csv",  # one-sided washout
                "MDE_Encounters_controls.csv")          # untyped, no Encounter Type
for (f in SUPERSEDED)
  if (file.exists(file.path(RAW, f)))
    log_msg(sprintf("NOTE present but NOT used: %s", f))

prov <- data.frame(
  file = req,
  rows = vapply(req, function(f) if (grepl("\\.xlsx$", f)) NA_integer_ else nrows(f), integer(1)),
  md5_12 = vapply(req, md5, character(1)),
  role = c("master cohort, index dates, matching vars, outcome",
           "dated encounters + Encounter Type, CASES",
           "dated encounters + Encounter Type, COMPARATORS",
           "dated BMI, both arms",
           "seizure diagnosis codes", "seizure conditions",
           "medications, cases", "medications, comparators",
           "carpal tunnel (negative control)",
           rep("negative control outcome", 11)),
  stringsAsFactors = FALSE, row.names = NULL)

## Encounter-file integrity: the case file must exceed Excel's row ceiling,
## which is what proved the .xlsb exports were truncated rather than the query.
EXCEL_CEILING <- 1048575L
nc_case <- prov$rows[prov$file == "MDE_Encounters_types_full.csv"]
assert(nc_case > EXCEL_CEILING,
       sprintf("case encounter file has %d rows, at or below Excel's ceiling -- possible truncation", nc_case))
log_msg(sprintf("case encounter rows %s exceed Excel ceiling %s: untruncated export confirmed",
                format(nc_case, big.mark = ","), format(EXCEL_CEILING, big.mark = ",")))

## Master workbook must carry the final sheet set.
sh <- readxl::excel_sheets(file.path(RAW, "IIH_MASTER_FINAL.xlsx"))
assert(all(c("Analysis_Cohort","Cases","Controls","Source_Manifest") %in% sh),
       paste("master workbook sheet set unexpected:", paste(sh, collapse = ", ")))
log_msg(sprintf("master workbook sheets: %s", paste(sh, collapse = ", ")))

write_tab(prov, "Z_T00_provenance")
print(prov[, c("file","rows","md5_12")], row.names = FALSE)
log_msg("Z0 provenance gate PASSED")
