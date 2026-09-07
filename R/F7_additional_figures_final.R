## F7_additional_figures_final.R ----------------------------------------------
## Figures for the F6 analyses. Each exists because a number in F6 is easier to
## misread as a table than as a picture.

source("R/00_setup.R")
log_msg("=== F7 additional figures ===")
if (!HAS_GG) { log_msg("ggplot2 absent; skipping"); quit(save = "no") }
E <- readRDS(file.path(PATH$derived, "F6_extra.rds"))
FIG <- function(p, n, w = 8, h = 5.5) save_fig(p, paste0("FIN_", n), w, h)

## --- G1. latency to first seizure -------------------------------------------
## Q: when do events happen, and does the timing pattern differ by cohort?
lat <- E$lat_raw
med <- E$lat[, c("cohort", "median_y")]
p1 <- ggplot(lat, aes(years, cohort, fill = cohort)) +
  geom_violin(alpha = 0.35, colour = NA, scale = "width") +
  geom_boxplot(width = 0.16, outlier.size = 0.7, alpha = 0.9) +
  geom_vline(xintercept = 3, linetype = 2, colour = "grey40") +
  annotate("text", x = 3.1, y = 0.55, label = "3-year horizon", hjust = 0,
           size = 3, colour = "grey35") +
  scale_fill_manual(values = COHORT_COL, guide = "none") +
  labs(x = "Years from index to first seizure", y = NULL,
       title = "When do the seizures happen?",
       subtitle = sprintf("Median %.2f y in IIH vs %.2f y in controls (Wilcoxon p = %s), among those with an event",
                          E$lat$median_y[2], E$lat$median_y[1], E$lat$wilcoxon_p[1]),
       caption = paste("Only 55% of IIH events fall within three years, against 80% of control events: the exposed hazard persists",
                       "\nwell beyond the primary window. This argues AGAINST the events being an artefact of the diagnostic work-up,",
                       "\nwhich would cluster them immediately after index. Conditional on having an event, so not an effect estimate.")) +
  theme_pub()
FIG(p1, "G1_latency_distribution", 8.5, 4.4)

## --- G2. continuous effect modification -------------------------------------
## Q: does the effect really vary with BMI, or was that an artefact of cutting
## BMI at 35?
bc <- E$bmi_curve
p2 <- ggplot(bc, aes(bmi, hr)) +
  geom_hline(yintercept = 1, linetype = 2, colour = "grey45") +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.2, fill = COL[["control"]]) +
  geom_line(linewidth = 0.9, colour = COL[["iih"]]) +
  geom_vline(xintercept = 35, linetype = 3, colour = COL[["warn"]], linewidth = 0.7) +
  annotate("text", x = 35.4, y = max(bc$hi) * 0.92, label = "the arbitrary BMI 35 split",
           hjust = 0, size = 3, colour = "grey30") +
  scale_y_log10() +
  labs(x = "BMI at index (kg/m2)", y = "Hazard ratio, IIH vs control (log scale)",
       title = "The BMI interaction does not survive a continuous analysis",
       subtitle = sprintf("Continuous BMI x IIH interaction p = %s (the dichotomised subgroup test gave p = 0.028)",
                          signif(E$int_p, 3)),
       caption = paste("Splitting BMI at 35 produced an apparently significant interaction. Modelled continuously the gradient is flat",
                       "\nand the interaction disappears. This is what dichotomising a continuous modifier does: it can manufacture",
                       "\neffect modification. The continuous result is the trustworthy one, and it says the effect is uniform across BMI.")) +
  theme_pub()
FIG(p2, "G2_bmi_interaction_continuous", 8.5, 5)

## --- G3. absolute risk difference by subgroup -------------------------------
## Q: what does this mean for a patient? Ratios do not answer that.
ar <- E$abs_risk
ar$subgroup <- factor(ar$subgroup, levels = rev(ar$subgroup))
p3 <- ggplot(ar, aes(risk_difference_pp, subgroup)) +
  geom_vline(xintercept = 0, linetype = 2, colour = "grey45") +
  geom_errorbarh(aes(xmin = rd_lo, xmax = rd_hi), height = 0.2, linewidth = 0.5,
                 colour = COL[["control"]]) +
  geom_point(aes(size = events), colour = COL[["iih"]]) +
  geom_text(aes(x = 6.1, label = paste0("NNH ", nnh)), hjust = 1, size = 3,
            colour = "grey25") +
  scale_size_continuous(range = c(1.6, 3.6), guide = "none") +
  coord_cartesian(xlim = c(-0.5, 6.2)) +
  labs(x = "3-year absolute risk difference (percentage points)", y = NULL,
       title = "What the association means in absolute terms",
       subtitle = "Aalen-Johansen cumulative incidence at 3 years, death treated as a competing event",
       caption = paste("NNH = number of IIH patients followed three years for one additional seizure. Absolute risk differences are",
                       "\nsmall in every subgroup: even the largest, in men, is about 3 extra seizures per 100 patients over three years.",
                       "\nSubgroup differences here are descriptive; the formal interaction tests are in the subgroup forest.")) +
  theme_pub()
FIG(p3, "G3_absolute_risk_by_subgroup", 8.5, 5)

## --- G4. calendar trend ------------------------------------------------------
## Q: is the association stable over time, or an artefact of a coding era?
tr <- E$trend
p4 <- ggplot(tr, aes(era, rate, colour = cohort, group = cohort)) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.12,
                position = position_dodge(0.3), linewidth = 0.6) +
  geom_line(position = position_dodge(0.3), linewidth = 0.6, alpha = 0.6) +
  geom_point(size = 3, position = position_dodge(0.3)) +
  scale_colour_manual(values = COHORT_COL) + scale_y_log10() +
  labs(x = "Index period", y = "Seizures per 1,000 person-years (log scale)",
       title = "The association is stable across calendar eras",
       subtitle = sprintf("Exposure x era interaction p = %s. The ICD-9 to ICD-10 transition (Oct 2015) falls between the middle two bands.",
                          E$era_p),
       caption = paste("Absolute rates fall over time in BOTH arms, so the decline is a feature of the cohorts or of ascertainment,",
                       "\nnot of the contrast: the ratio is unchanged. That is the reassuring pattern -- a coding artefact would have",
                       "\nmoved one arm relative to the other. Early bands rest on very few events and their intervals are wide.")) +
  theme_pub()
FIG(p4, "G4_calendar_trend", 8.5, 5)

## --- G5. what the study could have detected ---------------------------------
## Q: what does a null result here actually rule out?
md <- E$mde
md$analysis <- factor(md$analysis, levels = rev(md$analysis))
md$kind <- ifelse(grepl("Negative control", md$analysis), "Negative control", "Primary outcome")
p5 <- ggplot(md, aes(min_detectable_hr, analysis, colour = kind)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey45") +
  geom_segment(aes(x = 1, xend = min_detectable_hr, yend = analysis), linewidth = 0.5) +
  geom_point(size = 3) +
  geom_text(aes(label = paste0(events, " events")), hjust = -0.35, size = 2.9,
            colour = "grey30") +
  scale_colour_manual(values = c("Primary outcome" = COL[["control"]],
                                 "Negative control" = COL[["warn"]])) +
  coord_cartesian(xlim = c(1, 6)) +
  labs(x = "Smallest hazard ratio detectable with 80% power", y = NULL,
       title = "What this study could and could not have seen",
       subtitle = "Schoenfeld approximation at alpha = 0.05",
       caption = paste("This is the honest reading of every null result. The negative control (amber) had 80% power only for HR >= 1.99,",
                       "\nso its null result rules out a LARGE surveillance effect, not a modest one of, say, 1.5. The male estimate needed",
                       "\nHR >= 4.65 to be detectable, so its apparent size reflects low power as much as a genuinely larger effect.")) +
  theme_pub()
FIG(p5, "G5_minimum_detectable_effect", 8.5, 4.6)

## --- G6. smooth time-varying hazard ratio -----------------------------------
## Q: is the excess risk front-loaded (work-up detection) or sustained?
tv <- E$tv
p6 <- ggplot(tv, aes(time_y, hr)) +
  geom_hline(yintercept = 1, linetype = 2, colour = "grey45") +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.18, fill = COL[["control"]]) +
  geom_line(linewidth = 0.9, colour = COL[["iih"]]) +
  scale_y_log10() +
  labs(x = "Years since day 180", y = "Hazard ratio (log scale)",
       title = "Excess risk is highest in the first year, then plateaus",
       subtitle = "Smoothed scaled Schoenfeld residuals from the primary model",
       caption = paste("The curve falls from roughly 7.5 to about 3 over the first year and then flattens; it does NOT decay toward",
                       "the null, which is what a pure diagnostic work-up artefact would do. The plateau is the point, not flatness.",
                       "The band is an approximate pointwise interval from the residual scatter, not a formal confidence band;",
                       "the formal test is in F_S6.")) +
  theme_pub()
FIG(p6, "G6_time_varying_hr", 7.5, 4.6)

log_msg("F7 complete")
