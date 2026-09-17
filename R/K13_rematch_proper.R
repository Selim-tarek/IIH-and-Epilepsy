## K13_rematch_proper.R -------------------------------------------------------
## RE-MATCH DONE CORRECTLY, using the control encounter file.
##
## K11 was retracted because it re-assigned controls to new cases while leaving
## them on their old index dates. With dated encounters for every control that
## can now be fixed: a control inherits the matched case's index date, and
## EVERY time-anchored quantity is re-derived from it -- engagement, the
## washout, the prevalence exclusion, the at-risk window, and the day offset of
## every diagnosis code.
##
## ELIGIBILITY, evaluated against the CASE's index date I:
##   - at least one encounter day in [I-365, I-1]        (protocol 2.2)
##   - no qualifying seizure code and no chronic antiseizure therapy starting
##     on or before I+180                                 (the washout rule)
##   - at-risk window extends beyond the washout: last encounter, death or
##     freeze is more than 180 days after I
##   - sex exact; age +/-3; BMI +/-3; race exact where both recorded
##   with the protocol's relaxation ladder (drop race, BMI +/-5, age +/-5).
##
## DEVIATION, recorded rather than buried: the protocol matches females on BMI
## CALENDAR YEAR +/-2. No BMI measurement date exists in any supplied file, and
## once a control inherits the case's index date its own index year is
## meaningless, so this criterion is dropped entirely rather than approximated.
## K11 approximated it with index_year, which compared the control's OLD index
## year to the case's -- a quantity with no interpretation after re-matching.
##
## SECOND CAVEAT: the encounter file reproduces the supplied `engaged` flag for
## 93% of controls but not all (519 flagged engaged have no encounter in the
## window; 127 the reverse), and its distinct-day counts run below the supplied
## enc_pre12 for 2,792 controls. The file is titled "Create Date" but its
## timestamps follow clinic hours, so it is contemporaneous with the visit; the
## residual gap is most likely a narrower encounter-type filter. Engagement here
## is therefore derived consistently from THIS file for every control rather
## than mixing two definitions.
##
## Cases keep their own engagement status: no encounter file was supplied for
## them, and 99.5% are engaged by the master flag.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K13 proper re-match on dated encounters ===")
set.seed(SEED)
## Applying the prevalence exclusion DURING matching lets a control be paired to
## whichever index date leaves them non-prevalent, which selects for later
## seizure onset and can deflate the comparator rate. Applying it AFTER matching
## avoids that but breaks some sets. Both are run; see K_T33.
PREV_AT_MATCH <- as.logical(Sys.getenv("PREV_AT_MATCH", "TRUE"))
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds"))
W <- 180; TAU <- 3; FR <- as.Date("2026-09-03")

## ---- encounters --------------------------------------------------------------
EN <- utils::read.csv(file.path("data-raw","MDE_Encounters_controls.csv"), colClasses="character")
names(EN) <- c("mrn","death","date")
EN <- data.frame(mrn=trimws(EN$mrn), d=as.Date(substr(EN$date,1,10)), stringsAsFactors=FALSE)
EN <- unique(EN[!is.na(EN$d), ])                     # distinct patient-days
EN$dn <- as.numeric(EN$d)
EN <- EN[order(EN$dn), ]
last_enc <- tapply(EN$dn, EN$mrn, max)
log_msg("encounter days ", nrow(EN), " for ", length(unique(EN$mrn)), " controls")

## ---- seizure evidence (same definition as K9) --------------------------------
dx <- utils::read.csv(file.path("data-raw","SZ_dx_62.csv"), colClasses="character")
names(dx) <- c("mrn","s","code","desc","date")
cn <- utils::read.csv(file.path("data-raw","SZ_conditions_10.csv"), colClasses="character")
names(cn) <- c("mrn","s","code","desc","on","rec")
o <- as.Date(substr(cn$on,1,10)); r <- as.Date(substr(cn$rec,1,10))
e <- rbind(data.frame(mrn=trimws(dx$mrn), code=dx$code, desc=dx$desc, date=as.Date(substr(dx$date,1,10))),
           data.frame(mrn=trimws(cn$mrn), code=cn$code, desc=cn$desc,
                      date=as.Date(ifelse(is.na(o), r, o), origin="1970-01-01")))
e <- e[e$mrn %in% d0$mrn & !is.na(e$date), ]
exc <- grepl("^F44|^300\\.11|^R56\\.1|^780\\.33|^780\\.32|^Z82|^G43|^E936|^966", e$code) |
       grepl("febrile|non.epileptic|psychogenic|conversion|family history|migraine|poisoning|adverse",
             e$desc, ignore.case=TRUE)
e$sz <- grepl("^G40|^345|^0345|^R56|^780\\.39|^07703", e$code) & !exc
e$spell <- grepl("spells", e$desc, ignore.case=TRUE)

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
M$en[!is.na(M$en) & M$en >= as.Date("9999-01-01")] <- FR
M$en[!is.na(M$en) & (M$en > FR | M$en < M$st)] <- NA
spn <- tapply(seq_len(nrow(M)), M$mrn, function(k){
  s1 <- as.numeric(max(M$st[k]) - min(M$st[k]))
  s2 <- suppressWarnings(max(as.numeric(M$en[k] - M$st[k]), na.rm=TRUE))
  max(s1, ifelse(is.finite(s2), s2, -1)) })
CHRONIC <- names(spn)[spn >= 180]
asm_days <- tapply(as.numeric(M$st[M$mrn %in% CHRONIC]), M$mrn[M$mrn %in% CHRONIC], sort)

## Spells rule needs a window, which depends on the index date, so it is applied
## after matching (below) rather than here.
SZ <- e[e$sz, ]
sz_days <- tapply(as.numeric(SZ$date), SZ$mrn, sort)
sz_spell <- tapply(SZ$spell, SZ$mrn, function(z) z)

## ---- matching ----------------------------------------------------------------
cases <- d0[d0$iih == 1 & d0$engaged, ]
ctl   <- d0[d0$iih == 0, ]
ctl$dn_last  <- as.numeric(last_enc[ctl$mrn])
ctl$dn_death <- as.numeric(ctl$death_date)
ctl$used <- FALSE
first_sz  <- vapply(ctl$mrn, function(m){ v <- sz_days[[m]];  if (is.null(v)) Inf else v[1] }, numeric(1))
first_asm <- vapply(ctl$mrn, function(m){ v <- asm_days[[m]]; if (is.null(v)) Inf else v[1] }, numeric(1))

TIERS <- list(list(race=TRUE,  age=3, bmi=3), list(race=FALSE, age=3, bmi=3),
              list(race=FALSE, age=3, bmi=5), list(race=FALSE, age=5, bmi=5))
ord <- sample(nrow(cases))
csets <- rep(NA_integer_, nrow(cases)); ctlset <- rep(NA_integer_, nrow(ctl))
tier_of <- rep(NA_integer_, nrow(cases))
pick <- function(ca) {
  I <- as.numeric(ca$index_date)
  lo <- findInterval(I - 365, EN$dn, left.open=TRUE) + 1L
  hi <- findInterval(I - 1,  EN$dn)
  if (hi < lo) return(NULL)
  eligible <- unique(EN$mrn[lo:hi])                      # encounter in [I-365, I-1]
  ok0 <- !ctl$used & (ctl$mrn %in% eligible) &
         pmin(ifelse(is.na(ctl$dn_death), Inf, ctl$dn_death),
              ctl$dn_last, as.numeric(FR)) > I + W        # at risk beyond washout
  if (PREV_AT_MATCH) ok0 <- ok0 & first_sz > I + W & first_asm > I + W
  for (ti in seq_along(TIERS)) {
    T <- TIERS[[ti]]
    ok <- ok0 & ctl$sex == ca$sex &
          abs(ctl$age_index - ca$age_index) <= T$age &
          abs(ctl$bmi_index - ca$bmi_index) <= T$bmi
    if (T$race && !is.na(ca$race) && ca$race != "")
      ok <- ok & (is.na(ctl$race) | ctl$race == "" | ctl$race == ca$race)
    ok[is.na(ok)] <- FALSE
    cand <- which(ok)
    if (length(cand)) {
      oo <- order(abs(ctl$bmi_index[cand] - ca$bmi_index),
                  abs(ctl$age_index[cand] - ca$age_index))
      return(list(idx=cand[oo][1], tier=ti))
    }
  }
  NULL
}
sid <- 0L
for (pass in 1:4) {
  for (ii in ord) {
    if (pass > 1 && is.na(csets[ii])) next
    b <- pick(cases[ii, ]); if (is.null(b)) next
    if (pass == 1) { sid <- sid + 1L; csets[ii] <- sid; tier_of[ii] <- b$tier }
    ctl$used[b$idx] <- TRUE; ctlset[b$idx] <- csets[ii]
  }
  log_msg("pass ", pass, ": cases ", sum(!is.na(csets)), " | controls ", sum(!is.na(ctlset)))
}

## ---- assemble, re-anchoring every control to its case's index date ----------
cs <- cases[!is.na(csets), ]; cs$ms <- csets[!is.na(csets)]
cc <- ctl[!is.na(ctlset), ];  cc$ms <- ctlset[!is.na(ctlset)]
cc$index_date <- cs$index_date[match(cc$ms, cs$ms)]           # inherit, per protocol 2.3
cc$open <- pmin(pmin(ifelse(is.na(cc$dn_death), Inf, cc$dn_death), cc$dn_last, as.numeric(FR)) -
                as.numeric(cc$index_date), W + TAU*365.25)
cs$open <- pmin(cs$fu_carpal_end_day, W + TAU*365.25)
keep <- intersect(names(cs), names(cc))
m <- rbind(cs[, keep], cc[, keep]); m$match_set <- m$ms

## ---- outcome, re-derived from the inherited index date ----------------------
ev_day <- function(mrn, idx, open) {
  v <- sz_days[[mrn]]; sp <- sz_spell[[mrn]]
  d <- if (is.null(v)) numeric(0) else v - idx
  keepv <- d > W & d <= open + 1e-6
  if (any(keepv) && all(sp[keepv])) keepv[] <- FALSE     # Spells-only, unless chronic ASM
  if (!any(keepv) && mrn %in% CHRONIC) keepv <- logical(0)
  a <- asm_days[[mrn]]; ad <- if (is.null(a)) Inf else min(a[a - idx > W] - idx, Inf)
  cd <- if (any(keepv)) min(d[keepv]) else Inf
  if (mrn %in% CHRONIC) { if (!any(keepv) && is.finite(ad)) cd <- min(cd, ad) } 
  if (is.infinite(cd)) NA_real_ else cd
}
## When prevalence was not screened at matching, screen it now.
if (!PREV_AT_MATCH) {
  pv <- mapply(function(mr, idx){
    v <- sz_days[[mr]]; a <- asm_days[[mr]]
    (!is.null(v) && any(v - idx <= W)) || (!is.null(a) && any(a - idx <= W)) },
    m$mrn, as.numeric(m$index_date))
  log_msg("prevalent excluded after matching: ", sum(pv))
  m <- m[!pv, ]
}
m$evday <- mapply(ev_day, m$mrn, as.numeric(m$index_date), m$open)
m$ev <- as.integer(!is.na(m$evday) & m$evday <= m$open + 1e-6)
m$t  <- (ifelse(m$ev == 1, m$evday, m$open) - W)/365.25
a <- m[m$t > 0, ]
fitm <- coxph(Surv(t, ev) ~ iih, data=a, cluster=match_set); s <- summary(fitm)
ph <- tryCatch(signif(cox.zph(fitm)$table["iih","p"],3), error=function(z) NA)
rt <- function(g){ x <- a[a$iih==g,]; ci <- stats::poisson.test(sum(x$ev), sum(x$t))$conf.int
                   sprintf("%.2f (%.2f to %.2f)", 1000*sum(x$ev)/sum(x$t), 1000*ci[1], 1000*ci[2]) }
a$dday <- as.numeric(a$death_date - a$index_date)
a$cr <- factor(ifelse(a$ev==1,"seizure", ifelse(!is.na(a$dday) & a$dday<=a$open,"death","censor")),
               levels=c("censor","seizure","death"))
fs <- survfit(Surv(t, cr) ~ iih, data=a); sm <- summary(fs, times=TAU, extend=TRUE)
cif <- 100*sm$pstate[, which(fs$states=="seizure")]
out <- data.frame(cohort="Re-matched on dated encounters",
  iih=sprintf("%d/%d", sum(a$ev[a$iih==1]), sum(a$iih==1)),
  comparator=sprintf("%d/%d", sum(a$ev[a$iih==0]), sum(a$iih==0)),
  iih_rate=rt(1), ctl_rate=rt(0),
  HR=fmt_est(s$conf.int[1], s$conf.int[3], s$conf.int[4]), p=signif(s$coef[1,6],4), ph_p=ph,
  cif3_iih=round(cif[2],2), cif3_ctl=round(cif[1],2),
  risk_diff_pp=round(cif[2]-cif[1],2), NNH=round(100/(cif[2]-cif[1])))
out$prevalence_screen <- if (PREV_AT_MATCH) "at matching" else "after matching"
write_tab(out, if (PREV_AT_MATCH) "K_T30_rematched_proper" else "K_T33_prev_after_matching"); print(out, row.names=FALSE)

flow <- data.frame(quantity=c("cases eligible","cases matched","cases unmatched",
                              "controls used","mean controls per case","tier-1 matches"),
  value=c(nrow(cases), sum(!is.na(csets)), sum(is.na(csets)), sum(!is.na(ctlset)),
          round(sum(!is.na(ctlset))/sum(!is.na(csets)),2), sum(tier_of==1, na.rm=TRUE)))
if (PREV_AT_MATCH) write_tab(flow, "K_T31_rematch_flow_proper"); print(flow, row.names=FALSE)
bal <- rbind(
  data.frame(variable="age", iih=round(mean(m$age_index[m$iih==1],na.rm=TRUE),2),
             control=round(mean(m$age_index[m$iih==0],na.rm=TRUE),2),
             smd=round(smd_cont(m$age_index, m$iih),4)),
  data.frame(variable="BMI", iih=round(mean(m$bmi_index[m$iih==1],na.rm=TRUE),2),
             control=round(mean(m$bmi_index[m$iih==0],na.rm=TRUE),2),
             smd=round(smd_cont(m$bmi_index, m$iih),4)),
  data.frame(variable="female", iih=round(mean(m$sex[m$iih==1]=="F"),3),
             control=round(mean(m$sex[m$iih==0]=="F"),3),
             smd=round(smd_bin(m$sex=="F", m$iih),4)))
if (PREV_AT_MATCH) write_tab(bal, "K_T32_rematch_balance_proper"); print(bal, row.names=FALSE)
if (PREV_AT_MATCH) saveRDS(a, file.path(PATH$derived, "K13_rematched.rds"))
log_msg("K13 complete")
