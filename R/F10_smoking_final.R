## F10_smoking_final.R --------------------------------------------------------
## Repopulates smoking for controls from the social-history extract, so smoking
## can finally enter the multivariable model.
##
## Until now smoking was recorded only for cases (all 9,122 controls were coded
## "Unknown"), which made it perfectly nested within the exposure and forced its
## exclusion from every model. This extract fixes that.
##
## One caveat is structural and cannot be engineered away: social-history
## contact dates begin in 2017, while many index dates are earlier. For those
## patients the smoking record post-dates index and is not strictly a baseline
## covariate. The proportion is reported, and a pre-index-only sensitivity
## analysis is run alongside.

source("R/00_setup.R")
log_msg("=== F10 smoking ===")
d <- readRDS(file.path(PATH$derived, "F1_typed.rds"))
TAU <- 3

sh <- utils::read.csv(file.path("data-raw", "MDE_SocialHistory_smoking_1.csv"),
                      colClasses = "character", check.names = FALSE)
names(sh) <- c("mrn", "question", "abbrev", "contact_date", "answer")
sh$mrn <- trimws(sh$mrn)
sh$contact_date <- as.Date(substr(sh$contact_date, 1, 10))

## SMOKING_TOB_USE_C is the graded field; CIGARETTES_YN is a yes/no fallback.
smk <- sh[sh$abbrev == "SMOKING_TOB_USE_C", ]
map_smoke <- function(x) {
  x <- tolower(trimws(x))
  ifelse(x %in% c("never", "passive smoke exposure - never smoker"), "Never",
  ifelse(x == "former", "Former",
  ifelse(x %in% c("every day", "some days", "light smoker", "heavy smoker",
                  "current every day smoker", "current some day smoker"), "Current",
         NA_character_)))
}
smk$status <- map_smoke(smk$answer)
unmapped <- sort(table(smk$answer[is.na(smk$status)]), decreasing = TRUE)
write_tab(data.frame(answer = names(unmapped), n = as.integer(unmapped),
                     treated_as = "Unknown"), "F_S8_smoking_unmapped_answers")
smk <- smk[!is.na(smk$status), ]

d$mrn <- ifelse(d$iih == 1, d$record_id, d$clinic_number)

## Pick the record closest to index: the most recent on or before index if one
## exists, otherwise the earliest afterwards. Which rule fired is recorded, so
## the post-index records can be excluded in sensitivity analysis.
idx <- setNames(d$index_date, d$mrn)
smk <- smk[smk$mrn %in% d$mrn, ]
smk$idx_date <- idx[smk$mrn]
smk$delta <- as.numeric(smk$contact_date - smk$idx_date)
pick <- do.call(rbind, lapply(split(smk, smk$mrn), function(g) {
  pre <- g[g$delta <= 0, ]
  if (nrow(pre)) { r <- pre[which.max(pre$delta), ]; r$src <- "pre-index"; r }
  else { r <- g[which.min(g$delta), ]; r$src <- "post-index (dated after index)"; r }
}))
log_msg("controls/cases matched in social history: ", nrow(pick))

d$smoking_new <- NA_character_; d$smoking_src <- NA_character_
m <- match(d$mrn, pick$mrn)
d$smoking_new[!is.na(m)] <- pick$status[m[!is.na(m)]]
d$smoking_src[!is.na(m)] <- pick$src[m[!is.na(m)]]

## Cases already carry a graded status in the workbook; keep it where present
## and fall back to the extract, so both arms use the same categories.
case_ok <- d$iih == 1 & !is.na(d$smoking) & d$smoking != "Unknown"
d$smoking_final <- ifelse(case_ok, as.character(d$smoking), d$smoking_new)
d$smoking_final[is.na(d$smoking_final)] <- "Unknown"
d$smoking_final <- stats::relevel(factor(d$smoking_final,
    levels = c("Never", "Former", "Current", "Unknown")), ref = "Never")

cov <- do.call(rbind, lapply(c(1, 0), function(g) {
  s <- d[d$iih == g, ]
  data.frame(cohort = ifelse(g == 1, "IIH", "Non-IIH control"), n = nrow(s),
             Never = sum(s$smoking_final == "Never"),
             Former = sum(s$smoking_final == "Former"),
             Current = sum(s$smoking_final == "Current"),
             Unknown = sum(s$smoking_final == "Unknown"),
             pct_known = round(100 * mean(s$smoking_final != "Unknown"), 1))
}))
write_tab(cov, "F_T16a_smoking_coverage")
print(cov)

src <- as.data.frame(table(cohort = d$cohort, source = d$smoking_src, useNA = "ifany"))
write_tab(src, "F_T16b_smoking_record_timing")
print(src)
log_msg("records dated AFTER index: ",
        sum(d$smoking_src == "post-index (dated after index)", na.rm = TRUE))

## ---- is smoking now COMPARABLE across arms? --------------------------------
## Populating a variable is not the same as making it comparable. Case smoking
## comes from the workbook's chart abstraction; control smoking comes from
## social-history flowsheets. If the two sources grade smoking differently, the
## variable is differentially misclassified and adjusting for it can do more
## harm than leaving it out.
prov <- data.frame(
  category = c("Never", "Former", "Current"),
  iih_pct = round(100 * c(mean(d$smoking_final[d$iih==1] == "Never"),
                          mean(d$smoking_final[d$iih==1] == "Former"),
                          mean(d$smoking_final[d$iih==1] == "Current")), 1),
  control_pct = round(100 * c(mean(d$smoking_final[d$iih==0] == "Never"),
                              mean(d$smoking_final[d$iih==0] == "Former"),
                              mean(d$smoking_final[d$iih==0] == "Current")), 1))
prov$ratio <- round(prov$control_pct / pmax(prov$iih_pct, 0.01), 1)
prov$source_iih <- "workbook chart abstraction"
prov$source_control <- "social-history flowsheet"
prov$assessment <- ifelse(prov$ratio > 3 | prov$ratio < 0.33,
  "IMPLAUSIBLE as biology -- this is a measurement difference, not a real one",
  "compatible")
write_tab(prov, "F_T16e_smoking_comparability")
print(prov)

## ---- smoking is now adjustable ---------------------------------------------
s3 <- d; s3$t <- pmin(s3$t_y, TAU)
s3$ev <- ifelse(s3$t_y > TAU, 0L, as.integer(s3$event))
s3$log_enc_pre <- log1p(s3$enc_pre12)
fitm <- function(rhs, lab, dat = s3) {
  fit <- survival::coxph(stats::as.formula(paste("Surv(t, ev) ~", rhs)),
                         data = dat, cluster = dat$match_set, robust = TRUE)
  sm <- summary(fit)
  data.frame(model = lab, n = fit$n, events = fit$nevent,
             HR_IIH = fmt_est(sm$conf.int[1,1], sm$conf.int[1,3], sm$conf.int[1,4]),
             p = fmt_p(sm$coefficients[1, ncol(sm$coefficients)]))
}
BASE <- "iih + age_index + bmi_index + sex + osa + htn + pcos + log_enc_pre"
mods <- rbind(
  fitm("iih", "Crude"),
  fitm(BASE, "Adjusted, smoking EXCLUDED (previous model)"),
  fitm(paste(BASE, "+ smoking_final"), "Adjusted, smoking INCLUDED (new)"),
  fitm(paste(BASE, "+ smoking_final"), "Adjusted + smoking, pre-index records only",
       dat = s3[is.na(s3$smoking_src) | s3$smoking_src == "pre-index", ]))
write_tab(mods, "F_T16c_models_with_smoking")
print(mods)

## Full coefficient table of the smoking-adjusted model.
fitf <- survival::coxph(stats::as.formula(paste("Surv(t, ev) ~", BASE, "+ smoking_final")),
                        data = s3, cluster = s3$match_set, robust = TRUE)
smf <- summary(fitf)
coefs <- data.frame(term = rownames(smf$coefficients),
                    HR = round(smf$conf.int[,1], 3), lo = round(smf$conf.int[,3], 3),
                    hi = round(smf$conf.int[,4], 3),
                    p = fmt_p(smf$coefficients[, ncol(smf$coefficients)]), row.names = NULL)
coefs$estimate <- fmt_est(coefs$HR, coefs$lo, coefs$hi)
write_tab(coefs[, c("term", "estimate", "p")], "F_T16d_smoking_model_coefficients")
print(coefs[, c("term", "estimate", "p")])

saveRDS(list(cov = cov, src = src, mods = mods, coefs = coefs),
        file.path(PATH$derived, "F10_smoking.rds"))
log_msg("F10 complete")
