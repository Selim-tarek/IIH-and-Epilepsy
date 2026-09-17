## K10_benzodiazepine_check.R -------------------------------------------------
## Should midazolam / lorazepam / diazepam / clonazepam count as qualifying
## antiseizure medication?
##
## No, and the reason is worth putting in the manuscript rather than just in a
## methods footnote.
##
## These agents are given for procedural sedation, imaging, agitation, alcohol
## withdrawal, anxiety and insomnia far more often than for seizures. In this
## cohort 52% of IIH patients and 28% of comparators have at least one such
## record. Counting them would make a majority of the IIH arm outcome-positive.
##
## The decisive test: use a benzodiazepine record ALONE as the outcome, with no
## seizure code required at all. If the resulting hazard ratio resembles the
## seizure hazard ratio, then that estimate is tracking drug exposure and
## healthcare contact rather than seizures.
##
## It does resemble it, closely. That is a caution about the primary estimate
## and is reported as one.
##
## WITH ONE IMPORTANT QUALIFICATION. The benzodiazepine contrast is itself
## contaminated by the same source asymmetry that runs through the medication
## data: the case file records inpatient ADMINISTRATIONS (midazolam 6,110
## records, lorazepam 3,562 -- the signature of procedural sedation) while the
## comparator file records outpatient PRESCRIPTIONS, where a sedation dose
## never appears. Part of the 52% against 28% gap is therefore provenance, not
## exposure, and the benzodiazepine hazard ratio is inflated by an unknown
## amount. It cannot be read as a clean negative control, and the honest
## statement is that it raises a question the current data cannot settle.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K10 benzodiazepine check ===")
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds")); W <- 180; TAU <- 3
d0$open <- pmin(d0$fu_carpal_end_day, W + TAU*365.25)

mc <- utils::read.csv(file.path("data-raw","MDE_Medications_cases_22.csv"), colClasses="character")
md <- utils::read.csv(file.path("data-raw","IIH_medications_detail.csv"), colClasses="character")
M <- rbind(data.frame(mrn=trimws(mc[[1]]), st=as.Date(substr(mc$Started.Date,1,10)),
                      g=paste(mc$Medication.Generic.Name, mc$Medication.Name)),
           data.frame(mrn=trimws(md$clinic_number), st=as.Date(substr(md$start_date,1,10)),
                      g=paste(md$asm_generic, md$medication_name)))
M <- M[M$mrn %in% d0$mrn, ]
BZ <- c("midazolam","lorazepam","diazepam","clonazepam")
B <- M[Reduce(`|`, lapply(BZ, function(a) grepl(a, tolower(M$g), fixed=TRUE))) & !is.na(M$st), ]
B$day <- as.numeric(B$st - d0$index_date[match(B$mrn, d0$mrn)])

prev <- data.frame(arm=c("IIH","Comparator"),
  patients_with_any=c(sum(d0$mrn[d0$iih==1] %in% B$mrn), sum(d0$mrn[d0$iih==0] %in% B$mrn)),
  n=c(sum(d0$iih==1), sum(d0$iih==0)))
prev$pct <- round(100*prev$patients_with_any/prev$n, 1)
write_tab(prev, "K_T19_benzodiazepine_prevalence"); print(prev, row.names=FALSE)

bfirst <- tapply(B$day[B$day > W], B$mrn[B$day > W], min)
res <- do.call(rbind, lapply(c(TRUE,FALSE), function(eng){
  a <- d0[d0$open > W, ]; if (eng) a <- a[a$engaged, ]
  dd <- as.numeric(bfirst[a$mrn])
  a$ev <- as.integer(!is.na(dd) & dd <= a$open + 1e-6)
  a$t  <- (ifelse(a$ev==1, dd, a$open) - W)/365.25; a <- a[a$t > 0, ]
  m <- coxph(Surv(t, ev) ~ iih, data=a, cluster=match_set); s <- summary(m)
  data.frame(outcome="A benzodiazepine record alone, no seizure code required",
    cohort=if (eng) "Engagement-restricted" else "Full cohort",
    iih=sprintf("%d/%d", sum(a$ev[a$iih==1]), sum(a$iih==1)),
    comparator=sprintf("%d/%d", sum(a$ev[a$iih==0]), sum(a$iih==0)),
    estimate=fmt_est(s$conf.int[1], s$conf.int[3], s$conf.int[4])) }))
res <- rbind(res, data.frame(outcome="Seizure or epilepsy (corrected primary, K_T17)",
  cohort=c("Engagement-restricted","Full cohort"), iih=c("63/2593","64/2605"),
  comparator=c("48/4017","207/9085"),
  estimate=c("1.87 (1.28 to 2.72)","1.03 (0.78 to 1.36)")))
write_tab(res, "K_T20_benzodiazepine_as_outcome"); print(res, row.names=FALSE)
log_msg("K10 complete")
