## F3_medications_final.R -----------------------------------------------------
## Links the medication extracts to the FINAL cohort and re-runs the anchored
## tipping-point analysis on it. PROVISIONAL: the extracts are still to be
## revised and filtered by the investigators.
##
## Coverage remains the binding constraint: medications exist for controls only.
## The acetazolamide-only restriction, time-varying treatment models and
## marginal structural models therefore remain unimplementable.

source("R/00_setup.R")
log_msg("=== F3 medications (FINAL cohort, PROVISIONAL) ===")
f_sum <- file.path("data-raw", "IIH_medications_patient_summary.csv")
f_det <- file.path("data-raw", "IIH_medications_detail.csv")
if (!file.exists(f_sum)) { log_msg("medication extract absent; skipping"); quit(save = "no") }

d <- readRDS(file.path(PATH$derived, "F1_typed.rds"))
summ <- utils::read.csv(f_sum, colClasses = "character", check.names = FALSE)
det  <- utils::read.csv(f_det, colClasses = "character", check.names = FALSE)
TAU <- 3

cut_at <- function(dat, tau) {
  dat$t  <- pmin(dat$t_y, tau)
  dat$ev <- ifelse(dat$t_y > tau, 0L, as.integer(dat$event))
  dat
}

## ---- coverage against the FINAL cohort -------------------------------------
cov <- data.frame(
  item = c("IIH cases in final cohort", "  with medication data",
           "Controls in final cohort", "  with medication data",
           "Acetazolamide rows anywhere in the extract"),
  n = c(sum(d$iih == 1), sum(d$record_id[d$iih == 1] %in% summ$record_id),
        sum(d$iih == 0), sum(d$record_id[d$iih == 0] %in% summ$record_id),
        sum(grepl("acetazolamide", tolower(det$medication_name)))))
write_tab(cov, "F_T12_medication_coverage")
print(cov)

## ---- ASM classification against protocol s4.2 ------------------------------
## Gabapentin and pregabalin are neuropathic-pain drugs and must NOT count as
## antiseizure medication; topiramate and acetazolamide are IIH treatments.
mn <- tolower(det$medication_name)
chk <- do.call(rbind, lapply(
  list(c("gabapentin", "NOT an ASM"), c("pregabalin", "NOT an ASM"),
       c("topiramate", "NOT counted (IIH treatment)"),
       c("acetazolamide", "NOT counted (IIH treatment)"),
       c("levetiracetam", "counted"), c("zonisamide", "counted"),
       c("lorazepam", "NOT counted (sedation)")),
  function(z) {
    i <- grepl(z[1], mn, fixed = TRUE)
    data.frame(drug = z[1], n_rows = sum(i),
               class_assigned = paste(unique(det$medication_class[i]), collapse = "; "),
               counted_as_asm = paste(unique(det$asm_generic[i] != ""), collapse = "/"),
               protocol_expectation = z[2])
  }))
chk$agrees <- ifelse(chk$n_rows == 0, "no rows",
  ifelse(grepl("NOT", chk$protocol_expectation) == grepl("FALSE", chk$counted_as_asm),
         "YES", "REVIEW"))
write_tab(chk, "F_T12c_asm_classification_check")
print(chk[, c("drug", "n_rows", "class_assigned", "agrees")])

## ---- ASM against the recorded outcome, in controls -------------------------
ctl <- d$record_id[d$iih == 0]
s <- merge(summ[summ$record_id %in% ctl,
                c("record_id", "asm_ever", "asm_pre_index", "asm_post_index",
                  "asm_list", "first_asm_date")],
           d[, c("record_id", "event", "index_date", "t_y")], by = "record_id")
conc <- as.data.frame(table(asm_ever = s$asm_ever, outcome = s$event))
write_tab(conc, "F_T13_asm_vs_outcome_controls")
disc <- s[s$asm_ever == "1" & s$event == 0, ]
log_msg("controls on an unambiguous ASM with NO recorded outcome: ", nrow(disc),
        sprintf(" (%.2f%% of %d covered)", 100 * nrow(disc) / nrow(s), nrow(s)))

## ---- anchored tipping point -------------------------------------------------
## These are named controls who received an unambiguous ASM and were never coded
## with epilepsy. Their first ASM date supplies a real event time. They are NOT
## all missed epilepsy -- levetiracetam and lamotrigine have common non-epilepsy
## indications -- so the fraction that is real is swept rather than asserted.
s$first_asm <- as.Date(substr(s$first_asm_date, 1, 10))
s$asm_t <- as.numeric(s$first_asm - s$index_date) / 365.25 - 180 / 365.25
cand <- s$record_id[s$asm_ever == "1" & s$event == 0 & !is.na(s$asm_t) & s$asm_t > 0]
asm_t <- setNames(s$asm_t, s$record_id)
base <- cut_at(d, TAU)

tip <- do.call(rbind, lapply(c(0, 0.25, 0.5, 0.75, 1), function(fr) {
  set.seed(SEED)
  ss <- base
  hit <- if (fr > 0) sample(cand, round(fr * length(cand))) else character(0)
  i <- match(hit, ss$record_id); i <- i[!is.na(i)]
  ok <- 0
  if (length(i)) {
    te <- asm_t[ss$record_id[i]]
    w <- !is.na(te) & te > 0 & te <= ss$t[i]
    ss$ev[i[w]] <- 1L; ss$t[i[w]] <- te[w]; ok <- sum(w)
  }
  fit <- survival::coxph(Surv(t, ev) ~ iih, data = ss, cluster = ss$match_set,
                         robust = TRUE)
  sm <- summary(fit)
  data.frame(pct_of_ASM_discordant_assumed_true = 100 * fr,
             events_added = ok, hr = round(sm$conf.int[1,1], 2),
             lo = round(sm$conf.int[1,3], 2), hi = round(sm$conf.int[1,4], 2),
             crosses_null = sm$conf.int[1,3] < 1)
}))
write_tab(tip, "F_T13b_anchored_tipping_point")
print(tip)

## Extrapolated: medication data covers only part of the control arm, so the
## same rate is applied to the uncovered remainder. Events are added to controls
## only, because no case medications exist -- a worst case by construction.
rate <- nrow(disc) / nrow(s)
tip_x <- do.call(rbind, lapply(c(0, 0.5, 1), function(fr) {
  set.seed(SEED)
  ss <- base
  hit <- if (fr > 0) sample(cand, round(fr * length(cand))) else character(0)
  i <- match(hit, ss$record_id); i <- i[!is.na(i)]
  if (length(i)) { te <- asm_t[ss$record_id[i]]
    w <- !is.na(te) & te > 0 & te <= ss$t[i]
    ss$ev[i[w]] <- 1L; ss$t[i[w]] <- te[w] }
  unseen <- which(ss$iih == 0 & ss$ev == 0 & !(ss$record_id %in% s$record_id))
  k <- round(fr * rate * length(unseen))
  if (k > 0) { h2 <- sample(unseen, k); ss$ev[h2] <- 1L
               ss$t[h2] <- stats::runif(k) * ss$t[h2] }
  fit <- survival::coxph(Surv(t, ev) ~ iih, data = ss, cluster = ss$match_set,
                         robust = TRUE)
  sm <- summary(fit)
  data.frame(pct_assumed_true = 100 * fr, extrapolated_added = k,
             hr = round(sm$conf.int[1,1], 2), lo = round(sm$conf.int[1,3], 2),
             hi = round(sm$conf.int[1,4], 2), crosses_null = sm$conf.int[1,3] < 1)
}))
write_tab(tip_x, "F_T13d_anchored_tipping_extrapolated")
print(tip_x)

status <- data.frame(
  status = "PROVISIONAL -- extracts pending investigator revision",
  coverage = sprintf("Controls covered: %d of %d. IIH cases covered: %d of %d.",
                     sum(d$record_id[d$iih == 0] %in% summ$record_id), sum(d$iih == 0),
                     sum(d$record_id[d$iih == 1] %in% summ$record_id), sum(d$iih == 1)),
  still_blocked = paste("Acetazolamide-only restriction, time-varying treatment models",
                        "and marginal structural models: no case medications, and",
                        "acetazolamide appears nowhere in the extract."),
  decisive_asymmetry = paste(
    "Both tipping scenarios add hidden events to controls and none to cases,",
    "because no case medications were extracted. If IIH patients have a similar",
    "rate of ASM-without-diagnosis the misclassification is non-differential and",
    "the hazard ratio barely moves. Extracting case medications would settle it."))
write_tab(status, "F_S7_medication_status")
saveRDS(list(cov = cov, chk = chk, tip = tip, tip_x = tip_x, n_disc = nrow(disc),
             n_cov = nrow(s)), file.path(PATH$derived, "F3_meds.rds"))
log_msg("F3 complete")
