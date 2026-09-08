## G1_build_master.R ----------------------------------------------------------
## Single ingest of every source supplied, producing one analytic dataset.
## Supersedes the F-series build. Outputs carry a G_ prefix.
##
## Sources
##   IIH_MASTER_FINAL.xlsx            cohort, index date, matching, seizure outcome
##   MDE_Diagnosis_carpal_12.csv      dated carpal tunnel, BOTH arms
##   MDE_SocialHistory_smoking_1.csv  smoking, controls
##   MDE_Medications_cases_22.csv     medications, CASES (new)
##   IIH_medications_*.csv            medications, controls
##   MDE_Radiology_*.csv              imaging text, both arms
##
## Three corrections to the earlier build, all of which changed a result:
##   1. The carpal outcome was censored at t_y, which is censored at the SEIZURE.
##      A carpal diagnosis occurring after a patient's seizure was therefore
##      discarded. Carpal now uses its own window, to last attended encounter.
##   2. Carpal prevalent-at-baseline was never examined. It is 3.8x commoner in
##      cases, so the arms are not exchangeable for that outcome to begin with.
##   3. Protocol v2.0 required controls to have >=1 encounter in the 12 months
##      before index. 55.7% of controls have zero. An engagement-restricted
##      cohort is therefore built alongside the full one.

source("R/00_setup.R")
log_msg("=== G1 build master dataset ===")
WASHOUT_D <- 180; CUTOFF <- as.Date("2026-09-03")

d <- readRDS(file.path(PATH$derived, "F1_typed.rds"))
d$mrn <- ifelse(d$iih == 1, d$record_id, d$clinic_number)
assert(!any(duplicated(d$mrn)), "MRN not unique")

## Carpal has its own at-risk window: to last attended encounter or death,
## NOT to the seizure event.
d$fu_carpal_end_day <- as.numeric(pmin(d$last_encounter,
                                       ifelse(is.na(d$death_date), CUTOFF, d$death_date),
                                       CUTOFF, na.rm = TRUE) - d$index_date)
d$fu_seizure_end_day <- WASHOUT_D + d$t_y * 365.25

## ---- carpal tunnel ----------------------------------------------------------
cp <- utils::read.csv(file.path("data-raw", "MDE_Diagnosis_carpal_12.csv"),
                      colClasses = "character", check.names = FALSE)
names(cp) <- c("mrn", "system", "code", "desc", "dx_date")
cp$mrn <- trimws(cp$mrn); cp$dx_date <- as.Date(substr(cp$dx_date, 1, 10))
cp <- cp[grepl("^354\\.0|^G56\\.0", cp$code) |
         grepl("carpal tunnel", cp$desc, ignore.case = TRUE), ]
cp$day <- as.numeric(cp$dx_date - d$index_date[match(cp$mrn, d$mrn)])
first_any  <- tapply(cp$day, cp$mrn, min)
first_post <- tapply(cp$day[cp$day > WASHOUT_D], cp$mrn[cp$day > WASHOUT_D], min)
d$cp_first_day <- as.numeric(first_any[d$mrn])
d$cp_post_day  <- as.numeric(first_post[d$mrn])
d$cp_prevalent <- !is.na(d$cp_first_day) & d$cp_first_day <= WASHOUT_D
d$cp_event <- as.integer(!is.na(d$cp_post_day) &
                         d$cp_post_day <= d$fu_carpal_end_day + 1e-6)
d$cp_t_y <- ifelse(d$cp_event == 1,
                   (d$cp_post_day - WASHOUT_D) / 365.25,
                   pmax((d$fu_carpal_end_day - WASHOUT_D) / 365.25, 1 / 365.25))

## ---- medications, both arms unified ----------------------------------------
ASM <- c("levetiracetam","lamotrigine","lacosamide","oxcarbazepine","carbamazepine",
         "phenytoin","fosphenytoin","valproa","divalproex","zonisamide","perampanel",
         "brivaracetam","felbamate","rufinamide","vigabatrin","tiagabine","primidone",
         "ethosuximide","phenobarb","eslicarbazepine","cenobamate")
is_asm <- function(x) { g <- tolower(x); Reduce(`|`, lapply(ASM, function(a) grepl(a, g, fixed = TRUE))) }

mc <- utils::read.csv(file.path("data-raw", "MDE_Medications_cases_22.csv"),
                      colClasses = "character", check.names = FALSE)
names(mc) <- c("mrn","ended","started","generic","name","tclass","tcode","admin")
mc$mrn <- trimws(mc$mrn); mc$date <- as.Date(substr(mc$started, 1, 10))
mc <- data.frame(mrn = mc$mrn, date = mc$date, generic = mc$generic,
                 asm = is_asm(mc$generic), src = "cases extract")

md <- utils::read.csv(file.path("data-raw", "IIH_medications_detail.csv"),
                      colClasses = "character", check.names = FALSE)
md$date <- as.Date(substr(md$start_date, 1, 10))
md <- data.frame(mrn = trimws(md$clinic_number), date = md$date,
                 generic = md$medication_name,
                 asm = md$asm_generic != "", src = "controls extract")
meds <- rbind(mc, md)
meds <- meds[meds$mrn %in% d$mrn & !is.na(meds$date), ]
d$has_med <- d$mrn %in% meds$mrn

asm <- meds[meds$asm, ]
asm$day <- as.numeric(asm$date - d$index_date[match(asm$mrn, d$mrn)])
d$asm_first_day <- as.numeric(tapply(asm$day, asm$mrn, min)[d$mrn])
ap <- tapply(asm$day[asm$day > WASHOUT_D], asm$mrn[asm$day > WASHOUT_D], min)
d$asm_post_day <- as.numeric(ap[d$mrn])

## ---- smoking ----------------------------------------------------------------
sh <- utils::read.csv(file.path("data-raw", "MDE_SocialHistory_smoking_1.csv"),
                      colClasses = "character", check.names = FALSE)
names(sh) <- c("mrn","question","abbrev","contact_date","answer")
sh <- sh[sh$abbrev == "SMOKING_TOB_USE_C", ]
sh$mrn <- trimws(sh$mrn); sh$date <- as.Date(substr(sh$contact_date, 1, 10))
sh$status <- ifelse(tolower(sh$answer) %in% c("never","passive smoke exposure - never smoker"), "Never",
             ifelse(tolower(sh$answer) == "former", "Former",
             ifelse(tolower(sh$answer) %in% c("every day","some days","light smoker","heavy smoker"),
                    "Current", NA)))
sh <- sh[!is.na(sh$status) & sh$mrn %in% d$mrn, ]
sh$delta <- as.numeric(sh$date - d$index_date[match(sh$mrn, d$mrn)])
pick <- do.call(rbind, lapply(split(sh, sh$mrn), function(g) {
  pre <- g[g$delta <= 0, ]; if (nrow(pre)) pre[which.max(pre$delta), ] else g[which.min(g$delta), ] }))
d$smoke_ext <- pick$status[match(d$mrn, pick$mrn)]
d$smoking_final <- factor(ifelse(d$iih == 1 & !is.na(d$smoking) & d$smoking != "Unknown",
                                 as.character(d$smoking),
                                 ifelse(is.na(d$smoke_ext), "Unknown", d$smoke_ext)),
                          levels = c("Never","Former","Current","Unknown"))

## ---- baseline engagement, the variable that turned out to matter -----------
d$engaged <- !is.na(d$enc_pre12) & d$enc_pre12 >= 1

## ---- availability report ----------------------------------------------------
avail <- do.call(rbind, lapply(list(
    c("Seizure outcome", "!is.na(d$event)"),
    c("Carpal tunnel (dated)", "TRUE"),
    c("Medication record", "d$has_med"),
    c("Smoking (graded)", "d$smoking_final != 'Unknown'"),
    c(">=1 pre-index encounter", "d$engaged")),
  function(z) {
    v <- eval(parse(text = z[2]))
    if (length(v) == 1) v <- rep(v, nrow(d))
    data.frame(variable = z[1],
               iih_pct = round(100 * mean(v[d$iih == 1]), 1),
               control_pct = round(100 * mean(v[d$iih == 0]), 1))
  }))
avail$asymmetry <- round(abs(avail$iih_pct - avail$control_pct), 1)
write_tab(avail, "G_T01_data_availability")
print(avail)

flow <- data.frame(
  cohort = c("Full matched cohort", "  IIH", "  control",
             "Engagement-restricted (>=1 pre-index encounter)", "  IIH", "  control"),
  n = c(nrow(d), sum(d$iih == 1), sum(d$iih == 0),
        sum(d$engaged), sum(d$engaged & d$iih == 1), sum(d$engaged & d$iih == 0)))
write_tab(flow, "G_T02_cohorts")
print(flow)

saveRDS(d, file.path(PATH$derived, "G1_master.rds"))
saveRDS(meds, file.path(PATH$derived, "G1_meds.rds"))
log_msg("G1 complete")
