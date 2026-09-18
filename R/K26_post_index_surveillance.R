## K26_post_index_surveillance.R ----------------------------------------------
## Post-index surveillance: encounters, care settings, and the eleven negative
## outcomes, all as rates per person-year with exact Poisson intervals.
##
## WHAT IS AVAILABLE AND WHAT IS NOT, established by inspection rather than
## assumed:
##
##   available   total clinical visits; emergency encounters; hospital and
##               inpatient encounters; procedural and diagnostic encounters;
##               laboratory encounters. All carry an Encounter Type in both
##               arms, so all are comparable.
##
##   NOT available, and reported as such rather than approximated:
##     neurology visits   No encounter type names a specialty. Of 171 types,
##                        none is "Neurology". Specialty is simply not in the
##                        extract, so neurology contact cannot be counted in
##                        either arm.
##     imaging            An encounter type "Radiology" exists but carries 386
##                        case rows against 12 comparator rows -- far too few
##                        to be a record of imaging studies, and a 32-fold gap
##                        that reflects coding practice rather than scans. The
##                        radiology extract itself covers comparators only
##                        (1,234 patients, zero IIH). Neither can support a
##                        between-arm imaging rate.
##     EEG                Recorded for 393 IIH patients and zero comparators.
##                        A rate ratio cannot be formed from that.
##
## These three are exactly the measures a reader most wants for a detection-bias
## argument, and their absence is a real limitation of the study, not a
## presentational choice.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K26 post-index surveillance ===")
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
  z[!grepl(ADMIN, z$type), ] }
EN <- unique(rbind(rd("data-raw/MDE_Encounters_types_full.csv", 3, 2),
                   rd("data-raw/MDE_Encounters_controls_typed.csv", 5, 6)))
EN <- EN[EN$mrn %in% a$mrn, ]
EN$rel <- as.numeric(EN$d - a$index_date[match(EN$mrn, a$mrn)])
EN$iih <- a$iih[match(EN$mrn, a$mrn)]
EN <- EN[EN$rel > W & EN$rel <= W + TAU*365.25, ]          # post-index window only
py <- tapply(a$t, a$iih, sum)

cnt_rate <- function(sel, lab) {
  n1 <- sum(sel & EN$iih==1); n0 <- sum(sel & EN$iih==0)
  c1 <- stats::poisson.test(n1, py[["1"]])$conf.int; c0 <- stats::poisson.test(n0, py[["0"]])$conf.int
  rr <- (n1/py[["1"]])/(n0/py[["0"]])
  z  <- sqrt(1/n1 + 1/n0)
  data.frame(measure=lab, IIH_n=n1, Comparator_n=n0,
    IIH_rate=sprintf("%.2f (%.2f to %.2f)", n1/py[["1"]], c1[1], c1[2]),
    Comparator_rate=sprintf("%.2f (%.2f to %.2f)", n0/py[["0"]], c0[1], c0[2]),
    rate_ratio=sprintf("%.2f (%.2f to %.2f)", rr, rr*exp(-1.96*z), rr*exp(1.96*z))) }
S <- rbind(
  cnt_rate(rep(TRUE, nrow(EN)),                         "All clinical visits"),
  cnt_rate(grepl("^Emergency", EN$type),                "Emergency encounters"),
  cnt_rate(grepl("^(Inpatient|Hospital Encounter|Observation|OP in a bed)", EN$type),
                                                         "Hospital or inpatient encounters"),
  cnt_rate(grepl("^(Office Visit|Clinic|Clinic Outpatient|Appointment|Comprehensive Visit|Primary Care)$", EN$type),
                                                         "Office or clinic visits"),
  cnt_rate(grepl("^(Procedure Pass|Procedure visit|Ancillary Procedure|Diagnostic|Surgery|Anesthesia)", EN$type),
                                                         "Procedural or diagnostic encounters"),
  cnt_rate(grepl("^Lab", EN$type),                       "Laboratory encounters"))
S$note <- ""
NA_ROWS <- data.frame(measure=c("Neurology visits","Ophthalmology visits","Brain MRI or CT","EEG"),
  IIH_n=NA, Comparator_n=NA, IIH_rate="not available", Comparator_rate="not available",
  rate_ratio="not estimable",
  note=c("no encounter type names a specialty; none of the 171 types is Neurology",
         "same; the Historic Ophthalmology types are imported records, not visits",
         "radiology extract covers comparators only (1,234 patients, 0 IIH); the Radiology encounter type has 386 case against 12 comparator rows and cannot be a record of scans",
         "recorded for 393 IIH patients and 0 comparators"))
S <- rbind(S, NA_ROWS)
write_tab(S, "K_T54_post_index_surveillance")
print(S[, c("measure","IIH_rate","Comparator_rate","rate_ratio")], row.names=FALSE)

## ---- the eleven negative outcomes, as incidence rates -------------------------
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
inc <- function(nm, spec) {
  x <- utils::read.csv(file.path("data-raw", spec$f), colClasses="character")
  hn <- tolower(names(x)); names(x)[grep("clinic", hn)[1]] <- "mrn"
  names(x)[grep("code$", hn)[1]] <- "code"; names(x)[grep("date", hn)[1]] <- "date"
  x$mrn <- trimws(x$mrn)
  x$day <- as.numeric(as.Date(substr(x$date,1,10)) - a$index_date[match(x$mrn, a$mrn)])
  x <- x[!is.na(x$day) & grepl(spec$pat, x$code), ]
  pr <- unique(x$mrn[x$day <= W]); po <- tapply(x$day[x$day > W], x$mrn[x$day > W], min)
  s <- a[!(a$mrn %in% pr), ]; dd <- as.numeric(po[s$mrn])
  s$ev <- as.integer(!is.na(dd) & dd <= s$open + 1e-6)
  s$t  <- (ifelse(s$ev==1, dd, s$open) - W)/365.25; s <- s[s$t > 0, ]
  r <- function(g){ x2 <- s[s$iih==g, ]; e <- sum(x2$ev); p <- sum(x2$t)
    ci <- stats::poisson.test(e, p)$conf.int
    list(e=e, p=p, txt=sprintf("%.2f (%.2f to %.2f)", 1000*e/p, 1000*ci[1], 1000*ci[2])) }
  A <- r(1); B <- r(0); rr <- (A$e/A$p)/(B$e/B$p); z <- sqrt(1/A$e + 1/B$e)
  data.frame(outcome=nm, iih_events=A$e, ctl_events=B$e,
    IIH_per1000py=A$txt, Comparator_per1000py=B$txt,
    rate_ratio=sprintf("%.2f (%.2f to %.2f)", rr, rr*exp(-1.96*z), rr*exp(1.96*z))) }
NC <- do.call(rbind, Map(inc, names(GRP), GRP))
sz <- local({ e1 <- sum(a$ev[a$iih==1]); p1 <- sum(a$t[a$iih==1])
  e0 <- sum(a$ev[a$iih==0]); p0 <- sum(a$t[a$iih==0])
  c1 <- stats::poisson.test(e1,p1)$conf.int; c0 <- stats::poisson.test(e0,p0)$conf.int
  rr <- (e1/p1)/(e0/p0); z <- sqrt(1/e1 + 1/e0)
  data.frame(outcome="SEIZURE OR EPILEPSY (primary outcome)", iih_events=e1, ctl_events=e0,
    IIH_per1000py=sprintf("%.2f (%.2f to %.2f)", 1000*e1/p1, 1000*c1[1], 1000*c1[2]),
    Comparator_per1000py=sprintf("%.2f (%.2f to %.2f)", 1000*e0/p0, 1000*c0[1], 1000*c0[2]),
    rate_ratio=sprintf("%.2f (%.2f to %.2f)", rr, rr*exp(-1.96*z), rr*exp(1.96*z))) })
NC <- rbind(sz, NC[order(-as.numeric(sub(" .*","",NC$rate_ratio))), ])
write_tab(NC, "K_T55_negative_outcome_rates"); print(NC, row.names=FALSE)
log_msg("K26 complete")
