## Z3_complete_sets.R ---------------------------------------------------------
## The matching screen requires comparators to have follow-up beyond the washout;
## IIH cases are not screened that way, so 352 cases fall out of the analysis set
## while their matched comparators remain. Those comparators contribute
## person-time and events to a set with no case in it, which inflates the
## comparator denominator. This quantifies the effect rather than assuming it is
## negligible.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== Z3 orphaned matched sets ===")
V <- readRDS(file.path(PATH$derived, "K15_final_visits.rds")); a <- V$a

cs   <- unique(a$match_set[a$iih == 1])
orph <- setdiff(unique(a$match_set[a$iih == 0]), cs)
b    <- a[a$match_set %in% cs, ]          # complete sets only

fit <- function(dat) {
  m <- coxph(Surv(t, ev) ~ iih + cluster(match_set), data = dat)
  s <- summary(m)
  sprintf("%.2f (%.2f to %.2f)", s$conf.int[1], s$conf.int[3], s$conf.int[4])
}
pv <- function(dat) summary(coxph(Surv(t, ev) ~ iih + cluster(match_set), data = dat))$coef[1, 6]

out <- data.frame(
  analysis = c("Primary, as reported (all matched comparators retained)",
               "Complete sets only (comparators whose case was dropped removed)"),
  iih = c(sprintf("%d/%d", sum(a$ev[a$iih==1]), sum(a$iih==1)),
          sprintf("%d/%d", sum(b$ev[b$iih==1]), sum(b$iih==1))),
  comparator = c(sprintf("%d/%d", sum(a$ev[a$iih==0]), sum(a$iih==0)),
                 sprintf("%d/%d", sum(b$ev[b$iih==0]), sum(b$iih==0))),
  HR = c(fit(a), fit(b)),
  p  = signif(c(pv(a), pv(b)), 3),
  stringsAsFactors = FALSE)

write_tab(out, "Z_T01_complete_sets")
print(out, row.names = FALSE)
log_msg(sprintf("orphaned sets %d | comparators %d | their events %d",
                length(orph), sum(a$match_set %in% orph & a$iih == 0),
                sum(a$ev[a$match_set %in% orph & a$iih == 0])))
