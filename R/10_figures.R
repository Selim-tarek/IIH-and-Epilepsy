## 10_figures.R ---------------------------------------------------------------
## Every figure answers one stated question. Palette is grayscale-separable
## (the two cohort colours differ in lightness as well as hue).

source("R/00_setup.R")
log_msg("=== 10 figures ===")
if (!HAS_GG) { log_msg("ggplot2 unavailable; skipping figures"); quit(save = "no") }

a   <- readRDS(file.path(PATH$derived, "05_analytic.rds"))
tr  <- readRDS(file.path(PATH$derived, "05_truncate_fn.rds"))
pr  <- readRDS(file.path(PATH$derived, "06_primary.rds"))
sec <- readRDS(file.path(PATH$derived, "07_secondary.rds"))
sn  <- readRDS(file.path(PATH$derived, "08_sens.rds"))
bal <- readRDS(file.path(PATH$derived, "04_balance.rds"))
d   <- readRDS(file.path(PATH$derived, "01_typed.rds"))

## --- F1. cohort flow (STROBE/RECORD) ---------------------------------------
## Q: how did 3,601 coded IIH patients become the analysed cohort?
flow <- data.frame(
  y = 6:1,
  lab = c(sprintf("IIH-coded patients supplied\nafter upstream exclusions (n = %d)", sum(d$iih == 1)),
          sprintf("Seizure at/within 180 d of index\n(presenting, analysed separately): n = %d",
                  sum(d$presenting_seizure == 1, na.rm = TRUE)),
          sprintf("No matchable control found: n = %d", sum(d$iih == 1 & !d$in_matched)),
          sprintf("IIH cases in matched cohort (n = %d)", sum(d$iih == 1 & d$in_matched)),
          sprintf("Matched non-IIH controls (n = %d)\n1:4 attempted; mean achieved 3.57", sum(d$iih == 0 & d$in_matched)),
          sprintf("Analysed: %d patients, %d incident seizures at 3 y",
                  sum(d$in_matched), sum(pr$s3$ev))),
  kind = c("main", "side", "side", "main", "main", "main"))
p1 <- ggplot(flow, aes(x = 1, y = y)) +
  geom_tile(aes(fill = kind), width = 0.9, height = 0.72, colour = "grey30") +
  geom_text(aes(label = lab), size = 3.1, lineheight = 1.05) +
  scale_fill_manual(values = c(main = "#EAF0F6", side = "#F5EDE4"), guide = "none") +
  scale_y_continuous(expand = expansion(add = 0.5)) +
  labs(title = "Cohort construction",
       subtitle = "Protocol v2.0. Upstream exclusions were applied before this export and cannot be itemised here.",
       caption = "Shaded (tan) boxes are patients removed from the comparative analysis.") +
  theme_void(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        plot.caption = element_text(hjust = 0, colour = "grey35", size = 8))
save_fig(p1, "F1_cohort_flow", w = 7.5, h = 6)

## --- F2. covariate balance (Love plot) --------------------------------------
## Q: did the match achieve balance, and on what did it NOT?
b <- bal[!is.na(bal$smd), ]
b$post <- grepl("POST-EXPOSURE", b$variable)
b$variable <- sub(" \\(POST-EXPOSURE\\)", "", b$variable)
b$variable <- factor(b$variable, levels = b$variable[order(abs(b$smd))])
p2 <- ggplot(b, aes(x = abs(smd), y = variable, colour = post)) +
  geom_vline(xintercept = 0.1, linetype = 2, colour = "grey45") +
  geom_segment(aes(x = 0, xend = abs(smd), yend = variable), linewidth = 0.4) +
  geom_point(size = 2.8) +
  scale_colour_manual(values = c(`FALSE` = COL[["control"]], `TRUE` = COL[["warn"]]),
                      labels = c("Baseline covariate", "Post-index (imbalance expected)")) +
  labs(x = "|Standardised mean difference|", y = NULL,
       title = "Covariate balance after matching",
       subtitle = "Dashed line = 0.1. Age, BMI, sex and index year are balanced; comorbidity and healthcare contact are not.",
       caption = paste("Pre-index encounters remain strongly imbalanced (SMD 0.67) despite the v2.0 rule requiring",
                       ">=1 control encounter in the prior year. Post-index variables are consequences of exposure.")) +
  theme_pub()
save_fig(p2, "F2_balance_love_plot", w = 8.5, h = 5)

## --- F3. incidence rates with exact Poisson CIs -----------------------------
## Q: what is the absolute rate in each arm, and how does it depend on horizon?
r <- pr$rates
r$horizon <- factor(r$horizon, levels = unique(r$horizon))
p3 <- ggplot(r, aes(x = horizon, y = rate_per_1000py, colour = cohort, group = cohort)) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.12,
                position = position_dodge(0.35), linewidth = 0.6) +
  geom_point(size = 3, position = position_dodge(0.35)) +
  scale_colour_manual(values = COHORT_COL) +
  labs(x = NULL, y = "Incident seizures per 1,000 person-years",
       title = "Incidence of first seizure or epilepsy",
       subtitle = "Exact (Garwood) Poisson 95% confidence intervals",
       caption = paste("The control rate FALLS as the horizon lengthens while the case rate is stable, because",
                       "\ncontrol person-time accrues without events. Full follow-up is the least reliable column",
                       "\n(case person-time includes impossible encounter dates: audit C1).")) +
  theme_pub()
save_fig(p3, "F3_incidence_rates", w = 7.5, h = 5)

## --- F4. cumulative incidence with death as a competing event ---------------
## Q: what is the absolute 3-year risk? Aalen-Johansen, NOT 1 - Kaplan-Meier.
s3 <- pr$s3
s3$evf <- factor(s3$evc, levels = 0:2, labels = c("censored", "seizure", "death"))
aj <- survival::survfit(Surv(t, evf) ~ iih, data = s3, id = seq_len(nrow(s3)))
grid <- seq(0, 3, by = 0.02)
sm <- summary(aj, times = grid, extend = TRUE)
k <- which(aj$states == "seizure"); kd <- which(aj$states == "death")
cifd <- rbind(
  data.frame(t = sm$time, cohort = ifelse(grepl("iih=1", as.character(sm$strata)), "IIH", "Non-IIH control"),
             pct = 100 * sm$pstate[, k], lo = 100 * sm$lower[, k], hi = 100 * sm$upper[, k],
             event = "Seizure or epilepsy"),
  data.frame(t = sm$time, cohort = ifelse(grepl("iih=1", as.character(sm$strata)), "IIH", "Non-IIH control"),
             pct = 100 * sm$pstate[, kd], lo = NA, hi = NA, event = "Death (competing event)"))
p4 <- ggplot(cifd, aes(t, pct, colour = cohort, fill = cohort)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.15, colour = NA) +
  geom_step(linewidth = 0.8) +
  facet_wrap(~event, scales = "free_y") +
  scale_colour_manual(values = COHORT_COL) + scale_fill_manual(values = COHORT_COL) +
  labs(x = "Years since index date", y = "Cumulative incidence (%)",
       title = "Cumulative incidence of seizure, with death as a competing event",
       subtitle = sprintf("Aalen-Johansen. 3-year risk: %.2f%% (IIH) vs %.2f%% (control); difference %.2f pp, NNH %d",
                          pr$rd$iih_risk_pct, pr$rd$control_risk_pct, pr$rd$estimate,
                          pr$rd$number_needed_to_harm),
       caption = paste("1 - Kaplan-Meier is NOT shown: it would overstate absolute risk by treating the deceased as still at risk.",
                       "\nNote the death panel: mortality is markedly LOWER in the IIH arm, which may be real or may reflect",
                       "\ndifferential death ascertainment (controls carry no date fields at all).")) +
  theme_pub()
save_fig(p4, "F4_cumulative_incidence", w = 9, h = 5)

## --- F5. forest plot of the primary and all sensitivity analyses ------------
## Q: how robust is the estimate to specification?
parse_est <- function(x) {
  m <- regmatches(x, regexec("^([0-9.]+) \\(([0-9.]+) to ([0-9.]+)\\)$", x))
  t(vapply(m, function(z) if (length(z) == 4) as.numeric(z[2:4]) else rep(NA_real_, 3),
           numeric(3)))
}
fs <- sn$sens
est <- parse_est(fs$estimate)
fs$hr <- est[, 1]; fs$lo <- est[, 2]; fs$hi <- est[, 3]
fs <- fs[!is.na(fs$hr), ]
fs$analysis <- factor(fs$analysis, levels = rev(fs$analysis))
fs$flag <- ifelse(grepl("CORRECTED PRIMARY", fs$analysis), "primary",
           ifelse(grepl("CONSERVATIVE BOUND", fs$analysis), "bound", "other"))
p5 <- ggplot(fs, aes(hr, analysis, colour = flag)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey45") +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.22, linewidth = 0.5) +
  geom_point(aes(size = events)) +
  scale_x_log10(breaks = c(0.5, 1, 2, 3, 5, 10, 20)) +
  scale_size_continuous(range = c(1.4, 3.6), guide = "none") +
  scale_colour_manual(values = c(primary = COL[["iih"]], bound = COL[["warn"]],
                                 other = COL[["control"]]),
                      labels = c("Mediator-adjusted bound", "Other specification", "Corrected primary")) +
  labs(x = "Hazard ratio (log scale)", y = NULL,
       title = "Sensitivity of the IIH-seizure association to specification",
       subtitle = "Point size is proportional to event count; 3-year horizon unless named otherwise",
       caption = paste("The mediator-adjusted estimate (amber) is a conservative LOWER BOUND, not a causal estimate:",
                       "\npost-index encounters are a consequence of both the exposure and the outcome (protocol section 5.3).")) +
  theme_pub()
save_fig(p5, "F5_forest_sensitivity", w = 11, h = 6.5)

## --- F6. hazard ratio by time -----------------------------------------------
## Q: is the excess risk early (suggesting detection at work-up) or sustained?
ts <- sec$tsplit
ts <- ts[is.finite(ts$hr) & ts$hr > 0, ]
p6 <- ggplot(ts, aes(x = period, y = hr)) +
  geom_hline(yintercept = 1, linetype = 2, colour = "grey45") +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.12, linewidth = 0.6,
                colour = COL[["iih"]]) +
  geom_point(size = 3.2, colour = COL[["iih"]]) +
  geom_text(aes(label = paste0(events, " events")), vjust = -1.6, size = 3, colour = "grey30") +
  scale_y_log10() +
  labs(x = NULL, y = "Hazard ratio (log scale)",
       title = "Timing of the excess seizure risk",
       subtitle = sprintf("Time-split Cox model. Test for change over time: p = %s",
                          ifelse(is.na(sec$int_p), "not estimable", format(sec$int_p))),
       caption = paste("The 0-6 month window is omitted: NO IIH case can have an event there, because the protocol's",
                       "\n180-day presenting-seizure rule was applied to cases only. The risk is sustained rather than",
                       "\nconcentrated at diagnosis, which argues against pure work-up detection.")) +
  theme_pub()
save_fig(p6, "F6_hazard_by_time", w = 7.5, h = 5)

## --- F7. follow-up and censoring by cohort ----------------------------------
## Q: is follow-up comparable? (It is not, and this is central.)
fu <- a[, c("cohort", "followup_years")]
p7 <- ggplot(fu, aes(followup_years, fill = cohort, colour = cohort)) +
  geom_density(alpha = 0.25, linewidth = 0.7, adjust = 1.2) +
  geom_vline(xintercept = 3, linetype = 2, colour = "grey30") +
  annotate("text", x = 3.15, y = Inf, label = "primary horizon", vjust = 1.6,
           hjust = 0, size = 3, colour = "grey30") +
  scale_fill_manual(values = COHORT_COL) + scale_colour_manual(values = COHORT_COL) +
  labs(x = "Follow-up (years)", y = "Density",
       title = "Follow-up duration differs systematically between cohorts",
       subtitle = sprintf("Median %.2f y (IIH) vs %.2f y (control)",
                          median(a$followup_years[a$iih == 1]), median(a$followup_years[a$iih == 0])),
       caption = paste("Longer exposed follow-up combined with contact-dependent outcome ascertainment is the",
                       "\nclassic differential-surveillance pattern, and is the reason the primary estimand is truncated.")) +
  theme_pub()
save_fig(p7, "F7_followup_distribution", w = 7.5, h = 4.6)

## --- F8. missingness, separating absence from clinical negativity -----------
## Q: which variables are unavailable, and is the absence structural?
dict <- readRDS(file.path(PATH$derived, "01_dictionary.rds"))
mm <- dict[, c("variable", "n_blank_structural", "n_code_99_unknown", "n_code_88_na")]
mm$observed <- nrow(d) - rowSums(mm[, -1])
ml <- do.call(rbind, lapply(c("observed", "n_code_99_unknown", "n_code_88_na",
                              "n_blank_structural"), function(k)
  data.frame(variable = mm$variable, kind = k, n = mm[[k]])))
ml$kind <- factor(ml$kind,
  levels = c("observed", "n_code_99_unknown", "n_code_88_na", "n_blank_structural"),
  labels = c("Observed value", "99: unknown after searching",
             "88: not applicable / not assessable", "Blank: never extracted"))
ord <- mm$variable[order(mm$observed)]
ml$variable <- factor(ml$variable, levels = ord)
p8 <- ggplot(ml, aes(n, variable, fill = kind)) +
  geom_col(width = 0.8) +
  scale_fill_manual(values = c("Observed value" = "grey80",
                               "99: unknown after searching" = COL[["control"]],
                               "88: not applicable / not assessable" = COL[["warn"]],
                               "Blank: never extracted" = COL[["iih"]])) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.02))) +
  labs(x = "Patients", y = NULL, title = "Three kinds of absence, kept apart",
       subtitle = "Only the grey segment is data. The three coloured segments must never be imputed as negatives.",
       caption = paste("Red = the variable was never extracted for one whole cohort (all imaging and EEG in controls;",
                       "\nall dates and race in cases). Amber = the scan or test could not answer the question:",
                       "\nan unassessable scan is NOT a negative scan.")) +
  theme_pub(base_size = 8) + theme(legend.position = "right")
save_fig(p8, "F8_missingness", w = 9.5, h = 9)

## --- F9. tipping point ------------------------------------------------------
## Q: how much unrecorded control seizure would erase the association?
tp <- sn$tip
p9 <- ggplot(tp, aes(pct_censored_controls_with_hidden_seizure, hr)) +
  geom_hline(yintercept = 1, linetype = 2, colour = "grey40") +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.2, fill = COL[["control"]]) +
  geom_line(linewidth = 0.8, colour = COL[["iih"]]) +
  geom_point(size = 2.4, colour = COL[["iih"]]) +
  scale_y_log10() +
  labs(x = "% of censored controls assumed to have an unrecorded seizure",
       y = "Hazard ratio (log scale)",
       title = "The association is fragile to unrecorded seizures in controls",
       subtitle = "Tipping-point analysis: the null is reached at roughly 1% hidden events among censored controls",
       caption = paste("This is the study's most serious quantitative vulnerability, and it is the direct consequence of a",
                       "\nvery low control event count (83 events among 9,742 controls). The null negative-control result",
                       "\n(carpal tunnel HR 0.89) is the main evidence AGAINST such gross differential under-ascertainment.")) +
  theme_pub()
save_fig(p9, "F9_tipping_point", w = 7.5, h = 5)

## --- F10. DAG ---------------------------------------------------------------
## Q: what is the assumed causal structure, including the bias paths?
nodes <- data.frame(
  name = c("Obesity / BMI", "IIH", "Seizure /\nepilepsy", "Healthcare\ncontact",
           "Encephalocele", "Coding &\nascertainment", "Unmeasured\n(OSA, PCOS, HTN)"),
  x = c(0.0, 1.5, 3.0, 2.25, 2.25, 3.0, 0.0),
  y = c(1.0, 1.0, 1.0, 2.0, 0.0, 2.0, 0.0),
  kind = c("confounder", "exposure", "outcome", "bias", "mediator", "bias", "confounder"))
edges <- data.frame(
  from = c("Obesity / BMI", "Obesity / BMI", "IIH", "IIH", "Encephalocele",
           "IIH", "Healthcare\ncontact", "Healthcare\ncontact", "Coding &\nascertainment",
           "Unmeasured\n(OSA, PCOS, HTN)", "Unmeasured\n(OSA, PCOS, HTN)"),
  to   = c("IIH", "Seizure /\nepilepsy", "Seizure /\nepilepsy", "Encephalocele",
           "Seizure /\nepilepsy", "Healthcare\ncontact", "Coding &\nascertainment",
           "Encephalocele", "Seizure /\nepilepsy",
           "IIH", "Seizure /\nepilepsy"),
  kind = c("confounding", "confounding", "CAUSAL EFFECT OF INTEREST", "mediation",
           "mediation", "bias", "bias", "bias", "bias", "confounding", "confounding"),
  curv = c(0, -0.32, 0, 0, 0, 0, 0, 0, 0, 0, -0.42))
e <- merge(merge(edges, nodes[, c("name", "x", "y")], by.x = "from", by.y = "name"),
           nodes[, c("name", "x", "y")], by.x = "to", by.y = "name",
           suffixes = c("_from", "_to"))
## Shorten each edge at both ends so the arrowhead lands outside the node label.
shrink <- function(x1, y1, x2, y2, pad = 0.30) {
  dx <- x2 - x1; dy <- y2 - y1; L <- sqrt(dx^2 + dy^2)
  if (L == 0) return(c(x1, y1, x2, y2))
  c(x1 + dx / L * pad, y1 + dy / L * pad, x2 - dx / L * pad, y2 - dy / L * pad)
}
sh <- t(mapply(shrink, e$x_from, e$y_from, e$x_to, e$y_to))
e$x_from <- sh[, 1]; e$y_from <- sh[, 2]; e$x_to <- sh[, 3]; e$y_to <- sh[, 4]

p10 <- ggplot() +
  lapply(split(e, seq_len(nrow(e))), function(r)
    geom_curve(data = r, aes(x = x_from, y = y_from, xend = x_to, yend = y_to,
                             colour = kind, linetype = kind),
               curvature = r$curv, linewidth = 0.6,
               arrow = arrow(length = unit(0.18, "cm"), type = "closed"))) +
  geom_label(data = nodes, aes(x, y, label = name, fill = kind),
             size = 2.9, label.r = unit(0.16, "lines"), colour = "grey10") +
  scale_colour_manual(values = c("CAUSAL EFFECT OF INTEREST" = COL[["iih"]],
                                 confounding = COL[["control"]],
                                 mediation = COL[["accent"]], bias = COL[["warn"]])) +
  scale_linetype_manual(values = c("CAUSAL EFFECT OF INTEREST" = 1, confounding = 1,
                                   mediation = 3, bias = 2), guide = "none") +
  scale_fill_manual(values = c(exposure = "#F6D9DE", outcome = "#F6D9DE",
                               confounder = "#DCE6F1", mediator = "#D6ECE7",
                               bias = "#FAF0D7"), guide = "none") +
  coord_cartesian(xlim = c(-0.45, 3.45), ylim = c(-0.45, 2.45)) +
  labs(title = "Assumed causal structure",
       subtitle = "Solid red = target effect. Dashed amber = the surveillance/ascertainment paths the design must break.",
       caption = paste("Matching closes the obesity/age/sex path. The encephalocele mediation path (dotted) is SUSPENDED:",
                       "\nthe mediator is measured in 2.5% of cases and 0% of controls. The amber paths are addressed by the",
                       "\nnegative-control outcome, not by adjustment -- conditioning on healthcare contact opens a collider path.")) +
  theme_void(base_size = 10) +
  theme(legend.position = "bottom", legend.title = element_blank(),
        plot.title = element_text(face = "bold"),
        plot.caption = element_text(hjust = 0, colour = "grey35", size = 7.5))
save_fig(p10, "F10_dag", w = 8.5, h = 6)

## --- F11. negative control side by side -------------------------------------
## Q: is the design measuring disease, or just healthcare contact?
nc <- sec$neg
est <- parse_est(nc$estimate)
nc$hr <- est[, 1]; nc$lo <- est[, 2]; nc$hi <- est[, 3]
nc$outcome <- factor(nc$outcome, levels = rev(nc$outcome))
p11 <- ggplot(nc, aes(hr, outcome)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey45") +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.14, linewidth = 0.7,
                 colour = COL[["iih"]]) +
  geom_point(size = 3.4, colour = COL[["iih"]]) +
  scale_x_log10(breaks = c(0.25, 0.5, 1, 2, 4)) +
  labs(x = "Hazard ratio (log scale)", y = NULL,
       title = "Negative-control outcome: the specificity check",
       subtitle = "Female matched sets, 3-year horizon. Carpal tunnel has no plausible causal link to IIH.",
       caption = paste("The carpal tunnel hazard is null while the seizure hazard is clearly elevated. If the design were",
                       "\nsimply measuring greater healthcare contact among IIH patients, BOTH would be elevated.",
                       "\nThis is the strongest single piece of evidence that the primary result is not pure ascertainment.")) +
  theme_pub()
save_fig(p11, "F11_negative_control", w = 8, h = 3.8)

log_msg("10 complete")
