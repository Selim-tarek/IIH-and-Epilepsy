## J2_outcome_definition_sensitivity.R ----------------------------------------
## Why this exists.
##
## Building the epilepsy phenotype (J1) required assembling seizure codes from
## the diagnosis and conditions extracts. Doing so made it possible, for the
## first time, to ascertain the seizure outcome IDENTICALLY in both arms from a
## single source. That is a check the pipeline had never run: the primary
## outcome comes from the abstracted master workbook, and until now nothing
## tested whether the workbook's rule had been applied symmetrically.
##
## It has not been. Evidence, all on the primary's own clock and washout:
##
##   - The workbook outcome is code-derived in BOTH arms: the primary event date
##     equals the first post-washout qualifying code date exactly in 88% of IIH
##     events and 80% of control events.
##   - Among IIH, having a post-washout qualifying code and being a primary
##     event are the same set. 118 primary-negative IIH patients appear in the
##     extract, and between them they carry SIX qualifying code rows, all in the
##     washout. Their codes are F44.5 psychogenic (166 rows), G43.10 migraine
##     (67), Z82.0 family history of epilepsy (49) -- the differential, not the
##     outcome.
##   - Among controls, 194 primary-negative patients carry qualifying codes
##     INSIDE the primary's own clock. This is not explained by the longer
##     phenotype clock used in J1, which accounts for exactly one of them.
##
## So the identical rule that yields 102 events in IIH yields ~258 in controls,
## while the workbook records 64. This script quantifies what that does to the
## headline estimate. It does not assert which ascertainment is correct.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== J2 outcome-definition sensitivity ===")
P <- readRDS(file.path(PATH$derived, "J1_phenotype.rds"))$code
WASHOUT_D <- 180

dx <- utils::read.csv(file.path("data-raw","SZ_dx_62.csv"), colClasses="character")
names(dx) <- c("mrn","s","code","desc","date")
cn <- utils::read.csv(file.path("data-raw","SZ_conditions_10.csv"), colClasses="character")
names(cn) <- c("mrn","s","code","desc","on","rec")
o <- as.Date(substr(cn$on,1,10)); r <- as.Date(substr(cn$rec,1,10))
e <- rbind(data.frame(mrn=trimws(dx$mrn), code=dx$code, desc=dx$desc, date=as.Date(substr(dx$date,1,10))),
           data.frame(mrn=trimws(cn$mrn), code=cn$code, desc=cn$desc,
                      date=as.Date(ifelse(is.na(o), r, o), origin="1970-01-01")))
i <- match(e$mrn, P$mrn); e <- e[!is.na(i), ]; i <- i[!is.na(i)]
e$day <- as.numeric(e$date - P$index_date[i])
exc <- grepl("^F44\\.5|^300\\.11|^R56\\.1|^780\\.33|^780\\.32", e$code) |
       grepl("febrile|non.epileptic|psychogenic|conversion", e$desc, ignore.case=TRUE)
DEF <- list("Any qualifying code (G40/345 + R56.9/780.39)" =
              grepl("^G40|^345|^0345|^R56|^780\\.39|^07703", e$code) & !exc,
            "Epilepsy-specific codes only (G40/345)" =
              grepl("^G40|^345|^0345", e$code) & !exc)

fit <- function(a, tv, ev) {
  if (sum(a[[ev]]) < 5) return(rep(NA_real_, 4))
  m <- coxph(stats::reformulate("iih", sprintf("Surv(%s,%s)", tv, ev)), data=a, cluster=match_set)
  s <- summary(m)
  if (abs(s$coef[1,1]) > 5) return(rep(NA_real_, 4))   # separation guard
  c(s$conf.int[1], s$conf.int[3], s$conf.int[4], s$coef[1,6])
}
rows <- list()
for (eng in c(FALSE, TRUE)) {
  ## the abstracted workbook outcome, for reference
  a <- P[P$fu_seizure_end_day > WASHOUT_D, ]; if (eng) a <- a[a$engaged, ]
  h <- fit(a, "t_y", "event")
  rows[[length(rows)+1]] <- data.frame(
    outcome="Abstracted workbook outcome (primary)", cohort=if (eng) "Engagement-restricted" else "Full",
    iih_events=sum(a$event[a$iih==1]), iih_n=sum(a$iih==1),
    ctl_events=sum(a$event[a$iih==0]), ctl_n=sum(a$iih==0),
    HR=h[1], lo=h[2], hi=h[3], p=h[4])
  for (nm in names(DEF)) {
    q <- e[DEF[[nm]], ]; p <- P
    p$prev <- p$mrn %in% unique(q$mrn[q$day <= WASHOUT_D])
    f <- tapply(q$day[q$day > WASHOUT_D], q$mrn[q$day > WASHOUT_D], min)
    p$cday <- as.numeric(f[p$mrn])
    a <- p[!p$prev & p$fu_seizure_end_day > WASHOUT_D, ]; if (eng) a <- a[a$engaged, ]
    a$ev2 <- as.integer(!is.na(a$cday) & a$cday <= a$fu_seizure_end_day + 1e-6)
    a$t2 <- (ifelse(a$ev2 == 1, a$cday, a$fu_seizure_end_day) - WASHOUT_D)/365.25
    h <- fit(a, "t2", "ev2")
    rows[[length(rows)+1]] <- data.frame(
      outcome=nm, cohort=if (eng) "Engagement-restricted" else "Full",
      iih_events=sum(a$ev2[a$iih==1]), iih_n=sum(a$iih==1),
      ctl_events=sum(a$ev2[a$iih==0]), ctl_n=sum(a$iih==0),
      HR=h[1], lo=h[2], hi=h[3], p=h[4])
  }
}
out <- do.call(rbind, rows)
out$estimate <- fmt_est(out$HR, out$lo, out$hi)
write_tab(out, "J_T05_outcome_definition_sensitivity")
print(out[, c("outcome","cohort","iih_events","ctl_events","estimate","p")], row.names=FALSE)
log_msg("J2 complete")
