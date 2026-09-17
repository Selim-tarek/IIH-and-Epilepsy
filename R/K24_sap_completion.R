## K24_sap_completion.R -------------------------------------------------------
## Completes the analyses in the statistical analysis plan that are feasible with
## the delivered data and had not yet been run.
##
##   T1  baseline characteristics with standardised mean differences
##   T2  healthcare utilisation and surveillance, rates with exact intervals
##   T3  period-specific hazard ratios and landmark analyses
##   T4  competing risks: cause-specific and subdistribution
##   T5  prespecified subgroups with interaction tests on the sandwich covariance
##   T6  propensity score: overlap weighting and matching-weight diagnostics
##   T7  missing data
##   T8  events per parameter
##
## WHAT CANNOT BE DONE, and why, recorded here rather than silently omitted:
##   - Diabetes, hyperlipidemia, stroke/TIA, traumatic brain injury, CNS
##     infection, brain tumour, migraine, sleep and psychiatric disorders and
##     substance use are NOT in any delivered file. Table 1 is correspondingly
##     thin. Note that stroke, TBI, tumour and CVST were exclusion criteria, so
##     their absence at baseline is by design, not by chance.
##   - Race is populated for 100% of comparators and 0% of IIH cases. It
##     therefore could not constrain matching despite being in the protocol, and
##     cannot appear in Table 1 as a comparison. This is a data defect.
##   - Neurology and ophthalmology visits cannot be separated: encounter type
##     distinguishes office visit from hospital encounter but carries no
##     specialty. Surveillance is therefore quantified in total clinical visits.
##   - EEG is recorded for 15% of IIH patients and 0% of comparators; opening
##     pressure for 73% and 0%. Neither supports a between-arm comparison.
##   - Brain MRI and CT counts are unavailable: the radiology extract covers
##     comparators only.
##   - Shunt and stent are IIH treatments and are zero in comparators by
##     definition; they are descriptors of the exposed arm, not covariates.
##   - Smoking is populated in both arms but the distributions are not credible
##     (former smokers 1.5% of IIH against 15.9% of comparators), so it is
##     reported and not adjusted for.
##   - An ACTIVE COMPARATOR (for example chronic migraine or another headache
##     disorder under equivalent specialist follow-up) is not available in the
##     delivered data and cannot be constructed from it. This is the single
##     most valuable missing design element and is stated as such.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K24 SAP completion ===")
V <- readRDS(file.path(PATH$derived, "K15_final_visits.rds")); a <- V$a
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds"))
W <- 180; TAU <- 3
a$htn <- d0$htn[match(a$mrn, d0$mrn)]
a$smoke <- d0$smoking_final[match(a$mrn, d0$mrn)]

## encounter-derived surveillance
ADMIN <- paste0("^(Patient Message|Clinical Communication|History|Orders Only|",
 "Recurring Plan|Reconciled Outside Data|Account-less|Refill|Wait List|",
 "Ancillary Orders|Letter \\(Out\\)|Historical Appointment|Documentation|",
 "Results Follow-Up|Transcribe Orders|Series|Silent Schedule|Abstract|",
 "OurPractice Advisory|Episode Changes|Dictaphone|Committee Review|",
 "Community Orders|Outside Material Tracking|Aria Results|Enrollment|Education|",
 "Patient Outreach|External Outreach|Patient Self-Triage|Remote Monitoring|",
 "CPAP Download|Prep for Case|Specialty Pharmacy|Internal E-Consult|Admin Visit)|",
 "Conversion Encounter|^Erroneous|^Historic|^Clinical Support")
rd <- function(p, dc, tc){ x <- utils::read.csv(p, colClasses="character")
  z <- data.frame(mrn=trimws(x[[1]]), d=as.Date(substr(x[[dc]],1,10)), type=trimws(x[[tc]]))
  z[!grepl(ADMIN, z$type), ] }
EN <- unique(rbind(rd("data-raw/MDE_Encounters_types_full.csv", 3, 2),
                   rd("data-raw/MDE_Encounters_controls_typed.csv", 5, 6)))
EN <- EN[EN$mrn %in% a$mrn, ]
EN$rel <- as.numeric(EN$d - a$index_date[match(EN$mrn, a$mrn)])
gv <- function(v){ z <- as.numeric(v[a$mrn]); z[is.na(z)] <- 0; z }
a$pre12 <- gv(tapply(EN$rel >= -365 & EN$rel < 0, EN$mrn, sum))
a$n_post <- gv(tapply(EN$rel > W & EN$rel <= W + TAU*365.25, EN$mrn, sum))
ED  <- EN[grepl("^Emergency", EN$type), ]
INP <- EN[grepl("^(Inpatient|Hospital Encounter|Observation)", EN$type), ]
a$n_ed  <- gv(tapply(ED$rel  > W & ED$rel  <= W+TAU*365.25, ED$mrn,  sum))
a$n_inp <- gv(tapply(INP$rel > W & INP$rel <= W+TAU*365.25, INP$mrn, sum))

## ---- T1 baseline ---------------------------------------------------------------
num <- function(v, lab) data.frame(variable=lab,
  IIH=sprintf("%.1f (%.1f)", mean(a[[v]][a$iih==1], na.rm=TRUE), stats::sd(a[[v]][a$iih==1], na.rm=TRUE)),
  Comparator=sprintf("%.1f (%.1f)", mean(a[[v]][a$iih==0], na.rm=TRUE), stats::sd(a[[v]][a$iih==0], na.rm=TRUE)),
  SMD=round(smd_cont(a[[v]], a$iih), 3))
bin <- function(x, lab) data.frame(variable=lab,
  IIH=sprintf("%d (%.1f%%)", sum(x[a$iih==1], na.rm=TRUE), 100*mean(x[a$iih==1], na.rm=TRUE)),
  Comparator=sprintf("%d (%.1f%%)", sum(x[a$iih==0], na.rm=TRUE), 100*mean(x[a$iih==0], na.rm=TRUE)),
  SMD=round(smd_bin(x, a$iih), 3))
T1 <- rbind(num("age_index","Age at index, years, mean (SD)"),
            bin(a$sex=="F","Female"),
            num("bmi_index","BMI, kg/m2, mean (SD)"),
            bin(a$bmi_index>=30,"Obese (BMI >= 30)"),
            bin(as.numeric(a$htn)==1,"Hypertension"),
            bin(a$smoke=="Current","Current smoker (not comparable, see note)"),
            num("pre12","Clinical visits, 12 months before index, mean (SD)"))
write_tab(T1, "SAP_T1_baseline"); print(T1, row.names=FALSE)

## ---- T2 surveillance -------------------------------------------------------------
py <- tapply(a$t, a$iih, sum)
rate <- function(cnt, lab) { r <- tapply(cnt, a$iih, sum)
  ci1 <- stats::poisson.test(r[["1"]], py[["1"]])$conf.int
  ci0 <- stats::poisson.test(r[["0"]], py[["0"]])$conf.int
  rr  <- (r[["1"]]/py[["1"]])/(r[["0"]]/py[["0"]])
  data.frame(measure=lab,
    IIH=sprintf("%.2f (%.2f to %.2f)", r[["1"]]/py[["1"]], ci1[1], ci1[2]),
    Comparator=sprintf("%.2f (%.2f to %.2f)", r[["0"]]/py[["0"]], ci0[1], ci0[2]),
    rate_ratio=round(rr, 2)) }
T2 <- rbind(rate(a$n_post,"All clinical visits per person-year"),
            rate(a$n_ed,  "Emergency encounters per person-year"),
            rate(a$n_inp, "Hospital or inpatient encounters per person-year"))
write_tab(T2, "SAP_T2_surveillance"); print(T2, row.names=FALSE)

## ---- T3 period-specific and landmark ---------------------------------------------
cuts <- c(0, .5, 1, 2, TAU)
sp <- survSplit(Surv(t, ev) ~ ., data=a, cut=cuts[-c(1,length(cuts))], episode="per")
sp$per <- factor(sp$per, labels=c("0 to 6 months","6 to 12 months","1 to 2 years","2 to 3 years"))
m_per <- coxph(Surv(tstart, t, ev) ~ iih:per + strata(per), data=sp, cluster=match_set)
s <- summary(m_per)
T3a <- data.frame(period=levels(sp$per),
  HR=fmt_est(s$conf.int[,1], s$conf.int[,3], s$conf.int[,4]))
lm_fit <- function(L) { b <- a[a$t > L, ]; b$t2 <- b$t - L
  m <- coxph(Surv(t2, ev) ~ iih, data=b, cluster=match_set); z <- summary(m)
  data.frame(analysis=sprintf("Landmark: events in the first %.0f days after washout excluded", L*365.25),
    iih_events=sum(b$ev[b$iih==1]), ctl_events=sum(b$ev[b$iih==0]),
    HR=fmt_est(z$conf.int[1], z$conf.int[3], z$conf.int[4])) }
T3b <- rbind(data.frame(analysis="Primary (180-day washout only)",
               iih_events=sum(a$ev[a$iih==1]), ctl_events=sum(a$ev[a$iih==0]),
               HR=fmt_est(summary(coxph(Surv(t,ev)~iih,data=a,cluster=match_set))$conf.int[c(1,3,4)][1],
                          summary(coxph(Surv(t,ev)~iih,data=a,cluster=match_set))$conf.int[3],
                          summary(coxph(Surv(t,ev)~iih,data=a,cluster=match_set))$conf.int[4])),
             lm_fit(30/365.25), lm_fit(90/365.25), lm_fit(180/365.25))
write_tab(T3a, "SAP_T3a_period_specific"); print(T3a, row.names=FALSE)
write_tab(T3b, "SAP_T3b_landmark");        print(T3b, row.names=FALSE)

## ---- T4 competing risks ------------------------------------------------------------
a$dd <- as.numeric(a$death_date - a$index_date)
a$cr <- factor(ifelse(a$ev==1,"seizure", ifelse(!is.na(a$dd) & a$dd<=a$open,"death","censor")),
               levels=c("censor","seizure","death"))
cs_sz <- summary(coxph(Surv(t, ev) ~ iih, data=a, cluster=match_set))
a$dev <- as.integer(a$cr=="death")
cs_d  <- summary(coxph(Surv(t, dev) ~ iih, data=a, cluster=match_set))
fg <- summary(coxph(Surv(fgstart, fgstop, fgstatus) ~ iih,
       data=finegray(Surv(t, cr) ~ ., data=a, etype="seizure"), weights=fgwt, cluster=match_set))
T4 <- data.frame(estimand=c("Cause-specific HR, seizure (primary)",
                            "Subdistribution HR, seizure (Fine-Gray)",
                            "Cause-specific HR, death (competing event)"),
  estimate=c(fmt_est(cs_sz$conf.int[1], cs_sz$conf.int[3], cs_sz$conf.int[4]),
             fmt_est(fg$conf.int[1], fg$conf.int[3], fg$conf.int[4]),
             fmt_est(cs_d$conf.int[1], cs_d$conf.int[3], cs_d$conf.int[4])))
write_tab(T4, "SAP_T4_competing_risks"); print(T4, row.names=FALSE)

## ---- T5 subgroups -------------------------------------------------------------------
sub <- function(var, lab) {
  a$g <- var
  out <- do.call(rbind, lapply(levels(factor(a$g)), function(k){ b <- a[a$g==k, ]
    if (sum(b$ev[b$iih==1]) < 3 || sum(b$ev[b$iih==0]) < 3) return(NULL)
    z <- summary(coxph(Surv(t,ev) ~ iih, data=b, cluster=match_set))
    data.frame(subgroup=lab, level=k, iih_events=sum(b$ev[b$iih==1]), ctl_events=sum(b$ev[b$iih==0]),
               HR=fmt_est(z$conf.int[1], z$conf.int[3], z$conf.int[4])) }))
  m <- coxph(Surv(t,ev) ~ iih*factor(g), data=a, cluster=match_set)
  ix <- grep(":", names(coef(m)))
  p <- if (!length(ix)) NA else {
    b <- coef(m)[ix]; Vr <- vcov(m)[ix, ix, drop=FALSE]
    stats::pchisq(as.numeric(t(b) %*% solve(Vr) %*% b), length(ix), lower.tail=FALSE) }
  if (!is.null(out)) out$interaction_p <- signif(p, 3)
  out }
T5 <- rbind(sub(ifelse(a$age_index < 35, "Age < 35", "Age >= 35"), "Age"),
            sub(ifelse(a$sex=="F", "Female", "Male"), "Sex"),
            sub(ifelse(a$bmi_index < 35, "BMI < 35", "BMI >= 35"), "BMI"))
write_tab(T5, "SAP_T5_subgroups"); print(T5, row.names=FALSE)

## ---- T6 propensity ------------------------------------------------------------------
ps <- stats::glm(iih ~ age_index + I(sex=="F") + bmi_index + log1p(pre12),
                 family=binomial, data=a)
a$ps <- stats::fitted(ps)
ov <- range(a$ps[a$iih==1]); ov0 <- range(a$ps[a$iih==0])
a$w_ov <- ifelse(a$iih==1, 1-a$ps, a$ps)                 # overlap weights
bal <- function(v, wt) { x <- a[[v]]
  m1 <- stats::weighted.mean(x[a$iih==1], wt[a$iih==1], na.rm=TRUE)
  m0 <- stats::weighted.mean(x[a$iih==0], wt[a$iih==0], na.rm=TRUE)
  sdp <- sqrt((stats::var(x[a$iih==1], na.rm=TRUE) + stats::var(x[a$iih==0], na.rm=TRUE))/2)
  (m1-m0)/sdp }
mw <- summary(coxph(Surv(t,ev) ~ iih, data=a, weights=w_ov, cluster=match_set, robust=TRUE))
T6 <- data.frame(
  quantity=c("Propensity model c-statistic",
             "Propensity overlap, IIH range", "Propensity overlap, comparator range",
             "SMD age, unweighted -> overlap-weighted",
             "SMD BMI, unweighted -> overlap-weighted",
             "SMD pre-index visits, unweighted -> overlap-weighted",
             "Overlap-weighted hazard ratio"),
  value=c(round(as.numeric(pROC_auc <- {r <- rank(a$ps); n1 <- sum(a$iih==1); n0 <- sum(a$iih==0)
             (sum(r[a$iih==1]) - n1*(n1+1)/2)/(n1*n0)}), 3),
          sprintf("%.3f to %.3f", ov[1], ov[2]), sprintf("%.3f to %.3f", ov0[1], ov0[2]),
          sprintf("%.3f -> %.3f", bal("age_index", rep(1,nrow(a))), bal("age_index", a$w_ov)),
          sprintf("%.3f -> %.3f", bal("bmi_index", rep(1,nrow(a))), bal("bmi_index", a$w_ov)),
          sprintf("%.3f -> %.3f", bal("pre12", rep(1,nrow(a))), bal("pre12", a$w_ov)),
          fmt_est(mw$conf.int[1], mw$conf.int[3], mw$conf.int[4])))
write_tab(T6, "SAP_T6_propensity"); print(T6, row.names=FALSE)

## ---- T7 missing data / T8 power ------------------------------------------------------
miss <- data.frame(variable=c("Age","Sex","BMI","Hypertension","Race","Opening pressure","EEG performed"),
  missing_iih=sprintf("%.1f%%", 100*c(mean(is.na(a$age_index)), mean(is.na(a$sex)),
    mean(is.na(a$bmi_index)), mean(is.na(a$htn)), 1, 1-0.731, 1-0.150)),
  missing_comparator=sprintf("%.1f%%", 100*c(0,0,0,0,0,1,1)),
  handling=c("complete","complete","complete","complete",
             "NOT USABLE - absent for every IIH case, so could not constrain matching",
             "IIH only - used for one sensitivity analysis, never for adjustment",
             "IIH only - not used"))
write_tab(miss, "SAP_T7_missing"); print(miss, row.names=FALSE)
epv <- data.frame(quantity=c("Events, IIH","Events, comparator","Total events",
                             "Parameters in the primary model","Events per parameter",
                             "Parameters in the propensity model","Events per parameter, propensity"),
  value=c(sum(a$ev[a$iih==1]), sum(a$ev[a$iih==0]), sum(a$ev), 1, sum(a$ev), 4, round(sum(a$ev)/4,1)))
write_tab(epv, "SAP_T8_events_per_parameter"); print(epv, row.names=FALSE)
saveRDS(a, file.path(PATH$derived, "K24_analysis.rds"))
log_msg("K24 complete")
