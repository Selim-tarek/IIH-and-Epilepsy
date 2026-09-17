## K23_post_index_collider.R --------------------------------------------------
## Why post-index visits must NOT be adjusted for.
##
## The natural instinct is to adjust for how often a patient was seen DURING
## follow-up, since that is when the outcome is detected. It is the one
## adjustment that cannot be made, and this script shows why rather than
## asserting it.
##
## Post-index visit count is a CONSEQUENCE of the outcome. A seizure brings a
## patient into hospital, generates neurology follow-up, imaging, EEG and
## medication review. In these data patients with an event have 40 post-index
## visits against 17 without one in the IIH arm, and 9 against 3 among
## comparators. Conditioning on it is conditioning on a descendant of the
## outcome -- a collider -- which induces bias of unpredictable direction and
## magnitude.
##
## The demonstration that settles it is the negative control. Adjusting for
## post-index visits makes IIH appear PROTECTIVE against fracture, hazard ratio
## 0.39 (0.23 to 0.67). Nothing about idiopathic intracranial hypertension
## protects anyone from breaking a bone. An adjustment that produces that result
## is invalid, and the same adjustment applied to the seizure outcome is
## therefore equally uninformative -- it is not evidence that the seizure
## association is spurious.
##
## Pre-index measures do not have this problem: they are fixed before the
## outcome can occur, so nothing about the outcome can influence them.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K23 post-index adjustment is a collider ===")
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
gv <- function(v){ z <- as.numeric(v[a$mrn]); z[is.na(z)] <- 0; z }
a$pre12 <- gv(tapply(EN$rel >= -365 & EN$rel < 0, EN$mrn, sum))
a$post  <- gv(tapply(EN$rel > W & EN$rel <= W + TAU*365.25, EN$mrn, sum))

ev <- do.call(rbind, lapply(c(1,0), function(g){ s <- a[a$iih==g, ]
  data.frame(arm=ifelse(g==1,"IIH","Comparator"),
             median_visits_no_event=stats::median(s$post[s$ev==0]),
             median_visits_with_event=stats::median(s$post[s$ev==1])) }))
write_tab(ev, "K_T51_visits_by_event"); print(ev, row.names=FALSE)

hr <- function(s, fo) { m <- coxph(as.formula(fo), data=s, cluster=match_set); z <- summary(m)
  sprintf("%.2f (%.2f to %.2f)", z$conf.int[1,1], z$conf.int[1,3], z$conf.int[1,4]) }
mkset <- function(f, pat) {
  x <- utils::read.csv(file.path("data-raw", f), colClasses="character")
  hn <- tolower(names(x)); names(x)[grep("clinic", hn)[1]] <- "mrn"
  names(x)[grep("code$", hn)[1]] <- "code"; names(x)[grep("date", hn)[1]] <- "date"
  x$mrn <- trimws(x$mrn)
  x$day <- as.numeric(as.Date(substr(x$date,1,10)) - a$index_date[match(x$mrn, a$mrn)])
  x <- x[!is.na(x$day) & grepl(pat, x$code), ]
  pr <- unique(x$mrn[x$day <= W]); po <- tapply(x$day[x$day > W], x$mrn[x$day > W], min)
  s <- a[!(a$mrn %in% pr), ]; dd <- as.numeric(po[s$mrn])
  s$ev <- as.integer(!is.na(dd) & dd <= s$open + 1e-6)
  s$t  <- (ifelse(s$ev==1, dd, s$open) - W)/365.25; s[s$t > 0, ] }
SET <- list("SEIZURE OR EPILEPSY" = a,
            "Fracture (negative control)" = mkset("NC2_dx_20.csv", "^S[1-9]2|^8(0[5-9]|1[0-9]|2[0-9])"),
            "Upper respiratory infection (negative control)" =
              mkset("NC2_dx_13.csv", "^J0[0-6]|^J09|^J1[01]|^J2[01]|^46[0-6]|^487|^488"))
res <- do.call(rbind, lapply(names(SET), function(nm){ s <- SET[[nm]]
  data.frame(outcome=nm,
    unadjusted=hr(s, "Surv(t,ev) ~ iih"),
    adj_pre_index=hr(s, "Surv(t,ev) ~ iih + log1p(pre12)"),
    adj_post_index_COLLIDER=hr(s, "Surv(t,ev) ~ iih + log1p(post)")) }))
write_tab(res, "K_T52_collider_demonstration"); print(res, row.names=FALSE)
log_msg("K23 complete")
