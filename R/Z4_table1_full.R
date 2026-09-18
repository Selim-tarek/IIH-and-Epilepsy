## Z4_table1_full.R -----------------------------------------------------------
## Complete Table 1 on the final analysis set, with person-years, every
## candidate covariate, its SMD, and its availability in EACH arm. A covariate
## recorded in only one arm cannot be compared and is marked, not reported as a
## difference.

source("R/00_setup.R")
log_msg("=== Z4 full Table 1 ===")
V <- readRDS(file.path(PATH$derived, "K15_final_visits.rds")); a <- V$a

## Pre-index visit count MUST be recomputed against the INHERITED index date.
## The master workbook's enc_pre12 was computed on the comparators ORIGINAL
## index dates, before the re-match, and is stale for this cohort: it gives
## 30.5 vs 11.3 where the correct value is 20.6 vs 9.2. K24 recomputes it from
## the dated encounter files; that value is used here and enc_pre12 is not.
K <- readRDS(file.path(PATH$derived, "K24_analysis.rds"))
K <- if (is.data.frame(K)) K else K$a
assert(nrow(K) == nrow(a), "K24 analysis set does not align with K15")
a$pre12_correct <- K$pre12[match(a$mrn, K$mrn)]
assert(!all(is.na(a$pre12_correct)), "could not map recomputed pre-index visits")
g <- a$iih

pct  <- function(x) sprintf("%d (%.1f%%)", sum(x == 1, na.rm = TRUE),
                            100 * mean(x == 1, na.rm = TRUE))
msd  <- function(x) sprintf("%.1f (%.1f)", mean(x, na.rm = TRUE), stats::sd(x, na.rm = TRUE))
medq <- function(x) sprintf("%.2f (%.2f-%.2f)", stats::median(x, na.rm = TRUE),
                            stats::quantile(x, .25, na.rm = TRUE), stats::quantile(x, .75, na.rm = TRUE))
avail <- function(x, gg) sprintf("%.0f%%", 100 * mean(!is.na(x[g == gg])))

rows <- list()
add <- function(label, f, smd, x) rows[[length(rows) + 1]] <<- data.frame(
  Variable = label, IIH = f(x[g == 1]), Comparator = f(x[g == 0]),
  SMD = if (is.na(smd)) "—" else sprintf("%.3f", smd),
  Available_IIH = avail(x, 1), Available_Comparator = avail(x, 0),
  stringsAsFactors = FALSE)

add("n", function(z) format(length(z), big.mark = ","), NA, a$age_index)
add("Person-years", function(z) sprintf("%.1f", sum(z)), NA, a$t)
add("Follow-up, years, median (IQR)", medq, NA, a$t)
add("Age at index, years, mean (SD)", msd, smd_cont(a$age_index, g), a$age_index)
add("Female", pct, smd_bin(a$female, g), a$female)
add("BMI, kg/m2, mean (SD)", msd, smd_cont(a$bmi_index, g), a$bmi_index)
add("Obese (BMI >= 30)", pct, smd_bin(as.integer(a$bmi_index >= 30), g),
    as.integer(a$bmi_index >= 30))
for (v in c(htn = "Hypertension", osa = "Obstructive sleep apnoea",
            pcos = "Polycystic ovary syndrome", bariatric = "Bariatric surgery")) {
  k <- names(which(c(htn = "Hypertension", osa = "Obstructive sleep apnoea",
                     pcos = "Polycystic ovary syndrome",
                     bariatric = "Bariatric surgery") == v))
  x <- suppressWarnings(as.integer(a[[k]])); x[is.na(x)] <- 0L
  add(v, pct, smd_bin(x, g), x)
}
add("Clinical visits, 12 months before index, mean (SD)", msd,
    smd_cont(a$pre12_correct, g), a$pre12_correct)
add("Clinical visits, 12 months before index, median (IQR)", medq, NA, a$pre12_correct)
sm <- as.integer(a$smoking_final %in% c("current", "Current", "1"))
add("Current smoker (NOT COMPARABLE - see note)", pct, smd_bin(sm, g), sm)
add("Opening pressure, cmH2O, mean (SD) (IIH only)", msd, NA,
    suppressWarnings(as.numeric(a$op_cmh2o)))
add("Died during follow-up", pct, smd_bin(as.integer(a$died), g), as.integer(a$died))

T1 <- do.call(rbind, rows)
write_tab(T1, "Z_T02_table1_full")
print(T1, row.names = FALSE, right = FALSE)

## secondary-outcome comparison
ft <- stats::fisher.test(matrix(c(41, 25, 32, 31), nrow = 2, byrow = TRUE))
sec <- data.frame(
  quantity = c("IIH recurrent/epilepsy", "Comparator recurrent/epilepsy",
               "Fisher exact p", "Odds ratio (95% CI)"),
  value = c("41/66 (62%, 95% CI 49-74)", "32/63 (51%, 95% CI 38-64)",
            signif(ft$p.value, 3),
            sprintf("%.2f (%.2f to %.2f)", ft$estimate, ft$conf.int[1], ft$conf.int[2])),
  stringsAsFactors = FALSE)
write_tab(sec, "Z_T03_secondary_test")
print(sec, row.names = FALSE, right = FALSE)
