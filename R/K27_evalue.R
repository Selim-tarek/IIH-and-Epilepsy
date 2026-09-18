## K27: E-values for the primary estimate, and comparison against the
## observed surveillance rate ratios. VanderWeele & Ding (2017).
## Outcome is rare (3.83% vs 1.71% at 3 years), so HR ~ RR.

ev <- function(rr) if (rr >= 1) rr + sqrt(rr * (rr - 1)) else {r <- 1/rr; r + sqrt(r*(r-1))}

HR <- 2.28; LO <- 1.62; HI <- 3.22

cat("=== E-values for the primary estimate ===\n")
cat(sprintf("  HR point estimate %.2f -> E-value %.2f\n", HR, ev(HR)))
cat(sprintf("  CI lower limit    %.2f -> E-value %.2f\n", LO, ev(LO)))

cat("\n=== observed post-index surveillance rate ratios (K26) ===\n")
surv <- c(visits = 2.70, hospital = 2.27, ED = 5.74, laboratory = 1.14)
for (n in names(surv))
  cat(sprintf("  %-12s RR %.2f  %s\n", n, surv[[n]],
      ifelse(surv[[n]] >= ev(HR), "EXCEEDS the E-value threshold",
      ifelse(surv[[n]] >= ev(LO), "exceeds the CI-bound threshold only", "below both thresholds"))))

cat("\n=== interpretation ===\n")
cat(sprintf("  To explain away HR %.2f entirely, an unmeasured mechanism would need to be\n", HR))
cat(sprintf("  associated with BOTH IIH status AND seizure ascertainment by >= %.2f-fold each,\n", ev(HR)))
cat("  conditional on the measured covariates. Marginal association at that magnitude is\n")
cat("  NOT sufficient -- the E-value is a threshold on the conditional associations.\n")
cat(sprintf("  To move the CI to include 1 requires >= %.2f-fold on both.\n", ev(LO)))
cat("\n  NOTE: ED contact RR (5.74) exceeds the point-estimate threshold. This is a caveat,\n")
cat("  not a reassurance: ED contact is a plausible ascertainment channel for seizures and\n")
cat("  its magnitude is compatible with a substantial detection contribution.\n")

out <- data.frame(
  quantity = c("E-value, point estimate", "E-value, CI limit nearest the null",
               "surveillance RR, all clinical visits", "surveillance RR, office or clinic",
               "surveillance RR, procedural or diagnostic", "surveillance RR, hospital or inpatient",
               "surveillance RR, emergency department", "surveillance RR, laboratory"),
  value = c(round(ev(HR),2), round(ev(LO),2), 2.70, 2.92, 2.32, 2.27, 5.74, 1.14),
  vs_threshold = c("-", "-", "below point-estimate threshold", "below point-estimate threshold",
                   "below point-estimate threshold", "below both thresholds",
                   "EXCEEDS point-estimate threshold", "below both thresholds"),
  stringsAsFactors = FALSE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)
write.csv(out, "outputs/tables/K_T56_evalue.csv", row.names = FALSE)
cat("\nwrote outputs/tables/K_T56_evalue.csv\n")
cat("NOTE: supersedes T4e_evalue.csv (4.92 / 3.27), computed against an earlier estimate.\n")
