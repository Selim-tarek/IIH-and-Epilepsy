## Z7_publication_figures.R ---------------------------------------------------
## Publication-grade figures for Epilepsia submission.
## Each figure written as: vector PDF (submission), 600-dpi TIFF with LZW
## (Epilepsia's preferred raster), and 600-dpi PNG (preview).
##
## Palette validated with the dataviz validator: #2a78d6 / #eb6834 passes
## lightness band, chroma floor, CVD separation (worst adjacent dE 24.7 protan),
## normal-vision floor (33.6) and contrast vs surface. Identity is never carried
## by colour alone: every series is also direct-labelled or line-typed, so the
## figures survive greyscale printing.

source("R/00_setup.R")
suppressMessages({library(survival); library(ggplot2)})
log_msg("=== Z7 publication figures ===")

IIH_COL <- "#2a78d6"; CTL_COL <- "#eb6834"; INK <- "#1a1a1a"; MUTED <- "#595959"
OUT <- "outputs/figures_publication"; dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

th <- function(base = 9) {
  theme_classic(base_size = base, base_family = "sans") +
    theme(axis.text  = element_text(colour = INK, size = base),
          axis.title = element_text(colour = INK, size = base + 0.5),
          axis.line  = element_line(colour = "#404040", linewidth = 0.35),
          axis.ticks = element_line(colour = "#404040", linewidth = 0.35),
          plot.title = element_text(colour = INK, size = base + 1.5, face = "bold", hjust = 0),
          plot.subtitle = element_text(colour = MUTED, size = base - 0.5, hjust = 0),
          plot.caption  = element_text(colour = MUTED, size = base - 1.5, hjust = 0),
          legend.position = "none",
          panel.grid.major.y = element_line(colour = "#ebebeb", linewidth = 0.3),
          plot.margin = margin(6, 10, 6, 6))
}

## Epilepsia column widths: single 85 mm, double 180 mm.
save3 <- function(p, name, w_mm, h_mm) {
  w <- w_mm / 25.4; h <- h_mm / 25.4
  ggsave(file.path(OUT, paste0(name, ".pdf")), p, width = w, height = h,
         units = "in", device = grDevices::cairo_pdf)
  ggsave(file.path(OUT, paste0(name, ".tiff")), p, width = w, height = h,
         units = "in", dpi = 600, compression = "lzw")
  ggsave(file.path(OUT, paste0(name, ".png")), p, width = w, height = h,
         units = "in", dpi = 600)
  log_msg("wrote ", name, " (pdf / tiff 600dpi / png 600dpi), ", w_mm, "x", h_mm, " mm")
}

V <- readRDS(file.path(PATH$derived, "K15_final_visits.rds")); a <- V$a

## ---- Figure 1: cumulative incidence ----------------------------------------
a$cr <- factor(ifelse(a$ev == 1, "event", ifelse(a$died %in% c(1, TRUE), "death", "censor")),
               levels = c("censor", "event", "death"))
sf <- survfit(Surv(t, cr) ~ iih, data = a)
sm <- summary(sf, times = seq(0, 3, by = 1/24), extend = TRUE)
## pstate carries no dimnames; locate the event column by its state position.
ev_col <- match("event", sf$states)
assert(!is.na(ev_col), "event state not found in survfit")
st <- data.frame(time = sm$time, cif = sm$pstate[, ev_col],
                 lo = pmax(0, sm$lower[, ev_col]), hi = sm$upper[, ev_col],
                 arm = ifelse(grepl("iih=1", sm$strata), "IIH", "Comparator"),
                 stringsAsFactors = FALSE)
st$cif <- 100 * st$cif; st$lo <- 100 * st$lo; st$hi <- 100 * st$hi
## Endpoint labels use the reported 3-year cumulative incidence (K_T38), not the
## last step of the interpolated curve, so figure and text cannot disagree.
cif3 <- utils::read.csv(file.path(PATH$tables, "K_T38_FINAL_results_visits.csv"),
                        stringsAsFactors = FALSE)
lab <- do.call(rbind, lapply(split(st, st$arm), function(z) z[which.max(z$time), ]))
lab$cif <- ifelse(lab$arm == "IIH", cif3$cif3_iih[1], cif3$cif3_ctl[1])

f1 <- ggplot(st, aes(time, cif, colour = arm, fill = arm)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.13, colour = NA) +
  geom_step(aes(linetype = arm), linewidth = 0.7) +
  geom_text(data = lab, aes(label = sprintf("%s  %.2f%%", arm, cif)),
            hjust = 1, vjust = -0.9, size = 2.9, fontface = "bold", show.legend = FALSE) +
  scale_colour_manual(values = c(IIH = IIH_COL, Comparator = CTL_COL)) +
  scale_fill_manual(values   = c(IIH = IIH_COL, Comparator = CTL_COL)) +
  scale_linetype_manual(values = c(IIH = "solid", Comparator = "22")) +
  scale_x_continuous("Years after the 180-day washout", breaks = 0:3, expand = c(0.01, 0)) +
  scale_y_continuous("Cumulative incidence of seizure or epilepsy (%)",
                     limits = c(0, 5), breaks = seq(0, 5, 1), expand = c(0, 0)) +
  labs(title = "Cumulative incidence of incident seizure or epilepsy",
       subtitle = "Aalen-Johansen estimator with death as a competing event; shaded bands are 95% CIs",
       caption = "HR 2.28 (95% CI 1.62 to 3.22), p < 0.001. Numbers at risk are given in Table 2.") +
  th()
save3(f1, "Figure_1_cumulative_incidence", 140, 100)

## ---- Figure 2: forest of specifications ------------------------------------
rd <- function(n) utils::read.csv(file.path(PATH$tables, paste0(n, ".csv")),
                                  check.names = FALSE, stringsAsFactors = FALSE)
pv <- rd("K_T38_FINAL_results_visits"); pa <- rd("K_T38_FINAL_results_all")
zc <- rd("Z_T01_complete_sets");        lm <- rd("SAP_T3b_landmark")
cr <- rd("SAP_T4_competing_risks");     pr <- rd("SAP_T6_propensity")
cm <- rd("Z_T04_comorbidity_adjusted"); ag <- rd("Z_T07_age18_sensitivity")
par3 <- function(x) as.numeric(regmatches(x, gregexpr("[0-9.]+", x))[[1]])[1:3]

rows <- list(
  c("Primary analysis",                              pv$HR[1]),
  c("Codes only, medication criterion removed",      pv$HR[2]),
  c("Epilepsy-specific codes only (G40/345)",        pv$HR[3]),
  c("Opening pressure 25 cmH2O or higher",         pv$HR[4]),
  c("All encounter rows counted as contact",         pa$HR[1]),
  c("Complete matched sets only",                    zc$HR[2]),
  c("Age 18 or older at index",                        ag$HR[2]),
  c("Landmark: first 30 days excluded",              lm$HR[2]),
  c("Landmark: first 90 days excluded",              lm$HR[3]),
  c("Landmark: first 180 days excluded",             lm$HR[4]),
  c("Fine-Gray subdistribution hazard",         cr$estimate[2]),
  c("Overlap-weighted",                              pr$value[7]),
  c("Adjusted for OSA, hypertension, PCOS",          cm$HR[5]))
fd <- do.call(rbind, lapply(rows, function(r) {
  v <- par3(r[2]); data.frame(label = r[1], hr = v[1], lo = v[2], hi = v[3],
                              stringsAsFactors = FALSE) }))
fd$label <- factor(fd$label, levels = rev(fd$label))
fd$primary <- fd$label == "Primary analysis"

f2 <- ggplot(fd, aes(hr, label)) +
  geom_vline(xintercept = 1, colour = "#9a9a9a", linewidth = 0.4) +
  geom_vline(xintercept = fd$hr[1], colour = IIH_COL, linewidth = 0.4, linetype = "22", alpha = 0.5) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0, linewidth = 0.55, colour = INK) +
  geom_point(aes(size = primary, shape = primary), fill = IIH_COL, colour = IIH_COL) +
  geom_text(aes(x = 6.4, label = sprintf("%.2f (%.2f to %.2f)", hr, lo, hi)),
            hjust = 1, size = 2.55, colour = INK) +
  scale_shape_manual(values = c(`FALSE` = 21, `TRUE` = 23)) +
  scale_size_manual(values  = c(`FALSE` = 1.7, `TRUE` = 2.6)) +
  scale_x_continuous("Hazard ratio (95% CI), log scale", trans = "log",
                     breaks = c(0.8, 1, 1.5, 2, 3, 4), limits = c(0.8, 6.6)) +
  labs(y = NULL, title = "Hazard ratio across specifications",
       subtitle = "Diamond marks the primary analysis; dashed line its point estimate",
       caption = "Point estimates range from 1.93 to 2.79; every confidence interval excludes 1.") +
  th() + theme(panel.grid.major.y = element_blank(),
               panel.grid.major.x = element_line(colour = "#ebebeb", linewidth = 0.3))
save3(f2, "Figure_2_forest_specifications", 180, 115)

## ---- Figure 3: detection assessment, two panels ----------------------------
## 3A calibration; 3B direction of movement under healthcare-seeking adjustment.
nc1 <- rd("K_T42_negative_controls"); nc2 <- rd("K_T45_negative_controls_v2")
c1 <- data.frame(outcome = nc1$outcome, br = as.numeric(nc1$baseline_ratio),
                 hr = suppressWarnings(as.numeric(nc1$hr)), stringsAsFactors = FALSE)
c2 <- data.frame(outcome = nc2$outcome, br = as.numeric(nc2$baseline_ratio),
                 hr = as.numeric(nc2$hr), stringsAsFactors = FALSE)
nc <- rbind(c1, c2); nc <- nc[!is.na(nc$hr) & !is.na(nc$br), ]
fitc <- lm(log(hr) ~ log(br), data = nc)
gx <- exp(seq(log(min(nc$br) * 0.85), log(max(nc$br) * 1.1), length.out = 80))
pp <- as.data.frame(predict(fitc, newdata = data.frame(br = gx), interval = "prediction"))
band <- data.frame(br = gx, fit = exp(pp$fit), lo = exp(pp$lwr), hi = exp(pp$upr))
p0 <- exp(predict(fitc, newdata = data.frame(br = 1), interval = "prediction"))

f3a <- ggplot() +
  geom_ribbon(data = band, aes(br, ymin = lo, ymax = hi), fill = "#c9d7ea", alpha = 0.45) +
  geom_line(data = band, aes(br, fit), colour = "#4a4a4a", linewidth = 0.55) +
  geom_hline(yintercept = 1, colour = "#9a9a9a", linewidth = 0.35) +
  geom_point(data = nc, aes(br, hr), shape = 21, size = 2.1,
             fill = CTL_COL, colour = "white", stroke = 0.45) +
  geom_point(aes(x = 1, y = 2.28), shape = 23, size = 3.1,
             fill = IIH_COL, colour = "white", stroke = 0.5) +
  annotate("text", x = 1.02, y = 2.28, label = "Seizure or epilepsy\n2.28", hjust = 0,
           vjust = -0.25, size = 2.6, fontface = "bold", colour = IIH_COL) +
  annotate("text", x = 1.02, y = p0[1], label = sprintf("Predicted detection-only\n%.2f (%.2f to %.2f)",
           p0[1], p0[2], p0[3]), hjust = 0, vjust = 1.25, size = 2.4, colour = "#404040") +
  annotate("point", x = 1, y = p0[1], shape = 21, size = 2.3, fill = "white", colour = "#404040") +
  scale_x_continuous("Baseline prevalence ratio (IIH / comparator), log scale",
                     trans = "log", breaks = c(1, 1.5, 2, 3, 5)) +
  scale_y_continuous("Post-index hazard ratio, log scale", trans = "log",
                     breaks = c(0.8, 1, 1.5, 2, 3, 5)) +
  labs(title = "A   Empirical calibration across 11 negative-control outcomes",
       subtitle = "r = 0.66, p = 0.026. Shaded band is the 95% prediction interval",
       caption = "The prediction interval at baseline balance includes the observed seizure estimate,\nso calibration alone does not distinguish the association from a detection artefact.") +
  th()
save3(f3a, "Figure_3A_calibration", 140, 105)

rob <- rd("K_T50_contact_robustness"); rob <- rob[rob$measure != "(unadjusted)", ]
nm <- c(visits_12m = "Visits, 12 months", visits_24m = "Visits, 24 months",
        months_12m = "Months with a visit", visits_all = "All visits on record",
        history_years = "Years of record history", office_12m = "Office visits, 12 months")
rob$lab <- nm[rob$measure]
rb <- data.frame(lab = factor(rob$lab, levels = rev(rob$lab)),
                 ctl = as.numeric(sub("%", "", rob$controls_median_change)),
                 sz  = as.numeric(sub("[+]", "", sub("%", "", rob$seizure_change))),
                 stringsAsFactors = FALSE)
rl <- rbind(data.frame(lab = rb$lab, v = rb$ctl, who = "Negative controls (median of 11)"),
            data.frame(lab = rb$lab, v = rb$sz,  who = "Seizure or epilepsy"))

f3b <- ggplot(rl, aes(v, lab, colour = who, shape = who)) +
  geom_vline(xintercept = 0, colour = "#6a6a6a", linewidth = 0.45) +
  geom_segment(data = rb, aes(x = ctl, xend = sz, y = lab, yend = lab),
               inherit.aes = FALSE, colour = "#c4c4c4", linewidth = 0.4) +
  geom_point(size = 2.3, stroke = 0.5, fill = "white") +
  scale_colour_manual(values = c("Negative controls (median of 11)" = CTL_COL,
                                 "Seizure or epilepsy" = IIH_COL)) +
  scale_shape_manual(values = c("Negative controls (median of 11)" = 16,
                                "Seizure or epilepsy" = 18)) +
  scale_x_continuous("Change in hazard ratio on adjustment (%)",
                     breaks = seq(-40, 30, 10), limits = c(-48, 34)) +
  labs(y = NULL, title = "B   Response to healthcare-contact adjustment",
       subtitle = "All 66 control-by-measure combinations move toward the null;\nthe seizure estimate moves away under all six",
       caption = "Circles: median of the 11 negative controls. Diamonds: the seizure outcome.") +
  th() + theme(legend.position = "bottom", legend.title = element_blank(),
               legend.text = element_text(size = 7.5),
               panel.grid.major.y = element_blank(),
               panel.grid.major.x = element_line(colour = "#ebebeb", linewidth = 0.3))
save3(f3b, "Figure_3B_contact_direction", 140, 100)

log_msg("Z7 complete")
