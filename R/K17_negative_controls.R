## K17_negative_controls.R ----------------------------------------------------
## Negative-control panel, recomputed on the REBUILT matched cohort.
##
## The published panel was computed on the old matching, in which comparators
## were matched on their own index dates and then deleted if unengaged. Every
## quantity in it -- baseline prevalence, post-index hazard, person-time -- is
## therefore anchored differently from the current analysis and cannot be
## compared with it. The panel is rebuilt here on the K15 visits cohort, with
## each comparator on its inherited index date.
##
## For each candidate outcome, on the same clock and washout as the primary:
##   baseline prevalence  the code recorded on or before day 180, per arm
##   baseline ratio       IIH prevalence / comparator prevalence
##   post-index hazard    first code after day 180, Cox clustered on match set
##
## THE LOGIC. A negative control has no plausible causal link to IIH, so any
## apparent post-index excess measures detection rather than disease. If the
## apparent excess is a function of baseline imbalance, the fitted line predicts
## what a purely detection-driven hazard ratio looks like at perfect baseline
## balance. The seizure outcome can then be read against that prediction.
##
## A control is only informative if its baseline prevalence is balanced; one
## already commoner in IIH before index tells us nothing about detection, since
## the imbalance may be causal. That criterion is reported per outcome.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K17 negative controls on the rebuilt cohort ===")
V <- readRDS(file.path(PATH$derived, "K15_final_visits.rds"))
a <- V$a; W <- 180; TAU <- 3
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds"))

NC <- list(
  "Herpes zoster"      = list(f="NC_dx_21.csv",             pat="^05[23]\\.|^B02"),
  "Renal/ureteric stone"= list(f="NC_dx_58.csv",            pat="^59[24]\\.|^N20|^N23"),
  "Gallstones"         = list(f="NC_dx_59.csv",             pat="^57[45]\\.|^K80|^K81"),
  "Acute appendicitis" = list(f="NC_dx_60.csv",             pat="^54[01]|^K35|^K37"),
  "Limb fracture"      = list(f="NC_dx_61.csv",             pat="^8[0-2][0-9]|^S[45678][0-9]"),
  "Carpal tunnel"      = list(f="MDE_Diagnosis_carpal_12.csv", pat="^354\\.0|^G56\\.0"))

rows <- list()
for (nm in names(NC)) {
  x <- utils::read.csv(file.path("data-raw", NC[[nm]]$f), colClasses="character")
  names(x)[c(1,3,5)] <- c("mrn","code","date")
  x <- data.frame(mrn=trimws(x$mrn), code=x$code, date=as.Date(substr(x$date,1,10)))
  x <- x[grepl(NC[[nm]]$pat, x$code) & !is.na(x$date), ]
  ## day offsets on the INHERITED index date, not the patient's own
  x$day <- as.numeric(x$date - a$index_date[match(x$mrn, a$mrn)])
  x <- x[!is.na(x$day), ]
  pre  <- unique(x$mrn[x$day <= W])
  post <- tapply(x$day[x$day > W], x$mrn[x$day > W], min)
  b <- vapply(c(1,0), function(g) 100*mean(a$mrn[a$iih==g] %in% pre), numeric(1))
  s <- a[!(a$mrn %in% pre), ]
  dd <- as.numeric(post[s$mrn])
  s$ev2 <- as.integer(!is.na(dd) & dd <= s$open + 1e-6)
  s$t2  <- (ifelse(s$ev2==1, dd, s$open) - W)/365.25
  s <- s[s$t2 > 0, ]
  n1 <- sum(s$ev2[s$iih==1]); n0 <- sum(s$ev2[s$iih==0])
  hr <- c(NA,NA,NA)
  if (n1 >= 3 && n0 >= 3) { m <- coxph(Surv(t2,ev2) ~ iih, data=s, cluster=match_set)
    ss <- summary(m); if (abs(ss$coef[1,1]) <= 5) hr <- ss$conf.int[c(1,3,4)] }
  pv <- if (b[2] > 0) stats::fisher.test(matrix(c(
          sum(a$mrn[a$iih==1] %in% pre), sum(a$iih==1)-sum(a$mrn[a$iih==1] %in% pre),
          sum(a$mrn[a$iih==0] %in% pre), sum(a$iih==0)-sum(a$mrn[a$iih==0] %in% pre)), 2))$p.value else NA
  rows[[nm]] <- data.frame(outcome=nm, baseline_iih_pct=round(b[1],2), baseline_ctl_pct=round(b[2],2),
    baseline_ratio=round(b[1]/b[2],2), baseline_p=signif(pv,3),
    balanced=ifelse(!is.na(pv) & pv >= .05, "PASS", "FAIL"),
    events_iih=n1, events_ctl=n0,
    hr=hr[1], lo=hr[2], hi=hr[3],
    estimate=if (is.na(hr[1])) "not estimable" else fmt_est(hr[1], hr[2], hr[3]))
}
P <- do.call(rbind, rows)
write_tab(P, "K_T42_negative_controls"); print(P[,c("outcome","baseline_iih_pct","baseline_ctl_pct",
  "baseline_ratio","balanced","events_iih","events_ctl","estimate")], row.names=FALSE)

## ---- calibration line ---------------------------------------------------------
fitP <- P[!is.na(P$hr) & is.finite(P$baseline_ratio) & P$baseline_ratio > 0, ]
ct <- stats::cor.test(log(fitP$baseline_ratio), log(fitP$hr))
fit <- stats::lm(log(hr) ~ log(baseline_ratio), data=fitP)
pr1 <- stats::predict(fit, data.frame(baseline_ratio=1), interval="prediction")
sz  <- read.csv(file.path(PATH$tables,"K_T38_FINAL_results_visits.csv"))[1, ]
trend <- data.frame(quantity=c("outcomes in the fit","correlation of log ratio with log HR",
    "slope","predicted detection-only HR at baseline balance","observed seizure HR"),
  value=c(nrow(fitP),
    sprintf("r = %.3f (p = %.4f)", unname(ct$estimate), ct$p.value),
    sprintf("%.2f (SE %.2f)", coef(fit)[2], summary(fit)$coefficients[2,2]),
    sprintf("%.2f (%.2f to %.2f)", exp(pr1[1]), exp(pr1[2]), exp(pr1[3])),
    sz$HR))
write_tab(trend, "K_T43_calibration"); print(trend, row.names=FALSE)
saveRDS(list(P=P, fit=fit, ct=ct, pr1=pr1), file.path(PATH$derived,"K17_nc.rds"))
log_msg("K17 complete")
