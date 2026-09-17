## K22_contact_robustness.R ---------------------------------------------------
## Is the discriminating result robust to how healthcare-seeking is measured?
##
## K20 showed that adjusting for the pre-index 12-month visit count moved all
## eleven negative controls toward the null while the seizure association moved
## away from it. That rests on ONE proxy. If the direction is an artefact of
## that particular measure it should not survive alternatives.
##
## Six measures, each computed only from information available BEFORE the index
## date, so none can be a collider on the outcome:
##   visits_12m     visits in the 12 months before index
##   visits_24m     visits in the 24 months before index
##   months_12m     distinct calendar months with a visit, 12 months before
##   visits_all     all visits before index, however far back
##   history_years  years from first recorded visit to index
##   office_12m     visits in the 12 months before index restricted to
##                  office, clinic and appointment types -- the closest thing
##                  available to routine primary care, and the measure least
##                  contaminated by specialist referral for IIH itself
##
## Each is applied identically to the seizure outcome and to all eleven negative
## controls. The question is not whether the seizure hazard ratio changes, but
## whether it moves in the SAME direction as the controls.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K22 robustness of the contact adjustment ===")
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
OFFICE <- "^(Office Visit|Clinic|Clinic Outpatient|Appointment|Comprehensive Visit|Primary Care)$"
rd <- function(p, dc, tc){ x <- utils::read.csv(p, colClasses="character")
  z <- data.frame(mrn=trimws(x[[1]]), d=as.Date(substr(x[[dc]],1,10)), type=trimws(x[[tc]]))
  z[!grepl(ADMIN, z$type), ] }
EN <- unique(rbind(rd("data-raw/MDE_Encounters_types_full.csv", 3, 2),
                   rd("data-raw/MDE_Encounters_controls_typed.csv", 5, 6)))
EN <- EN[EN$mrn %in% a$mrn, ]
EN$rel <- as.numeric(EN$d - a$index_date[match(EN$mrn, a$mrn)])
EN$ym  <- format(EN$d, "%Y-%m")
g <- function(v) { z <- as.numeric(v[a$mrn]); z[is.na(z)] <- 0; z }
a$visits_12m <- g(tapply(EN$rel >= -365 & EN$rel < 0, EN$mrn, sum))
a$visits_24m <- g(tapply(EN$rel >= -730 & EN$rel < 0, EN$mrn, sum))
a$visits_all <- g(tapply(EN$rel < 0, EN$mrn, sum))
sub <- EN[EN$rel >= -365 & EN$rel < 0, ]
a$months_12m <- g(tapply(sub$ym, sub$mrn, function(z) length(unique(z))))
a$history_years <- g(tapply(EN$rel, EN$mrn, function(z) -min(z)))/365.25
off <- EN[grepl(OFFICE, EN$type) & EN$rel >= -365 & EN$rel < 0, ]
a$office_12m <- g(tapply(rep(TRUE, nrow(off)), off$mrn, sum))
MEAS <- c("visits_12m","visits_24m","months_12m","visits_all","history_years","office_12m")
smry <- do.call(rbind, lapply(MEAS, function(m) data.frame(measure=m,
  iih_median=stats::median(a[[m]][a$iih==1]), ctl_median=stats::median(a[[m]][a$iih==0])))) 
write_tab(smry, "K_T49_contact_measures"); print(smry, row.names=FALSE)

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

build <- function(spec) {
  x <- utils::read.csv(file.path("data-raw", spec$f), colClasses="character")
  hn <- tolower(names(x))
  names(x)[grep("clinic", hn)[1]] <- "mrn"
  names(x)[grep("code$", hn)[1]]  <- "code"
  names(x)[grep("date", hn)[1]]   <- "date"
  x$mrn <- trimws(x$mrn)
  x$day <- as.numeric(as.Date(substr(x$date,1,10)) - a$index_date[match(x$mrn, a$mrn)])
  x <- x[!is.na(x$day) & grepl(spec$pat, x$code), ]
  pr <- unique(x$mrn[x$day <= W]); po <- tapply(x$day[x$day > W], x$mrn[x$day > W], min)
  s <- a[!(a$mrn %in% pr), ]; dd <- as.numeric(po[s$mrn])
  s$ev2 <- as.integer(!is.na(dd) & dd <= s$open + 1e-6)
  s$t2  <- (ifelse(s$ev2==1, dd, s$open) - W)/365.25
  s[s$t2 > 0, ]
}
SETS <- lapply(GRP, build)
sz <- a; sz$ev2 <- sz$ev; sz$t2 <- sz$t
SETS[["SEIZURE OR EPILEPSY"]] <- sz

hrof <- function(s, adj) {
  if (sum(s$ev2[s$iih==1]) < 3 || sum(s$ev2[s$iih==0]) < 3) return(NA_real_)
  fo <- if (is.null(adj)) "Surv(t2,ev2) ~ iih" else sprintf("Surv(t2,ev2) ~ iih + log1p(%s)", adj)
  z <- summary(coxph(as.formula(fo), data=s, cluster=match_set))
  if (abs(z$coef[1,1]) > 5) NA_real_ else z$conf.int[1,1]
}
base <- vapply(SETS, hrof, numeric(1), adj=NULL)
R <- do.call(rbind, lapply(MEAS, function(m) {
  adj <- vapply(SETS, hrof, numeric(1), adj=m)
  ch  <- 100*(adj - base)/base
  nc  <- ch[names(ch) != "SEIZURE OR EPILEPSY"]
  data.frame(measure=m,
    controls_median_change=sprintf("%+.1f%%", stats::median(nc, na.rm=TRUE)),
    controls_range=sprintf("%+.0f%% to %+.0f%%", min(nc, na.rm=TRUE), max(nc, na.rm=TRUE)),
    controls_moving_up=sum(nc > 0, na.rm=TRUE),
    seizure_hr=round(adj[["SEIZURE OR EPILEPSY"]], 2),
    seizure_change=sprintf("%+.1f%%", ch[["SEIZURE OR EPILEPSY"]]),
    seizure_direction=ifelse(ch[["SEIZURE OR EPILEPSY"]] > 0, "AWAY from null", "toward null")) }))
R <- rbind(data.frame(measure="(unadjusted)", controls_median_change="-", controls_range="-",
             controls_moving_up=NA, seizure_hr=round(base[["SEIZURE OR EPILEPSY"]],2),
             seizure_change="-", seizure_direction="-"), R)
write_tab(R, "K_T50_contact_robustness"); print(R, row.names=FALSE)
log_msg("K22 complete")
