## 09_subgroups_and_alternative_models.R --------------------------------------
## Three things the earlier scripts left out:
##   A. subgroup effect modification, tested with interaction terms (never by
##      comparing whether one subgroup is "significant" and another is not);
##   B. restricted mean time lost to seizure, an assumption-free complement to
##      the hazard ratio;
##   C. a smooth time-varying hazard ratio, rather than three discrete periods.

source("R/00_setup.R")
log_msg("=== 09 subgroups & alternative models ===")
a  <- readRDS(file.path(PATH$derived, "05_analytic.rds"))
tr <- readRDS(file.path(PATH$derived, "05_truncate_fn.rds"))

LM  <- 180 / 365.25    # symmetric outcome window (see 08)
TAU <- 3

prep <- function(dat, tau = TAU) {
  s <- tr(dat, tau)
  s <- s[!is.na(s$t) & !is.na(s$ev) & s$t > LM, ]
  s$t0 <- LM
  s
}

## ---- A. subgroups, with interaction tests ----------------------------------
## Each subgroup variable is defined at or before index. enc_pre12 (baseline
## surveillance intensity) is pre-index and therefore a legitimate modifier;
## post-index encounter volume is NOT used here, because it is a consequence of
## exposure and conditioning on it would open a collider path.
a$grp_sex  <- ifelse(a$sex == "F", "Female", "Male")
a$grp_age  <- ifelse(a$age_index < 35, "Age <35 y", "Age >=35 y")
a$grp_bmi  <- ifelse(a$bmi_index < 35, "BMI <35", "BMI >=35")
a$grp_era  <- ifelse(a$index_year < 2015, "Index <2015", "Index >=2015")
med_pre    <- stats::median(a$enc_pre12, na.rm = TRUE)
a$grp_surv <- ifelse(a$enc_pre12 < med_pre,
                     sprintf("Pre-index encounters <%g", med_pre),
                     sprintf("Pre-index encounters >=%g", med_pre))

subgroup_row <- function(dat, label) {
  s <- prep(dat)
  if (sum(s$ev) < 8 || length(unique(s$iih)) < 2)
    return(data.frame(subgroup = label, n = nrow(s), events = sum(s$ev),
                      hr = NA, lo = NA, hi = NA,
                      note = "too few events to estimate"))
  fit <- try(survival::coxph(Surv(t0, t, ev) ~ iih, data = s,
                             cluster = s$match_set, robust = TRUE), silent = TRUE)
  if (inherits(fit, "try-error") || !is.finite(stats::coef(fit)[1]))
    return(data.frame(subgroup = label, n = nrow(s), events = sum(s$ev),
                      hr = NA, lo = NA, hi = NA, note = "did not converge"))
  sm <- summary(fit)
  data.frame(subgroup = label, n = fit$n, events = fit$nevent,
             hr = sm$conf.int[1, 1], lo = sm$conf.int[1, 3], hi = sm$conf.int[1, 4],
             note = "")
}

## Wald test on the exposure-by-modifier interaction, using the robust
## (cluster-sandwich) covariance. This is the correct test for effect
## modification; the subgroup-specific HRs are descriptive companions to it.
interaction_p <- function(dat, var) {
  s <- prep(dat); s$mod <- factor(s[[var]])
  if (nlevels(s$mod) < 2) return(NA_real_)
  fit <- try(survival::coxph(
    stats::as.formula("Surv(t0, t, ev) ~ iih * mod"), data = s,
    cluster = s$match_set, robust = TRUE), silent = TRUE)
  if (inherits(fit, "try-error")) return(NA_real_)
  b <- stats::coef(fit); k <- grep("^iih:", names(b))
  if (!length(k) || any(!is.finite(b[k]))) return(NA_real_)
  V <- fit$var[k, k, drop = FALSE]
  if (any(!is.finite(V)) || abs(det(V)) < 1e-12) return(NA_real_)
  W <- as.numeric(t(b[k]) %*% solve(V) %*% b[k])
  signif(stats::pchisq(W, df = length(k), lower.tail = FALSE), 3)
}

sg_vars <- c(grp_sex = "Sex", grp_age = "Age at index", grp_bmi = "BMI at index",
             grp_era = "Calendar period", grp_surv = "Baseline surveillance")
overall <- subgroup_row(a, "Overall")
sub <- do.call(rbind, lapply(names(sg_vars), function(v) {
  lv <- sort(unique(stats::na.omit(a[[v]])))
  rows <- do.call(rbind, lapply(lv, function(l) subgroup_row(a[which(a[[v]] == l), ], l)))
  rows$modifier <- sg_vars[[v]]
  rows$interaction_p <- c(interaction_p(a, v), rep(NA, nrow(rows) - 1))
  rows
}))
overall$modifier <- "Overall"; overall$interaction_p <- NA
sub <- rbind(overall, sub)
sub$estimate <- ifelse(is.na(sub$hr), sub$note, fmt_est(sub$hr, sub$lo, sub$hi))
write_tab(sub[, c("modifier", "subgroup", "n", "events", "estimate", "interaction_p")],
          "T8_subgroup_interactions")
print(sub[, c("modifier", "subgroup", "events", "estimate", "interaction_p")])

## No subgroup is claimed to differ unless its interaction p-value supports it.
## With 112 events overall, these tests have low power: a non-significant
## interaction is NOT evidence that the effect is uniform.
sg_note <- data.frame(
  caution = paste(
    "Subgroup hazard ratios are descriptive. Differences between them are",
    "assessed ONLY by the interaction p-value, never by comparing which",
    "subgroup reached significance. With 112 events, power to detect",
    "effect modification is low, so a large interaction p-value does not",
    "establish that the effect is homogeneous. The male estimate rests on",
    "20 events and male matching used no calendar-year constraint",
    "(protocol v2.0 change #6); it is exploratory."))
write_tab(sg_note, "S19_subgroup_caution")

## ---- B. restricted mean time lost to seizure -------------------------------
## Defined as the integral of the cause-specific cumulative incidence over
## [0, tau]: the average time spent in the seizure state per patient. Unlike
## RMST from a Kaplan-Meier curve, this is competing-risk correct -- it does not
## assume the deceased could still have a seizure.
rmtl <- function(dat) {
  s <- dat
  s$evf <- factor(s$evc, levels = 0:2, labels = c("censored", "seizure", "death"))
  f <- survival::survfit(Surv(t, evf) ~ iih, data = s, id = seq_len(nrow(s)))
  g <- seq(0, TAU, by = 0.01)
  sm <- summary(f, times = g, extend = TRUE)
  k <- which(f$states == "seizure")
  strat <- as.character(sm$strata)
  vapply(c("iih=0", "iih=1"), function(z) {
    y <- sm$pstate[strat == z, k]
    sum((utils::head(y, -1) + utils::tail(y, -1)) / 2 * diff(g))   # trapezoid
  }, numeric(1))
}
s_full <- tr(a, TAU); s_full <- s_full[!is.na(s_full$t), ]
obs <- rmtl(s_full)

## Cluster bootstrap over matched sets: resampling whole sets preserves the
## dependence induced by matching.
set.seed(SEED)
sets <- unique(s_full$match_set)
idx  <- split(seq_len(nrow(s_full)), s_full$match_set)
B <- 400
boot <- vapply(seq_len(B), function(b) {
  pick <- sample(sets, length(sets), replace = TRUE)
  rows <- unlist(idx[pick], use.names = FALSE)
  d2 <- s_full[rows, ]
  d2$match_set <- rep(seq_along(pick), lengths(idx[pick]))  # unique ids after resampling
  out <- try(rmtl(d2), silent = TRUE)
  if (inherits(out, "try-error") || length(out) != 2) return(c(NA, NA, NA))
  c(out, out[2] - out[1])
}, numeric(3))

rm_tab <- data.frame(
  quantity = c("Non-IIH control", "IIH", "Difference (IIH - control)"),
  days_lost_over_3y = round(c(obs[1], obs[2], obs[2] - obs[1]) * 365.25, 2),
  lo = round(apply(boot, 1, stats::quantile, 0.025, na.rm = TRUE) * 365.25, 2),
  hi = round(apply(boot, 1, stats::quantile, 0.975, na.rm = TRUE) * 365.25, 2))
rm_tab$estimate <- fmt_est(rm_tab$days_lost_over_3y, rm_tab$lo, rm_tab$hi)
rm_tab$interpretation <- c(
  "", "", paste("Average additional time spent in the post-seizure state per",
                "IIH patient over 3 years. Assumption-free: no proportional-hazards",
                "requirement, and death is handled as a competing event."))
write_tab(rm_tab, "T9_restricted_mean_time_lost")
print(rm_tab[, c("quantity", "estimate")])

## ---- C. smooth time-varying hazard ratio -----------------------------------
## The scaled Schoenfeld residuals give a direct estimate of beta(t). This
## replaces the three-period split with a continuous picture, and is the honest
## way to show that the effect is sustained rather than front-loaded.
s3 <- prep(a)
fit3 <- survival::coxph(Surv(t0, t, ev) ~ iih, data = s3)
z <- survival::cox.zph(fit3, transform = "identity")
tv <- local({
  x <- z$x; y <- z$y[, 1]
  fitsm <- stats::smooth.spline(x, y, df = 3)
  pr <- stats::predict(fitsm, sort(unique(x)))
  ## Approximate pointwise band from the residual scatter.
  s_res <- stats::sd(y - stats::predict(fitsm, x)$y)
  data.frame(time_y = pr$x, beta = pr$y,
             lo = pr$y - 1.96 * s_res / sqrt(length(x) / 4),
             hi = pr$y + 1.96 * s_res / sqrt(length(x) / 4))
})
tv$hr <- exp(tv$beta); tv$hr_lo <- exp(tv$lo); tv$hr_hi <- exp(tv$hi)
write_tab(tv, "S20_time_varying_hr")

saveRDS(list(sub = sub, rmtl = rm_tab, tv = tv, zph = z),
        file.path(PATH$derived, "09_alt.rds"))
log_msg("09 complete")
