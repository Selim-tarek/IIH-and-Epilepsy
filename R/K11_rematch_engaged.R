## K11_rematch_engaged.R ------------------------------------------------------
## RE-MATCH against the engaged control pool only, then re-run the primary.
##
## The submitted analysis matched against all controls and then deleted the
## unengaged ones, which leaves broken sets: 516 cases end up with no control
## at all, and the surviving sets are whatever happened to remain rather than
## the closest available match. Protocol section 2.2 requires an encounter in
## the 12 months before index, so that requirement belongs in the matching, not
## after it.
##
## MATCHING, per protocol section 3, cases in randomised order, nearest
## neighbour on BMI then age, without replacement, up to 1:4:
##   tier 1  sex exact, race exact where both recorded, age +/-3, BMI +/-3,
##           BMI calendar year +/-2 (females only)
##   tier 2  drop race
##   tier 3  BMI +/-5
##   tier 4  year +/-3
##   tier 5  age +/-5
## Sex is never relaxed.
##
## The achievable ratio is limited by the pool: 4,037 engaged controls against
## 2,618 cases is at most about 1.5 to 1, so most sets are 1:1 and the design
## becomes variable-ratio. That is the investigator's explicit instruction and
## is handled correctly by the clustered variance already in use.
##
## Cases that cannot be matched at any tier are dropped, and the count is
## reported rather than hidden: an unmatched case contributes no comparison.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K11 re-match against the engaged pool ===")
set.seed(SEED)
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds")); W <- 180; TAU <- 3
d0$open <- pmin(d0$fu_carpal_end_day, W + TAU*365.25)

cases <- d0[d0$iih == 1 & d0$engaged, ]
pool  <- d0[d0$iih == 0 & d0$engaged, ]
log_msg("cases ", nrow(cases), " | engaged control pool ", nrow(pool))

pool$used <- FALSE
TIERS <- list(
  list(race=TRUE,  age=3, bmi=3, yr=2),
  list(race=FALSE, age=3, bmi=3, yr=2),
  list(race=FALSE, age=3, bmi=5, yr=2),
  list(race=FALSE, age=3, bmi=5, yr=3),
  list(race=FALSE, age=5, bmi=5, yr=3))

## Matched in PASSES rather than taking up to four controls per case in one
## sweep. A single greedy 1:4 sweep exhausts a pool this size after about
## 1,100 cases and leaves the remaining 1,500 with nothing, which throws away
## most of the study. Pass one gives every case its nearest control; later
## passes add a second, third and fourth where any remain. This maximises the
## number of cases retained, which is what determines power here.
newset <- rep(NA_integer_, nrow(pool)); casesets <- rep(NA_integer_, nrow(cases))
tier_used <- rep(NA_integer_, nrow(cases))
ord <- sample(nrow(cases))
best <- function(ca) {
  for (ti in seq_along(TIERS)) {
    T <- TIERS[[ti]]
    ok <- !pool$used & pool$sex == ca$sex &
          abs(pool$age_index - ca$age_index) <= T$age &
          abs(pool$bmi_index - ca$bmi_index) <= T$bmi
    if (T$race && !is.na(ca$race) && ca$race != "")
      ok <- ok & (is.na(pool$race) | pool$race == "" | pool$race == ca$race)
    if (!is.na(ca$sex) && ca$sex == "F")
      ok <- ok & abs(pool$index_year - ca$index_year) <= T$yr
    ok[is.na(ok)] <- FALSE
    cand <- which(ok)
    if (length(cand)) {
      o <- order(abs(pool$bmi_index[cand] - ca$bmi_index),
                 abs(pool$age_index[cand] - ca$age_index))
      return(list(idx=cand[o][1], tier=ti))
    }
  }
  NULL
}
sid <- 0L
for (pass in 1:4) {
  for (ii in ord) {
    if (pass == 1) {
      b <- best(cases[ii, ]); if (is.null(b)) next
      sid <- sid + 1L; casesets[ii] <- sid; tier_used[ii] <- b$tier
      pool$used[b$idx] <- TRUE; newset[b$idx] <- sid
    } else {
      if (is.na(casesets[ii])) next
      b <- best(cases[ii, ]); if (is.null(b)) next
      pool$used[b$idx] <- TRUE; newset[b$idx] <- casesets[ii]
    }
  }
  log_msg("pass ", pass, ": cases matched ", sum(!is.na(casesets)),
          " | controls used ", sum(!is.na(newset)))
}
log_msg("cases matched ", sum(!is.na(casesets)), " of ", nrow(cases),
        " | controls used ", sum(!is.na(newset)))

pool$used <- NULL
cases$ms <- casesets; pool$ms <- newset
m <- rbind(cases[!is.na(cases$ms), ], pool[!is.na(pool$ms), ])
m$match_set <- m$ms
rat <- table(table(m$match_set[m$iih==0]))
flow <- data.frame(quantity=c("cases eligible (IIH, engaged)","cases matched","cases unmatched",
                              "engaged control pool","controls used","mean controls per case"),
  value=c(nrow(cases), sum(!is.na(casesets)), sum(is.na(casesets)),
          nrow(pool), sum(!is.na(newset)),
          round(sum(!is.na(newset))/sum(!is.na(casesets)), 2)))
write_tab(flow, "K_T22_rematch_flow"); print(flow, row.names=FALSE)
write_tab(data.frame(controls_per_case=names(rat), sets=as.integer(rat)), "K_T23_ratio")
write_tab(data.frame(tier=names(table(tier_used)), cases=as.integer(table(tier_used))), "K_T24_tiers")

## ---- balance -----------------------------------------------------------------
bal <- do.call(rbind, lapply(c("age_index","bmi_index"), function(v)
  data.frame(variable=v, iih=round(mean(m[[v]][m$iih==1], na.rm=TRUE),2),
             control=round(mean(m[[v]][m$iih==0], na.rm=TRUE),2),
             smd=round(smd_cont(m[[v]], m$iih),4))))   # smd_cont(x, group)
bal <- rbind(bal, data.frame(variable="female", iih=round(mean(m$sex[m$iih==1]=="F"),3),
  control=round(mean(m$sex[m$iih==0]=="F"),3),
  smd=round(smd_bin(m$sex=="F", m$iih),4)))
write_tab(bal, "K_T25_rematch_balance"); print(bal, row.names=FALSE)

## ---- outcome: the inclusive rule, both arms ---------------------------------
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
exc <- grepl("^F44|^300\\.11|^R56\\.1|^780\\.33|^780\\.32|^Z82|^G43|^E936|^966", e$code) |
       grepl("febrile|non.epileptic|psychogenic|conversion|family history|migraine|poisoning|adverse",
             e$desc, ignore.case=TRUE)
e$g40 <- grepl("^G40|^345|^0345", e$code) & !exc
e$sz  <- (grepl("^R56|^780\\.39|^07703", e$code) & !exc) | e$g40
ASM <- c("levetiracetam","lamotrigine","carbamazepine","oxcarbazepine","valproa","divalproex",
 "phenytoin","fosphenytoin","lacosamide","zonisamide","perampanel","brivaracetam","felbamate",
 "rufinamide","vigabatrin","tiagabine","primidone","ethosuximide","phenobarb","eslicarbazepine","cenobamate")
isa <- function(x){ z <- tolower(x); Reduce(`|`, lapply(ASM, function(a) grepl(a, z, fixed=TRUE))) }
mc <- utils::read.csv(file.path("data-raw","MDE_Medications_cases_22.csv"), colClasses="character")
md <- utils::read.csv(file.path("data-raw","IIH_medications_detail.csv"), colClasses="character")
M <- rbind(data.frame(mrn=trimws(mc[[1]]), st=as.Date(substr(mc$Started.Date,1,10)),
                      en=as.Date(substr(mc$Ended.Date,1,10)),
                      g=paste(mc$Medication.Generic.Name, mc$Medication.Name)),
           data.frame(mrn=trimws(md$clinic_number), st=as.Date(substr(md$start_date,1,10)),
                      en=as.Date(substr(md$end_date,1,10)),
                      g=paste(md$asm_generic, md$medication_name)))
M <- M[isa(M$g) & !is.na(M$st) & M$mrn %in% d0$mrn, ]
FR <- as.Date("2026-09-03")
M$en[!is.na(M$en) & M$en >= as.Date("9999-01-01")] <- FR
M$en[!is.na(M$en) & (M$en > FR | M$en < M$st)] <- NA
M$day <- as.numeric(M$st - d0$index_date[match(M$mrn, d0$mrn)])
spn <- tapply(seq_len(nrow(M)), M$mrn, function(k){
  s1 <- as.numeric(max(M$st[k]) - min(M$st[k]))
  s2 <- suppressWarnings(max(as.numeric(M$en[k] - M$st[k]), na.rm=TRUE))
  max(s1, ifelse(is.finite(s2), s2, -1)) })
CHRONIC <- names(spn)[spn >= 180]
qa <- e[e$sz & e$day > W & e$day <= d0$open[match(e$mrn, d0$mrn)] + 1e-6, ]
DROP <- setdiff(names(which(tapply(grepl("spells", qa$desc, ignore.case=TRUE), qa$mrn, all))), CHRONIC)
e$sz[e$mrn %in% DROP & grepl("spells", e$desc, ignore.case=TRUE)] <- FALSE
q <- e[e$sz, ]
cf <- tapply(q$day[q$day > W], q$mrn[q$day > W], min)
af <- tapply(M$day[M$day > W], M$mrn[M$day > W], min)
prev <- unique(c(q$mrn[q$day <= W], M$mrn[M$day <= W & M$mrn %in% CHRONIC]))

a <- m[!(m$mrn %in% prev) & m$open > W, ]
ad <- ifelse(a$mrn %in% CHRONIC, as.numeric(af[a$mrn]), NA_real_)
dd <- suppressWarnings(pmin(as.numeric(cf[a$mrn]), ad, na.rm=TRUE)); dd[is.infinite(dd)] <- NA_real_
a$ev <- as.integer(!is.na(dd) & dd <= a$open + 1e-6)
a$t  <- (ifelse(a$ev==1, dd, a$open) - W)/365.25
a <- a[a$t > 0, ]
fitm <- coxph(Surv(t, ev) ~ iih, data=a, cluster=match_set); s <- summary(fitm)
ph <- tryCatch(signif(cox.zph(fitm)$table["iih","p"],3), error=function(z) NA)
a$dday <- as.numeric(a$death_date - a$index_date)
a$cr <- factor(ifelse(a$ev==1,"seizure", ifelse(!is.na(a$dday) & a$dday<=a$open,"death","censor")),
               levels=c("censor","seizure","death"))
fs <- survfit(Surv(t, cr) ~ iih, data=a); sm <- summary(fs, times=TAU, extend=TRUE)
cif <- 100*sm$pstate[, which(fs$states=="seizure")]
rt <- function(g){ x <- a[a$iih==g,]; ci <- stats::poisson.test(sum(x$ev), sum(x$t))$conf.int
                   sprintf("%.2f (%.2f to %.2f)", 1000*sum(x$ev)/sum(x$t), 1000*ci[1], 1000*ci[2]) }
out <- data.frame(cohort="Re-matched, engaged pool only",
  iih=sprintf("%d/%d", sum(a$ev[a$iih==1]), sum(a$iih==1)),
  comparator=sprintf("%d/%d", sum(a$ev[a$iih==0]), sum(a$iih==0)),
  iih_rate=rt(1), ctl_rate=rt(0),
  HR=fmt_est(s$conf.int[1], s$conf.int[3], s$conf.int[4]), p=signif(s$coef[1,6],4), ph_p=ph,
  cif3_iih=round(cif[2],2), cif3_ctl=round(cif[1],2),
  risk_diff_pp=round(cif[2]-cif[1],2), NNH=round(100/(cif[2]-cif[1])))
write_tab(out, "K_T26_rematched_primary"); print(out, row.names=FALSE)
saveRDS(a, file.path(PATH$derived, "K11_rematched.rds"))
log_msg("K11 complete")
