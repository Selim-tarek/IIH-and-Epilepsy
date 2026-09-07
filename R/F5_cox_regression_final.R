## F5_cox_regression_final.R --------------------------------------------------
## FULL COX REGRESSION.
##
## The primary model reported elsewhere is a Cox model with the exposure alone,
## because matching already handles age, sex, BMI and index year. This script
## does the thing matching did NOT do: adjust the confounders that remained
## imbalanced after matching (sleep apnoea SMD 0.36, PCOS 0.17, hypertension
## 0.16) and report every coefficient, not just the exposure.
##
## Degrees of freedom are the binding constraint. There are 115 events at three
## years, so at the conventional 10-events-per-parameter rule the model can
## carry about 11 terms. The full model sits exactly at that limit, which is why
## a parsimonious model is fitted alongside it and the two are compared.

source("R/00_setup.R")
log_msg("=== F5 Cox regression (FINAL) ===")
d <- readRDS(file.path(PATH$derived, "F1_typed.rds"))
TAU <- 3

cut_at <- function(dat, tau) {
  dat$t  <- pmin(dat$t_y, tau)
  dat$ev <- ifelse(dat$t_y > tau, 0L, as.integer(dat$event))
  dat
}
s <- cut_at(d, TAU)

## Model covariates. enc_pre12 is PRE-index and therefore a legitimate
## confounder; enc_post is deliberately excluded, being a consequence of both
## exposure and outcome (adjusting for it is mediator adjustment).
s$log_enc_pre <- log1p(s$enc_pre12)
s$smk <- ifelse(is.na(s$smoking), "Unknown", as.character(s$smoking))
s$iih_f <- factor(s$iih, levels = c(0, 1), labels = c("Non-IIH control", "IIH"))

## ---- smoking cannot enter a comparative model ------------------------------
## Detailed smoking status (Never/Former/Current) is recorded for IIH cases only.
## Every one of the 9,122 controls is coded "Unknown". Smoking is therefore
## perfectly nested within the exposure: "Current" and "Former" can only occur
## in an IIH case, so their coefficients are unidentified (the earlier fit hit
## separation and a singular information matrix). Including it does not adjust
## for smoking, it silently re-estimates the exposure effect within a case-only
## stratum and inflates the exposure standard error.
##
## It is excluded from every model below, and the reason is tabulated rather
## than buried.
smk_tab <- as.data.frame.matrix(table(s$smk, s$cohort))
smk_tab$level <- rownames(smk_tab); rownames(smk_tab) <- NULL
smk_tab$events <- as.integer(tapply(s$ev, s$smk, sum)[smk_tab$level])
smk_tab <- smk_tab[, c("level", "Non-IIH control", "IIH", "events")]
smk_tab$usable <- "NO -- level is case-only or control-only"
write_tab(smk_tab, "F_T14j_smoking_not_adjustable")
log_msg("smoking excluded from all models: all ", sum(s$cohort == "Non-IIH control"),
        " controls are coded Unknown (structural collinearity with exposure)")

FULL <- "iih + age_index + bmi_index + sex + osa + htn + pcos + log_enc_pre"
PARS <- "iih + age_index + bmi_index + sex + osa + htn + pcos"

## ---- 0. degrees of freedom budget ------------------------------------------
fit_full <- survival::coxph(stats::as.formula(paste("Surv(t, ev) ~", FULL)),
                            data = s, cluster = s$match_set, robust = TRUE,
                            ties = "efron", x = TRUE)
epv <- data.frame(
  quantity = c("Events at 3 years", "Parameters in the full model",
               "Events per parameter", "Rule-of-thumb minimum"),
  value = c(fit_full$nevent, length(stats::coef(fit_full)),
            round(fit_full$nevent / length(stats::coef(fit_full)), 1), 10))
write_tab(epv, "F_T14a_events_per_parameter")
print(epv)
if (fit_full$nevent / length(stats::coef(fit_full)) < 10)
  log_msg("WARNING: fewer than 10 events per parameter in the full model")

## ---- 1. univariable Cox for every covariate --------------------------------
## Reported because a manuscript table normally shows them, and because a
## covariate whose univariable and adjusted estimates diverge sharply is worth
## a second look. They are NOT used to select variables: stepwise selection on
## p-values biases coefficients and standard errors.
uni_terms <- c(iih = "iih", age_index = "age_index", bmi_index = "bmi_index",
               sex = "sex", osa = "osa", htn = "htn", pcos = "pcos",
               log_enc_pre = "log_enc_pre")
tidy_cox <- function(fit, model_label) {
  sm <- summary(fit)
  ci <- sm$conf.int; co <- sm$coefficients
  data.frame(model = model_label, term = rownames(co),
             hr = round(ci[, 1], 3), lo = round(ci[, 3], 3), hi = round(ci[, 4], 3),
             se = round(co[, "se(coef)"], 4),
             z = round(co[, ncol(co) - 1], 2),
             p = co[, ncol(co)], row.names = NULL, stringsAsFactors = FALSE)
}
uni <- do.call(rbind, lapply(names(uni_terms), function(v) {
  f <- survival::coxph(stats::as.formula(paste("Surv(t, ev) ~", uni_terms[[v]])),
                       data = s, cluster = s$match_set, robust = TRUE)
  tidy_cox(f, "univariable")
}))
uni$estimate <- fmt_est(uni$hr, uni$lo, uni$hi); uni$p <- fmt_p(uni$p)
write_tab(uni[, c("term", "estimate", "p")], "F_T14b_univariable_cox")

## ---- 2. multivariable Cox ---------------------------------------------------
fit_pars <- survival::coxph(stats::as.formula(paste("Surv(t, ev) ~", PARS)),
                            data = s, cluster = s$match_set, robust = TRUE,
                            ties = "efron", x = TRUE)
fit_strat <- survival::coxph(
  stats::as.formula(paste("Surv(t, ev) ~", FULL, "+ strata(match_set)")),
  data = s, ties = "efron")

mv <- rbind(tidy_cox(fit_full, "multivariable (full)"),
            tidy_cox(fit_pars, "multivariable (parsimonious)"),
            tidy_cox(fit_strat, "multivariable, stratified by matched set"))
mv$estimate <- fmt_est(mv$hr, mv$lo, mv$hi); mv$p_fmt <- fmt_p(mv$p)
write_tab(mv[, c("model", "term", "estimate", "se", "z", "p_fmt")],
          "F_T14c_multivariable_cox")

## The headline comparison: does adjusting the residual confounders move the
## exposure estimate?
exp_row <- function(fit, lab) {
  sm <- summary(fit); i <- which(rownames(sm$conf.int) == "iih")
  data.frame(model = lab, n = fit$n, events = fit$nevent,
             estimate = fmt_est(sm$conf.int[i, 1], sm$conf.int[i, 3], sm$conf.int[i, 4]),
             p = fmt_p(sm$coefficients[i, ncol(sm$coefficients)]))
}
fit_crude <- survival::coxph(Surv(t, ev) ~ iih, data = s, cluster = s$match_set,
                             robust = TRUE)
compare <- rbind(
  exp_row(fit_crude, "Crude (matched design only) -- PRIMARY"),
  exp_row(fit_pars,  "Adjusted: + age, BMI, sex, OSA, HTN, PCOS"),
  exp_row(fit_full,  "Adjusted: + pre-index healthcare contact"),
  exp_row(fit_strat, "Adjusted, stratified by matched set"))
write_tab(compare, "F_T14d_exposure_across_models")
print(compare)

## ---- 3. proportional hazards, per term and global --------------------------
z_full <- survival::cox.zph(survival::coxph(
  stats::as.formula(paste("Surv(t, ev) ~", FULL)), data = s))
ph <- as.data.frame(z_full$table)
ph$term <- rownames(ph); rownames(ph) <- NULL
ph <- ph[, c("term", "chisq", "df", "p")]
ph$chisq <- round(ph$chisq, 2); ph$p <- signif(ph$p, 3)
ph$conclusion <- ifelse(ph$p < 0.05, "PH VIOLATED", "PH not rejected")
write_tab(ph, "F_T14e_ph_by_term")
print(ph)

grDevices::pdf(file.path(PATH$diag, "F_cox_schoenfeld_multivariable.pdf"),
               width = 7, height = 5)
for (i in seq_len(nrow(z_full$table) - 1)) {
  plot(z_full[i]); graphics::abline(h = 0, lty = 2, col = "grey50")
}
grDevices::dev.off()

## ---- 4. functional form of the continuous covariates -----------------------
## Compares a linear term against a 3-knot restricted cubic spline by likelihood
## ratio. This is a check on the linearity assumption, not a model-selection
## exercise: the spline is adopted only if the data clearly demand it AND the
## degrees of freedom allow it.
rcs_basis <- function(x, knots) {
  k <- knots; kn <- length(k)
  out <- matrix(x, ncol = 1)
  for (j in seq_len(kn - 2)) {
    num <- pmax(x - k[j], 0)^3 -
      pmax(x - k[kn - 1], 0)^3 * (k[kn] - k[j]) / (k[kn] - k[kn - 1]) +
      pmax(x - k[kn], 0)^3 * (k[kn - 1] - k[j]) / (k[kn] - k[kn - 1])
    out <- cbind(out, num / (k[kn] - k[1])^2)
  }
  out
}
lin_check <- do.call(rbind, lapply(c("age_index", "bmi_index"), function(v) {
  x <- s[[v]]; kn <- stats::quantile(x, c(.1, .5, .9), na.rm = TRUE)
  B <- rcs_basis(x, kn)
  dd <- s; dd$b1 <- B[, 1]; dd$b2 <- B[, 2]
  f0 <- survival::coxph(Surv(t, ev) ~ iih + b1, data = dd)
  f1 <- survival::coxph(Surv(t, ev) ~ iih + b1 + b2, data = dd)
  lrt <- 2 * (f1$loglik[2] - f0$loglik[2])
  data.frame(covariate = v, knots = paste(round(kn, 1), collapse = ", "),
             lrt_chisq = round(lrt, 2), df = 1,
             p_nonlinearity = signif(stats::pchisq(lrt, 1, lower.tail = FALSE), 3),
             conclusion = ifelse(stats::pchisq(lrt, 1, lower.tail = FALSE) < 0.05,
                                 "non-linear -- consider a spline",
                                 "linear term adequate"))
}))
write_tab(lin_check, "F_T14f_linearity_checks")
print(lin_check)

## ---- 5. collinearity --------------------------------------------------------
## Variance inflation from the model's own covariance matrix. High VIF inflates
## standard errors and makes individual coefficients unstable, though it does
## not bias the exposure estimate if the exposure itself is not collinear.
vif_cox <- function(fit) {
  V <- stats::vcov(fit); X <- fit$x
  keep <- colnames(X)[apply(X, 2, stats::sd) > 0]
  R <- stats::cor(X[, keep, drop = FALSE])
  iv <- try(solve(R), silent = TRUE)
  if (inherits(iv, "try-error")) return(NULL)
  data.frame(term = keep, vif = round(diag(iv), 2),
             interpretation = ifelse(diag(iv) > 5, "HIGH -- unstable coefficient",
                                     "acceptable"), row.names = NULL)
}
vf <- vif_cox(fit_full)
if (!is.null(vf)) { write_tab(vf, "F_T14g_collinearity_vif"); print(vf) }

## ---- 6. influential observations -------------------------------------------
## dfbeta for the exposure coefficient: how much would dropping each patient
## move the log hazard ratio? A single patient should never drive the result.
db <- stats::residuals(fit_full, type = "dfbeta")
i_iih <- which(names(stats::coef(fit_full)) == "iih")
infl <- data.frame(
  metric = c("Largest |dfbeta| for the IIH coefficient",
             "As a percentage of the coefficient itself",
             "Patients with |dfbeta| > 10% of the coefficient"),
  value = c(signif(max(abs(db[, i_iih])), 3),
            paste0(round(100 * max(abs(db[, i_iih])) / abs(stats::coef(fit_full)[i_iih]), 2), "%"),
            sum(abs(db[, i_iih]) > 0.1 * abs(stats::coef(fit_full)[i_iih]))))
write_tab(infl, "F_T14h_influence")
print(infl)

## ---- 7. nested model comparison --------------------------------------------
## Wald tests on the robust covariance, because a likelihood ratio test is not
## valid once a sandwich variance is used.
wald_block <- function(fit, terms_regex, label) {
  b <- stats::coef(fit); k <- grep(terms_regex, names(b))
  if (!length(k)) return(NULL)
  V <- fit$var[k, k, drop = FALSE]
  W <- as.numeric(t(b[k]) %*% solve(V) %*% b[k])
  data.frame(block = label, df = length(k), wald_chisq = round(W, 2),
             p = signif(stats::pchisq(W, length(k), lower.tail = FALSE), 3))
}
blocks <- do.call(rbind, list(
  wald_block(fit_full, "^iih$", "Exposure (IIH)"),
  wald_block(fit_full, "^(age_index|bmi_index|sexM)$", "Matched covariates"),
  wald_block(fit_full, "^(osa|htn|pcos)$", "Comorbidity"),
  wald_block(fit_full, "^log_enc_pre$", "Pre-index healthcare contact")))
write_tab(blocks, "F_T14i_wald_blocks")
print(blocks)

## ---- 8. forest plot of the adjusted model ----------------------------------
if (HAS_GG) {
  lab <- c(iih = "IIH (vs non-IIH control)", age_index = "Age, per year",
           bmi_index = "BMI, per kg/m2", sexM = "Male (vs female)",
           osa = "Obstructive sleep apnoea", htn = "Hypertension", pcos = "PCOS",
           log_enc_pre = "Pre-index encounters, log(1+n)")
  fp <- tidy_cox(fit_full, "full")
  fp$label <- ifelse(is.na(lab[fp$term]), fp$term, lab[fp$term])
  fp$grp <- ifelse(fp$term == "iih", "Exposure", "Covariate")
  fp$label <- factor(fp$label, levels = rev(fp$label))
  p <- ggplot(fp, aes(hr, label, colour = grp)) +
    geom_vline(xintercept = 1, linetype = 2, colour = "grey45") +
    geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.2, linewidth = 0.5) +
    geom_point(size = 2.8) +
    scale_x_log10(breaks = c(0.5, 1, 2, 5, 10)) +
    scale_colour_manual(values = c(Exposure = COL[["iih"]], Covariate = COL[["control"]])) +
    labs(x = "Adjusted hazard ratio (log scale)", y = NULL,
         title = "Multivariable Cox regression",
         subtitle = sprintf("3-year horizon, %d events, %d parameters (%.1f events per parameter). Robust SE clustered on matched set.",
                            fit_full$nevent, length(stats::coef(fit_full)),
                            fit_full$nevent / length(stats::coef(fit_full))),
         caption = paste("Post-index encounters are deliberately EXCLUDED: they are a consequence of both exposure and outcome, so",
                         "\nadjusting for them is mediator adjustment. Pre-index contact is a legitimate confounder and is included.",
                         "\nCovariate hazard ratios are adjusted associations, not causal effects of those covariates.")) +
    theme_pub()
  save_fig(p, "FIN_F11_cox_multivariable_forest", w = 9, h = 5.5)
}

saveRDS(list(epv = epv, uni = uni, mv = mv, compare = compare, ph = ph,
             lin = lin_check, vif = vf, infl = infl, blocks = blocks),
        file.path(PATH$derived, "F5_cox.rds"))
log_msg("F5 complete")
