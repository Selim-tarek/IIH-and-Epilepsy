## Z5_comorbidity_adjustment.R ------------------------------------------------
## Sensitivity: adjust for the baseline comorbidities that matching did not
## balance. Obstructive sleep apnoea (SMD 0.342), polycystic ovary syndrome
## (0.171) and hypertension (0.146) all exceed the 0.10 threshold and are
## recorded in BOTH arms, so they are adjustable.
##
## OSA is the substantive concern: it has an established association with
## epilepsy and is nearly twice as common in the IIH arm.
##
## Stated before running: the result is reported whatever it shows. Every
## covariate here is measured at or before the index date, so none is a
## collider. The primary estimate remains the unadjusted matched one; this is a
## sensitivity analysis, not a replacement.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== Z5 comorbidity-adjusted sensitivity ===")
V <- readRDS(file.path(PATH$derived, "K15_final_visits.rds")); a <- V$a
K <- readRDS(file.path(PATH$derived, "K24_analysis.rds")); K <- if (is.data.frame(K)) K else K$a
a$pre12 <- K$pre12[match(a$mrn, K$mrn)]
assert(!all(is.na(a$pre12)), "pre-index visits did not join")

for (v in c("osa", "htn", "pcos")) {
  x <- suppressWarnings(as.integer(a[[v]])); x[is.na(x)] <- 0L; a[[v]] <- x
}

fit <- function(rhs, label) {
  f <- stats::as.formula(paste0("Surv(t, ev) ~ ", rhs, " + cluster(match_set)"))
  s <- summary(coxph(f, data = a))
  i <- which(rownames(s$conf.int) == "iih")
  data.frame(model = label,
             HR = sprintf("%.2f (%.2f to %.2f)",
                          s$conf.int[i, 1], s$conf.int[i, 3], s$conf.int[i, 4]),
             p  = signif(s$coef[i, 6], 3),
             change = NA_character_, stringsAsFactors = FALSE)
}

out <- rbind(
  fit("iih",                                  "Primary (matched, unadjusted)"),
  fit("iih + osa",                            "+ obstructive sleep apnoea"),
  fit("iih + htn",                            "+ hypertension"),
  fit("iih + pcos",                           "+ polycystic ovary syndrome"),
  fit("iih + osa + htn + pcos",               "+ all three comorbidities"),
  fit("iih + osa + htn + pcos + log1p(pre12)","+ all three, and pre-index visits"))

base <- as.numeric(sub(" .*", "", out$HR[1]))
out$change <- c("—", sprintf("%+.1f%%", 100 * (as.numeric(sub(" .*", "", out$HR[-1])) / base - 1)))

write_tab(out, "Z_T04_comorbidity_adjusted")
print(out, row.names = FALSE, right = FALSE)

## Is OSA itself associated with the outcome in this cohort? If it is not, it
## cannot confound regardless of how imbalanced it is.
so <- summary(coxph(Surv(t, ev) ~ osa + cluster(match_set), data = a))
sh <- summary(coxph(Surv(t, ev) ~ htn + cluster(match_set), data = a))
sp <- summary(coxph(Surv(t, ev) ~ pcos + cluster(match_set), data = a))
cc <- data.frame(
  covariate = c("Obstructive sleep apnoea", "Hypertension", "Polycystic ovary syndrome"),
  prevalence_iih = sprintf("%.1f%%", 100 * sapply(c("osa","htn","pcos"), function(v) mean(a[[v]][a$iih==1]))),
  prevalence_ctl = sprintf("%.1f%%", 100 * sapply(c("osa","htn","pcos"), function(v) mean(a[[v]][a$iih==0]))),
  SMD = sprintf("%.3f", sapply(c("osa","htn","pcos"), function(v) smd_bin(a[[v]], a$iih))),
  HR_for_outcome = c(
    sprintf("%.2f (%.2f to %.2f)", so$conf.int[1,1], so$conf.int[1,3], so$conf.int[1,4]),
    sprintf("%.2f (%.2f to %.2f)", sh$conf.int[1,1], sh$conf.int[1,3], sh$conf.int[1,4]),
    sprintf("%.2f (%.2f to %.2f)", sp$conf.int[1,1], sp$conf.int[1,3], sp$conf.int[1,4])),
  p = signif(c(so$coef[1,6], sh$coef[1,6], sp$coef[1,6]), 3),
  stringsAsFactors = FALSE, row.names = NULL)
write_tab(cc, "Z_T05_confounder_criteria")
print(cc, row.names = FALSE, right = FALSE)
log_msg("Z5 complete")
