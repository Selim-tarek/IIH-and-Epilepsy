## J3_epilepsy_among_cases.R --------------------------------------------------
## The investigator's question, posed correctly.
##
## The outcome was defined by the abstraction team from codes AND chart
## observation AND medications together. So the right question is not "who has
## seizure codes" -- it is: AMONG THE PATIENTS ALREADY CLASSIFIED AS
## OUTCOME-POSITIVE, which had recurrent unprovoked seizures (epilepsy) and
## which had a single seizure event?
##
## Conditioning on the outcome set has a real advantage: it does not depend on
## resolving the ascertainment asymmetry documented in J2, because both the
## analyst and the abstraction team agree on who these 166 patients are.
##
## THREE CHANNELS OF EVIDENCE FOR RECURRENT / ESTABLISHED DISEASE
##   (a) RECURRENCE   >=2 qualifying seizure code dates >=30 days apart
##   (b) EPILEPSY CODE  any G40.x / 345.x code, or a descriptor denoting
##                      established disease (intractable, status epilepticus,
##                      named epilepsy syndrome)
##   (c) CHRONIC ASM  antiseizure medication continued indefinitely: ASM records
##                    spanning >=180 days, or a single prescription written for
##                    >=180 days
## A patient meeting ANY channel is EPILEPSY; an outcome-positive patient
## meeting none is SINGLE SEIZURE.
##
## CLOCK. Ascertainment runs from index to last attended encounter / death /
## freeze -- NOT to the seizure. Recurrence by definition occurs after event
## one, so a clock that stops at the first seizure cannot ever observe it.
##
## ASM DRUG SET. Topiramate, gabapentin and clobazam are deliberately EXCLUDED.
## Topiramate is first-line for IIH itself and gabapentin is a pain drug;
## counting either would manufacture epilepsy in the IIH arm by construction.

source("R/00_setup.R")
log_msg("=== J3 epilepsy vs single seizure among outcome-positive patients ===")
P <- readRDS(file.path(PATH$derived, "J1_phenotype.rds"))$code
WASHOUT_D <- 180
E <- P[P$event == 1, ]

## ---- coded evidence ---------------------------------------------------------
dx <- utils::read.csv(file.path("data-raw","SZ_dx_62.csv"), colClasses="character")
names(dx) <- c("mrn","s","code","desc","date")
cn <- utils::read.csv(file.path("data-raw","SZ_conditions_10.csv"), colClasses="character")
names(cn) <- c("mrn","s","code","desc","on","rec")
o <- as.Date(substr(cn$on,1,10)); r <- as.Date(substr(cn$rec,1,10))
e <- rbind(data.frame(mrn=trimws(dx$mrn), code=dx$code, desc=dx$desc, date=as.Date(substr(dx$date,1,10))),
           data.frame(mrn=trimws(cn$mrn), code=cn$code, desc=cn$desc,
                      date=as.Date(ifelse(is.na(o), r, o), origin="1970-01-01")))
e <- e[e$mrn %in% E$mrn & !is.na(e$date), ]
i <- match(e$mrn, E$mrn)
e$day <- as.numeric(e$date - E$index_date[i])
e <- e[e$day > WASHOUT_D & e$day <= E$fu_carpal_end_day[i] + 1e-6, ]
exc <- grepl("^F44\\.5|^300\\.11|^R56\\.1|^780\\.33|^780\\.32", e$code) |
       grepl("febrile|non.epileptic|psychogenic|conversion", e$desc, ignore.case=TRUE)
e$qual <- grepl("^G40|^345|^0345|^R56|^780\\.39|^07703", e$code) & !exc
e$g40  <- grepl("^G40|^345|^0345", e$code) & !exc
e$estab <- e$g40 & grepl("intractable|status epilepticus|epilepsy|epileptic syndrome|recurrent",
                         e$desc, ignore.case=TRUE)

q <- e[e$qual, ]
rec <- tapply(q$day, q$mrn, function(x){ u <- sort(unique(x)); length(u) >= 2 && (max(u)-min(u)) >= 30 })
g40 <- tapply(e$g40 | e$estab, e$mrn, any)
E$ch_recurrence   <- isTRUE_v <- !is.na(rec[E$mrn]) & rec[E$mrn]
E$ch_epilepsy_code <- !is.na(g40[E$mrn]) & g40[E$mrn]

## ---- chronic ASM ------------------------------------------------------------
## Seizure-specific agents only (see header).
CORE <- c("levetiracetam","lamotrigine","lacosamide","oxcarbazepine","carbamazepine","phenytoin",
 "fosphenytoin","valproa","divalproex","zonisamide","perampanel","brivaracetam","felbamate",
 "rufinamide","vigabatrin","tiagabine","primidone","ethosuximide","phenobarb","eslicarbazepine","cenobamate")
isa <- function(x){ g <- tolower(x); Reduce(`|`, lapply(CORE, function(a) grepl(a, g, fixed=TRUE))) }
mc <- utils::read.csv(file.path("data-raw","MDE_Medications_cases_22.csv"), colClasses="character")
A <- data.frame(mrn=trimws(mc[[1]]), st=as.Date(substr(mc$Started.Date,1,10)),
                en=as.Date(substr(mc$Ended.Date,1,10)), g=mc$Medication.Generic.Name)
md <- utils::read.csv(file.path("data-raw","IIH_medications_detail.csv"), colClasses="character")
B <- data.frame(mrn=trimws(md$clinic_number), st=as.Date(substr(md$start_date,1,10)),
                en=as.Date(substr(md$end_date,1,10)),
                g=ifelse(md$asm_generic != "", md$asm_generic, md$medication_name))
M <- rbind(A, B); M <- M[M$mrn %in% E$mrn & isa(M$g) & !is.na(M$st), ]
CHRONIC_D <- 180
span <- tapply(seq_len(nrow(M)), M$mrn, function(k){
  st <- M$st[k]; en <- M$en[k]
  s1 <- as.numeric(max(st) - min(st))                       # records spanning >=180d
  s2 <- suppressWarnings(max(as.numeric(en - st), na.rm=TRUE))  # one script >=180d
  max(s1, ifelse(is.finite(s2), s2, -1)) })
E$asm_span <- as.numeric(span[E$mrn]); E$asm_span[is.na(E$asm_span)] <- -1
E$ch_chronic_asm <- E$asm_span >= CHRONIC_D
E$any_asm <- E$mrn %in% M$mrn

E$epilepsy <- E$ch_recurrence | E$ch_epilepsy_code | E$ch_chronic_asm
E$class <- ifelse(E$epilepsy, "EPILEPSY (recurrent/established)", "SINGLE SEIZURE")
saveRDS(E, file.path(PATH$derived, "J3_event_classification.rds"))

## ---- tables -----------------------------------------------------------------
main <- do.call(rbind, lapply(c(1,0), function(g){
  s <- E[E$iih==g, ]
  data.frame(arm=ifelse(g==1,"IIH","Control"), outcome_positive=nrow(s),
             epilepsy=sum(s$epilepsy), single_seizure=sum(!s$epilepsy),
             pct_epilepsy=round(100*mean(s$epilepsy),1)) }))
write_tab(main, "J_T06_epilepsy_vs_single"); print(main)

ch <- do.call(rbind, lapply(c(1,0), function(g){
  s <- E[E$iih==g, ]
  data.frame(arm=ifelse(g==1,"IIH","Control"), n=nrow(s),
             recurrence=sum(s$ch_recurrence), epilepsy_code=sum(s$ch_epilepsy_code),
             chronic_asm=sum(s$ch_chronic_asm),
             any_asm_record=sum(s$any_asm),
             codes_only_epilepsy=sum(s$ch_recurrence | s$ch_epilepsy_code)) }))
write_tab(ch, "J_T07_channel_contributions"); print(ch)

## Fisher test on the CODE-BASED definition only. The ASM channel is not
## comparable between arms (see J_T07 and the report): the case medication file
## records inpatient administrations, the control file outpatient prescriptions.
ct <- table(factor(E$iih,c(1,0)), factor(E$ch_recurrence | E$ch_epilepsy_code, c(TRUE,FALSE)))
ft <- stats::fisher.test(ct)
write_tab(data.frame(comparison="Epilepsy (code channels only) among outcome-positive, IIH vs control",
  OR=unname(ft$estimate), lo=ft$conf.int[1], hi=ft$conf.int[2], p=ft$p.value,
  estimate=fmt_est(unname(ft$estimate), ft$conf.int[1], ft$conf.int[2])),
  "J_T08_epilepsy_proportion_test")
cat(sprintf("\ncode-based epilepsy among outcome-positive: OR %.2f (%.2f to %.2f), p=%.3g\n",
    ft$estimate, ft$conf.int[1], ft$conf.int[2], ft$p.value))
log_msg("J3 complete")
