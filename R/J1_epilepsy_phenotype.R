## J1_epilepsy_phenotype.R ----------------------------------------------------
## SECONDARY OUTCOME: epilepsy (recurrent unprovoked seizures) distinguished
## from a single seizure event. The primary analysis is untouched.
##
## Evidence sources, per the investigator's specification:
##   - diagnosis extract   data-raw/SZ_dx_62.csv          (dated ICD-9/10)
##   - conditions extract  data-raw/SZ_conditions_10.csv  (problem list)
##   - medications         chronic antiseizure therapy, both arms
##
## PHENOTYPE (hierarchical, first match wins)
##   EPILEPSY  >=2 G40.x/345.x codes >=30 days apart, OR
##             a G40/345 code whose descriptor denotes established disease
##               (intractable, status epilepticus, named epilepsy syndrome), OR
##             a G40/345 code plus chronic ASM (>=180-day span of ASM records)
##   SEIZURE   a qualifying event not meeting the above: a single G40/345
##             code, or R56.9/780.39 only
##   NONE      no qualifying evidence in the window
##
## NOT counted at either level: F44.5 psychogenic non-epileptic seizures;
## R56.1/780.33 post-traumatic non-epileptic seizures; febrile convulsions.
##
## THREE CORRECTIONS to the first version of this script, each of which changed
## the counts materially:
##
##  1. CLOCK. v1 ascertained on fu_seizure_end_day, which is censored AT the
##     primary seizure event. Epilepsy is defined by RECURRENCE, so a clock that
##     stops at the first seizure makes the recurrence criterion unreachable --
##     and it does so preferentially in the arm with more events (IIH, 102 vs
##     64), which inverted the comparison. This is the same class of error as
##     the carpal-tunnel clock bug fixed in G1. The phenotype now runs on its
##     own clock, to last attended encounter / death / freeze, capped at the
##     same 3-year horizon as the primary so the arms stay comparable.
##
##  2. SOURCE SEPARATION. The primary outcome comes from the abstracted master
##     workbook; these are independent code extracts. In controls the two
##     disagree substantially (222 controls carry post-washout seizure codes
##     with no primary event). v1 silently mixed the two. This outcome is now
##     built ENTIRELY from the code + ASM extracts, applied identically in both
##     arms, and concordance with the primary is reported rather than assumed.
##
##  3. PREVALENT EXCLUSION. Applied symmetrically on the same extract: any
##     qualifying code on or before day 180 removes the patient from the
##     at-risk set for this outcome.

source("R/00_setup.R")
log_msg("=== J1 epilepsy vs single-seizure phenotype ===")
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds"))
TAU <- 3; WASHOUT_D <- 180; CUTOFF <- as.Date("2026-09-03")
HORIZON <- WASHOUT_D + TAU * 365.25

## ---- 1. assemble coded evidence from BOTH sources --------------------------
dx <- utils::read.csv(file.path("data-raw","SZ_dx_62.csv"), colClasses="character", check.names=FALSE)
names(dx) <- c("mrn","system","code","desc","date")
dx <- data.frame(mrn=trimws(dx$mrn), code=dx$code, desc=dx$desc,
                 date=as.Date(substr(dx$date,1,10)), src="diagnosis", stringsAsFactors=FALSE)

cn <- utils::read.csv(file.path("data-raw","SZ_conditions_10.csv"), colClasses="character", check.names=FALSE)
names(cn) <- c("mrn","system","code","cond","onset","recorded")
## Onset where present, recorded otherwise. Onset can precede recording by
## years; the earlier of the two is conservative for an incident outcome -- it
## makes a patient prevalent sooner rather than manufacturing a late event.
on <- as.Date(substr(cn$onset,1,10)); rc <- as.Date(substr(cn$recorded,1,10))
cn <- data.frame(mrn=trimws(cn$mrn), code=cn$code, desc=cn$cond,
                 date=as.Date(ifelse(is.na(on), rc, on), origin="1970-01-01"),
                 src="conditions", stringsAsFactors=FALSE)

ev <- rbind(dx, cn)
ev <- ev[ev$mrn %in% d0$mrn & !is.na(ev$date), ]

## ---- 2. classify codes ------------------------------------------------------
ev$excluded <- grepl("^F44\\.5|^300\\.11", ev$code) |
               grepl("^R56\\.1|^780\\.33|^780\\.32", ev$code) |
               grepl("febrile|non epileptic|non-epileptic|psychogenic|conversion|behavioral spell",
                     ev$desc, ignore.case=TRUE)
ev$g40 <- (grepl("^G40|^345", ev$code) | grepl("^0345", ev$code)) & !ev$excluded
ev$r56 <- (grepl("^R56|^780\\.39", ev$code) | grepl("^07703", ev$code)) & !ev$excluded & !ev$g40
ev$established <- ev$g40 & grepl("intractable|status epilepticus|epilepsy|epileptic syndrome|recurrent",
                                 ev$desc, ignore.case=TRUE)
ev$qual <- ev$g40 | ev$r56
codes <- as.data.frame(table(class=ifelse(ev$excluded,"excluded (provoked/non-epileptic)",
                        ifelse(ev$g40,"G40/345 epilepsy-specific",
                        ifelse(ev$r56,"R56/780.39 non-specific","unclassified")))))
write_tab(codes, "J_T01_code_classes"); print(codes)

## ---- 3. chronic ASM ---------------------------------------------------------
## COMPARABILITY CAVEAT. The case medication file records ADMINISTRATIONS (69%
## have administered-date equal to start-date) while the control file records
## PRESCRIPTIONS with end dates. Chronic outpatient therapy is captured
## differently in the two arms, and only 24 cohort patients meet a >=180-day
## ASM span at all -- implausibly few for a seizure cohort, i.e. the channel is
## under-captured in both arms. Every result below is reported with and without
## it, and it turns out to change nothing.
ASM <- c("levetiracetam","lamotrigine","lacosamide","oxcarbazepine","carbamazepine","phenytoin",
 "fosphenytoin","valproa","divalproex","zonisamide","perampanel","brivaracetam","felbamate",
 "rufinamide","vigabatrin","tiagabine","primidone","ethosuximide","phenobarb","eslicarbazepine","cenobamate")
isasm <- function(x){g<-tolower(x); Reduce(`|`, lapply(ASM, function(a) grepl(a,g,fixed=TRUE)))}
mc <- utils::read.csv(file.path("data-raw","MDE_Medications_cases_22.csv"), colClasses="character", check.names=FALSE)
names(mc)<-c("mrn","ended","started","generic","name","tclass","tcode","admin")
mc <- data.frame(mrn=trimws(mc$mrn), date=as.Date(substr(mc$started,1,10)), asm=isasm(mc$generic))
md <- utils::read.csv(file.path("data-raw","IIH_medications_detail.csv"), colClasses="character", check.names=FALSE)
md <- data.frame(mrn=trimws(md$clinic_number), date=as.Date(substr(md$start_date,1,10)), asm=md$asm_generic!="")
asm <- rbind(mc, md); asm <- asm[asm$asm & !is.na(asm$date) & asm$mrn %in% d0$mrn, ]
CHRONIC_D <- 180
sp <- tapply(asm$date, asm$mrn, function(x) as.numeric(max(x)-min(x)))
d0$asm_span <- as.numeric(sp[d0$mrn]); d0$asm_span[is.na(d0$asm_span)] <- -1
d0$chronic_asm <- d0$asm_span >= CHRONIC_D

## ---- 4. phenotype clock (correction 1) --------------------------------------
## To last attended encounter / death / freeze, capped at the primary horizon.
d0$fu_phen_end_day <- pmin(d0$fu_carpal_end_day, HORIZON)
ev$day <- as.numeric(ev$date - d0$index_date[match(ev$mrn, d0$mrn)])

## ---- 5. prevalent exclusion (correction 3) ----------------------------------
prev <- unique(ev$mrn[ev$qual & ev$day <= WASHOUT_D])
d0$phen_prevalent <- d0$mrn %in% prev
d0$phen_atrisk <- !d0$phen_prevalent & d0$fu_phen_end_day > WASHOUT_D
write_tab(data.frame(arm=c("IIH","Control"),
  n=c(sum(d0$iih==1), sum(d0$iih==0)),
  prevalent_excluded=c(sum(d0$phen_prevalent & d0$iih==1), sum(d0$phen_prevalent & d0$iih==0)),
  no_time_at_risk=c(sum(!d0$phen_prevalent & !d0$phen_atrisk & d0$iih==1),
                    sum(!d0$phen_prevalent & !d0$phen_atrisk & d0$iih==0)),
  at_risk=c(sum(d0$phen_atrisk & d0$iih==1), sum(d0$phen_atrisk & d0$iih==0))),
  "J_T02_at_risk")

## ---- 6. build the phenotype --------------------------------------------------
## Classification uses ALL in-window evidence, including evidence after the
## first qualifying code: epilepsy is defined by recurrence, which by
## construction occurs after event one. Two time origins are recorded --
## t_any (first qualifying code) and t_epi (the day the epilepsy definition is
## first met) -- so the two outcomes each get their own correct event time.
evq <- ev[ev$qual, ]
evq <- split(evq[, c("day","g40","established")], evq$mrn)
phen <- function(dat, use_asm) {
  dat$ph <- "NONE"; dat$t_any <- NA_real_; dat$t_epi <- NA_real_
  for (i in which(dat$phen_atrisk)) {
    e <- evq[[dat$mrn[i]]]; if (is.null(e)) next
    end <- dat$fu_phen_end_day[i]
    post <- e[e$day > WASHOUT_D & e$day <= end + 1e-6, ]
    if (!nrow(post)) next
    dat$ph[i] <- "SEIZURE"; dat$t_any[i] <- min(post$day)
    g <- post[post$g40, ]; if (!nrow(g)) next
    cand <- c()
    ud <- sort(unique(g$day))
    if (length(ud) >= 2) {                       # second code >=30 days later
      k <- which(ud >= ud[1] + 30)[1]
      if (!is.na(k)) cand <- c(cand, ud[k])
    }
    if (any(g$established)) cand <- c(cand, min(g$day[g$established]))
    if (use_asm && dat$chronic_asm[i]) cand <- c(cand, min(g$day))
    if (length(cand)) { dat$ph[i] <- "EPILEPSY"; dat$t_epi[i] <- min(cand) }
  }
  dat
}
log_msg("classifying phenotypes ...")
D_asm <- phen(d0, use_asm = TRUE)
D_cod <- phen(d0, use_asm = FALSE)
saveRDS(list(asm = D_asm, code = D_cod), file.path(PATH$derived, "J1_phenotype.rds"))

tab <- do.call(rbind, lapply(list(list(D_cod,"Codes only"), list(D_asm,"Codes + chronic ASM")),
  function(z) do.call(rbind, lapply(c(1,0), function(g) {
    s <- z[[1]][z[[1]]$iih==g & z[[1]]$phen_atrisk, ]
    py <- sum(pmax(0, ifelse(s$ph=="NONE", s$fu_phen_end_day, s$t_any) - WASHOUT_D))/365.25
    data.frame(definition=z[[2]], arm=ifelse(g==1,"IIH","Control"), at_risk=nrow(s),
               epilepsy=sum(s$ph=="EPILEPSY"), seizure_only=sum(s$ph=="SEIZURE"),
               none=sum(s$ph=="NONE"),
               pct_epilepsy=round(100*mean(s$ph=="EPILEPSY"),2),
               person_years=round(py,0)) }))))
write_tab(tab, "J_T03_phenotype_counts"); print(tab)

## ---- 7. concordance with the abstracted primary outcome (correction 2) ------
cc <- do.call(rbind, lapply(c(1,0), function(g) {
  s <- D_cod[D_cod$iih==g & D_cod$phen_atrisk, ]
  t <- table(factor(s$event,0:1), factor(s$ph, c("NONE","SEIZURE","EPILEPSY")))
  data.frame(arm=ifelse(g==1,"IIH","Control"),
             primary_no_code_none=t["0","NONE"], primary_no_code_sz=t["0","SEIZURE"],
             primary_no_code_epi=t["0","EPILEPSY"], primary_yes_code_none=t["1","NONE"],
             primary_yes_code_sz=t["1","SEIZURE"], primary_yes_code_epi=t["1","EPILEPSY"]) }))
write_tab(cc, "J_T04_concordance_with_primary"); print(cc)
log_msg("J1 complete")
