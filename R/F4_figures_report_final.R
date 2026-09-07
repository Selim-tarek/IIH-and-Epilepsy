## F4_figures_report_final.R --------------------------------------------------
## Publication figures and the narrative report for the FINAL workbook.
## Every figure answers one stated question. Palette is grayscale-separable.

source("R/00_setup.R")
log_msg("=== F4 figures & report (FINAL) ===")
d <- readRDS(file.path(PATH$derived, "F1_typed.rds"))
R <- readRDS(file.path(PATH$derived, "F2_results.rds"))
X <- if (file.exists(file.path(PATH$derived, "F5_cox.rds")))
  readRDS(file.path(PATH$derived, "F5_cox.rds")) else NULL
M <- if (file.exists(file.path(PATH$derived, "F3_meds.rds")))
  readRDS(file.path(PATH$derived, "F3_meds.rds")) else NULL
ex <- readRDS(file.path(PATH$derived, "F1_excluded.rds"))
FIG <- function(p, n, w = 8, h = 5.5) save_fig(p, paste0("FIN_", n), w, h)

parse_est <- function(x) {
  m <- regmatches(x, regexec("^([0-9.]+) \\(([0-9.]+) to ([0-9.]+)\\)$", x))
  t(vapply(m, function(z) if (length(z) == 4) as.numeric(z[2:4]) else rep(NA_real_, 3),
           numeric(3)))
}

if (HAS_GG) {
## --- 1. cohort flow ---------------------------------------------------------
fl <- data.frame(y = 5:1, lab = c(
  sprintf("Screened IIH-coded patients and control pool"),
  sprintf("Excluded: no matched counterpart (n = %d)", sum(ex$reason == "No matched counterpart")),
  sprintf("Excluded at 180-day washout / no follow-up after day 180 (n = %d)",
          sum(ex$reason != "No matched counterpart")),
  sprintf("Final matched cohort: %s IIH cases + %s controls",
          format(sum(d$iih == 1), big.mark = ","), format(sum(d$iih == 0), big.mark = ",")),
  sprintf("Analysed at 3 years: %d incident seizures (%d IIH, %d control)",
          sum(R$s3$ev), sum(R$s3$ev[R$s3$iih == 1]), sum(R$s3$ev[R$s3$iih == 0]))),
  kind = c("main", "side", "side", "main", "main"))
FIG(ggplot(fl, aes(1, y)) +
  geom_tile(aes(fill = kind), width = 0.92, height = 0.7, colour = "grey30") +
  geom_text(aes(label = lab), size = 3.2) +
  scale_fill_manual(values = c(main = "#EAF0F6", side = "#F5EDE4"), guide = "none") +
  labs(title = "Cohort construction (final workbook)",
       subtitle = "Symmetric 180-day washout applied to both arms; data cutoff 3 September 2026",
       caption = "Tan boxes are patients removed from the matched analysis and itemised on the Excluded_from_analysis sheet.") +
  theme_void(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        plot.caption = element_text(hjust = 0, colour = "grey35", size = 8)),
  "F1_cohort_flow", 8.5, 5)

## --- 2. balance -------------------------------------------------------------
b <- R$bal; b$post <- grepl("POST-EXPOSURE", b$variable)
b$variable <- factor(sub(" \\(POST-EXPOSURE\\)", "", b$variable),
                     levels = sub(" \\(POST-EXPOSURE\\)", "", b$variable)[order(abs(b$smd))])
FIG(ggplot(b, aes(abs(smd), variable, colour = post)) +
  geom_vline(xintercept = 0.1, linetype = 2, colour = "grey45") +
  geom_segment(aes(x = 0, xend = abs(smd), yend = variable), linewidth = 0.4) +
  geom_point(size = 2.8) +
  scale_colour_manual(values = c(`FALSE` = COL[["control"]], `TRUE` = COL[["warn"]]),
    labels = c("Baseline covariate", "Post-index (imbalance expected)")) +
  labs(x = "|Standardised mean difference|", y = NULL,
       title = "Covariate balance after matching",
       subtitle = sprintf("Dashed line = 0.1. Propensity c-statistic %.3f.", R$cstat),
       caption = "Matched targets (age, BMI, sex, index year) are balanced. Comorbidity and healthcare contact were NOT matched on and remain imbalanced; they are confounders the design does not close.") +
  theme_pub(), "F2_balance", 9, 5)

## --- 3. incidence rates -----------------------------------------------------
r <- R$rates; r$horizon <- factor(r$horizon, levels = unique(r$horizon))
FIG(ggplot(r, aes(horizon, rate_per_1000py, colour = cohort, group = cohort)) +
  geom_errorbar(aes(ymin = rate_lo, ymax = rate_hi), width = 0.12,
                position = position_dodge(0.35), linewidth = 0.6) +
  geom_point(size = 3, position = position_dodge(0.35)) +
  scale_colour_manual(values = COHORT_COL) +
  labs(x = NULL, y = "Incident seizures per 1,000 person-years",
       title = "Incidence of first seizure or epilepsy after the 180-day washout",
       subtitle = "Exact (Garwood) Poisson 95% confidence intervals",
       caption = "Person-time runs from day 180 to event, death, or last attended encounter. Follow-up is verifiable for all 11,740 patients.") +
  theme_pub(), "F3_incidence_rates", 7.5, 5)

## --- 4. cumulative incidence ------------------------------------------------
s3 <- R$s3; s3$evf <- factor(s3$evc, levels = 0:2,
                             labels = c("censored", "seizure", "death"))
aj <- survival::survfit(Surv(t, evf) ~ iih, data = s3, id = seq_len(nrow(s3)))
g <- seq(0, 3, by = 0.02); sm <- summary(aj, times = g, extend = TRUE)
ks <- which(aj$states == "seizure"); kd <- which(aj$states == "death")
coh <- ifelse(grepl("iih=1", as.character(sm$strata)), "IIH", "Non-IIH control")
cifd <- rbind(
  data.frame(t = sm$time, cohort = coh, pct = 100 * sm$pstate[, ks],
             lo = 100 * sm$lower[, ks], hi = 100 * sm$upper[, ks],
             event = "Seizure or epilepsy"),
  data.frame(t = sm$time, cohort = coh, pct = 100 * sm$pstate[, kd],
             lo = NA, hi = NA, event = "Death (competing event)"))
cifd$event <- factor(cifd$event, levels = c("Seizure or epilepsy", "Death (competing event)"))
FIG(ggplot(cifd, aes(t, pct, colour = cohort, fill = cohort)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.15, colour = NA) +
  geom_step(linewidth = 0.8) + facet_wrap(~event, scales = "free_y") +
  scale_colour_manual(values = COHORT_COL) + scale_fill_manual(values = COHORT_COL) +
  labs(x = "Years since index (day 180 = 0)", y = "Cumulative incidence (%)",
       title = "Cumulative incidence of seizure, with death as a competing event",
       subtitle = sprintf("Aalen-Johansen. 3-year risk %.2f%% (IIH) vs %.2f%% (control); difference %.2f pp, NNH %d",
         R$rd$iih_risk_pct, R$rd$control_risk_pct, R$rd$estimate, R$rd$number_needed_to_harm),
       caption = "1 - Kaplan-Meier is NOT shown: it would overstate absolute risk by treating the deceased as still at risk.") +
  theme_pub(), "F4_cumulative_incidence", 9, 5)

## --- 5. forest of sensitivity analyses --------------------------------------
fs <- R$sens; e <- parse_est(fs$estimate)
fs$hr <- e[,1]; fs$lo <- e[,2]; fs$hi <- e[,3]; fs <- fs[!is.na(fs$hr), ]
fs$analysis <- factor(fs$analysis, levels = rev(fs$analysis))
fs$flag <- ifelse(grepl("Primary", fs$analysis), "primary",
           ifelse(grepl("CONSERVATIVE BOUND", fs$analysis), "bound", "other"))
FIG(ggplot(fs, aes(hr, analysis, colour = flag)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey45") +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.22, linewidth = 0.5) +
  geom_point(aes(size = events)) +
  scale_x_log10(breaks = c(1, 2, 3, 5, 10, 20)) +
  scale_size_continuous(range = c(1.4, 3.6), guide = "none") +
  scale_colour_manual(values = c(primary = COL[["iih"]], bound = COL[["warn"]],
                                 other = COL[["control"]]),
    labels = c("Mediator-adjusted bound", "Other specification", "Primary")) +
  labs(x = "Hazard ratio (log scale)", y = NULL,
       title = "Sensitivity of the IIH-seizure association to specification",
       subtitle = "Point size proportional to event count; 3-year horizon unless named otherwise",
       caption = "The mediator-adjusted estimate (amber) is a conservative LOWER BOUND, not a causal estimate: post-index encounters are a consequence of both exposure and outcome.") +
  theme_pub(), "F5_forest_sensitivity", 11, 6)

## --- 6. subgroup forest -----------------------------------------------------
sg <- R$sub[!is.na(R$sub$hr), ]
sg$lab <- sprintf("%s  (%d events)",
                  ifelse(sg$modifier == "Overall", "Overall", sg$subgroup), sg$events)
sg$ip <- ifelse(is.na(sg$interaction_p), "", paste0("interaction p = ", sg$interaction_p))
sg$modifier <- factor(sg$modifier, levels = c("Overall", "Sex", "Age at index",
                       "BMI at index", "Calendar period", "Baseline surveillance"))
sg <- sg[order(sg$modifier), ]; sg$lab <- factor(sg$lab, levels = rev(sg$lab))
FIG(ggplot(sg, aes(hr, lab)) +
  geom_vline(xintercept = R$sub$hr[1], linetype = 3, colour = COL[["accent"]]) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey45") +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.2, linewidth = 0.5,
                 colour = COL[["control"]]) +
  geom_point(aes(size = events), colour = COL[["iih"]]) +
  geom_text(aes(x = 95, label = ip), size = 2.8, hjust = 1, colour = "grey20") +
  facet_grid(modifier ~ ., scales = "free_y", space = "free_y", switch = "y") +
  scale_x_log10(breaks = c(1, 2, 5, 10, 20), limits = c(0.25, 100)) +
  scale_size_continuous(range = c(1.5, 3.5), guide = "none") +
  labs(x = "Hazard ratio (log scale)", y = NULL,
       title = "Effect modification, tested by interaction",
       subtitle = "Dotted green = overall estimate. Subgroup HRs are descriptive; only the interaction p-value tests modification.",
       caption = "With 115 events, power to detect modification is low: a large interaction p-value does NOT establish a uniform effect.") +
  theme_pub() + theme(strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0, hjust = 1),
    panel.spacing.y = unit(0.15, "lines")), "F6_subgroups", 11, 6)

## --- 7. negative control ----------------------------------------------------
nc <- R$neg; e2 <- parse_est(nc$estimate)
nc$hr <- e2[,1]; nc$lo <- e2[,2]; nc$hi <- e2[,3]
nc$outcome <- factor(nc$outcome, levels = rev(nc$outcome))
FIG(ggplot(nc, aes(hr, outcome)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey45") +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.14, linewidth = 0.7,
                 colour = COL[["iih"]]) +
  geom_point(size = 3.4, colour = COL[["iih"]]) +
  scale_x_log10(breaks = c(0.25, 0.5, 1, 2, 4)) +
  labs(x = "Hazard ratio (log scale)", y = NULL,
       title = "Negative-control outcome: the specificity check",
       subtitle = "Female matched sets, 3-year horizon. Carpal tunnel has no plausible causal link to IIH.",
       caption = "The carpal tunnel hazard is null while the seizure hazard is clearly elevated. Were the design merely measuring healthcare contact, both would be elevated.") +
  theme_pub(), "F7_negative_control", 8.5, 3.8)

## --- 8. tipping point -------------------------------------------------------
tp <- R$tip
FIG(ggplot(tp, aes(pct_censored_controls_with_hidden_seizure, hr)) +
  geom_hline(yintercept = 1, linetype = 2, colour = "grey40") +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.2, fill = COL[["control"]]) +
  geom_line(linewidth = 0.8, colour = COL[["iih"]]) +
  geom_point(size = 2.4, colour = COL[["iih"]]) + scale_y_log10() +
  labs(x = "% of censored controls assumed to have an unrecorded seizure",
       y = "Hazard ratio (log scale)",
       title = "How much hidden seizure in controls would erase the association?",
       subtitle = "Tipping-point analysis; the null is reached at about 2%",
       caption = "The medication extract puts an empirical anchor on this: 2.26% of covered controls received an unambiguous ASM without an epilepsy code (see report section 8).") +
  theme_pub(), "F8_tipping_point", 7.5, 5)

## --- 9. follow-up distribution ----------------------------------------------
FIG(ggplot(d, aes(t_y, fill = cohort, colour = cohort)) +
  geom_density(alpha = 0.25, linewidth = 0.7, adjust = 1.2) +
  geom_vline(xintercept = 3, linetype = 2, colour = "grey30") +
  annotate("text", x = 3.15, y = Inf, label = "primary horizon", vjust = 1.6,
           hjust = 0, size = 3, colour = "grey30") +
  scale_fill_manual(values = COHORT_COL) + scale_colour_manual(values = COHORT_COL) +
  labs(x = "Post-washout follow-up (years)", y = "Density",
       title = "Follow-up still differs between cohorts",
       subtitle = sprintf("Median %.2f y (IIH) vs %.2f y (control)",
         stats::median(d$t_y[d$iih == 1]), stats::median(d$t_y[d$iih == 0])),
       caption = "Now measured to the last ATTENDED encounter in both arms and verifiable for every patient, but the imbalance itself remains and is why the primary estimand is truncated.") +
  theme_pub(), "F9_followup", 7.5, 4.6)

## --- 10. DAG ----------------------------------------------------------------
nodes <- data.frame(
  name = c("Obesity / BMI", "IIH", "Seizure /\nepilepsy", "Healthcare\ncontact",
           "Encephalocele", "Coding &\nascertainment", "Unmeasured\n(OSA, PCOS, HTN)"),
  x = c(0, 1.5, 3.0, 2.25, 2.25, 3.0, 0), y = c(1, 1, 1, 2, 0, 2, 0),
  kind = c("confounder", "exposure", "outcome", "bias", "mediator", "bias", "confounder"))
edges <- data.frame(
  from = c("Obesity / BMI", "Obesity / BMI", "IIH", "IIH", "Encephalocele", "IIH",
           "Healthcare\ncontact", "Healthcare\ncontact", "Coding &\nascertainment",
           "Unmeasured\n(OSA, PCOS, HTN)", "Unmeasured\n(OSA, PCOS, HTN)"),
  to = c("IIH", "Seizure /\nepilepsy", "Seizure /\nepilepsy", "Encephalocele",
         "Seizure /\nepilepsy", "Healthcare\ncontact", "Coding &\nascertainment",
         "Encephalocele", "Seizure /\nepilepsy", "IIH", "Seizure /\nepilepsy"),
  kind = c("confounding", "confounding", "CAUSAL EFFECT OF INTEREST", "mediation",
           "mediation", "bias", "bias", "bias", "bias", "confounding", "confounding"),
  curv = c(0, -0.32, 0, 0, 0, 0, 0, 0, 0, 0, -0.42))
e <- merge(merge(edges, nodes[, c("name","x","y")], by.x = "from", by.y = "name"),
           nodes[, c("name","x","y")], by.x = "to", by.y = "name",
           suffixes = c("_from", "_to"))
shr <- function(x1,y1,x2,y2,p=0.30){dx<-x2-x1;dy<-y2-y1;L<-sqrt(dx^2+dy^2)
  if(L==0) return(c(x1,y1,x2,y2)); c(x1+dx/L*p,y1+dy/L*p,x2-dx/L*p,y2-dy/L*p)}
sh <- t(mapply(shr, e$x_from, e$y_from, e$x_to, e$y_to))
e$x_from<-sh[,1]; e$y_from<-sh[,2]; e$x_to<-sh[,3]; e$y_to<-sh[,4]
FIG(ggplot() +
  lapply(split(e, seq_len(nrow(e))), function(r)
    geom_curve(data = r, aes(x = x_from, y = y_from, xend = x_to, yend = y_to,
                             colour = kind, linetype = kind),
               curvature = r$curv, linewidth = 0.6,
               arrow = arrow(length = unit(0.18, "cm"), type = "closed"))) +
  geom_label(data = nodes, aes(x, y, label = name, fill = kind), size = 2.9,
             label.r = unit(0.16, "lines"), colour = "grey10") +
  scale_colour_manual(values = c("CAUSAL EFFECT OF INTEREST" = COL[["iih"]],
    confounding = COL[["control"]], mediation = COL[["accent"]], bias = COL[["warn"]])) +
  scale_linetype_manual(values = c("CAUSAL EFFECT OF INTEREST" = 1, confounding = 1,
    mediation = 3, bias = 2), guide = "none") +
  scale_fill_manual(values = c(exposure = "#F6D9DE", outcome = "#F6D9DE",
    confounder = "#DCE6F1", mediator = "#D6ECE7", bias = "#FAF0D7"), guide = "none") +
  coord_cartesian(xlim = c(-0.45, 3.45), ylim = c(-0.45, 2.45)) +
  labs(title = "Assumed causal structure",
       subtitle = "Solid red = target effect. Dashed amber = the ascertainment paths the design must break.",
       caption = "Matching closes the obesity/age/sex path. The encephalocele mediation path (dotted) is SUSPENDED. Amber paths are addressed by the negative control, not by adjustment: conditioning on healthcare contact opens a collider path.") +
  theme_void(base_size = 10) +
  theme(legend.position = "bottom", legend.title = element_blank(),
        plot.title = element_text(face = "bold"),
        plot.caption = element_text(hjust = 0, colour = "grey35", size = 7.5)),
  "F10_dag", 8.5, 6)
}

## ---- report ----------------------------------------------------------------
tbl_md <- function(df, digits = 3) {
  df <- as.data.frame(df)
  num <- vapply(df, is.numeric, logical(1))
  df[num] <- lapply(df[num], function(x) format(round(x, digits), trim = TRUE))
  paste(c(paste("|", paste(names(df), collapse = " | "), "|"),
          paste("|", paste(rep("---", ncol(df)), collapse = " | "), "|"),
          apply(df, 1, function(r) paste("|", paste(r, collapse = " | "), "|"))),
        collapse = "\n")
}
p <- R$models[1, ]
txt <- c(
"---", "title: \"IIH and Incident Epilepsy: Final Analysis\"", "---", "",
"# Incident seizures and epilepsy after IIH", "", "### Final analysis report", "",
sprintf("**Source:** `IIH_MASTER_FINAL.xlsx` · **Cutoff:** 3 September 2026 · **Analysis date:** %s · **Seed:** %d · **R:** %s",
        format(Sys.Date()), SEED, R.version.string), "", "---", "",
"## 1. Headline", "",
sprintf("Among **%s IIH cases** and **%s matched controls**, over the three years following a symmetric 180-day washout:",
        format(sum(d$iih == 1), big.mark = ","), format(sum(d$iih == 0), big.mark = ",")),
"",
sprintf("> **Hazard ratio %s**, %d events (p < 0.001)", p$estimate, p$events),
"",
sprintf("Three-year absolute risk %.2f%% versus %.2f%%: a difference of %.2f percentage points (%.2f to %.2f), or one extra seizure per **%d** patients followed three years. Over three years, IIH patients lose an average of **%s days** to the post-seizure state.",
        R$rd$iih_risk_pct, R$rd$control_risk_pct, R$rd$estimate, R$rd$lo, R$rd$hi,
        R$rd$number_needed_to_harm, R$rmtl$estimate[3]),
"",
"**This is an association. It is not a demonstration that IIH causes epilepsy** (section 10).",
"", "---", "",
"## 2. What this workbook fixed", "",
"The earlier export had four defects that this one resolves. They are listed because each changed an estimate.",
"",
"| Defect in the earlier export | Resolution here | Effect |",
"| --- | --- | --- |",
"| 180-day washout applied to cases only; earliest case event day 183, earliest control event day 16 | Applied to **both** arms (earliest event day 183 vs 187) | Removes an artefact that biased the HR toward the null |",
"| Person-time to 2038 from scheduled future appointments | Person-time to last **attended** encounter, cutoff 3 Sep 2026 | Removes inflated denominators |",
"| Controls carried no dates; censoring unverifiable | Controls carry last encounter and death date; `censoring_verifiable` = 1 for all 11,740 | Censoring is auditable in both arms |",
"| Competing-event flag coded death for controls only | Rebuilt from death dates present in both arms | Death HR moves from an implausible 0.23 to 0.57 |",
"",
"The supplied `e3`/`t3` and `e5`/`t5` columns reproduce exactly from `t_y` and `event`; the pipeline asserts this rather than trusting it.",
"", "---", "",
"## 3. Estimand", "",
"| Element | Specification |", "| --- | --- |",
"| Population | Matchable IIH-coded patients aged 13-60 and their matched non-IIH controls |",
"| Exposure | An IIH diagnosis code, **not chart-adjudicated IIH** |",
"| Outcome | First incident coded seizure/epilepsy, identical algorithm in both arms |",
"| Time zero | Day 180 after index (index = diagnostic LP; controls inherit it) |",
"| Contrast | Cause-specific hazard ratio over 3 years |",
"| Competing event | Death (Aalen-Johansen for absolute risk) |",
"| Censoring | Event, death, or last attended encounter, whichever first |",
"", "---", "",
"## 4. Incidence and models", "", tbl_md(R$rates[, c("horizon","cohort","n","events",
  "person_years","rate_per_1000py","rate_lo","rate_hi","irr","irr_lo","irr_hi")], 2), "",
tbl_md(R$models[, c("model","n","events","estimate","p")]), "",
"### Proportional hazards", "", tbl_md(R$ph), "",
"**PH now holds at every horizon, including full follow-up.** In the earlier export it failed (p = 0.031). That violation was an artefact of contaminated person-time, not a feature of the biology — a good illustration of why the data-quality work mattered.",
"", "### Competing risk", "", tbl_md(R$cr[, c("estimand","estimate","interpretation")]), "",
"Cause-specific and subdistribution estimates are nearly identical because death is uncommon over three years. The death hazard is now 0.57 (0.34-0.95) rather than the earlier implausible 0.23, consistent with IIH being a disease of otherwise-healthier younger adults.",
"", "---", "",
"## 5. Is this just healthcare contact?", "",
"IIH patients have far more clinical contact (post-index encounters 171 vs 35), so they have more opportunity to be **detected**. Three lines of evidence:",
"", "**1. The negative control is null.**", "",
tbl_md(R$neg[, c("outcome","n","events","estimate","p")]), "",
"Carpal tunnel syndrome has no plausible causal link to IIH and is ascertained identically. If the design were measuring contact, it would be elevated. It is not. This is the single strongest argument that the result is not pure ascertainment.",
"", "**2. Risk is sustained, not front-loaded.**", "",
tbl_md(R$tsplit[, c("period","events","estimate")]), "",
"A work-up detection artefact would spike early and decay.",
"", "**3. Adjusting for contact attenuates but does not abolish it.**", "",
sprintf("Adjusted for post-index encounters: %s. Reported as a **conservative lower bound only** — post-index encounters are a consequence of both exposure and outcome, so conditioning on them is mediator adjustment and opens a collider path.",
        R$sens$estimate[grep("CONSERVATIVE", R$sens$analysis)]),
"", "---", "",
"## 6. Balance", "", tbl_md(R$bal[, c("variable","iih","control","smd","balance")]), "",
sprintf("Matched targets are balanced (propensity c-statistic %.3f). Sleep apnoea, hypertension and PCOS were **not** matching targets, remain imbalanced, and are unadjusted residual confounders.", R$cstat),
"", "---", "",
"## 6b. Multivariable Cox regression", "",
"Matching handles age, sex, BMI and index year. It does **not** handle sleep apnoea, hypertension or PCOS, which were never matching targets and remain imbalanced. This section adjusts them and reports every coefficient.",
"",
"### Smoking cannot be adjusted for", "",
"Detailed smoking status (Never / Former / Current) is recorded for IIH cases only; **all 9,122 controls are coded Unknown**. Smoking is therefore perfectly nested within the exposure - a Current or Former smoker can only be a case - so its coefficients are unidentified. Including it does not adjust for smoking; it re-estimates the exposure effect inside a case-only stratum and inflates the exposure standard error (the first fit hit separation and a singular information matrix). It is excluded from every model, and residual confounding by smoking therefore remains.",
"", "### Degrees of freedom", "",
if (!is.null(X)) tbl_md(X$epv, 1) else "",
"", "### Exposure estimate across specifications", "",
if (!is.null(X)) tbl_md(X$compare) else "",
"",
"Adjustment does not weaken the association. Adding comorbidity moves it slightly down (3.48); adding pre-index healthcare contact moves it up (4.27), which is what a confounder suppressing the estimate looks like - controls with more baseline contact are more likely to have an event detected.",
"", "### Full multivariable model", "",
if (!is.null(X)) tbl_md(X$mv[X$mv$model == "multivariable (full)",
                             c("term", "estimate", "se", "z", "p_fmt")]) else "",
"",
"No covariate other than the exposure reaches significance. **Covariate hazard ratios are adjusted associations, not causal effects of those covariates** - the model is specified to estimate the IIH effect, not theirs.",
"",
"Post-index encounters are deliberately excluded: they are a consequence of both exposure and outcome, so adjusting for them is mediator adjustment (reported separately as a conservative bound in section 9).",
"", "### Diagnostics", "",
"**Proportional hazards, per term:**", "",
if (!is.null(X)) tbl_md(X$ph) else "",
"",
"The global test is not rejected (p = 0.247), but the exposure term is borderline at three years (p = 0.040; the univariable test gives p = 0.053). It is clean at five years and over full follow-up. The hazard ratio should therefore be read as an average over the three-year window, and the restricted mean time lost (section 1) is the assumption-free companion that does not depend on proportionality at all.",
"",
"**Linearity of continuous covariates:**", "",
if (!is.null(X)) tbl_md(X$lin) else "",
"", "Linear terms are adequate; no spline is warranted.",
"", "**Collinearity and influence:**", "",
if (!is.null(X) && !is.null(X$vif)) tbl_md(X$vif) else "",
"",
if (!is.null(X)) sprintf("All variance inflation factors are near 1. The most influential single patient moves the IIH log hazard ratio by %s of its value, and no patient exceeds 10%%: the result is not driven by any individual.",
        X$infl$value[2]) else "",
"", "**Joint tests by covariate block:**", "",
if (!is.null(X)) tbl_md(X$blocks) else "",
"",
"Only the exposure block carries information. The covariates are included because they are confounders, not because they predict the outcome.",
"", "---", "",
"## 7. Effect modification", "", tbl_md(R$sub[, c("modifier","subgroup","n","events",
  "estimate","interaction_p")]), "",
"Subgroup HRs are descriptive; only the interaction p-value tests modification. The BMI interaction (p = 0.028) is the one signal worth pursuing: the association is stronger below BMI 35. Either IIH coded in a non-obese patient is more often secondary or miscoded intracranial hypertension carrying its own seizure risk, or obesity-related confounding dilutes the high-BMI stratum. This analysis cannot separate them. Post hoc.",
"", "---", "",
"## 8. What would overturn this", "", "### Tipping point", "", tbl_md(R$tip), "",
"About **2%** of censored controls carrying an unrecorded seizure would erase the association — a consequence of only 64 control events among 9,122 controls.",
"", "### An empirical anchor from the medication extract", "",
if (!is.null(M)) sprintf("%d of %d covered controls (%.2f%%) received an unambiguous antiseizure medication without ever being coded with epilepsy. These are named patients with real first-ASM dates.",
        M$n_disc, M$n_cov, 100 * M$n_disc / M$n_cov) else "Medication extract not available.",
"",
if (!is.null(M)) tbl_md(M$tip) else "", "",
if (!is.null(M)) "Assuming **every** one is a true missed seizure, the association survives (2.13, 1.55-2.94)." else "",
"",
if (!is.null(M)) tbl_md(M$tip_x) else "",
"",
if (!is.null(M)) "Extrapolating the same rate to controls with no medication data reaches the null at about half. **Both scenarios add hidden events to controls and none to cases**, because no case medications were extracted — a worst case by construction. If IIH patients have a similar ASM-without-diagnosis rate, the misclassification is non-differential and the HR barely moves." else "",
"", "### E-value", "", tbl_md(R$evalue), "",
"### Outcome misclassification", "", tbl_md(R$mis), "",
"Non-differential misclassification does not move a rate ratio. Only differential detection does.",
"", "---", "",
"## 9. Sensitivity analyses", "", tbl_md(R$sens[, c("analysis","status","n","events",
  "estimate","p")]), "", "---", "",
"## 10. Why this is not proof that IIH causes epilepsy", "",
"1. **The exposure is a code, not a diagnosis.** Friedman adjudication was dropped; among cases with a recorded opening pressure, 28% fall below the 25 cmH2O threshold.",
"2. **Confounding by indication for investigation.** Both IIH and seizure prompt neuroimaging and neurology referral; matching on age, sex and BMI does not close that path.",
"3. **Control event rates are low enough that ~2% differential under-ascertainment reverses the finding**, and the medication data show a real mechanism by which that could happen.",
"4. **Follow-up remains unequal** (median 4.9 vs 3.8 years), which is why the estimand is truncated.",
"5. **No mechanism is demonstrated.** The encephalocele hypothesis is untestable here (section 11).",
"6. **Residual confounding** by sleep apnoea (SMD 0.36), PCOS (0.17) and hypertension (0.16) is present and unadjusted.",
"",
"The defensible claim: *patients carrying an IIH diagnosis code have a substantially higher recorded rate of incident seizure and epilepsy than matched non-IIH patients, and this is not explained by healthcare contact alone.*",
"", "---", "",
"## 11. Still not possible with this workbook", "",
"| Analysis | Blocker |", "| --- | --- |",
"| Encephalocele mediation | Assessable in a small minority of cases and in **zero** controls. Not identifiable, not merely underpowered. |",
"| Severity gradient (mild/moderate/severe) | No severity variable. Shunt/stent is a post-index decision carrying immortal time. |",
"| Opening-pressure splines | Too few events to place knots; linear term reported and null. |",
"| Time-varying treatment / marginal structural model | No medication start-stop data for cases. |",
"| Acetazolamide-only restriction | No case medications, and acetazolamide appears **nowhere** in the extract. |",
"| Algorithm PPV, sensitivity, reliability kappas | No blinded review sample and no double-read overlap. |",
"| GERD negative control; male carpal tunnel | Never extracted. |",
"| Reverse cohort (epilepsy then IIH) | Requires an epilepsy-indexed cohort. |",
"", "---", "",
"## 12. Reproducibility", "",
sprintf("- Seed %d; R %s; `survival` %s", SEED, getRversion(),
        as.character(utils::packageVersion("survival"))),
"- Raw workbook opened read-only and never modified.",
"- Run `Rscript run_final.R` to regenerate every number, table and figure.",
"", "### Model formulas", "", "```",
"Primary:      coxph(Surv(t, ev) ~ iih, cluster = match_set, robust = TRUE)",
"              t = pmin(t_y, 3); t_y already runs from day 180",
"Stratified:   coxph(Surv(t, ev) ~ iih + strata(match_set))",
"IPTW:         coxph(Surv(t, ev) ~ iih, weights = stabilised trimmed IPTW,",
"                    cluster = match_set, robust = TRUE)",
"Fine-Gray:    coxph(Surv(fgstart, fgstop, fgstatus) ~ iih, weights = fgwt)",
"Propensity:   glm(iih ~ age_index + bmi_index + sex + index_year, binomial)",
"```", "")
writeLines(txt, file.path(PATH$report, "final_analysis_report.md"))
log_msg("wrote report/final_analysis_report.md")
if (requireNamespace("rmarkdown", quietly = TRUE))
  try(rmarkdown::render(file.path(PATH$report, "final_analysis_report.md"),
        output_format = rmarkdown::html_document(toc = TRUE, toc_float = TRUE,
        theme = "flatly", df_print = "kable"), quiet = TRUE), silent = TRUE)
log_msg("F4 complete")
