## G4_negative_control_screen.R -----------------------------------------------
## Validity screen for candidate negative-control outcomes.
##
## Carpal tunnel failed not because the estimate was wrong but because the
## OUTCOME was invalid: it was already 3.6x commoner in cases before index. A
## control that is imbalanced at baseline cannot tell you whether your primary
## result is biased, in either direction.
##
## This screens a candidate BEFORE it is used, on four criteria:
##   1. BASELINE BALANCE  - prevalence before index must be similar (the test
##                          carpal tunnel failed at p < 2e-16)
##   2. POWER             - enough incident events to exclude a modest effect
##   3. ENGAGEMENT GRADIENT - within CONTROLS only, does the outcome track
##                          baseline encounter count? If yes, it measures
##                          healthcare contact rather than disease and will be
##                          elevated for that reason alone
##   4. STABILITY         - does the estimate move when controls are restricted
##                          to those engaged in care?
##
## Usage: supply a dated diagnosis extract with columns
##   Clinic Number, Diagnosis Code, Diagnosis Description, Diagnosis Date
## and a regex for the codes that define the outcome.

source("R/00_setup.R")
TAU <- 3; WASHOUT_D <- 180

screen_negative_control <- function(file, code_regex, desc_regex = NULL, label) {
  d <- readRDS(file.path(PATH$derived, "G1_master.rds"))
  x <- utils::read.csv(file, colClasses = "character", check.names = FALSE)
  names(x)[1] <- "mrn"
  dt <- grep("date", names(x), ignore.case = TRUE, value = TRUE)[1]
  cd <- grep("code", names(x), ignore.case = TRUE, value = TRUE)[1]
  ds <- grep("desc", names(x), ignore.case = TRUE, value = TRUE)[1]
  x$mrn <- trimws(x$mrn); x$date <- as.Date(substr(x[[dt]], 1, 10))
  keep <- grepl(code_regex, x[[cd]])
  if (!is.null(desc_regex)) keep <- keep | grepl(desc_regex, x[[ds]], ignore.case = TRUE)
  x <- x[keep & !is.na(x$date), ]

  x$day <- as.numeric(x$date - d$index_date[match(x$mrn, d$mrn)])
  d$first <- as.numeric(tapply(x$day, x$mrn, min)[d$mrn])
  post <- tapply(x$day[x$day > WASHOUT_D], x$mrn[x$day > WASHOUT_D], min)
  d$post <- as.numeric(post[d$mrn])
  d$prev <- !is.na(d$first) & d$first <= WASHOUT_D
  d$ev_all <- as.integer(!is.na(d$post) & d$post <= d$fu_carpal_end_day + 1e-6)
  d$t_all <- ifelse(d$ev_all == 1, (d$post - WASHOUT_D) / 365.25,
                    pmax((d$fu_carpal_end_day - WASHOUT_D) / 365.25, 1/365.25))

  ## 1. baseline balance
  pt <- stats::prop.test(c(sum(d$prev[d$iih==1]), sum(d$prev[d$iih==0])),
                         c(sum(d$iih==1), sum(d$iih==0)))
  p1 <- c(mean(d$prev[d$iih==1]), mean(d$prev[d$iih==0]))

  ## 3. engagement gradient among CONTROLS ONLY
  c0 <- d[d$iih == 0, ]
  hi <- c0$enc_pre12 >= stats::median(c0$enc_pre12, na.rm = TRUE)
  grad <- mean(c0$ev_all[hi], na.rm = TRUE) / max(mean(c0$ev_all[!hi], na.rm = TRUE), 1e-9)

  fitq <- function(dat) {
    s <- dat[!dat$prev, ]; s$t <- pmin(s$t_all, TAU)
    s$ev <- ifelse(s$t_all > TAU, 0L, s$ev_all); s <- s[s$t > 0, ]
    e1 <- sum(s$ev[s$iih==1]); e0 <- sum(s$ev[s$iih==0])
    if (e1 == 0 || e0 == 0) return(list(est = "not estimable", e1 = e1, e0 = e0, mde = NA))
    f <- survival::coxph(Surv(t, ev) ~ iih, data = s, cluster = s$match_set, robust = TRUE)
    sm <- summary(f)
    mde <- exp((stats::qnorm(.975) + stats::qnorm(.8)) /
               sqrt(sum(s$ev) * mean(s$iih==1) * (1 - mean(s$iih==1))))
    list(est = fmt_est(sm$conf.int[1,1], sm$conf.int[1,3], sm$conf.int[1,4]),
         e1 = e1, e0 = e0, mde = round(mde, 2))
  }
  a <- fitq(d); b <- fitq(d[d$engaged, ])

  data.frame(
    candidate = label,
    baseline_pct_iih = round(100*p1[1], 2), baseline_pct_control = round(100*p1[2], 2),
    baseline_p = format.pval(pt$p.value, digits = 3),
    criterion_1_balance = ifelse(pt$p.value > 0.05, "PASS", "FAIL - imbalanced before index"),
    events_iih = a$e1, events_control = a$e0,
    criterion_2_power = ifelse(is.na(a$mde), "FAIL - no events",
                        ifelse(a$mde <= 1.5, "PASS", paste0("WEAK - 80% power only for HR>=", a$mde))),
    engagement_gradient = round(grad, 2),
    criterion_3_contact = ifelse(is.finite(grad) && grad < 2, "PASS",
                                 "FAIL - tracks healthcare contact"),
    estimate_full = a$est, estimate_engaged = b$est,
    criterion_4_stability = ifelse(a$est == "not estimable" || b$est == "not estimable",
                                   "n/a", "compare the two columns"),
    stringsAsFactors = FALSE)
}

## Demonstrated on carpal tunnel, the control that failed.
if (sys.nframe() == 0) {
  res <- screen_negative_control(
    file.path("data-raw", "MDE_Diagnosis_carpal_12.csv"),
    code_regex = "^354\\.0|^G56\\.0", desc_regex = "carpal tunnel",
    label = "Carpal tunnel syndrome")
  write_tab(res, "G_T10_negative_control_screen")
  print(t(res))
}
