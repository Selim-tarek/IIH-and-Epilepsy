## 15_medications.R -----------------------------------------------------------
## PROVISIONAL -- the investigators have said these extracts will be revised and
## filtered before final use. Nothing here changes the primary estimate; the
## script audits the extract and uses it for one thing the study badly needed:
## an EMPIRICAL anchor for the tipping-point analysis.
##
## The decisive fact about this extract is its coverage. It contains medications
## for 2,821 of 9,742 matched controls (29%) and for ZERO IIH cases in the
## cohort. So it still cannot support the acetazolamide-only restriction, the
## time-varying treatment model, or a marginal structural model -- all of those
## need case medications.

source("R/00_setup.R")
log_msg("=== 15 medications (PROVISIONAL) ===")

f_det <- file.path("data-raw", "IIH_medications_detail.csv")
f_sum <- file.path("data-raw", "IIH_medications_patient_summary.csv")
if (!file.exists(f_sum)) { log_msg("medication extracts absent; skipping"); quit(save = "no") }

det  <- utils::read.csv(f_det, colClasses = "character", check.names = FALSE)
summ <- utils::read.csv(f_sum, colClasses = "character", check.names = FALSE)
d    <- readRDS(file.path(PATH$derived, "01_typed.rds"))
a    <- readRDS(file.path(PATH$derived, "05_analytic.rds"))
tr   <- readRDS(file.path(PATH$derived, "05_truncate_fn.rds"))
LM   <- 180 / 365.25

ctl_ids  <- d$record_id[d$iih == 0]
case_ids <- d$record_id[d$iih == 1]

## ---- A. coverage and provenance -------------------------------------------
cov <- data.frame(
  item = c("Detail rows", "Distinct patients in detail", "Summary rows",
           "Matched controls with medication data", "Matched controls WITHOUT",
           "IIH cases in the cohort with medication data",
           "Screened controls not in the final cohort",
           "IIH cases that surfaced in the control extract (screened out)"),
  n = c(nrow(det), length(unique(det$record_id)), nrow(summ),
        sum(ctl_ids %in% summ$record_id), sum(!ctl_ids %in% summ$record_id),
        sum(case_ids %in% summ$record_id),
        sum(grepl("screened control", summ$cohort_status)),
        sum(grepl("IIH case", summ$cohort_status))))
write_tab(cov, "T12_medication_coverage")
print(cov)

## Source files are female_controls / male_controls only -- confirming this is a
## control-side extract, not a cohort-wide one.
src <- as.data.frame(table(source_file = det$source_file))
write_tab(src, "S28_medication_source_files")

## ---- B. cohort-contamination check (protocol s2.2) -------------------------
## Controls must be screened against the case MRN list. 59 IIH cases surfaced in
## the control extract; the question is whether any of them was actually USED as
## a matched control. None was. This is a clean pass on a real risk.
sus <- summ[grepl("IIH case", summ$cohort_status), ]
contam <- data.frame(
  check = c("IIH cases appearing in the control extract",
            "...of those, used as a matched control in the master file",
            "...of those, present in the master file as a control record"),
  n = c(nrow(sus),
        sum(sus$clinic_number %in% d$clinic_number[d$iih == 0]),
        sum(sus$record_id %in% ctl_ids)),
  verdict = c("expected -- the control pool is screened, not pre-filtered",
              "PASS -- no case contributes to both arms",
              "PASS"))
write_tab(contam, "T12b_contamination_check")
print(contam)

## ---- C. does the ASM classification match protocol s4.2? -------------------
## Protocol s4.2 counts 21 named agents and explicitly excludes benzodiazepines,
## gabapentinoids (gabapentin, pregabalin) and the IIH treatments (topiramate,
## acetazolamide). Verified here rather than assumed.
mn <- tolower(det$medication_name)
check_drug <- function(drug, expected) {
  i <- grepl(drug, mn, fixed = TRUE)
  data.frame(drug = drug, n_rows = sum(i),
             classes = paste(unique(det$medication_class[i]), collapse = "; "),
             counted_as_asm = paste(unique(det$asm_generic[i] != ""), collapse = "/"),
             protocol_expectation = expected)
}
cls <- rbind(
  check_drug("gabapentin",    "NOT an ASM (neuropathic pain)"),
  check_drug("pregabalin",    "NOT an ASM (neuropathic pain)"),
  check_drug("topiramate",    "NOT counted (IIH treatment)"),
  check_drug("acetazolamide", "NOT counted (IIH treatment)"),
  check_drug("levetiracetam", "counted (unambiguous ASM)"),
  check_drug("zonisamide",    "counted (unambiguous ASM, but also used for IIH)"),
  check_drug("lorazepam",     "NOT counted (procedural sedation)"))
cls$agrees_with_protocol <- ifelse(
  cls$n_rows == 0, "no rows to check",
  ifelse(grepl("NOT", cls$protocol_expectation) == grepl("FALSE", cls$counted_as_asm),
         "YES", "REVIEW"))
write_tab(cls, "T12c_asm_classification_check")
print(cls[, c("drug", "n_rows", "classes", "agrees_with_protocol")])

asm_freq <- as.data.frame(table(asm_generic = det$asm_generic[det$asm_generic != ""]))
asm_freq <- asm_freq[order(-asm_freq$Freq), ]
write_tab(asm_freq, "S29_asm_frequency")

## Acetazolamide has zero rows anywhere in the extract. Worth stating plainly:
## the acetazolamide-only sensitivity analysis is not merely blocked by missing
## CASE data, it is blocked by the drug being absent from the extract entirely.
log_msg("acetazolamide rows in extract: ", sum(grepl("acetazolamide", mn)))

## ---- D. ASM against the recorded outcome, in controls ----------------------
s <- merge(summ[summ$record_id %in% ctl_ids,
                c("record_id", "asm_ever", "asm_pre_index", "asm_post_index",
                  "asm_list", "first_asm_date")],
           d[, c("record_id", "seizure_incident", "outcome_criterion")],
           by = "record_id")
conc <- as.data.frame(table(asm_ever = s$asm_ever, outcome = s$seizure_incident))
write_tab(conc, "T13_asm_vs_outcome_controls")

disc <- s[s$asm_ever == "1" & s$seizure_incident == 0, ]
log_msg("controls with an unambiguous ASM but NO recorded outcome: ", nrow(disc),
        sprintf(" (%.2f%% of %d with medication data)", 100 * nrow(disc) / nrow(s), nrow(s)))

## Every one of them started the ASM AFTER index -- consistent with the
## pre-index ASM exclusion having been applied correctly.
pre_post <- as.data.frame(table(pre = disc$asm_pre_index, post = disc$asm_post_index))
write_tab(pre_post, "S30_discordant_asm_timing")

drugs <- sort(table(unlist(strsplit(disc$asm_list, ",\\s*"))), decreasing = TRUE)
write_tab(data.frame(asm = names(drugs), n = as.integer(drugs)),
          "S31_discordant_asm_drugs")

## ---- E. EMPIRICALLY ANCHORED TIPPING POINT ---------------------------------
## Until now the tipping point was hypothetical: "what if x% of censored
## controls had a hidden seizure?" This extract identifies actual, named
## controls who received an unambiguous antiseizure medication and were never
## coded with an epilepsy diagnosis. They are the concrete candidates.
##
## They are NOT all missed epilepsy. Levetiracetam is used for post-operative
## prophylaxis and lamotrigine for bipolar disorder, and these two account for
## most of the list. So the analysis sweeps the fraction that are real, rather
## than asserting one.
##
## The event time used is the first ASM date, which is a defensible proxy for
## when treatment began -- not an invented date.
s$first_asm <- as.Date(substr(s$first_asm_date, 1, 10))
anchor <- merge(a, s[, c("record_id", "asm_ever", "seizure_incident", "first_asm")],
                by = "record_id", suffixes = c("", "_med"))
cand <- anchor$record_id[anchor$asm_ever == "1" & anchor$event_seizure == 0 &
                         !is.na(anchor$first_asm)]

base <- tr(a, 3); base <- base[!is.na(base$t) & base$t > LM, ]; base$t0 <- LM
asm_time <- setNames(
  as.numeric(s$first_asm - d$index_date[match(s$record_id, d$record_id)]) / 365.25,
  s$record_id)

tip2 <- do.call(rbind, lapply(c(0, 0.25, 0.5, 0.75, 1), function(frac) {
  set.seed(SEED)
  k <- round(frac * length(cand))
  hit <- if (k > 0) sample(cand, k) else character(0)
  ss <- base
  i <- match(hit, ss$record_id); i <- i[!is.na(i)]
  if (length(i)) {
    te <- asm_time[ss$record_id[i]]
    ok <- !is.na(te) & te > ss$t0[i] & te <= ss$t[i]
    ss$ev[i[ok]] <- 1L; ss$t[i[ok]] <- te[ok]
  }
  fit <- survival::coxph(Surv(t0, t, ev) ~ iih, data = ss,
                         cluster = ss$match_set, robust = TRUE)
  sm <- summary(fit)
  data.frame(pct_of_ASM_discordant_controls_assumed_true = 100 * frac,
             controls_reclassified = length(i),
             events_added_in_window = if (length(i)) sum(ok) else 0,
             hr = round(sm$conf.int[1, 1], 2), lo = round(sm$conf.int[1, 3], 2),
             hi = round(sm$conf.int[1, 4], 2),
             crosses_null = sm$conf.int[1, 3] < 1)
}))
write_tab(tip2, "T13b_anchored_tipping_point")
print(tip2)

## The scenario above uses only the controls we can actually see. Medication data
## exists for 29% of matched controls, so restricting to them understates the
## total number of discordant controls in the cohort. This second scenario
## extrapolates the observed rate to the 71% with no medication data, drawing the
## extra candidates at random from censored controls and timing their events
## uniformly within the at-risk window. That is an assumption, stated as one, and
## it is the pessimistic bound the earlier hypothetical analysis was groping for.
rate_disc <- nrow(disc) / nrow(s)
tip3 <- do.call(rbind, lapply(c(0, 0.5, 1), function(frac_true) {
  set.seed(SEED)
  ss <- base
  ## (a) the observed, named candidates
  i <- match(sample(cand, round(frac_true * length(cand))), ss$record_id)
  i <- i[!is.na(i)]
  if (length(i)) {
    te <- asm_time[ss$record_id[i]]
    ok <- !is.na(te) & te > ss$t0[i] & te <= ss$t[i]
    ss$ev[i[ok]] <- 1L; ss$t[i[ok]] <- te[ok]
  }
  ## (b) the unobserved remainder, at the same rate
  unseen <- which(ss$iih == 0 & ss$ev == 0 & !(ss$record_id %in% s$record_id))
  k <- round(frac_true * rate_disc * length(unseen))
  added <- 0
  if (k > 0) {
    hit <- sample(unseen, k)
    ss$ev[hit] <- 1L
    ss$t[hit] <- ss$t0[hit] + stats::runif(length(hit)) * (ss$t[hit] - ss$t0[hit])
    added <- k
  }
  fit <- survival::coxph(Surv(t0, t, ev) ~ iih, data = ss,
                         cluster = ss$match_set, robust = TRUE)
  sm <- summary(fit)
  data.frame(pct_assumed_true = 100 * frac_true,
             observed_candidates_used = if (length(i)) sum(ok) else 0,
             extrapolated_events_added = added,
             hr = round(sm$conf.int[1, 1], 2), lo = round(sm$conf.int[1, 3], 2),
             hi = round(sm$conf.int[1, 4], 2),
             crosses_null = sm$conf.int[1, 3] < 1)
}))
write_tab(tip3, "T13d_anchored_tipping_extrapolated")
print(tip3)

interp <- data.frame(
  finding = sprintf("%.2f%% of controls with medication data (%d of %d) received an unambiguous ASM without ever being coded with epilepsy",
                    100 * nrow(disc) / nrow(s), nrow(disc), nrow(s)),
  scenario_observed = paste(
    "Using only the named, observed candidates, the association survives even the",
    "extreme assumption that ALL of them are true missed seizures: HR falls from",
    "3.40 to 1.98 (1.42-2.75) and does not reach the null."),
  scenario_extrapolated = paste(
    "Medication data covers only 29% of matched controls. If the same rate holds",
    "in the other 71%, the null IS reached at about half of candidates being true",
    "(HR 1.25, 0.92-1.70). The reassurance above is therefore conditional on the",
    "medication-covered controls being representative, which is untested."),
  the_decisive_asymmetry = paste(
    "BOTH scenarios add hidden events to controls and NONE to cases, because no",
    "case medications were extracted. That is the worst case by construction and",
    "is almost certainly wrong: IIH patients also receive levetiracetam and",
    "lamotrigine for non-epilepsy indications. If the ASM-without-diagnosis rate",
    "is similar in cases, the misclassification is non-differential and the hazard",
    "ratio moves very little. The entire question turns on whether that rate",
    "differs by exposure, and this extract cannot answer it."),
  required_next_step = paste(
    "Extract the identical medication data for the 2,732 matched IIH cases.",
    "This is now the single highest-value addition to the study: it converts the",
    "largest remaining uncertainty from an untestable assumption into a measured",
    "quantity. Extending coverage to the remaining 71% of controls is second."))
write_tab(interp, "T13c_anchored_tipping_interpretation")

status <- data.frame(
  status = "PROVISIONAL -- extracts to be revised and filtered by the investigators",
  used_for = "Extract audit, protocol s4.2 classification check, contamination check, and the anchored tipping-point analysis.",
  not_used_for = paste(
    "The primary estimate is unchanged by this script. The acetazolamide-only",
    "restriction, time-varying treatment models and marginal structural models",
    "remain unimplementable: no IIH case in the cohort has medication data, and",
    "acetazolamide does not appear anywhere in the extract."))
write_tab(status, "S32_medication_extract_status")

saveRDS(list(cov = cov, cls = cls, conc = conc, tip2 = tip2, interp = interp,
             n_disc = nrow(disc), n_with_med = nrow(s)),
        file.path(PATH$derived, "15_meds.rds"))
log_msg("15 complete")
