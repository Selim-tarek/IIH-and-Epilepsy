## Z6_age_sensitivity.R -------------------------------------------------------
## The analysis set contains 106 patients under 18 (62 IIH, 44 comparators;
## youngest 13). No lower age bound was applied. It also stops abruptly at ~59
## in both arms, which is a property of the supplied extract, not of this
## analysis. Both facts are established here and the restriction to >=18 is run
## as a sensitivity.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== Z6 age bounds and >=18 sensitivity ===")
V  <- readRDS(file.path(PATH$derived, "K15_final_visits.rds")); a <- V$a
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds"))

## Where does the upper bound come from -- the source extract, or matching?
src <- data.frame(
  stage = c("Source master (all supplied patients)", "  of which IIH", "  of which comparators",
            "Final analysis set", "  of which IIH", "  of which comparators"),
  n = c(nrow(d0), sum(d0$iih == 1), sum(d0$iih == 0),
        nrow(a), sum(a$iih == 1), sum(a$iih == 0)),
  min_age = round(c(min(d0$age_index, na.rm = TRUE), min(d0$age_index[d0$iih==1], na.rm=TRUE),
                    min(d0$age_index[d0$iih==0], na.rm=TRUE), min(a$age_index),
                    min(a$age_index[a$iih==1]), min(a$age_index[a$iih==0])), 1),
  max_age = round(c(max(d0$age_index, na.rm = TRUE), max(d0$age_index[d0$iih==1], na.rm=TRUE),
                    max(d0$age_index[d0$iih==0], na.rm=TRUE), max(a$age_index),
                    max(a$age_index[a$iih==1]), max(a$age_index[a$iih==0])), 1),
  under18 = c(sum(d0$age_index < 18, na.rm=TRUE), sum(d0$age_index[d0$iih==1] < 18, na.rm=TRUE),
              sum(d0$age_index[d0$iih==0] < 18, na.rm=TRUE), sum(a$age_index < 18),
              sum(a$age_index[a$iih==1] < 18), sum(a$age_index[a$iih==0] < 18)),
  stringsAsFactors = FALSE)
write_tab(src, "Z_T06_age_bounds")
print(src, row.names = FALSE, right = FALSE)

## >=18 restriction. Matched sets are kept intact where possible: dropping a
## case would orphan its comparators, so sets are reported both ways.
fit <- function(dat, lab) {
  s <- summary(coxph(Surv(t, ev) ~ iih + cluster(match_set), data = dat))
  data.frame(analysis = lab,
             iih = sprintf("%d/%d", sum(dat$ev[dat$iih==1]), sum(dat$iih==1)),
             comparator = sprintf("%d/%d", sum(dat$ev[dat$iih==0]), sum(dat$iih==0)),
             HR = sprintf("%.2f (%.2f to %.2f)", s$conf.int[1], s$conf.int[3], s$conf.int[4]),
             p = signif(s$coef[1,6], 3), stringsAsFactors = FALSE)
}
b <- a[a$age_index >= 18, ]
keep <- intersect(unique(b$match_set[b$iih==1]), unique(b$match_set[b$iih==0]))
cc <- b[b$match_set %in% keep, ]

out <- rbind(
  fit(a,  "Primary (no age restriction; ages 13.0-59.1)"),
  fit(b,  "Restricted to age >= 18 at index"),
  fit(cc, "Age >= 18, complete matched sets only"))
write_tab(out, "Z_T07_age18_sensitivity")
print(out, row.names = FALSE, right = FALSE)
log_msg("Z6 complete")
