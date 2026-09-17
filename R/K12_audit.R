## K12_audit.R ----------------------------------------------------------------
## Audit of the re-matching (K11) and of the outcome definition, before anything
## else is built on either.
##
## FINDING 1 -- THE RE-MATCH IN K11 IS INVALID. RETRACTED.
##
## Protocol section 2.3: "Each control inherits the index date of its matched
## case. All exclusions, follow-up time and outcome ascertainment are measured
## from that date."
##
## K11 re-assigned controls to different cases but left each control on its
## ORIGINAL index date. After re-matching, 71% of controls sit with a case whose
## index date differs from their own by more than 30 days and 48% by more than
## a year. Every time-anchored quantity for those controls -- the 180-day
## washout, the at-risk window, the day offset of every diagnosis code, the
## engagement flag itself -- is measured from the wrong origin.
##
## It cannot be repaired with the data on hand. Re-anchoring a control to a new
## index date requires re-deriving whether they had an encounter in the 12
## months before THAT date, and the extract supplies only the counts enc_pre12
## and enc_post, not dated encounters. A correct re-match needs encounter-level
## dates for the control pool.
##
## FINDING 2 -- two matching deviations in K11, minor beside the above but
## recorded for completeness. The protocol matches on BMI CALENDAR YEAR for
## females; no BMI measurement date exists in the extract, so index_year was
## substituted. And race was used at tier 1 despite the earlier audit finding
## race unverifiable in this dataset.
##
## FINDING 3 -- the honest alternative also has a defect, in the other
## direction. Keeping the original matched sets and dropping unengaged controls
## leaves 513 of 2,606 cases with no control in their set. Those cases are not a
## random subset: they are younger (32.8 vs 35.2), less often female (82% vs
## 88%) and have a HIGHER event rate (5.65% vs 3.39%). Excluding them would bias
## the estimate downward. The marginal Cox model used here retains them -- they
## contribute to the overall risk set rather than to a within-set comparison --
## which is why the headline analysis keeps them and a complete-sets analysis is
## reported alongside rather than instead.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K12 audit ===")
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds")); W <- 180; TAU <- 3
d0$open <- pmin(d0$fu_carpal_end_day, W + TAU*365.25)

## index-date mismatch created by the K11 re-match
a11 <- readRDS(file.path(PATH$derived, "K11_rematched.rds"))
cs <- a11[a11$iih==1, c("match_set","index_date")]; names(cs)[2] <- "case_index"
ct <- merge(a11[a11$iih==0, c("match_set","index_date")], cs, by="match_set")
ct$diff <- abs(as.numeric(ct$case_index - ct$index_date))
mm <- data.frame(quantity=c("re-matched controls","index date differs from matched case by >30 d",
                            "by >365 d","median absolute difference (days)"),
                 value=c(nrow(ct), sum(ct$diff>30), sum(ct$diff>365), round(stats::median(ct$diff))))
write_tab(mm, "K_T27_rematch_index_mismatch"); print(mm, row.names=FALSE)

## orphaned cases under the original sets
sets_ok <- unique(d0$match_set[d0$iih==0 & d0$engaged])
o <- d0[d0$iih==1 & d0$engaged, ]; o$orph <- !(o$match_set %in% sets_ok)
orp <- data.frame(group=c("cases with >=1 engaged control","cases orphaned"),
  n=c(sum(!o$orph), sum(o$orph)),
  mean_age=round(c(mean(o$age_index[!o$orph],na.rm=TRUE), mean(o$age_index[o$orph],na.rm=TRUE)),1),
  pct_female=round(100*c(mean(o$sex[!o$orph]=="F"), mean(o$sex[o$orph]=="F")),1),
  pct_event=round(100*c(mean(o$event[!o$orph]==1), mean(o$event[o$orph]==1)),2))
write_tab(orp, "K_T28_orphaned_cases"); print(orp, row.names=FALSE)

## complete-sets sensitivity on the accepted (K9) analysis
src <- readRDS(file.path(PATH$derived, "J1_phenotype.rds"))$code   # for mrn/index alignment
e <- local({
  dx <- utils::read.csv(file.path("data-raw","SZ_dx_62.csv"), colClasses="character")
  names(dx) <- c("mrn","s","code","desc","date")
  cn <- utils::read.csv(file.path("data-raw","SZ_conditions_10.csv"), colClasses="character")
  names(cn) <- c("mrn","s","code","desc","on","rec")
  o2 <- as.Date(substr(cn$on,1,10)); r2 <- as.Date(substr(cn$rec,1,10))
  z <- rbind(data.frame(mrn=trimws(dx$mrn), code=dx$code, desc=dx$desc, date=as.Date(substr(dx$date,1,10))),
             data.frame(mrn=trimws(cn$mrn), code=cn$code, desc=cn$desc,
                        date=as.Date(ifelse(is.na(o2), r2, o2), origin="1970-01-01")))
  z <- z[z$mrn %in% d0$mrn & !is.na(z$date), ]
  z$day <- as.numeric(z$date - d0$index_date[match(z$mrn, d0$mrn)]); z })
exc <- grepl("^F44|^300\\.11|^R56\\.1|^780\\.33|^780\\.32|^Z82|^G43|^E936|^966", e$code) |
       grepl("febrile|non.epileptic|psychogenic|conversion|family history|migraine|poisoning|adverse",
             e$desc, ignore.case=TRUE)
e$sz <- (grepl("^G40|^345|^0345|^R56|^780\\.39|^07703", e$code)) & !exc
q <- e[e$sz, ]
cf <- tapply(q$day[q$day > W], q$mrn[q$day > W], min)
prev <- unique(q$mrn[q$day <= W])
run <- function(complete_only){
  a <- d0[d0$engaged & d0$open > W & !(d0$mrn %in% prev), ]
  if (complete_only) a <- a[a$match_set %in% sets_ok, ]
  dd <- as.numeric(cf[a$mrn])
  a$ev <- as.integer(!is.na(dd) & dd <= a$open + 1e-6)
  a$t  <- (ifelse(a$ev==1, dd, a$open) - W)/365.25; a <- a[a$t>0, ]
  m <- coxph(Surv(t, ev) ~ iih, data=a, cluster=match_set); s <- summary(m)
  data.frame(analysis=if (complete_only) "Sets with at least one engaged control only"
                      else "All engaged patients (headline)",
    iih=sprintf("%d/%d", sum(a$ev[a$iih==1]), sum(a$iih==1)),
    comparator=sprintf("%d/%d", sum(a$ev[a$iih==0]), sum(a$iih==0)),
    estimate=fmt_est(s$conf.int[1], s$conf.int[3], s$conf.int[4]), p=signif(s$coef[1,6],3))
}
cs2 <- rbind(run(FALSE), run(TRUE))
write_tab(cs2, "K_T29_complete_sets_sensitivity"); print(cs2, row.names=FALSE)
log_msg("K12 complete")
