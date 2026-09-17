## K8_drop_nonspecific.R ------------------------------------------------------
## What happens if the non-specific convulsion codes are dropped, and does the
## medication channel rescue patients who have drugs but no epilepsy code?
##
## Three definitions, each applied IDENTICALLY to both arms and on the same
## outcome-independent clock (index to last attended encounter, death or
## freeze, capped at 3 years):
##
##   A  any seizure code            R56.9/780.39 or G40/345      (current K6)
##   B  epilepsy codes only         G40/345
##   C  epilepsy code OR chronic ASM   G40/345, or antiseizure medication
##                                     spanning 180+ days with no code at all
##
## C exists because the investigator asks whether IIH patients might be
## outcome-positive on medication rather than coding. They can be, and the
## channel is included here for both arms -- but see the coverage note below
## before reading anything into it.
##
## MEDICATION COVERAGE IS NOT EQUAL BETWEEN THE ARMS, and this is the single
## most important caveat on definition C. The case file records inpatient
## ADMINISTRATIONS for 2,187 of 2,618 IIH patients; the comparator file records
## outpatient PRESCRIPTIONS. Protocol antiseizure drugs appear for 88 IIH
## patients (17 of the 102 events, 71 non-events) and the commonest single
## agent recorded in cases is fosphenytoin, given intravenously for acute
## seizures rather than as maintenance therapy. Chronic outpatient treatment in
## the IIH arm is therefore substantially under-captured, so definition C adds
## more comparators than cases for reasons of data provenance, not biology.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K8 dropping the non-specific codes ===")
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
e$r56 <- grepl("^R56|^780\\.39|^07703", e$code) & !exc & !e$g40

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
M$en[!is.na(M$en) & M$en >= as.Date("9999-01-01")] <- FR
M$en[!is.na(M$en) & (M$en > FR | M$en < M$st)] <- NA
M$day <- as.numeric(M$st - d0$index_date[match(M$mrn, d0$mrn)])
spn <- tapply(seq_len(nrow(M)), M$mrn, function(k){
  s1 <- as.numeric(max(M$st[k]) - min(M$st[k]))
  s2 <- suppressWarnings(max(as.numeric(M$en[k] - M$st[k]), na.rm=TRUE))
  max(s1, ifelse(is.finite(s2), s2, -1)) })
CHRONIC <- names(spn)[spn >= 180]
asm_first <- tapply(M$day[M$day > W], M$mrn[M$day > W], min)

## ---- assemble ---------------------------------------------------------------
fit <- function(sel_code, use_asm, lab, eng) {
  q <- e[sel_code, ]
  prev <- unique(c(q$mrn[q$day <= W], M$mrn[M$day <= W]))
  f <- tapply(q$day[q$day > W], q$mrn[q$day > W], min)
  a <- d0[d0$open > W & !(d0$mrn %in% prev), ]; if (eng) a <- a[a$engaged, ]
  cday <- as.numeric(f[a$mrn])
  if (use_asm) {
    aday <- ifelse(a$mrn %in% CHRONIC, as.numeric(asm_first[a$mrn]), NA_real_)
    cday <- suppressWarnings(pmin(cday, aday, na.rm=TRUE))
    cday[is.infinite(cday)] <- NA_real_
  }
  ## IIH keeps its chart-abstracted event, but only where that patient also
  ## satisfies the definition being tested -- otherwise the rule would bite on
  ## comparators alone, which is the asymmetry under repair.
  dd <- ifelse(a$iih == 1, ifelse(!is.na(cday), a$lat_days, NA_real_), cday)
  a$ev <- as.integer(!is.na(dd) & dd <= a$open + 1e-6 & (a$iih == 0 | a$event == 1))
  a$t  <- (ifelse(a$ev == 1, dd, a$open) - W)/365.25
  a <- a[a$t > 0, ]
  n1 <- sum(a$ev[a$iih==1]); n0 <- sum(a$ev[a$iih==0])
  m <- coxph(Surv(t, ev) ~ iih, data=a, cluster=match_set); s <- summary(m)
  ok <- n1 > 0 && n0 > 0 && abs(s$coef[1,1]) <= 5
  data.frame(definition=lab, cohort=if (eng) "Engagement-restricted" else "Full",
    iih=sprintf("%d/%d", n1, sum(a$iih==1)), comparator=sprintf("%d/%d", n0, sum(a$iih==0)),
    estimate=if (ok) fmt_est(s$conf.int[1], s$conf.int[3], s$conf.int[4]) else "not estimable",
    p=if (ok) signif(s$coef[1,6],3) else NA)
}
res <- do.call(rbind, unlist(lapply(c(TRUE,FALSE), function(g) list(
  fit(e$g40 | e$r56, FALSE, "A. Any seizure code (R56.9/780.39 or G40/345)", g),
  fit(e$g40,         FALSE, "B. Epilepsy codes only (G40/345)", g),
  fit(e$g40,         TRUE,  "C. Epilepsy code OR chronic antiseizure drug", g))), recursive=FALSE))
write_tab(res, "K_T15_dropping_nonspecific"); print(res, row.names=FALSE)

## ---- medication coverage, stated plainly ------------------------------------
cov <- data.frame(
  quantity = c("IIH patients in the case medication file",
               "IIH patients with any protocol antiseizure drug",
               "IIH events with any protocol antiseizure drug",
               "IIH non-events with any protocol antiseizure drug",
               "comparators with any protocol antiseizure drug",
               "patients meeting chronic ASM (180+ days), IIH",
               "patients meeting chronic ASM (180+ days), comparator"),
  value = c(length(unique(trimws(mc[[1]])[trimws(mc[[1]]) %in% d0$mrn])),
            sum(d0$mrn[d0$iih==1] %in% M$mrn),
            sum(d0$mrn[d0$iih==1 & d0$event==1] %in% M$mrn),
            sum(d0$mrn[d0$iih==1 & d0$event==0] %in% M$mrn),
            sum(d0$mrn[d0$iih==0] %in% M$mrn),
            sum(d0$mrn[d0$iih==1] %in% CHRONIC),
            sum(d0$mrn[d0$iih==0] %in% CHRONIC)))
write_tab(cov, "K_T16_medication_coverage"); print(cov, row.names=FALSE)
log_msg("K8 complete")
