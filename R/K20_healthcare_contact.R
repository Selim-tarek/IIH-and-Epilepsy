## K20_healthcare_contact.R ---------------------------------------------------
## Does the seizure association behave like a detection artefact?
##
## THE PROBLEM. Every negative control examined is more prevalent in the IIH arm
## before index, by ratios of 1.6 to 5.0. The mechanism is visible directly:
## after matching, patients with IIH attend 34.3 clinical visits per patient over
## three years against 9.3 for comparators, and 13.3 against 5.9 in the year
## before index. Anything that requires a visit to be recorded will be inflated
## in the IIH arm regardless of biology.
##
## TWO TESTS THAT CAN DISCRIMINATE.
##
## 1. CALIBRATION. Across eleven negative controls the apparent post-index
##    hazard ratio scales with baseline imbalance (r = 0.66, p = 0.026, slope
##    0.84). Extrapolating to perfect baseline balance predicts what a purely
##    detection-driven hazard ratio looks like, and the seizure estimate can be
##    read against that.
##
## 2. ADJUSTMENT FOR HEALTHCARE-SEEKING. Pre-index visit count is a proxy for
##    healthcare-seeking behaviour that is NOT caused by the outcome, so it can
##    be adjusted for without collider bias. Post-index visits cannot: a seizure
##    causes visits, so conditioning on them would be conditioning on a
##    consequence of the exposure.
##
##    If an association is detection-driven it should shrink toward the null when
##    healthcare-seeking is adjusted for. If it is real it should not.
##
## This script applies both to every negative control and to the seizure
## outcome, on identical terms.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K20 healthcare contact ===")
V <- readRDS(file.path(PATH$derived, "K15_final_visits.rds")); a <- V$a
W <- 180; TAU <- 3

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
  z[!grepl(ADMIN, z$type), c("mrn","d")] }
EN <- unique(rbind(rd("data-raw/MDE_Encounters_types_full.csv", 3, 2),
                   rd("data-raw/MDE_Encounters_controls_typed.csv", 5, 6)))
EN <- EN[EN$mrn %in% a$mrn, ]
EN$rel <- as.numeric(EN$d - a$index_date[match(EN$mrn, a$mrn)])
pre <- tapply(EN$rel >= -365 & EN$rel < 0, EN$mrn, sum)
a$pre12 <- as.numeric(pre[a$mrn]); a$pre12[is.na(a$pre12)] <- 0
dens <- data.frame(arm=c("IIH","Comparator"),
  visits_pre12_per_patient=round(c(sum(EN$rel>=-365 & EN$rel<0 & EN$mrn %in% a$mrn[a$iih==1]),
                                   sum(EN$rel>=-365 & EN$rel<0 & EN$mrn %in% a$mrn[a$iih==0]))/
                                 c(sum(a$iih==1), sum(a$iih==0)), 1),
  visits_post_per_patient=round(c(sum(EN$rel>W & EN$rel<=W+TAU*365.25 & EN$mrn %in% a$mrn[a$iih==1]),
                                  sum(EN$rel>W & EN$rel<=W+TAU*365.25 & EN$mrn %in% a$mrn[a$iih==0]))/
                                c(sum(a$iih==1), sum(a$iih==0)), 1))
write_tab(dens, "K_T46_visit_density"); print(dens, row.names=FALSE)

## ---- outcome builders ----------------------------------------------------------
GRP <- list(
 "Upper respiratory infection"=list(f="NC2_dx_13.csv", pat="^J0[0-6]|^J09|^J1[01]|^J2[01]|^46[0-6]|^487|^488"),
 "Otitis media or externa"    =list(f="NC2_dx_14.csv", pat="^H6[0567]|^380\\.1|^38[12]"),
 "Sprain or strain"           =list(f="NC2_dx_16.csv", pat="^S[1-9]3|^84[0-8]"),
 "Laceration or open wound"   =list(f="NC2_dx_17.csv", pat="^S[4-9]1|^88[0-4]|^89[0-4]"),
 "Contact dermatitis"         =list(f="NC2_dx_18.csv", pat="^L2[345]|^692"),
 "Fracture, excl. skull/face" =list(f="NC2_dx_20.csv", pat="^S[1-9]2|^8(0[5-9]|1[0-9]|2[0-9])"),
 "Herpes zoster"              =list(f="NC_dx_21.csv",  pat="^05[23]\\.|^B02"),
 "Renal/ureteric stone"       =list(f="NC_dx_58.csv",  pat="^59[24]\\.|^N20|^N23"),
 "Gallstones"                 =list(f="NC_dx_59.csv",  pat="^57[45]\\.|^K80|^K81"),
 "Acute appendicitis"         =list(f="NC_dx_60.csv",  pat="^54[01]|^K35|^K37"),
 "Carpal tunnel"              =list(f="MDE_Diagnosis_carpal_12.csv", pat="^354\\.0|^G56\\.0"))

fit_pair <- function(s, lab, ratio) {
  e1 <- sum(s$ev2[s$iih==1]); e0 <- sum(s$ev2[s$iih==0])
  if (e1 < 3 || e0 < 3) return(NULL)
  g <- function(fo){ m <- coxph(as.formula(fo), data=s, cluster=match_set); z <- summary(m)
                     if (abs(z$coef[1,1]) > 5) rep(NA,3) else z$conf.int[1, c(1,3,4)] }
  u <- g("Surv(t2,ev2) ~ iih"); j <- g("Surv(t2,ev2) ~ iih + log1p(pre12)")
  data.frame(outcome=lab, baseline_ratio=ratio, events_iih=e1, events_ctl=e0,
    hr_unadj=u[1], lo_unadj=u[2], hi_unadj=u[3],
    hr_adj=j[1],  lo_adj=j[2],  hi_adj=j[3],
    pct_change=round(100*(j[1]-u[1])/u[1], 1))
}
rows <- list()
for (nm in names(GRP)) {
  x <- utils::read.csv(file.path("data-raw", GRP[[nm]]$f), colClasses="character")
  hn <- tolower(names(x))
  names(x)[grep("clinic", hn)[1]] <- "mrn"
  names(x)[grep("code$", hn)[1]]  <- "code"
  names(x)[grep("date", hn)[1]]   <- "date"
  x$mrn <- trimws(x$mrn)
  x$day <- as.numeric(as.Date(substr(x$date,1,10)) - a$index_date[match(x$mrn, a$mrn)])
  x <- x[!is.na(x$day) & grepl(GRP[[nm]]$pat, x$code), ]
  pr <- unique(x$mrn[x$day <= W])
  k1 <- sum(a$mrn[a$iih==1] %in% pr)/sum(a$iih==1); k0 <- sum(a$mrn[a$iih==0] %in% pr)/sum(a$iih==0)
  po <- tapply(x$day[x$day > W], x$mrn[x$day > W], min)
  s <- a[!(a$mrn %in% pr), ]; dd <- as.numeric(po[s$mrn])
  s$ev2 <- as.integer(!is.na(dd) & dd <= s$open + 1e-6)
  s$t2  <- (ifelse(s$ev2==1, dd, s$open) - W)/365.25; s <- s[s$t2 > 0, ]
  rows[[nm]] <- fit_pair(s, nm, if (k0 > 0) round(k1/k0, 2) else NA)
}
## the seizure outcome itself, on identical terms
sz <- a; sz$ev2 <- sz$ev; sz$t2 <- sz$t
SZ <- fit_pair(sz, "SEIZURE OR EPILEPSY", NA)

NCP <- do.call(rbind, rows)
out <- rbind(NCP, SZ)
out$unadjusted <- fmt_est(out$hr_unadj, out$lo_unadj, out$hi_unadj)
out$adjusted   <- fmt_est(out$hr_adj,  out$lo_adj,  out$hi_adj)
write_tab(out, "K_T47_contact_adjustment")
print(out[, c("outcome","baseline_ratio","events_iih","events_ctl","unadjusted","adjusted","pct_change")],
      row.names=FALSE)

## ---- calibration on the unadjusted controls -----------------------------------
f <- lm(log(hr_unadj) ~ log(baseline_ratio), data=NCP[!is.na(NCP$baseline_ratio), ])
ct <- cor.test(log(NCP$baseline_ratio), log(NCP$hr_unadj))
pr1 <- stats::predict(f, data.frame(baseline_ratio=1), interval="prediction")
cal <- data.frame(quantity=c("negative controls in the fit",
  "correlation, log baseline ratio with log HR", "slope",
  "predicted detection-only HR at baseline balance",
  "observed seizure HR, unadjusted", "observed seizure HR, contact-adjusted",
  "median change in negative-control HR on adjustment",
  "change in seizure HR on adjustment"),
  value=c(sum(!is.na(NCP$baseline_ratio)),
    sprintf("r = %.3f (p = %.4f)", unname(ct$estimate), ct$p.value),
    sprintf("%.2f (SE %.2f)", coef(f)[2], summary(f)$coefficients[2,2]),
    sprintf("%.2f (%.2f to %.2f)", exp(pr1[1]), exp(pr1[2]), exp(pr1[3])),
    SZ$hr_unadj |> round(2), SZ$hr_adj |> round(2),
    sprintf("%+.1f%%", stats::median(NCP$pct_change, na.rm=TRUE)),
    sprintf("%+.1f%%", SZ$pct_change)))
write_tab(cal, "K_T48_calibration_v2"); print(cal, row.names=FALSE)
saveRDS(list(out=out, NCP=NCP, SZ=SZ, fit=f, ct=ct, pr1=pr1),
        file.path(PATH$derived, "K20_contact.rds"))
log_msg("K20 complete")
