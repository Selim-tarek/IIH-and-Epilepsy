## G3_figures_report.R --------------------------------------------------------
source("R/00_setup.R")
log_msg("=== G3 figures & report ===")
d <- readRDS(file.path(PATH$derived, "G1_master.rds"))
R <- readRDS(file.path(PATH$derived, "G2_results.rds"))
FIG <- function(p, n, w = 9, h = 5.5) save_fig(p, paste0("G_", n), w, h)

if (HAS_GG) {
## G1: the finding that reframes everything
m <- R$main[!is.na(R$main$hr), ]
m$lab <- paste0(m$outcome, " - ", m$model)
m$lab <- factor(m$lab, levels = rev(unique(m$lab)))
m$kind <- ifelse(m$outcome == "carpal", "Negative control", "Seizure outcome")
FIG(ggplot(m, aes(hr, lab, colour = kind)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey45") +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = .2, linewidth = .5) +
  geom_point(aes(size = events_iih + events_ctl)) +
  facet_grid(cohort ~ ., scales = "free_y", space = "free_y", switch = "y") +
  scale_x_log10(breaks = c(1,2,3,5,10)) +
  scale_size_continuous(range = c(1.5,3.5), guide = "none") +
  scale_colour_manual(values = c("Seizure outcome" = COL[["iih"]],
                                 "Negative control" = COL[["warn"]])) +
  labs(x = "Hazard ratio (log scale)", y = NULL,
       title = "The negative control is elevated in both cohorts",
       subtitle = "Restricting controls to those with baseline healthcare contact raises the seizure estimate but leaves the negative control unchanged",
       caption = "If the excess were purely baseline non-comparability, restriction would have moved both. It moved only the seizure estimate.") +
  theme_pub() + theme(strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0), panel.spacing.y = unit(.2,"lines")),
  "F1_seizure_vs_negative_control", 10, 6)

## G2: baseline carpal prevalence
pv <- R$prev
FIG(ggplot(pv, aes(arm, pct, fill = arm)) +
  geom_col(width = .6) +
  geom_text(aes(label = sprintf("%.2f%%\n(%d)", pct, prevalent_carpal)), vjust = -0.25, size = 3.2) +
  facet_wrap(~cohort) +
  scale_fill_manual(values = c(IIH = COL[["iih"]], Control = COL[["control"]]), guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, .18))) +
  labs(x = NULL, y = "Carpal tunnel present BEFORE index (%)",
       title = "The negative control was already imbalanced at baseline",
       subtitle = "A valid negative control must be balanced before index. This one is not.",
       caption = "Restricting to engaged controls halves the imbalance (3.6x to 1.9x) but does not remove it, so baseline healthcare contact explains part of the carpal excess and not all of it.") +
  theme_pub(), "F2_carpal_baseline_prevalence", 8.5, 5)

## G3: incidence rates
rt <- R$rates
rt$grp <- paste(rt$outcome, rt$cohort)
FIG(ggplot(rt, aes(cohort, rate, colour = cohort, shape = cohort)) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .12, linewidth = .6) +
  geom_point(size = 3) + facet_wrap(~outcome) +
  scale_colour_manual(values = c(IIH = COL[["iih"]], Control = COL[["control"]]), guide="none") +
  scale_shape(guide = "none") +
  labs(x = NULL, y = "Events per 1,000 person-years",
       title = "Incidence rates, exact Poisson intervals",
       subtitle = "Each outcome on its own at-risk clock",
       caption = "Note the control seizure rate falls from 2.65 to 1.78 once disengaged controls are removed, which is what raises the hazard ratio.") +
  theme_pub(), "F3_rates", 8.5, 5)

## G4: balance
b <- R$bal
b$variable <- factor(b$variable, levels = unique(b$variable[order(abs(b$smd))]))
FIG(ggplot(b, aes(abs(smd), variable, colour = cohort)) +
  geom_vline(xintercept = .1, linetype = 2, colour = "grey45") +
  geom_point(size = 3, position = position_dodge(.4)) +
  scale_colour_manual(values = c(FULL = COL[["control"]], ENGAGED = COL[["accent"]])) +
  labs(x = "|Standardised mean difference|", y = NULL,
       title = "Covariate balance before and after the engagement restriction",
       subtitle = "Dashed line = 0.1",
       caption = "The restriction cuts the pre-index encounter imbalance from 0.68 to 0.32 and fixes hypertension, but sleep apnoea and PCOS remain imbalanced in both.") +
  theme_pub(), "F4_balance", 9, 5)

## G5: calibration
cb <- R$calib
cb2 <- do.call(rbind, lapply(seq_len(nrow(cb)), function(i) {
  p <- function(x) as.numeric(regmatches(x, regexec("^([0-9.]+)", x))[[1]][2])
  lohi <- function(x) as.numeric(regmatches(x, regexec("\\(([0-9.]+) to ([0-9.]+)\\)", x))[[1]][2:3])
  do.call(rbind, lapply(c("seizure","negative_control","calibrated"), function(k)
    data.frame(cohort = cb$cohort[i], quantity = k, hr = p(cb[[k]][i]),
               lo = lohi(cb[[k]][i])[1], hi = lohi(cb[[k]][i])[2]))) }))
cb2$quantity <- factor(cb2$quantity, levels = c("calibrated","negative_control","seizure"),
  labels = c("Calibrated (seizure / neg. control)","Negative control","Seizure outcome"))
FIG(ggplot(cb2, aes(hr, quantity, colour = cohort)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey45") +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = .2, linewidth = .6,
                 position = position_dodge(.45)) +
  geom_point(size = 3, position = position_dodge(.45)) +
  scale_x_log10(breaks = c(0.5,1,2,3,5,10)) +
  scale_colour_manual(values = c(FULL = COL[["control"]], ENGAGED = COL[["accent"]])) +
  labs(x = "Hazard ratio (log scale)", y = NULL,
       title = "Negative-control calibration",
       subtitle = "Dividing the seizure estimate by the negative-control estimate removes bias shared by both outcomes",
       caption = "The calibrated estimate crosses the null in the full cohort (1.41) and is borderline in the engagement-restricted one (2.10, 0.97-4.54). It assumes the bias acts equally on both outcomes, which is unverifiable.") +
  theme_pub(), "F5_calibration", 9.5, 4.6)
}

## ---- report -----------------------------------------------------------------
tb <- function(df, dig = 3) {
  df <- as.data.frame(df); num <- vapply(df, is.numeric, logical(1))
  df[num] <- lapply(df[num], function(x) format(round(x, dig), trim = TRUE))
  paste(c(paste("|", paste(names(df), collapse=" | "), "|"),
          paste("|", paste(rep("---", ncol(df)), collapse=" | "), "|"),
          apply(df, 1, function(r) paste("|", paste(r, collapse=" | "), "|"))), collapse="\n")
}
mm <- R$main[, c("cohort","outcome","model","events_iih","events_ctl","estimate","p")]
txt <- c(
"---","title: \"IIH and Incident Epilepsy: Rebuilt Analysis\"","---","",
"# Rebuilt analysis, all sources ingested","",
sprintf("Analysis date %s. Seed %d. Supersedes the F-series.", format(Sys.Date()), SEED),
"","## 1. What changed in this rebuild","",
"| Correction | Consequence |","| --- | --- |",
"| Carpal tunnel was censored at `t_y`, which is censored at the SEIZURE. Carpal diagnoses occurring after a patient's seizure were discarded. | Each outcome now runs on its own clock, to last attended encounter. |",
"| Carpal prevalence at baseline had never been examined. | It is 3.6x commoner in cases BEFORE index. The negative control was not balanced to begin with. |",
"| Protocol v2.0 required controls to have >=1 pre-index encounter. 55.7% have zero. | An engagement-restricted cohort is analysed alongside the full one. |",
"| Case medications went from 53 to 2,187 patients (83.5%); smoking now covers 89.8% of controls; radiology now exists for both arms. | Smoking is adjustable; medication coverage is no longer 2% vs 29%. |",
"","## 2. Results","",tb(mm),"",
"## 3. Incidence rates","",tb(R$rates),"",
"## 4. The negative control","",
"Carpal tunnel is elevated in BOTH cohorts (2.60 and 2.66) and the engagement restriction does not move it, while it raises the seizure estimate from 3.66 to 5.58. So baseline disengagement of controls explains part of the picture but not the carpal excess.",
"","### Baseline prevalence","",tb(R$prev[, c("cohort","arm","n","prevalent_carpal","pct")]),"",
"The imbalance exists before index, so it cannot be caused by IIH or by post-index surveillance. It reflects a pre-existing difference in who these patients are. That makes carpal tunnel a poor negative control: it violates the requirement of no association with the exposure other than through bias.",
"","### Calibration","",tb(R$calib),"",
"","## 5. Balance","",tb(R$bal),"",
"## 6. Proportional hazards (engagement-restricted)","",tb(R$ph),"",
"## 7. Absolute risk (engagement-restricted)","",tb(R$rd),"",
"## 8. What this means","",
"The seizure association is robust and gets STRONGER when controls are restricted to those actually in care: 5.58 (3.15-9.87). That is the estimate least contaminated by comparing engaged patients with disengaged ones.",
"",
"But the negative control remains elevated at 2.66 and is already imbalanced at baseline, so it cannot be used to certify specificity. The calibrated estimate, 2.10 (0.97-4.54), is the conservative reading and is borderline.",
"",
"The honest position: a substantial association that survives every adjustment available, alongside a negative control that fails its own validity check and therefore cannot settle the surveillance-bias question either way.","")
writeLines(txt, file.path(PATH$report, "rebuilt_analysis_report.md"))
if (requireNamespace("rmarkdown", quietly = TRUE))
  try(rmarkdown::render(file.path(PATH$report, "rebuilt_analysis_report.md"),
      output_format = rmarkdown::html_document(toc=TRUE, toc_float=TRUE, theme="flatly",
      df_print="kable"), quiet = TRUE), silent = TRUE)
log_msg("G3 complete")
