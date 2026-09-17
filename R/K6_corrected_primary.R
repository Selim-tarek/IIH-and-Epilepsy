## K6_corrected_primary.R -----------------------------------------------------
## THE CORRECTED PRIMARY ANALYSIS.
##
## The investigator has settled the definition: the primary outcome is ANY
## seizure or epilepsy, with no distinction between them; the epilepsy versus
## single-event split is reported separately as a secondary outcome.
##
## That fixes which comparator rule is the fair one. IIH events were established
## by chart abstraction and counted any seizure, including the 70 of 102 that
## carry only a non-specific convulsion code (R56.9 / 780.39). Comparators were
## scored by the code algorithm recorded in outcome_criterion, which required an
## epilepsy-specific code and therefore discarded exactly that kind of event.
## Applying the investigator's own definition to both arms means comparators
## must also be counted on any seizure code.
##
## WHAT REMAINS UNEQUAL, and why the corrected estimate is a lower bound.
## Cases were chart-confirmed; comparators are scored from codes alone. Codes
## over-count, because a convulsion code can be entered for an episode a
## reviewer would reject. So the comparator count here is generous and the
## hazard ratio correspondingly conservative. The epilepsy-code row from K_T10
## (3.48) is the other end of the bracket. The truth lies between them and
## cannot be resolved without chart review of a sample of comparators.
##
## CLOCK. Index to last attended encounter, death or freeze, capped at the
## 3-year horizon, identical in both arms and defined without reference to the
## outcome. The published clock is censored at the delivered comparator event
## and cannot carry a re-scored one.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K6 corrected primary analysis ===")
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
e$sz  <- (grepl("^R56|^780\\.39|^07703", e$code) & !exc) | e$g40     # ANY seizure

## "Spells Neurological (HCC)" is too vague to stand on its own: per the
## investigator it qualifies only where the patient was placed on antiseizure
## medication indefinitely. Chronic ASM is defined as in J3 -- records spanning
## 180+ days, or one prescription written for 180+ days, restricted to the
## protocol's unambiguous agents. Applied to both arms. It affects one patient
## (an IIH case with no chronic ASM), because no comparator rests on this code
## alone; the rule is implemented rather than waved through so that the
## definition in the manuscript matches the code that produced the numbers.
ASMX <- c("levetiracetam","lamotrigine","carbamazepine","oxcarbazepine","valproa","divalproex",
 "phenytoin","fosphenytoin","lacosamide","zonisamide","perampanel","brivaracetam","felbamate",
 "rufinamide","vigabatrin","tiagabine","primidone","ethosuximide","phenobarb","eslicarbazepine","cenobamate")
isax <- function(x){ z <- tolower(x); Reduce(`|`, lapply(ASMX, function(a) grepl(a, z, fixed=TRUE))) }
mcx <- utils::read.csv(file.path("data-raw","MDE_Medications_cases_22.csv"), colClasses="character")
mdx <- utils::read.csv(file.path("data-raw","IIH_medications_detail.csv"), colClasses="character")
MX <- rbind(data.frame(mrn=trimws(mcx[[1]]), st=as.Date(substr(mcx$Started.Date,1,10)),
                       en=as.Date(substr(mcx$Ended.Date,1,10)), g=mcx$Medication.Generic.Name),
            data.frame(mrn=trimws(mdx$clinic_number), st=as.Date(substr(mdx$start_date,1,10)),
                       en=as.Date(substr(mdx$end_date,1,10)),
                       g=ifelse(mdx$asm_generic != "", mdx$asm_generic, mdx$medication_name)))
MX <- MX[isax(MX$g) & !is.na(MX$st), ]
FRX <- as.Date("2026-09-03")
MX$en[!is.na(MX$en) & MX$en >= as.Date("9999-01-01")] <- FRX          # open-ended script
MX$en[!is.na(MX$en) & (MX$en > FRX | MX$en < MX$st)] <- NA            # null / reversed
spx <- tapply(seq_len(nrow(MX)), MX$mrn, function(k){
  s1 <- as.numeric(max(MX$st[k]) - min(MX$st[k]))
  s2 <- suppressWarnings(max(as.numeric(MX$en[k] - MX$st[k]), na.rm=TRUE))
  max(s1, ifelse(is.finite(s2), s2, -1)) })
CHRONIC <- names(spx)[spx >= 180]
e$sz <- e$sz & !(grepl("spells", e$desc, ignore.case=TRUE) & !(e$mrn %in% CHRONIC))

## ---- build the analysis set -------------------------------------------------
q <- e[e$sz, ]
## Applying the Spells rule to the IIH arm too. IIH events arrive as a delivered
## chart-abstracted flag, so a code-level exclusion would otherwise bite only on
## comparators -- reintroducing the very asymmetry this analysis exists to
## remove. An IIH patient whose sole qualifying code is a Spells code and who
## was never on chronic ASM is therefore dropped from the event count as well.
## Judged on codes inside the analysis window only: a pre-washout code says
## nothing about what the post-washout event rested on.
qa   <- e[grepl("^G40|^345|^0345|^R56|^780\\.39|^07703", e$code) & !exc &
          e$day > W & e$day <= d0$open[match(e$mrn, d0$mrn)] + 1e-6, ]
drop_spells <- names(which(tapply(grepl("spells", qa$desc, ignore.case=TRUE), qa$mrn, all)))
drop_spells <- setdiff(drop_spells, CHRONIC)
log_msg("Spells-only without chronic ASM, dropped from both arms: ", length(drop_spells),
        " (IIH ", sum(d0$iih[match(drop_spells, d0$mrn)] == 1),
        ", comparator ", sum(d0$iih[match(drop_spells, d0$mrn)] == 0), ")")
prev <- unique(q$mrn[q$day <= W])                    # symmetric baseline exclusion
first <- tapply(q$day[q$day > W], q$mrn[q$day > W], min)
build <- function(eng) {
  a <- d0[d0$open > W & !(d0$mrn %in% prev & d0$iih == 0), ]
  if (eng) a <- a[a$engaged, ]
  dd <- ifelse(a$iih == 1, a$lat_days, as.numeric(first[a$mrn]))
  a$ev <- as.integer(!is.na(dd) & dd <= a$open + 1e-6 & (a$iih == 0 | a$event == 1) &
                     !(a$mrn %in% drop_spells))
  a$t  <- (ifelse(a$ev == 1, dd, a$open) - W)/365.25
  a[a$t > 0, ]
}

res <- list()
for (eng in c(TRUE, FALSE)) {
  a <- build(eng); lab <- if (eng) "Engagement-restricted" else "Full cohort"
  m  <- coxph(Surv(t, ev) ~ iih, data=a, cluster=match_set); s <- summary(m)
  ph <- tryCatch(signif(cox.zph(m)$table["iih","p"], 3), error=function(z) NA)
  ## rates
  rt <- function(g){ x <- a[a$iih==g, ]; ci <- stats::poisson.test(sum(x$ev), sum(x$t))$conf.int
                     sprintf("%.2f (%.2f to %.2f)", 1000*sum(x$ev)/sum(x$t), 1000*ci[1], 1000*ci[2]) }
  ## 3-year cumulative incidence, Aalen-Johansen with death as competing risk
  a$deadday <- as.numeric(a$death_date - a$index_date)
  a$cr <- factor(ifelse(a$ev==1, "seizure",
                 ifelse(!is.na(a$deadday) & a$deadday <= a$open, "death", "censor")),
                 levels=c("censor","seizure","death"))
  fs <- survfit(Surv(t, cr) ~ iih, data=a)
  sm <- summary(fs, times=TAU, extend=TRUE)
  ## summary.survfitms drops the column names here, so the seizure column is
  ## located from the fit's own state vector rather than by name.
  k  <- which(fs$states == "seizure")
  cif <- 100*sm$pstate[, k]
  rd  <- cif[2] - cif[1]
  res[[length(res)+1]] <- data.frame(
    cohort=lab,
    iih_events=sprintf("%d/%d", sum(a$ev[a$iih==1]), sum(a$iih==1)),
    ctl_events=sprintf("%d/%d", sum(a$ev[a$iih==0]), sum(a$iih==0)),
    iih_rate=rt(1), ctl_rate=rt(0),
    HR=fmt_est(s$conf.int[1], s$conf.int[3], s$conf.int[4]),
    p=signif(s$coef[1,6],3), ph_p=ph,
    cif3_iih=round(cif[2],2), cif3_ctl=round(cif[1],2),
    risk_diff_pp=round(rd,2), NNH=round(100/rd))
}
out <- do.call(rbind, res)
write_tab(out, "K_T12_corrected_primary")
print(out[, c("cohort","iih_events","ctl_events","HR","cif3_iih","cif3_ctl","risk_diff_pp","NNH")], row.names=FALSE)

## ---- secondary: of those with an event, how many had recurrent disease ------
## Applied to both arms from the codes, on the same open clock: two or more
## seizure code dates 30+ days apart, or an epilepsy-specific G40/345 code.
gsp <- split(e$day[e$g40], e$mrn[e$g40]); qsp <- split(q$day, q$mrn)
epi <- function(m, en) {
  g <- gsp[[m]]; if (!is.null(g) && any(g > W & g <= en)) return(TRUE)
  x <- qsp[[m]]; if (is.null(x)) return(FALSE)
  u <- sort(unique(x[x > W & x <= en])); length(u) >= 2 && (max(u)-min(u)) >= 30
}
sec <- do.call(rbind, lapply(c(TRUE,FALSE), function(eng){
  a <- build(eng); a <- a[a$ev==1, ]
  a$epi <- mapply(epi, a$mrn, a$open)
  do.call(rbind, lapply(c(1,0), function(g){ s <- a[a$iih==g, ]
    ci <- stats::binom.test(sum(s$epi), nrow(s))$conf.int
    data.frame(cohort=if (eng) "Engagement-restricted" else "Full cohort",
      arm=ifelse(g==1,"IIH","Comparator"), with_event=nrow(s),
      recurrent_or_epilepsy=sum(s$epi), single_seizure=sum(!s$epi),
      pct=sprintf("%.0f%% (%.0f to %.0f)", 100*mean(s$epi), 100*ci[1], 100*ci[2])) })) }))
write_tab(sec, "K_T13_secondary_recurrent"); print(sec, row.names=FALSE)
log_msg("K6 complete")
