## K3_one_rule_both_arms.R ----------------------------------------------------
## What the delivered outcome actually counted, and what happens under a single
## consistent rule.
##
## CORRECTION TO K2's READING. K2 inferred that the IIH seizure-code extract had
## been pulled conditional on the outcome. The investigator has confirmed the
## cause is benign: rows for IIH patients without seizures were removed by hand
## before the file was supplied, and those patients genuinely carry no seizure
## codes. The IIH arm's event ascertainment is therefore complete, and K2's
## conclusion that the symmetric re-derivation is "biased against IIH" does not
## hold. K2's tables stand; its interpretation is superseded by this script.
##
## WHAT THE DELIVERED OUTCOME COUNTED, post-washout:
##   IIH events      102: 31 carry an epilepsy code (G40/345), 70 carry ONLY a
##                        non-specific convulsion code (R56.9/780.39), 1 neither
##   comparator  64: 64 carry an epilepsy code, 0 counted on R56 alone
##   comparators NOT counted as events, but carrying codes in their own window:
##                   42 with an epilepsy code, 152 with R56 only
##
## So a non-specific convulsion code made an IIH patient an event and never made
## a comparator one. Protocol section 4.1 says R56.x/780.39 "do not satisfy the
## outcome", so the comparator arm was scored as written and the IIH arm was not.
##
## This script applies one rule to both arms, on a clock defined without
## reference to the outcome (index to last attended encounter, death or freeze,
## capped at the 3-year horizon).
##
## IT DOES NOT ESTABLISH THE CORRECT ANSWER. If the abstraction team
## chart-reviewed the R56-only comparators and rejected them as syncope or
## functional episodes, while confirming the R56-only IIH patients as true
## seizures, the asymmetry is clinically justified and the published estimate
## may stand. That question is answerable only by the team, and is stated at the
## end of the output.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K3 one rule, both arms ===")
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds")); W <- 180; TAU <- 3

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
d0$open <- pmin(d0$fu_carpal_end_day, W + TAU*365.25)

## ---- what the delivered outcome counted -------------------------------------
comp <- do.call(rbind, lapply(c(1,0), function(a){
  s <- d0[d0$iih==a & d0$event==1, ]; p <- e[e$mrn %in% s$mrn & e$day > W, ]
  g <- unique(p$mrn[p$g40]); rr <- setdiff(unique(p$mrn[p$r56]), g)
  data.frame(arm=ifelse(a==1,"IIH","Comparator"), events=nrow(s),
             with_epilepsy_code=length(g), r56_only=length(rr),
             neither=nrow(s)-length(g)-length(rr)) }))
nc <- d0[d0$iih==0 & d0$event==0, ]
p <- e[e$mrn %in% nc$mrn & e$day > W & e$day <= d0$fu_seizure_end_day[match(e$mrn, d0$mrn)], ]
g <- unique(p$mrn[p$g40]); rr <- setdiff(unique(p$mrn[p$r56]), g)
comp <- rbind(comp, data.frame(arm="Comparator, NOT counted as events", events=NA,
              with_epilepsy_code=length(g), r56_only=length(rr), neither=NA))
write_tab(comp, "K_T05_what_was_counted"); print(comp, row.names=FALSE)

## ---- one rule, both arms ----------------------------------------------------
run <- function(sel, lab, eng) {
  q <- e[sel, ]
  prev <- unique(q$mrn[q$day <= W])
  f <- tapply(q$day[q$day > W], q$mrn[q$day > W], min)
  a <- d0[!(d0$mrn %in% prev) & d0$open > W, ]; if (eng) a <- a[a$engaged, ]
  dd <- as.numeric(f[a$mrn])
  a$ev <- as.integer(!is.na(dd) & dd <= a$open + 1e-6)
  a$t  <- (ifelse(a$ev==1, dd, a$open) - W)/365.25
  a <- a[a$t > 0, ]
  m <- coxph(Surv(t,ev) ~ iih, data=a, cluster=match_set); s <- summary(m)
  data.frame(rule=lab, cohort=if (eng) "Engagement-restricted" else "Full",
    iih=sprintf("%d/%d", sum(a$ev[a$iih==1]), sum(a$iih==1)),
    comparator=sprintf("%d/%d", sum(a$ev[a$iih==0]), sum(a$iih==0)),
    estimate=fmt_est(s$conf.int[1], s$conf.int[3], s$conf.int[4]), p=signif(s$coef[1,6],3))
}
res <- do.call(rbind, c(
  lapply(c(FALSE,TRUE), function(g) run(e$g40, "Epilepsy code only (G40/345)", g)),
  lapply(c(FALSE,TRUE), function(g) run(e$g40 | e$r56, "Any seizure code, including R56.9", g))))
res <- rbind(data.frame(rule="As published (R56 counted in IIH only)", cohort="Engagement-restricted",
  iih="59/2606", comparator="15/4037", estimate="5.58 (3.15 to 9.87)", p=NA), res)
write_tab(res, "K_T06_one_rule_both_arms"); print(res, row.names=FALSE)

log_msg("THE QUESTION FOR THE ABSTRACTION TEAM: were the 152 comparators with ")
log_msg("R56-only codes chart-reviewed and rejected as non-seizures, and were ")
log_msg("the 70 IIH patients with R56-only codes chart-reviewed and confirmed? ")
log_msg("If both, the asymmetry is clinical and the published estimate stands. ")
log_msg("If not, the rule differed by arm and the estimate does not.")
log_msg("K3 complete")
