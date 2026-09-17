## K9_final_primary.R ---------------------------------------------------------
## FINAL CORRECTED PRIMARY ANALYSIS, to the investigator's specification:
##   - keep the non-specific convulsion codes (R56.9 / 780.39)
##   - additionally count as positive anyone qualifying by medication
##   - "Spells Neurological (HCC)" qualifies only with indefinite antiseizure
##     therapy (the rule set earlier)
##   - primary outcome is any seizure or epilepsy, no distinction
##
## OUTCOME: a qualifying seizure code after the 180-day washout, OR antiseizure
## medication continued indefinitely (records spanning 180+ days, or one
## prescription written for 180+ days, protocol agents only). Event date is the
## earlier of the two. Baseline exclusion uses the same evidence, symmetrically.
## Clock: index to last attended encounter, death or freeze, capped at 3 years,
## defined without reference to the outcome.
##
## TWO ROWS ARE REPORTED AND THEY DIFFER IN ONE RESPECT ONLY:
##   SYMMETRIC   the definition above decides both arms. Nothing else counts.
##   CHART-PLUS  as above, but an IIH patient also stays positive on the
##               delivered chart-abstracted flag even where no code or drug
##               supports it. This favours the IIH arm, because comparators
##               were never chart-reviewed and cannot be rescued the same way.
## The symmetric row is the defensible primary. The chart-plus row is shown
## because the IIH events are genuine clinical determinations and discarding
## them entirely would be its own distortion; it is an upper bound, not a
## result. IN THE EVENT THE TWO ROWS COINCIDE EXACTLY: every chart-abstracted
## IIH event also carries a qualifying code or drug, so the chart flag and the
## coded evidence agree completely in the IIH arm and nothing is being rescued
## by the softer rule. That agreement is itself reassuring about the IIH
## ascertainment -- the problem was never that the IIH events were wrong.
##
## MEDICATION COVERAGE IS UNEQUAL, and no reading of the medication channel
## should ignore it: the case file records inpatient ADMINISTRATIONS for 2,187
## of 2,618 IIH patients (commonest agent fosphenytoin, an intravenous drug for
## acute seizures), the comparator file records outpatient PRESCRIPTIONS. Only
## 20 IIH patients and 7 comparators meet the 180-day span. The channel adds
## almost nothing to either arm, and what it adds is not comparable.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K9 final corrected primary ===")
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
exc <- grepl("^F44|^300\\.11|^R56\\.1|^780\\.33|^780\\.32|^Z82|^G43|^E936|^966", e$code) |
       grepl("febrile|non.epileptic|psychogenic|conversion|family history|migraine|poisoning|adverse",
             e$desc, ignore.case=TRUE)
e$g40 <- grepl("^G40|^345|^0345", e$code) & !exc
e$sz  <- (grepl("^R56|^780\\.39|^07703", e$code) & !exc) | e$g40

## ---- medications -------------------------------------------------------------
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
M$en[!is.na(M$en) & M$en >= as.Date("9999-01-01")] <- FR       # open-ended script
M$en[!is.na(M$en) & (M$en > FR | M$en < M$st)] <- NA           # null / reversed
M$day <- as.numeric(M$st - d0$index_date[match(M$mrn, d0$mrn)])
spn <- tapply(seq_len(nrow(M)), M$mrn, function(k){
  s1 <- as.numeric(max(M$st[k]) - min(M$st[k]))
  s2 <- suppressWarnings(max(as.numeric(M$en[k] - M$st[k]), na.rm=TRUE))
  max(s1, ifelse(is.finite(s2), s2, -1)) })
CHRONIC <- names(spn)[spn >= 180]

## ---- Spells rule -------------------------------------------------------------
qa <- e[e$sz & e$day > W & e$day <= d0$open[match(e$mrn, d0$mrn)] + 1e-6, ]
spells_only <- names(which(tapply(grepl("spells", qa$desc, ignore.case=TRUE), qa$mrn, all)))
DROP <- setdiff(spells_only, CHRONIC)
e$sz[e$mrn %in% DROP & grepl("spells", e$desc, ignore.case=TRUE)] <- FALSE
log_msg("Spells-only without indefinite ASM, excluded from both arms: ", length(DROP))

## ---- event day ---------------------------------------------------------------
q <- e[e$sz, ]
code_first <- tapply(q$day[q$day > W], q$mrn[q$day > W], min)
asm_first  <- tapply(M$day[M$day > W], M$mrn[M$day > W], min)
prev <- unique(c(q$mrn[q$day <= W], M$mrn[M$day <= W & M$mrn %in% CHRONIC]))

build <- function(eng, chart_plus) {
  a <- d0[d0$open > W & !(d0$mrn %in% prev), ]; if (eng) a <- a[a$engaged, ]
  cd <- as.numeric(code_first[a$mrn])
  ad <- ifelse(a$mrn %in% CHRONIC, as.numeric(asm_first[a$mrn]), NA_real_)
  dd <- suppressWarnings(pmin(cd, ad, na.rm=TRUE)); dd[is.infinite(dd)] <- NA_real_
  if (chart_plus) dd <- ifelse(a$iih == 1 & a$event == 1 & is.na(dd), a$lat_days, dd)
  a$ev <- as.integer(!is.na(dd) & dd <= a$open + 1e-6)
  a$t  <- (ifelse(a$ev == 1, dd, a$open) - W)/365.25
  a[a$t > 0, ]
}
summar <- function(a, lab, eng) {
  m <- coxph(Surv(t, ev) ~ iih, data=a, cluster=match_set); s <- summary(m)
  ph <- tryCatch(signif(cox.zph(m)$table["iih","p"], 3), error=function(z) NA)
  rt <- function(g){ x <- a[a$iih==g,]; ci <- stats::poisson.test(sum(x$ev), sum(x$t))$conf.int
                     sprintf("%.2f (%.2f to %.2f)", 1000*sum(x$ev)/sum(x$t), 1000*ci[1], 1000*ci[2]) }
  a$dday <- as.numeric(a$death_date - a$index_date)
  a$cr <- factor(ifelse(a$ev==1,"seizure", ifelse(!is.na(a$dday) & a$dday <= a$open,"death","censor")),
                 levels=c("censor","seizure","death"))
  fs <- survfit(Surv(t, cr) ~ iih, data=a); sm <- summary(fs, times=TAU, extend=TRUE)
  cif <- 100*sm$pstate[, which(fs$states == "seizure")]
  data.frame(definition=lab, cohort=if (eng) "Engagement-restricted" else "Full cohort",
    iih=sprintf("%d/%d", sum(a$ev[a$iih==1]), sum(a$iih==1)),
    comparator=sprintf("%d/%d", sum(a$ev[a$iih==0]), sum(a$iih==0)),
    iih_rate=rt(1), ctl_rate=rt(0),
    HR=fmt_est(s$conf.int[1], s$conf.int[3], s$conf.int[4]), p=signif(s$coef[1,6],3), ph_p=ph,
    cif3_iih=round(cif[2],2), cif3_ctl=round(cif[1],2),
    risk_diff_pp=round(cif[2]-cif[1],2), NNH=round(100/(cif[2]-cif[1])))
}
res <- do.call(rbind, unlist(lapply(c(TRUE,FALSE), function(g) list(
  summar(build(g, FALSE), "SYMMETRIC: code or indefinite ASM, both arms", g),
  summar(build(g, TRUE),  "CHART-PLUS: IIH also keeps its abstracted events", g))), recursive=FALSE))
write_tab(res, "K_T17_final_primary")
print(res[, c("definition","cohort","iih","comparator","HR","cif3_iih","cif3_ctl","NNH")], row.names=FALSE)

## ---- secondary ---------------------------------------------------------------
gsp <- split(e$day[e$g40], e$mrn[e$g40]); qsp <- split(q$day, q$mrn)
epi <- function(m, en){ g <- gsp[[m]]; if (!is.null(g) && any(g > W & g <= en)) return(TRUE)
  x <- qsp[[m]]; if (is.null(x)) return(m %in% CHRONIC)
  u <- sort(unique(x[x > W & x <= en])); (length(u) >= 2 && (max(u)-min(u)) >= 30) || m %in% CHRONIC }
sec <- do.call(rbind, lapply(c(TRUE,FALSE), function(eng){
  a <- build(eng, FALSE); a <- a[a$ev==1, ]; a$epi <- mapply(epi, a$mrn, a$open)
  do.call(rbind, lapply(c(1,0), function(g){ s <- a[a$iih==g, ]
    ci <- stats::binom.test(sum(s$epi), nrow(s))$conf.int
    data.frame(cohort=if (eng) "Engagement-restricted" else "Full cohort",
      arm=ifelse(g==1,"IIH","Comparator"), with_event=nrow(s),
      recurrent_or_epilepsy=sum(s$epi), single_seizure=sum(!s$epi),
      pct=sprintf("%.0f%% (%.0f to %.0f)", 100*mean(s$epi), 100*ci[1], 100*ci[2])) })) }))
write_tab(sec, "K_T18_final_secondary"); print(sec, row.names=FALSE)
log_msg("K9 complete")
