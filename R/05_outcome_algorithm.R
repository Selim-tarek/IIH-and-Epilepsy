## 05_outcome_algorithm.R -----------------------------------------------------
## Builds the analysis-ready survival dataset.
##
## The single most important thing this script does is REBUILD the competing-
## event indicator. The supplied `status` column codes death (=2) in 144
## controls and in zero IIH cases, despite 91 cases having died_fu = 1 (audit
## D1). Used as supplied it would censor exposed deaths while treating
## unexposed deaths as competing events -- a differential, exposure-dependent
## error that biases every competing-risk estimate. It is discarded here.

source("R/00_setup.R")
log_msg("=== 05 outcome & follow-up ===")
d <- readRDS(file.path(PATH$derived, "01_typed.rds"))

## ---- outcome definition (protocol v2.0 s4.1) -------------------------------
## Applied identically in both cohorts upstream:
##   criterion 1 = two epilepsy-specific codes (G40.x / 345.x) >=30 d apart
##   criterion 2 = one epilepsy-specific code + >=1 unambiguous ASM (s4.2)
## Non-specific convulsion codes (R56.x / 780.39) exclude at baseline but do
## NOT satisfy the outcome. Acetazolamide and topiramate are NOT counted as
## ASM evidence; zonisamide IS counted (protocol s4.2) -- a defensible but
## non-trivial choice, since zonisamide is also used for IIH. Its impact
## cannot be tested here because per-drug data are not in this export.
d$event_seizure <- d$seizure_incident

## Patients whose seizure preceded or presented with the IIH diagnosis
## (within 180 d) are NOT incident events; they are described separately.
assert(all(d$seizure_incident[which(d$presenting_seizure == 1)] %in% c(0, NA)),
       "a presenting-seizure patient is coded as an incident event")

## ---- competing event: death ------------------------------------------------
d$died <- ifelse(is.na(d$died_fu), 0, d$died_fu)

## ---- follow-up time --------------------------------------------------------
## followup_years is the ONLY time variable available for controls (they carry
## no dates at all). For cases it is NOT simply last_encounter_date - index
## (median absolute difference 44 days), so it already reflects censoring at
## death or event.
##
## It does, however, run past the end of the data. Projecting each patient's
## end of follow-up as index_date + followup_years puts 6.0% of cases and
## 12.1% of controls beyond any plausible freeze, out to 2031 and 2034
## respectively. Person-time after the freeze is not observation, so every
## patient is administratively censored at FREEZE_DATE.
##
## This rule is applied identically in both arms, which matters: the excess
## sits in BOTH cohorts and is proportionally larger in controls, so leaving it
## in would inflate control person-time and bias the hazard ratio upward.
d$fu_max      <- as.numeric(FREEZE_DATE - d$index_date) / 365.25
d$fu_raw      <- d$followup_years
d$time_years  <- pmin(d$fu_raw, d$fu_max)
d$fu_censored_at_freeze <- !is.na(d$fu_raw) & d$fu_raw > d$fu_max

## An event or death recorded after the freeze would have to be censored too.
## There are none, so no outcome is lost by this rule -- assert it rather than
## assume it.
assert(sum(d$seizure_date > FREEZE_DATE, na.rm = TRUE) == 0,
       "seizure recorded after the data-freeze date")
assert(sum(d$death_date > FREEZE_DATE, na.rm = TRUE) == 0,
       "death recorded after the data-freeze date")
assert(all(d$time_years > 0 | is.na(d$time_years)),
       "non-positive follow-up after applying the freeze")

## Rebuilt competing-risk status: 0 censored, 1 seizure, 2 death before seizure.
## The supplied `status` column is discarded for the reason given in the header.
d$status_cr <- ifelse(!is.na(d$event_seizure) & d$event_seizure == 1, 1L,
               ifelse(d$died == 1, 2L, 0L))
d$status_cr <- factor(d$status_cr, levels = 0:2,
                      labels = c("censored", "seizure", "death"))

## Truncation helper: administratively censor everyone at `tau` years.
truncate_at <- function(dat, tau) {
  dat$t   <- pmin(dat$time_years, tau)
  dat$ev  <- ifelse(dat$time_years > tau, 0L,
                    ifelse(dat$event_seizure == 1, 1L, 0L))
  dat$evc <- ifelse(dat$time_years > tau, 0L, as.integer(dat$status_cr) - 1L)
  dat
}

## ---- analytic set ----------------------------------------------------------
a <- d[d$in_matched & !is.na(d$time_years) & d$time_years > 0, ]
assert(all(!is.na(a$event_seizure)), "missing outcome in matched set")
assert(all(a$time_years > 0), "non-positive follow-up in matched set")

## Drop matched sets that carry no comparison (a case with zero controls, or
## the reverse). A stratified Cox model discards these anyway; removing them
## explicitly makes the effective sample size visible rather than silent.
tab_sets <- table(a$match_set, a$iih)
informative <- rownames(tab_sets)[tab_sets[, "0"] > 0 & tab_sets[, "1"] > 0]
a$set_informative <- a$match_set %in% informative

## Impact of the freeze, reported so the reader can see what it cost.
freeze_tab <- do.call(rbind, lapply(c(1, 0), function(g) {
  ss <- d[d$in_matched & d$iih == g & !is.na(d$fu_raw), ]
  data.frame(cohort = ifelse(g == 1, "IIH", "Non-IIH control"),
             n = nrow(ss),
             n_censored_at_freeze = sum(ss$fu_censored_at_freeze),
             pct_censored = round(100 * mean(ss$fu_censored_at_freeze), 1),
             py_before = round(sum(ss$fu_raw)),
             py_after = round(sum(ss$time_years)),
             pct_py_removed = round(100 * (1 - sum(ss$time_years) / sum(ss$fu_raw)), 2))
}))
write_tab(freeze_tab, "S27_data_freeze_impact")
print(freeze_tab)

log_msg("matched analytic set: ", nrow(a), " (", sum(a$iih == 1), " IIH, ",
        sum(a$iih == 0), " controls)")
log_msg("sets with both arms present: ", length(informative))
log_msg("incident seizures: ", sum(a$event_seizure), " | deaths before seizure: ",
        sum(a$status_cr == "death"))

## Event counts at each truncation horizon drive how many parameters any model
## may carry (>=10 events per parameter is the working rule below).
horiz <- do.call(rbind, lapply(c(1, 2, 3, 5, Inf), function(tau) {
  s <- truncate_at(a, tau)
  data.frame(horizon_y = tau,
             events_iih = sum(s$ev[s$iih == 1]), events_ctl = sum(s$ev[s$iih == 0]),
             py_iih = round(sum(s$t[s$iih == 1])), py_ctl = round(sum(s$t[s$iih == 0])),
             deaths = sum(s$evc == 2))
}))
horiz$max_parameters <- floor(pmin(horiz$events_iih, horiz$events_ctl) / 10)
write_tab(horiz, "S14_events_by_horizon")
print(horiz)

## ---- descriptive: presenting-seizure group (kept OUT of the cohort) --------
pres <- d[which(d$presenting_seizure == 1), ]
pres_desc <- data.frame(
  item = c("n with seizure at/within 180 d of IIH diagnosis",
           "  median age", "  % female", "  median opening pressure (cmH2O)",
           "  n counted as incident outcome"),
  value = c(nrow(pres),
            sprintf("%.0f", stats::median(pres$age_index, na.rm = TRUE)),
            sprintf("%.0f%%", 100 * mean(pres$sex == "F", na.rm = TRUE)),
            ifelse(all(is.na(pres$op_cmh2o)), "not recorded",
                   sprintf("%.1f", stats::median(pres$op_cmh2o, na.rm = TRUE))),
            sum(pres$seizure_incident == 1, na.rm = TRUE)))
write_tab(pres_desc, "S15_presenting_seizure_group")

saveRDS(a, file.path(PATH$derived, "05_analytic.rds"))
saveRDS(truncate_at, file.path(PATH$derived, "05_truncate_fn.rds"))
log_msg("05 complete")
