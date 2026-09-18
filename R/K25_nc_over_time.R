## K25_nc_over_time.R ---------------------------------------------------------
## Do the negative-control excesses behave like detection effects OVER TIME?
##
## A detection effect driven by the index diagnostic episode should be largest
## soon after index, when the patient is in the system for the work-up, and
## decay as they return to ordinary care. A real biological effect has no
## particular reason to do that.
##
## This splits follow-up into four periods and estimates a separate hazard ratio
## in each, for every negative control and for the seizure outcome, on identical
## terms. Person-time is split with survSplit; each period is stratified so the
## baseline hazard may differ between them, and the interaction with period
## gives the period-specific estimate.
##
## A trend test follows: the hazard ratio is regressed on period midpoint
## (log scale, weighted by inverse variance) to ask whether the apparent effect
## is fading.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K25 negative controls over time ===")
V <- readRDS(file.path(PATH$derived, "K15_final_visits.rds")); a <- V$a
W <- 180; TAU <- 3
CUT <- c(.5, 1, 2); LAB <- c("0-6 mo","6-12 mo","1-2 y","2-3 y"); MID <- c(.25,.75,1.5,2.5)

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
 "Carpal tunnel"              =list(f="MDE_Diagnosis_carpal_12.csv", pat="^354\\.0|^G56\\.0"))

mkset <- function(spec) {
  x <- utils::read.csv(file.path("data-raw", spec$f), colClasses="character")
  hn <- tolower(names(x)); names(x)[grep("clinic", hn)[1]] <- "mrn"
  names(x)[grep("code$", hn)[1]] <- "code"; names(x)[grep("date", hn)[1]] <- "date"
  x$mrn <- trimws(x$mrn)
  x$day <- as.numeric(as.Date(substr(x$date,1,10)) - a$index_date[match(x$mrn, a$mrn)])
  x <- x[!is.na(x$day) & grepl(spec$pat, x$code), ]
  pr <- unique(x$mrn[x$day <= W]); po <- tapply(x$day[x$day > W], x$mrn[x$day > W], min)
  s <- a[!(a$mrn %in% pr), ]; dd <- as.numeric(po[s$mrn])
  s$ev <- as.integer(!is.na(dd) & dd <= s$open + 1e-6)
  s$t  <- (ifelse(s$ev==1, dd, s$open) - W)/365.25; s[s$t > 0, ] }
SETS <- lapply(GRP, mkset); SETS[["SEIZURE OR EPILEPSY"]] <- a

per_hr <- function(s) {
  sp <- survSplit(Surv(t, ev) ~ ., data=s, cut=CUT, episode="per")
  sp$per <- factor(sp$per, labels=LAB[seq_len(length(unique(sp$per)))])
  m <- coxph(Surv(tstart, t, ev) ~ iih:per + strata(per), data=sp, cluster=match_set)
  z <- summary(m); b <- z$conf.int
  ok <- !is.na(b[,1]) & b[,1] > .01 & b[,1] < 100
  data.frame(period=LAB[seq_len(nrow(b))], hr=b[,1], lo=b[,3], hi=b[,4],
             se=z$coefficients[,"robust se"], ok=ok) }

rows <- list()
for (nm in names(SETS)) {
  r <- try(per_hr(SETS[[nm]]), silent=TRUE)
  if (inherits(r, "try-error")) next
  r$outcome <- nm; r$mid <- MID[seq_len(nrow(r))]
  rows[[nm]] <- r
}
P <- do.call(rbind, rows)
tab <- do.call(rbind, lapply(split(P, P$outcome), function(z){
  v <- setNames(round(z$hr, 2), z$period); v[!z$ok] <- NA
  d <- as.data.frame(t(v)); d$outcome <- z$outcome[1]
  ## inverse-variance weighted trend of log HR on period midpoint
  u <- z[z$ok & is.finite(z$se) & z$se > 0, ]
  d$trend_slope_per_year <- if (nrow(u) >= 3)
      round(coef(stats::lm(log(hr) ~ mid, data=u, weights=1/se^2))[2], 3) else NA
  d }))
tab <- tab[, c("outcome", LAB, "trend_slope_per_year")]
tab <- tab[order(tab$outcome != "SEIZURE OR EPILEPSY", tab$outcome), ]
write_tab(tab, "K_T53_negative_controls_over_time"); print(tab, row.names=FALSE)
nc <- tab[tab$outcome != "SEIZURE OR EPILEPSY", ]
log_msg("negative-control trend slopes: median ", round(stats::median(nc$trend_slope_per_year, na.rm=TRUE),3),
        "  (negative = fading)   seizure ",
        tab$trend_slope_per_year[tab$outcome=="SEIZURE OR EPILEPSY"])
saveRDS(P, file.path(PATH$derived, "K25_nc_time.rds"))
log_msg("K25 complete")
