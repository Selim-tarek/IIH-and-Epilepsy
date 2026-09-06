## 00_setup.R — project constants, packages, logging, reproducibility.
## Run from the project root. Reads nothing, writes nothing except outputs/.
## NOTE: R is not installed in the container this was authored in, so the
## scripts in R/ have not yet been executed. The audit numbers quoted in
## docs/DATA_AUDIT.md come from tools/audit.py.

set.seed(20260906)

REQUIRED <- c("readxl", "dplyr", "tidyr", "janitor", "lubridate", "ggplot2",
              "survival", "broom", "gt")
OPTIONAL <- c("gtsummary", "tableone", "cmprsk", "riskRegression", "rms",
              "mice", "ggdag", "survminer", "flextable")

check_packages <- function(pkgs, required = TRUE) {
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    msg <- paste("Not installed:", paste(missing, collapse = ", "))
    if (required) stop(msg, call. = FALSE) else message(msg, " (optional)")
  }
  invisible(setdiff(pkgs, missing))
}

PATHS <- list(
  raw_master = file.path("data-raw", "IIH_MASTER_cases_and_controls.xlsx"),
  raw_final  = file.path("data-raw", "IIH_Epilepsy_FINAL.xlsx"),
  raw_csv    = file.path("data-raw", "IIH_FINAL_analysis_dataset.csv"),
  raw_rads   = "MDE Workflow Results for Radiology (25).csv",
  tables     = file.path("outputs", "tables"),
  figures    = file.path("outputs", "figures"),
  diagnostics= file.path("outputs", "diagnostics"),
  logs       = file.path("outputs", "logs")
)
for (p in PATHS[c("tables", "figures", "diagnostics", "logs")]) {
  dir.create(p, recursive = TRUE, showWarnings = FALSE)
}

## Missing-value codes. These are NOT interchangeable and must never be
## collapsed into NA before the missingness report is produced.
CODE_UNKNOWN        <- 99  # searched for, not found
CODE_NOT_APPLICABLE <- 88  # no event / not applicable

## The master sheet carries three banner rows before the header.
MASTER_HEADER_SKIP <- 4L

## Data-pull date, used to re-censor future-dated last encounters (see Q6).
DATA_PULL_DATE <- as.Date("2026-09-06")

log_session <- function(file = file.path(PATHS$logs, "session_info.txt")) {
  writeLines(capture.output(sessionInfo()), file)
  invisible(file)
}
