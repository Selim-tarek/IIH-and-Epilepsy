## 03_eligibility_and_cohort_flow.R -------------------------------------------
## Reconstructs the STROBE/RECORD flow that this export can support, and states
## plainly which protocol exclusions are NOT verifiable from it.

source("R/00_setup.R")
log_msg("=== 03 cohort flow ===")
d <- readRDS(file.path(PATH$derived, "01_typed.rds"))

## Protocol v2.0 section 2.1 exclusions (prior seizure, prior ASM, epileptiform
## EEG, TBI/stroke/tumour/CVST/craniotomy, <12 months records either side) were
## applied UPSTREAM of this export: the file already contains only the 3,601
## post-exclusion cases. The per-exclusion counts are therefore not
## reconstructible here, and no exclusion count may be invented.
##
## What IS verifiable in the file:
##   - excl_prior_seizure / excl_prior_asm are 0 for every control and blank for
##     every case -> the flags document control screening only.
##   - presenting_seizure (seizure within 180 days of index) is flagged in 71
##     cases and none of them is counted as an incident event.

flow <- data.frame(
  step = c(
    "IIH cases supplied after upstream protocol exclusions (v2.0 s2.1)",
    "  of which: seizure within 180 d of index (presenting, analysed separately)",
    "  of which: prevalent seizure ever, not incident",
    "IIH cases eligible for the comparative analysis",
    "  excluded: no matchable control found",
    "IIH cases in matched analysis",
    "Matched non-IIH controls (1:4 attempted, without replacement)",
    "Total matched-analysis population"),
  n = c(
    sum(d$iih == 1),
    sum(d$presenting_seizure == 1, na.rm = TRUE),
    sum(d$seizure_ever == 1 & d$seizure_incident %in% c(0, NA), na.rm = TRUE),
    sum(d$iih == 1),
    sum(d$iih == 1 & !d$in_matched),
    sum(d$iih == 1 & d$in_matched),
    sum(d$iih == 0 & d$in_matched),
    sum(d$in_matched)),
  verifiable_in_this_file = c("yes (total only)", "yes", "yes", "yes",
                              "yes", "yes", "yes", "yes"))
write_tab(flow, "T2_cohort_flow")

unverifiable <- data.frame(
  protocol_exclusion = c(
    "Seizure/epilepsy code at or before index",
    "Unambiguous ASM at or before index",
    "Epileptiform EEG at or before index",
    "TBI / stroke / tumour / CVST / craniotomy",
    ">=12 months of records before index",
    ">=12 months of records after index",
    "Measured height and weight",
    "Control screened against case MRN list"),
  status_in_export = c(
    "applied upstream; per-patient flag present for CONTROLS ONLY (all 0)",
    "applied upstream; per-patient flag present for CONTROLS ONLY (all 0)",
    "applied upstream; no flag retained",
    "applied upstream; no flag retained",
    "applied upstream; first_encounter_date present for cases only",
    "applied upstream; not reconstructible (see audit C1/C2)",
    "partially: bmi_index missing in 304 cases, 0 controls",
    "applied upstream; control clinic numbers are unique and disjoint by design"),
  consequence = c(
    rep("Cannot audit; must be reported as an upstream assumption", 6),
    "304 cases have no BMI and are necessarily unmatched",
    "Cannot audit"))
write_tab(unverifiable, "S10_unverifiable_exclusions")

## ---- immortal time / selection commentary (machine-readable) ---------------
## The >=12-months-of-follow-up requirement is applied at index but can only be
## satisfied by surviving and remaining in care for 12 months. Anyone with an
## event or death in months 0-12 who then left care is differentially removed.
## Because the requirement was imposed upstream and identically in both arms
## relative to the SAME index date, it does not create classical immortal time
## (no exposure is assigned using post-index information), but it does create
## a depletion-of-susceptibles selection that the landmark analyses in 08
## probe directly.
bias_notes <- data.frame(
  issue = c("Immortal time", "Minimum-follow-up selection", "Index-date alignment",
            "Post-index adjustment"),
  assessment = c(
    "LOW RISK: exposure is defined at index (date of diagnostic LP) and no post-index information is used to assign it. Controls inherit the case index date, so both arms start the clock at the same instant.",
    "MODERATE RISK: the >=12-month post-index records requirement conditions on remaining in care, which is itself associated with both exposure and outcome ascertainment. Probed by the 6/12/24-month landmark analyses (08) and by the 3-year truncated primary estimand.",
    "LOW RISK by design, but UNVERIFIABLE for controls, which carry no date fields (audit C2).",
    "HIGH RISK if enc_post is adjusted for as a confounder. It is a consequence of exposure and of the outcome, so it is reported only as a conservative bound (protocol s5.3)."),
  stringsAsFactors = FALSE)
write_tab(bias_notes, "S11_timing_bias_assessment")
log_msg("03 complete")
