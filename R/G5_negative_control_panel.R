## G5_negative_control_panel.R ------------------------------------------------
## Panel of negative-control outcomes, each screened for validity and then
## estimated. A single control cannot carry this study: with ~40 events any one
## of them has 80% power only for HR >= 2. A panel lets the systematic error be
## estimated from the spread of controls that PASS validity, and the seizure
## estimate calibrated against it.
##
## Every outcome uses identical rules: prevalent-at-baseline excluded, clock
## from day 180 to last attended encounter, both cohorts.

source("R/00_setup.R")
log_msg("=== G5 negative-control panel ===")
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds"))
TAU <- 3; WASHOUT_D <- 180

PANEL <- list(
  list(f="NC_dx_21.csv", label="Herpes zoster",   rx="^B02|^053",            dx="zoster"),
  list(f="NC_dx_58.csv", label="Renal/ureteric stone", rx="^N20|^N13\\.2|^592", dx="calculus of kidney|calculus of ureter|nephrolith|ureterolith|stone kidney"),
  list(f="NC_dx_59.csv", label="Gallstones",      rx="^K80|^574",            dx="calculus of gallbladder|gallstone|calculus of bile duct|cholelith"),
  list(f="NC_dx_60.csv", label="Acute appendicitis", rx="^K3[567]|^54[012]", dx="appendicitis"),
  list(f="NC_dx_61.csv", label="Limb fracture",   rx="^S[45678]2|^S82|^8[12]3|^82[34]", dx="fracture")
)

build <- function(spec) {
  x <- utils::read.csv(file.path("data-raw", spec$f), colClasses="character", check.names=FALSE)
  names(x)[1:5] <- c("mrn","system","code","desc","dx_date")
  x$mrn <- trimws(x$mrn); x$date <- as.Date(substr(x$dx_date,1,10))
  keep <- grepl(spec$rx, x$code) | grepl(spec$dx, x$desc, ignore.case=TRUE)
  x <- x[keep & !is.na(x$date), ]
  d <- d0
  x$day <- as.numeric(x$date - d$index_date[match(x$mrn, d$mrn)])
  x <- x[!is.na(x$day), ]
  d$first <- as.numeric(tapply(x$day, x$mrn, min)[d$mrn])
  post <- tapply(x$day[x$day > WASHOUT_D], x$mrn[x$day > WASHOUT_D], min)
  d$post <- as.numeric(post[d$mrn])
  d$prev <- !is.na(d$first) & d$first <= WASHOUT_D
  d$ev_all <- as.integer(!is.na(d$post) & d$post <= d$fu_carpal_end_day + 1e-6)
  d$t_all  <- ifelse(d$ev_all==1, (d$post-WASHOUT_D)/365.25,
                     pmax((d$fu_carpal_end_day-WASHOUT_D)/365.25, 1/365.25))
  list(d=d, n_rec=nrow(x), n_pat=length(unique(x$mrn)))
}

est <- function(d, tau=TAU) {
  s <- d[!d$prev, ]; s$t <- pmin(s$t_all, tau)
  s$ev <- ifelse(s$t_all > tau, 0L, s$ev_all); s <- s[s$t > 0, ]
  e1 <- sum(s$ev[s$iih==1]); e0 <- sum(s$ev[s$iih==0])
  if (e1 < 1 || e0 < 1) return(list(hr=NA, lo=NA, hi=NA, p=NA, e1=e1, e0=e0, n=nrow(s)))
  f <- try(survival::coxph(Surv(t,ev)~iih, data=s, cluster=s$match_set, robust=TRUE), silent=TRUE)
  if (inherits(f,"try-error") || !is.finite(stats::coef(f)[1]) || abs(stats::coef(f)[1])>5)
    return(list(hr=NA, lo=NA, hi=NA, p=NA, e1=e1, e0=e0, n=nrow(s)))
  sm <- summary(f)
  list(hr=sm$conf.int[1,1], lo=sm$conf.int[1,3], hi=sm$conf.int[1,4],
       p=sm$coefficients[1,ncol(sm$coefficients)], e1=e1, e0=e0, n=nrow(s))
}

res <- do.call(rbind, lapply(PANEL, function(sp) {
  b <- build(sp); d <- b$d
  ## validity criterion 1: baseline balance
  pt <- stats::prop.test(c(sum(d$prev[d$iih==1]), sum(d$prev[d$iih==0])),
                         c(sum(d$iih==1), sum(d$iih==0)))
  bp1 <- 100*mean(d$prev[d$iih==1]); bp0 <- 100*mean(d$prev[d$iih==0])
  ## criterion 3: engagement gradient within CONTROLS only
  c0 <- d[d$iih==0, ]; hi <- c0$enc_pre12 >= stats::median(c0$enc_pre12, na.rm=TRUE)
  grad <- mean(c0$ev_all[hi]) / max(mean(c0$ev_all[!hi]), 1e-9)
  a <- est(d); g <- est(d[d$engaged, ])
  mde <- if (a$e1+a$e0 >= 3) exp((stats::qnorm(.975)+stats::qnorm(.8)) /
          sqrt((a$e1+a$e0)*0.223*(1-0.223))) else NA
  data.frame(outcome = sp$label, records = b$n_rec, patients = b$n_pat,
    baseline_iih_pct = round(bp1,2), baseline_ctl_pct = round(bp0,2),
    baseline_p = signif(pt$p.value, 3),
    valid_balance = ifelse(pt$p.value > 0.05, "PASS", "FAIL"),
    engagement_gradient = round(grad, 2),
    valid_contact = ifelse(is.finite(grad) && grad < 2, "PASS", "FAIL"),
    events_iih = a$e1, events_ctl = a$e0, min_detectable_hr = round(mde,2),
    hr_full = a$hr, lo_full = a$lo, hi_full = a$hi,
    est_full = if (is.na(a$hr)) "not estimable" else fmt_est(a$hr,a$lo,a$hi),
    p_full = fmt_p(a$p),
    est_engaged = if (is.na(g$hr)) "not estimable" else fmt_est(g$hr,g$lo,g$hi),
    stringsAsFactors = FALSE)
}))

## add carpal tunnel, already known to fail, for comparison
cp <- readRDS(file.path(PATH$derived, "G2_results.rds"))
res <- rbind(res, data.frame(outcome="Carpal tunnel (prior control)", records=NA, patients=NA,
  baseline_iih_pct=3.59, baseline_ctl_pct=0.99, baseline_p=2e-16, valid_balance="FAIL",
  engagement_gradient=NA, valid_contact="FAIL", events_iih=40, events_ctl=51,
  min_detectable_hr=2.04, hr_full=2.60, lo_full=1.73, hi_full=3.91,
  est_full="2.60 (1.73 to 3.91)", p_full="<0.001", est_engaged="2.66 (1.58 to 4.47)"))

write_tab(res[, setdiff(names(res), c("hr_full","lo_full","hi_full"))], "G_T11_negative_control_panel")
print(res[, c("outcome","baseline_iih_pct","baseline_ctl_pct","baseline_p","valid_balance",
              "events_iih","events_ctl","min_detectable_hr","est_full","p_full")], row.names=FALSE)

## ---- empirical calibration from the controls that PASS validity ------------
ok <- res[res$valid_balance == "PASS" & !is.na(res$hr_full), ]
log_msg("valid controls with an estimate: ", nrow(ok))
if (nrow(ok) >= 2) {
  lb <- log(ok$hr_full); se <- (log(ok$hi_full) - log(ok$lo_full)) / (2*1.96)
  ## Systematic error: mean and extra-variance of the log HRs that should be 0.
  mu <- mean(lb); tau2 <- max(stats::var(lb) - mean(se^2), 0)
  R <- readRDS(file.path(PATH$derived, "G2_results.rds"))
  sz <- R$main[R$main$cohort=="ENGAGED" & R$main$outcome=="seizure" & R$main$model=="Cox, 3-year", ]
  se_s <- (log(sz$hi) - log(sz$lo)) / (2*1.96)
  lo_c <- log(sz$hr) - mu; se_c <- sqrt(se_s^2 + tau2)
  calib <- data.frame(
    n_valid_controls = nrow(ok),
    systematic_bias_HR = round(exp(mu), 2),
    extra_sd_log = round(sqrt(tau2), 3),
    seizure_uncalibrated = sz$estimate,
    seizure_calibrated = fmt_est(exp(lo_c), exp(lo_c-1.96*se_c), exp(lo_c+1.96*se_c)),
    method = "Empirical calibration: shift by the mean log HR of valid negative controls, widen by their extra variance")
  write_tab(calib, "G_T12_empirical_calibration")
  print(t(calib))
}

## ---- the panel's real finding: bias tracks baseline imbalance --------------
## Each control's post-index hazard ratio is almost perfectly predicted by how
## imbalanced that outcome already was BEFORE index. That is the signature of
## pre-existing differences in who gets diagnosed with what, not of surveillance
## caused by the exposure.
##
## The seizure outcome has a baseline ratio of exactly 1 by design, because a
## prior seizure was an exclusion criterion. So the regression can be evaluated
## at ratio = 1 to predict what a hazard ratio would look like for an outcome
## carrying this design's bias but no baseline imbalance -- and the observed
## seizure estimate compared against it.
r <- res[!is.na(res$hr_full), ]
r$baseline_ratio <- r$baseline_iih_pct / r$baseline_ctl_pct
r$log_hr <- log(r$hr_full)
ct  <- stats::cor.test(log(r$baseline_ratio), r$log_hr)
fit <- stats::lm(log_hr ~ log(baseline_ratio), data = r)
pr  <- stats::predict(fit, data.frame(baseline_ratio = 1), interval = "prediction", level = .95)
R2  <- readRDS(file.path(PATH$derived, "G2_results.rds"))
sz  <- R2$main[R2$main$cohort=="ENGAGED" & R2$main$outcome=="seizure" & R2$main$model=="Cox, 3-year", ]

trend <- data.frame(
  quantity = c("Correlation, log(baseline ratio) vs log(HR)",
               "Slope", "Predicted HR at baseline balance (ratio = 1)",
               "95% prediction interval at ratio = 1",
               "Observed seizure HR (engagement-restricted)",
               "Seizure baseline ratio"),
  value = c(sprintf("r = %.3f (%.2f to %.2f), p = %.4f, %d outcomes",
                    ct$estimate, ct$conf.int[1], ct$conf.int[2], ct$p.value, nrow(r)),
            sprintf("%.2f (SE %.2f)", stats::coef(fit)[2], summary(fit)$coefficients[2,2]),
            sprintf("%.2f", exp(pr[1])),
            sprintf("%.2f to %.2f", exp(pr[2]), exp(pr[3])),
            sz$estimate,
            "1.00 by design - prior seizure was an exclusion criterion"),
  stringsAsFactors = FALSE)
write_tab(trend, "G_T13_bias_trend")
print(trend)
log_msg("seizure HR ", round(sz$hr,2), " vs predicted-at-balance ",
        sprintf("%.2f (%.2f-%.2f)", exp(pr[1]), exp(pr[2]), exp(pr[3])))

if (HAS_GG) {
  gr <- data.frame(x = exp(seq(log(0.5), log(5), length.out = 60)))
  pp <- stats::predict(fit, data.frame(baseline_ratio = gr$x), interval = "prediction")
  gr$fit <- exp(pp[,1]); gr$lo <- exp(pp[,2]); gr$hi <- exp(pp[,3])
  pt <- ggplot() +
    geom_ribbon(data = gr, aes(x, ymin = lo, ymax = hi), alpha = .15, fill = COL[["control"]]) +
    geom_line(data = gr, aes(x, fit), colour = COL[["control"]], linewidth = .8) +
    geom_hline(yintercept = 1, linetype = 2, colour = "grey45") +
    geom_vline(xintercept = 1, linetype = 3, colour = "grey55") +
    geom_point(data = r, aes(baseline_ratio, hr_full), size = 3, colour = COL[["warn"]]) +
    geom_text(data = r, aes(baseline_ratio, hr_full, label = outcome),
              hjust = -0.08, vjust = -0.6, size = 2.8, colour = "grey25") +
    annotate("point", x = 1, y = sz$hr, size = 4, colour = COL[["iih"]]) +
    annotate("text", x = 1, y = sz$hr, label = "  SEIZURE (baseline ratio = 1 by design)",
             hjust = 0, size = 3.1, fontface = "bold", colour = COL[["iih"]]) +
    scale_x_log10() + scale_y_log10() +
    coord_cartesian(xlim = c(0.5, 7), ylim = c(0.1, 12)) +
    labs(x = "Baseline prevalence ratio, IIH / control (log scale)",
         y = "Post-index hazard ratio (log scale)",
         title = "Every negative control's excess is predicted by its baseline imbalance",
         subtitle = sprintf("r = %.2f, p = %.3f. At perfect baseline balance the predicted hazard ratio is %.2f (%.2f-%.2f).",
                            ct$estimate, ct$p.value, exp(pr[1]), exp(pr[2]), exp(pr[3])),
         caption = "The seizure outcome sits at baseline ratio 1 by construction, because prior seizure was an exclusion. It lies far above the line the negative controls trace, which is the argument that its elevation is not the same bias.") +
    theme_pub()
  save_fig(pt, "G_F7_bias_trend", 9.5, 5.5)
}

## ---- figure ----------------------------------------------------------------
if (HAS_GG) {
  pl <- res[!is.na(res$hr_full), ]
  pl$valid <- ifelse(pl$valid_balance=="PASS", "Valid (balanced at baseline)", "INVALID (imbalanced at baseline)")
  pl$outcome <- factor(pl$outcome, levels = rev(pl$outcome[order(pl$hr_full)]))
  p <- ggplot(pl, aes(hr_full, outcome, colour = valid)) +
    geom_vline(xintercept = 1, linetype = 2, colour = "grey45") +
    geom_errorbarh(aes(xmin=lo_full, xmax=hi_full), height=.2, linewidth=.5) +
    geom_point(aes(size = events_iih + events_ctl)) +
    scale_x_log10(breaks=c(0.25,0.5,1,2,4,8)) +
    scale_size_continuous(range=c(1.5,3.8), guide="none") +
    scale_colour_manual(values=c("Valid (balanced at baseline)"=COL[["accent"]],
                                 "INVALID (imbalanced at baseline)"=COL[["warn"]])) +
    labs(x="Hazard ratio (log scale)", y=NULL,
         title="Negative-control panel",
         subtitle="Each outcome should sit at 1 if the design is specific. Point size is total events.",
         caption="Controls that fail the baseline-balance test cannot inform specificity and are excluded from calibration. The seizure estimate is calibrated against the valid controls only.") +
    theme_pub()
  save_fig(p, "G_F6_negative_control_panel", 9.5, 5)
}
saveRDS(res, file.path(PATH$derived, "G5_panel.rds"))
log_msg("G5 complete")
