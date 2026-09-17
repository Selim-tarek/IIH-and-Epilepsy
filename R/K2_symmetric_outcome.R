## K2_symmetric_outcome.R -----------------------------------------------------
## Re-derivation of the primary outcome, applying protocol section 4.1
## IDENTICALLY to both arms from a single source.
##
## WHY. The delivered outcome was not applied symmetrically. 31 of 102 IIH
## events (30%) carry a post-washout epilepsy-specific G40/345 code, against
## 64 of 64 comparator events (100%), even though section 4.1 requires such a
## code and states that R56.x/780.39 do not satisfy the outcome. Separately,
## 194 comparators carry qualifying codes inside their own follow-up window and
## were never counted, against none in the IIH arm. Both observations say the
## comparator arm was held to a stricter standard.
##
## THE ALGORITHM, as written in the protocol and applied here to both arms:
##   outcome met if  (a) two G40.x/345.x codes recorded >= 30 days apart, or
##                   (b) one G40.x/345.x code plus >= 1 unambiguous ASM
##   R56.x / 780.39 exclude at baseline but never satisfy the outcome
##   exclusion at or before day 180: any G40/345/R56/780.39 code, or any ASM
##   event time: the date the criteria are MET (the second code, or the code
##   when the medication limb carries it). Dating at the first code instead is
##   reported as a sensitivity.
##
## THE CLOCK. A symmetric re-derivation cannot run on fu_seizure_end_day, the
## clock used by the delivered analysis: that clock is censored AT the
## delivered seizure, so a second confirmatory code 30 days later can never be
## observed, and the two-code limb collapses to zero events by construction
## (it does: 62 patients meet the two-code rule on an open clock, 1 on the
## seizure clock). The at-risk window here is therefore index to last attended
## encounter, death, or freeze, capped at the same 3-year horizon -- defined
## without reference to the outcome being derived, and identical in both arms.
##
## THE ASM LIMB IS NOT SYMMETRIC AND IS REPORTED SEPARATELY. The case
## medication file records inpatient administrations, the comparator file
## outpatient prescriptions; 17 of 102 outcome-positive IIH patients have any
## ASM record against 48 of 64 comparators. Limb (b) therefore cannot be
## applied evenhandedly, so the code-only definition (a) is the primary
## re-derivation and (a or b) is shown alongside.
##
## This script does NOT assert that its estimate is the correct one. It
## establishes what the protocol's own algorithm yields when applied without
## regard to arm.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K2 symmetric re-derivation of the primary outcome ===")
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds"))
TAU <- 3; WASHOUT_D <- 180

## ---- coded evidence, both arms, one source ---------------------------------
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
## Psychogenic and post-traumatic non-epileptic codes are neither outcome nor
## exclusion; febrile convulsions likewise.
exc <- grepl("^F44\\.5|^300\\.11|^R56\\.1|^780\\.33|^780\\.32", e$code) |
       grepl("febrile|non.epileptic|psychogenic|conversion", e$desc, ignore.case=TRUE)
e$g40 <- grepl("^G40|^345|^0345", e$code) & !exc          # satisfies the outcome
e$r56 <- grepl("^R56|^780\\.39|^07703", e$code) & !exc & !e$g40   # excludes only

## ---- unambiguous ASM, per protocol 4.2 (topiramate/acetazolamide excluded) --
ASM <- c("levetiracetam","lamotrigine","carbamazepine","oxcarbazepine","valproa","divalproex",
 "phenytoin","fosphenytoin","lacosamide","zonisamide","perampanel","brivaracetam","felbamate",
 "rufinamide","vigabatrin","tiagabine","primidone","ethosuximide","phenobarb","eslicarbazepine","cenobamate")
isa <- function(x){ g <- tolower(x); Reduce(`|`, lapply(ASM, function(a) grepl(a, g, fixed=TRUE))) }
mc <- utils::read.csv(file.path("data-raw","MDE_Medications_cases_22.csv"), colClasses="character")
md <- utils::read.csv(file.path("data-raw","IIH_medications_detail.csv"), colClasses="character")
M <- rbind(data.frame(mrn=trimws(mc[[1]]), date=as.Date(substr(mc$Started.Date,1,10)), g=mc$Medication.Generic.Name),
           data.frame(mrn=trimws(md$clinic_number), date=as.Date(substr(md$start_date,1,10)),
                      g=ifelse(md$asm_generic != "", md$asm_generic, md$medication_name)))
M <- M[M$mrn %in% d0$mrn & isa(M$g) & !is.na(M$date), ]
M$day <- as.numeric(M$date - d0$index_date[match(M$mrn, d0$mrn)])

## ---- baseline exclusion, applied identically -------------------------------
prev <- unique(c(e$mrn[(e$g40 | e$r56) & e$day <= WASHOUT_D], M$mrn[M$day <= WASHOUT_D]))
d0$prev <- d0$mrn %in% prev

## ---- outcome day under each definition -------------------------------------
gsp <- split(e$day[e$g40], e$mrn[e$g40])
asm_first <- tapply(M$day, M$mrn, min)
outcome_day <- function(use_asm) {
  vapply(d0$mrn, function(m){
    g <- sort(unique(gsp[[m]])); g <- g[g > WASHOUT_D]
    if (!length(g)) return(NA_real_)
    en <- d0$fu_open_end[match(m, d0$mrn)]; g <- g[g <= en + 1e-6]
    if (!length(g)) return(NA_real_)
    day2 <- if (length(g) >= 2) { k <- which(g >= g[1] + 30)[1]; if (is.na(k)) NA_real_ else g[k] } else NA_real_
    dayA <- if (use_asm && !is.na(asm_first[m]) && asm_first[m] > WASHOUT_D) max(g[1], asm_first[m]) else NA_real_
    suppressWarnings(min(c(day2, dayA), na.rm=TRUE)) }, numeric(1)) -> z
  z[is.infinite(z)] <- NA_real_; z
}
## At-risk window, independent of the outcome being derived (see header).
d0$fu_open_end <- pmin(d0$fu_carpal_end_day, WASHOUT_D + TAU*365.25)
d0$day_code <- outcome_day(FALSE)
d0$day_both <- outcome_day(TRUE)
d0$first_g40 <- vapply(d0$mrn, function(m){ g <- gsp[[m]]
                       g <- g[g > WASHOUT_D & g <= d0$fu_open_end[match(m, d0$mrn)] + 1e-6]
                       if (!length(g)) NA_real_ else min(g) }, numeric(1))

## ---- fit --------------------------------------------------------------------
fit <- function(dayvar, eng, label, datecol = NULL) {
  a <- d0[!d0$prev & d0$fu_open_end > WASHOUT_D, ]; if (eng) a <- a[a$engaged, ]
  dd <- a[[dayvar]]; if (!is.null(datecol)) dd <- ifelse(is.na(dd), NA, a[[datecol]])
  a$ev <- as.integer(!is.na(dd) & dd <= a$fu_open_end + 1e-6)
  a$t  <- (ifelse(a$ev == 1, dd, a$fu_open_end) - WASHOUT_D)/365.25
  a <- a[a$t > 0, ]
  ## Separation guard: with no events in an arm the Cox coefficient runs off to
  ## infinity and the "estimate" is an artefact, so it is reported as such.
  n1 <- sum(a$ev[a$iih==1]); n0 <- sum(a$ev[a$iih==0])
  hr <- c(NA_real_, NA_real_, NA_real_); pv <- NA_real_
  if (n1 > 0 && n0 > 0) {
    m <- coxph(Surv(t, ev) ~ iih, data=a, cluster=match_set); s <- summary(m)
    if (abs(s$coef[1,1]) <= 5) { hr <- s$conf.int[c(1,3,4)]; pv <- signif(s$coef[1,6],3) }
  }
  rt <- function(g) 1000*sum(a$ev[a$iih==g])/sum(a$t[a$iih==g])
  data.frame(definition=label, cohort=if (eng) "Engagement-restricted" else "Full",
             iih=sprintf("%d/%d", sum(a$ev[a$iih==1]), sum(a$iih==1)),
             control=sprintf("%d/%d", sum(a$ev[a$iih==0]), sum(a$iih==0)),
             iih_rate=round(rt(1),2), control_rate=round(rt(0),2),
             HR=hr[1], lo=hr[2], hi=hr[3],
             estimate=if (is.na(hr[1])) "not estimable (no events in one arm)"
                      else fmt_est(hr[1], hr[2], hr[3]), p=pv)
}
rows <- list()
for (eng in c(FALSE, TRUE)) {
  ## the delivered outcome, for reference, on the same at-risk set
  a <- d0[!d0$prev & d0$fu_seizure_end_day > WASHOUT_D, ]; if (eng) a <- a[a$engaged, ]
  a$ev <- as.integer(a$event==1 & a$t_y<=TAU); a$t <- pmin(a$t_y, TAU); a <- a[a$t>0, ]
  m <- coxph(Surv(t,ev) ~ iih, data=a, cluster=match_set); s <- summary(m)
  rows[[length(rows)+1]] <- data.frame(definition="Delivered outcome (as published)",
    cohort=if (eng) "Engagement-restricted" else "Full",
    iih=sprintf("%d/%d", sum(a$ev[a$iih==1]), sum(a$iih==1)),
    control=sprintf("%d/%d", sum(a$ev[a$iih==0]), sum(a$iih==0)),
    iih_rate=round(1000*sum(a$ev[a$iih==1])/sum(a$t[a$iih==1]),2),
    control_rate=round(1000*sum(a$ev[a$iih==0])/sum(a$t[a$iih==0]),2),
    HR=s$conf.int[1], lo=s$conf.int[3], hi=s$conf.int[4],
    estimate=fmt_est(s$conf.int[1], s$conf.int[3], s$conf.int[4]), p=signif(s$coef[1,6],3))
  rows[[length(rows)+1]] <- fit("day_code", eng, "Protocol 4.1, code limb only (symmetric)")
  rows[[length(rows)+1]] <- fit("day_both", eng, "Protocol 4.1, code or medication limb")
  rows[[length(rows)+1]] <- fit("first_g40", eng, "Symmetric, dated at first G40/345 code")
}
out <- do.call(rbind, rows)
write_tab(out, "K_T02_symmetric_outcome")
print(out[, c("definition","cohort","iih","control","estimate")], row.names=FALSE)

## ---- who moves ---------------------------------------------------------------
a <- d0[!d0$prev, ]
mv <- do.call(rbind, lapply(c(1,0), function(g){ s <- a[a$iih==g, ]
  sym <- !is.na(s$day_code) & s$day_code <= s$fu_open_end + 1e-6
  del <- s$event==1 & s$t_y<=TAU
  data.frame(arm=ifelse(g==1,"IIH","Control"), both=sum(sym & del),
             delivered_only=sum(del & !sym), symmetric_only=sum(sym & !del),
             neither=sum(!sym & !del)) }))
write_tab(mv, "K_T03_reclassification"); print(mv, row.names=FALSE)
log_msg("K2 complete")

## ---- IS THE SOURCE ITSELF ARM-COMPLETE? -------------------------------------
## This decides whether the re-derivation above is a corrected estimate or
## merely a demonstration that the two routes disagree.
##
## The seizure-code extract contains 156 IIH patients, 102 of whom (65%) are
## delivered events, and 54 who are not -- but those 54 carry SIX qualifying
## code rows between them, all inside the washout; what they actually carry is
## F44.5 psychogenic, G43.10 migraine and Z82.0 family history, i.e. the
## differential. In the comparator arm, 259 non-event patients appear in the
## extract and 194 of them carry qualifying codes inside their own follow-up.
##
## An unconditioned pull would yield seizure codes for non-event patients in
## BOTH arms. It does so only in comparators. The most economical reading is
## that the IIH seizure codes were pulled conditional on the outcome, so the
## extract cannot see IIH seizures that the abstraction did not already record.
##
## CONSEQUENCE: the symmetric re-derivation is biased AGAINST IIH and must not
## be reported as the corrected hazard ratio. What K_T02 establishes is that
## the delivered estimate is not reproducible from a single common source, and
## that the direction of the discrepancy depends on the arm. Resolving it needs
## a complete, outcome-independent seizure-code pull for the IIH arm.
note <- data.frame(
  question = c("IIH patients in the seizure-code extract",
               "of those, delivered events",
               "IIH non-event patients in the extract carrying a qualifying code",
               "comparator non-event patients in the extract carrying a qualifying code",
               "reading"),
  value = c("156 of 2,618", "102 (65%)", "0", "194",
            paste("the IIH extract appears conditioned on the outcome, so the symmetric",
                  "re-derivation is biased against IIH and is NOT a corrected estimate")))
write_tab(note, "K_T04_source_completeness"); print(note, row.names=FALSE)
