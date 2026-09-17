## K5_rescore_controls.R ------------------------------------------------------
## The investigator confirms the IIH events are correct: they were established
## by chart abstraction, not by the code algorithm. The comparator events were
## established by the code algorithm (outcome_criterion, K_T08: 57 by two
## epilepsy-specific codes 30+ days apart, 26 by one code plus a drug).
##
## So the arms were ascertained to DIFFERENT standards, and the standard applied
## to comparators is the stricter of the two. This script holds the IIH events
## fixed and re-scores the comparators under rules of varying strictness, to
## show how much of the published estimate rests on that difference.
##
## Both arms run on a clock defined without reference to the outcome: index to
## last attended encounter, death or freeze, capped at the 3-year horizon. The
## published clock cannot be used, because it is censored at the delivered
## comparator event and so cannot accommodate a re-scored one.
##
## WHICH ROW IS THE FAIR COMPARISON depends on what the abstractors recorded.
## If an IIH patient was counted for having had a seizure of any kind, the
## matching comparator rule is "any seizure code". If only epilepsy-grade events
## were counted, it is "any epilepsy code". The published row applies a rule to
## comparators that was not applied to cases, and is shown for reference only.
##
## NEITHER BOUND IS THE TRUTH. Code-based scoring of comparators will over-count
## (R56.9 captures syncope and functional episodes that a chart review would
## reject) and chart abstraction of cases may over-count in its own way. The
## honest statement is that the estimate is bracketed, not that it is known.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K5 re-score comparators to the case standard ===")
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds")); W <- 180; TAU <- 3
d0$open <- pmin(d0$fu_carpal_end_day, W + TAU*365.25)

dx <- utils::read.csv(file.path("data-raw","SZ_dx_62.csv"), colClasses="character")
names(dx) <- c("mrn","s","code","desc","date")
cn <- utils::read.csv(file.path("data-raw","SZ_conditions_10.csv"), colClasses="character")
names(cn) <- c("mrn","s","code","desc","on","rec")
o <- as.Date(substr(cn$on,1,10)); r <- as.Date(substr(cn$rec,1,10))
e <- rbind(data.frame(mrn=trimws(dx$mrn), code=dx$code, desc=dx$desc, date=as.Date(substr(dx$date,1,10))),
           data.frame(mrn=trimws(cn$mrn), code=cn$code, desc=cn$desc,
                      date=as.Date(ifelse(is.na(o), r, o), origin="1970-01-01")))
e <- e[e$mrn %in% d0$mrn & !is.na(e$date), ]
e$day <- as.numeric(e$date - d0$index_date[match(e$mrn, d0$mrn)])
exc <- grepl("^F44\\.5|^300\\.11|^R56\\.1|^780\\.33|^780\\.32", e$code) |
       grepl("febrile|non.epileptic|psychogenic|conversion", e$desc, ignore.case=TRUE)
e$g40 <- grepl("^G40|^345|^0345", e$code) & !exc
e$r56 <- grepl("^R56|^780\\.39|^07703", e$code) & !exc & !e$g40

fit <- function(a, lab, eng) {
  a <- a[a$t > 0, ]
  m <- coxph(Surv(t, ev) ~ iih, data=a, cluster=match_set); s <- summary(m)
  ok <- sum(a$ev[a$iih==1]) > 0 && sum(a$ev[a$iih==0]) > 0 && abs(s$coef[1,1]) <= 5
  data.frame(comparator_rule=lab, cohort=if (eng) "Engagement-restricted" else "Full",
    iih=sprintf("%d/%d", sum(a$ev[a$iih==1]), sum(a$iih==1)),
    comparator=sprintf("%d/%d", sum(a$ev[a$iih==0]), sum(a$iih==0)),
    estimate=if (ok) fmt_est(s$conf.int[1], s$conf.int[3], s$conf.int[4]) else "not estimable",
    p=if (ok) signif(s$coef[1,6],3) else NA)
}
rescore <- function(sel, lab, eng) {
  q <- e[sel, ]; f <- tapply(q$day[q$day > W], q$mrn[q$day > W], min)
  a <- d0[d0$open > W, ]; if (eng) a <- a[a$engaged, ]
  dd <- ifelse(a$iih==1, a$lat_days, as.numeric(f[a$mrn]))
  keep <- a$iih==0 | a$event==1           # IIH events held exactly as delivered
  a$ev <- as.integer(!is.na(dd) & dd <= a$open + 1e-6 & keep)
  a$t  <- (ifelse(a$ev==1, dd, a$open) - W)/365.25
  fit(a, lab, eng)
}
published <- function(eng) {
  a <- d0; if (eng) a <- a[a$engaged, ]
  a$ev <- as.integer(a$event==1 & a$t_y <= TAU); a$t <- pmin(a$t_y, TAU)
  fit(a, "As published (comparators by code algorithm only)", eng)
}
res <- do.call(rbind, unlist(lapply(c(FALSE,TRUE), function(g) list(
  published(g),
  rescore(e$g40,          "Comparators: any epilepsy code (G40/345)", g),
  rescore(e$g40 | e$r56,  "Comparators: any seizure code, incl. R56.9", g))), recursive=FALSE))
write_tab(res, "K_T10_rescored_comparators")
print(res[, c("comparator_rule","cohort","iih","comparator","estimate")], row.names=FALSE)
log_msg("K5 complete")
