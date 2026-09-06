## 13_radiology_text_extraction.R ---------------------------------------------
## EXPLORATORY -- NOT VALIDATED. Read this header before using any output.
##
## The radiology export contains 3,115 free-text MRI reports, one per patient.
## They link to 2,808 of 3,601 IIH cases via clinic number and to ZERO controls,
## so nothing here can support a case-control comparison. What it CAN do is
## raise the number of IIH cases with an assessable encephalocele / imaging
## phenotype from 90 (2.5%) to a much larger fraction, making the WITHIN-IIH
## imaging questions answerable for the first time.
##
## Three rules govern this script:
##   1. "Not mentioned" is its own category. A report that never discusses the
##      skull base is NOT a negative report. This mirrors the 88/99 distinction
##      in the main export and is the single easiest way to corrupt the study.
##   2. Negation is detected explicitly ("no", "without", "negative for",
##      "no evidence of"), within the sentence containing the term.
##   3. NO OUTPUT OF THIS SCRIPT IS USED IN ANY INFERENTIAL MODEL. It produces
##      counts and a per-patient review file. A manually reviewed sample must
##      establish precision and recall before any of it enters an analysis.

source("R/00_setup.R")
log_msg("=== 13 radiology text extraction (EXPLORATORY) ===")

RAD <- "MDE Workflow Results for Radiology (25).csv"
if (!file.exists(RAD)) { log_msg("radiology file absent; skipping"); quit(save = "no") }

rad <- utils::read.csv(RAD, colClasses = "character", check.names = FALSE)
names(rad) <- c("clinic_number", "report", "modality_code", "modality", "rad_date")
rad$clinic_number <- trimws(rad$clinic_number)
rad$rad_date <- as.Date(substr(rad$rad_date, 1, 10))
rad$txt <- tolower(gsub("[[:space:]]+", " ", rad$report))
log_msg("reports: ", nrow(rad), " | unique patients: ",
        length(unique(rad$clinic_number)), " | all one report per patient: ",
        !any(duplicated(rad$clinic_number)))

d <- readRDS(file.path(PATH$derived, "01_typed.rds"))
case_ids <- d$record_id[d$iih == 1]
ctl_ids  <- d$clinic_number[d$iih == 0]
link <- data.frame(
  linkage = c("Reports matching an IIH case record_id",
              "Reports matching a control clinic_number",
              "IIH cases with no report", "Reports matching neither cohort"),
  n = c(sum(rad$clinic_number %in% case_ids),
        sum(rad$clinic_number %in% ctl_ids),
        sum(!case_ids %in% rad$clinic_number),
        sum(!rad$clinic_number %in% c(case_ids, ctl_ids))))
write_tab(link, "S21_radiology_linkage")
print(link)

## ---- term definitions ------------------------------------------------------
## Each finding is a set of surface forms. Deliberately generous on synonyms and
## deliberately strict on negation: a false "not mentioned" costs less than a
## false "absent".
TERMS <- list(
  encephalocele   = c("encephalocele", "encephalocoele", "cephalocele",
                      "cephalocoele", "meningocele", "meningocoele",
                      "meningoencephalocele"),
  empty_sella     = c("empty sella", "partially empty sella", "partial empty sella",
                      "empty-appearing sella"),
  sinus_stenosis  = c("transverse sinus stenosis", "venous sinus stenosis",
                      "sigmoid sinus stenosis", "transverse sinus narrowing",
                      "venous sinus narrowing", "sinus stenosis"),
  onsd_distension = c("optic nerve sheath distension", "optic nerve sheath distention",
                      "distended optic nerve sheath", "prominent optic nerve sheath",
                      "optic nerve sheath dilat"),
  globe_flattening= c("posterior globe flattening", "flattening of the posterior globe",
                      "globe flattening", "posterior scleral flattening"),
  skullbase_thin  = c("skull base thinning", "thinning of the skull base",
                      "attenuation of the skull base", "osseous thinning",
                      "thinned skull base"),
  csf_leak        = c("csf leak", "cerebrospinal fluid leak", "csf fistula"),
  tonsillar_desc  = c("tonsillar ectopia", "tonsillar descent", "tonsillar herniation",
                      "cerebellar tonsillar"))

NEG_CUES <- c("no ", "no evidence of", "without", "negative for", "absence of",
              "not identified", "not seen", "not demonstrated", "unremarkable for",
              "rather than", "no definite", "no significant")

## Split into sentences, then decide status per finding from the sentences that
## mention it. If ANY mentioning sentence is unnegated, the finding is positive:
## radiologists negate a differential far more often than they retract a
## positive statement.
classify <- function(txt, patterns) {
  sent <- unlist(strsplit(txt, "(?<=[.;:])\\s+", perl = TRUE))
  hit <- grepl(paste(patterns, collapse = "|"), sent, fixed = FALSE)
  if (!any(hit)) return("not_mentioned")
  ms <- sent[hit]
  negated <- vapply(ms, function(s) {
    ## Look only at the text BEFORE the first matched term in that sentence.
    p <- regexpr(paste(patterns, collapse = "|"), s)
    pre <- substr(s, 1, max(1, p - 1))
    any(vapply(NEG_CUES, function(c) grepl(c, pre, fixed = TRUE), logical(1)))
  }, logical(1))
  if (all(negated)) "negated" else "positive"
}

for (f in names(TERMS)) {
  rad[[paste0("txt_", f)]] <- vapply(rad$txt, classify, character(1),
                                     patterns = TERMS[[f]], USE.NAMES = FALSE)
}

## ---- yield summary ---------------------------------------------------------
in_case <- rad$clinic_number %in% case_ids
yield <- do.call(rbind, lapply(names(TERMS), function(f) {
  v <- rad[[paste0("txt_", f)]][in_case]
  data.frame(finding = f,
             positive = sum(v == "positive"),
             negated = sum(v == "negated"),
             not_mentioned = sum(v == "not_mentioned"),
             pct_addressed = round(100 * mean(v != "not_mentioned"), 1))
}))
write_tab(yield, "T10_radiology_text_yield")
print(yield)

## ---- what this would add to the structured data ----------------------------
## Compares text-derived status against the structured field, for the findings
## where a structured field exists. Disagreement is expected and is exactly what
## the manual review sample must adjudicate; it is NOT resolved here.
cmp_map <- c(encephalocele = "enceph_index", empty_sella = "empty_sella",
             sinus_stenosis = "sinus_sten", onsd_distension = "onsd_distend",
             globe_flattening = "globe_flat", skullbase_thin = "skullbase_thin",
             csf_leak = "csf_leak")
dc <- d[d$iih == 1, ]
dc$key <- dc$record_id
rr <- rad[in_case, ]
mg <- merge(dc, rr[, c("clinic_number", paste0("txt_", names(TERMS)))],
            by.x = "key", by.y = "clinic_number")
gain <- do.call(rbind, lapply(names(cmp_map), function(f) {
  st <- mg[[cmp_map[[f]] ]]; sts <- mg[[paste0(cmp_map[[f]], "_status")]]
  tx <- mg[[paste0("txt_", f)]]
  data.frame(
    finding = f,
    structured_assessed = sum(sts == "assessed"),
    text_addressed = sum(tx != "not_mentioned"),
    newly_addressable = sum(sts != "assessed" & tx != "not_mentioned"),
    agree_both_assessed = sum(sts == "assessed" & tx != "not_mentioned" &
                              ((st == 1 & tx == "positive") | (st == 0 & tx == "negated")),
                              na.rm = TRUE),
    disagree_both_assessed = sum(sts == "assessed" & tx != "not_mentioned" &
                              ((st == 1 & tx == "negated") | (st == 0 & tx == "positive")),
                              na.rm = TRUE))
}))
write_tab(gain, "T10b_radiology_text_vs_structured")
print(gain)

## ---- per-patient output for manual review ----------------------------------
## This is the file an abstractor works from. It carries the sentence that drove
## each call so a reviewer can adjudicate without re-reading the whole report.
evidence <- function(txt, patterns) {
  sent <- unlist(strsplit(txt, "(?<=[.;:])\\s+", perl = TRUE))
  hit <- grepl(paste(patterns, collapse = "|"), sent)
  if (!any(hit)) return(NA_character_)
  substr(paste(sent[hit], collapse = " || "), 1, 400)
}
review <- rr[, c("clinic_number", "rad_date", paste0("txt_", names(TERMS)))]
for (f in names(TERMS))
  review[[paste0("evidence_", f)]] <- vapply(rr$txt, evidence, character(1),
                                             patterns = TERMS[[f]], USE.NAMES = FALSE)
write_tab(review, "S22_radiology_per_patient_for_review")

## A stratified review sample: all text-positive encephalocele calls plus a
## random sample of negated and not-mentioned reports. Sampling fractions are
## recorded so that precision/recall can later be corrected for the design.
set.seed(SEED)
pos <- which(review$txt_encephalocele == "positive")
neg <- which(review$txt_encephalocele == "negated")
nom <- which(review$txt_encephalocele == "not_mentioned")
samp <- rbind(
  data.frame(stratum = "positive", idx = pos, sampling_fraction = 1),
  data.frame(stratum = "negated", idx = sample(neg, min(100, length(neg))),
             sampling_fraction = min(100, length(neg)) / max(1, length(neg))),
  data.frame(stratum = "not_mentioned", idx = sample(nom, min(100, length(nom))),
             sampling_fraction = min(100, length(nom)) / max(1, length(nom))))
samp_out <- cbind(samp[, c("stratum", "sampling_fraction")], review[samp$idx, ])
write_tab(samp_out, "S23_radiology_review_sample")
log_msg("review sample: ", nrow(samp_out), " reports (all ", length(pos),
        " text-positive + sampled negatives)")

warn <- data.frame(
  status = "EXPLORATORY -- NOT VALIDATED, NOT USED IN ANY MODEL",
  requirements_before_use = paste(
    "1. An abstractor blinded to outcome status must review",
    "S23_radiology_review_sample.csv and record a gold-standard call per report.",
    "2. Precision and recall must be estimated, weighted by the recorded",
    "sampling fractions (the strata are sampled at different rates, so an",
    "unweighted estimate would be wrong).",
    "3. Only findings meeting a pre-specified precision threshold may enter an",
    "analysis, and 'not mentioned' must remain a distinct category throughout.",
    "4. Because reports exist for cases only, any resulting variable supports",
    "WITHIN-IIH analyses exclusively. It can never be used to compare cases",
    "with controls."))
write_tab(warn, "S24_radiology_extraction_status")
log_msg("13 complete")
