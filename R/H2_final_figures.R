## H2_final_figures.R ---------------------------------------------------------
## Final figure set. Every figure answers one question and none repeats a claim
## the negative-control panel has overturned.
source("R/00_setup.R")
log_msg("=== H2 final figures ===")
if (!HAS_GG) quit(save="no")
H <- readRDS(file.path(PATH$derived, "H1_final.rds"))
FIG <- function(p,n,w=9,h=5.5) save_fig(p, paste0("H_", n), w, h)

## --- F1 primary result across specifications --------------------------------
sp <- H$spec[!is.na(H$spec$hr), ]
sp$model <- factor(sp$model, levels = rev(sp$model))
sp$kind <- ifelse(grepl("PRIMARY", sp$model), "Primary",
           ifelse(grepl("BOUND ONLY", sp$model), "Mediator-adjusted bound",
           ifelse(grepl("SECONDARY", sp$model), "Full cohort (secondary)", "Other")))
FIG(ggplot(sp, aes(hr, model, colour = kind)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey45") +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = .22, linewidth = .5) +
  geom_point(aes(size = events)) +
  scale_x_log10(breaks = c(1,2,3,5,10,20)) +
  scale_size_continuous(range = c(1.4,3.6), guide = "none") +
  scale_colour_manual(values = c(Primary = COL[["iih"]],
    `Mediator-adjusted bound` = COL[["warn"]],
    `Full cohort (secondary)` = COL[["neutral"]], Other = COL[["control"]])) +
  labs(x = "Hazard ratio (log scale)", y = NULL,
       title = "Incident seizure or epilepsy after IIH",
       subtitle = "Engagement-restricted cohort, 3-year horizon unless stated. Point size is event count.",
       caption = "Post-index contact adjustment (amber) is a conservative lower bound, not a causal estimate: it conditions on a consequence of both exposure and outcome.") +
  theme_pub(), "F1_primary_specifications", 10, 6)

## --- F2 the negative-control panel and the bias trend -----------------------
pn <- H$panel[!is.na(H$panel$hr_full), ]
pn$ratio <- pn$baseline_iih_pct / pn$baseline_ctl_pct
fitb <- stats::lm(log(hr_full) ~ log(ratio), data = pn)
gr <- data.frame(x = exp(seq(log(.5), log(5), length.out = 60)))
pp <- stats::predict(fitb, data.frame(ratio = gr$x), interval = "prediction")
gr$fit <- exp(pp[,1]); gr$lo <- exp(pp[,2]); gr$hi <- exp(pp[,3])
pr1 <- stats::predict(fitb, data.frame(ratio = 1), interval = "prediction")
sz <- H$spec[1, ]
ct <- stats::cor.test(log(pn$ratio), log(pn$hr_full))
FIG(ggplot() +
  geom_ribbon(data = gr, aes(x, ymin = lo, ymax = hi), alpha = .13, fill = COL[["control"]]) +
  geom_line(data = gr, aes(x, fit), colour = COL[["control"]], linewidth = .8) +
  geom_hline(yintercept = 1, linetype = 2, colour = "grey45") +
  geom_vline(xintercept = 1, linetype = 3, colour = "grey55") +
  geom_errorbar(data = pn, aes(ratio, ymin = lo_full, ymax = hi_full),
                width = .03, linewidth = .4, colour = COL[["warn"]], alpha = .8) +
  geom_point(data = pn, aes(ratio, hr_full), size = 2.8, colour = COL[["warn"]]) +
  ## Manual label offsets: renal stone and carpal tunnel sit almost on top of
  ## each other, so they are pushed apart rather than left overlapping.
  geom_text(data = transform(pn,
      nx = c(-.09, -.09, -.09, -.09, -.09, 1.05)[match(outcome, pn$outcome)],
      ny = c(-.7, -1.4, -.7, -.7, -.7, 1.6)[match(outcome, pn$outcome)]),
    aes(ratio, hr_full, label = outcome, hjust = nx, vjust = ny),
    size = 2.7, colour = "grey25") +
  annotate("errorbar", x = 1, ymin = sz$lo, ymax = sz$hi, width = .04,
           linewidth = .6, colour = COL[["iih"]]) +
  annotate("point", x = 1, y = sz$hr, size = 4, colour = COL[["iih"]]) +
  annotate("text", x = 1, y = sz$hr, label = "  SEIZURE", hjust = 0, vjust = -1.1,
           size = 3.2, fontface = "bold", colour = COL[["iih"]]) +
  scale_x_log10(breaks = c(.5,1,2,3,5)) + scale_y_log10(breaks = c(.1,.25,.5,1,2,5,10)) +
  coord_cartesian(xlim = c(.5, 6.5), ylim = c(.1, 14)) +
  labs(x = "Baseline prevalence ratio, IIH / control (log scale)",
       y = "Post-index hazard ratio (log scale)",
       title = "Each negative control's excess is predicted by its baseline imbalance",
       subtitle = sprintf("r = %.2f (%.2f to %.2f), p = %.3f. At baseline balance the predicted hazard ratio is %.2f (%.2f to %.2f).",
         ct$estimate, ct$conf.int[1], ct$conf.int[2], ct$p.value,
         exp(pr1[1]), exp(pr1[2]), exp(pr1[3])),
       caption = "Prior seizure was an exclusion, so the seizure outcome sits at a baseline ratio of exactly 1. Its estimate lies far outside the range the controls predict there, which is the argument that it is not the same bias.") +
  theme_pub(), "F2_bias_trend", 10, 6)

## --- F3 the panel as a forest -----------------------------------------------
pf <- H$panel[!is.na(H$panel$hr_full), ]
pf$outcome <- factor(pf$outcome, levels = rev(pf$outcome[order(pf$hr_full)]))
pf$valid <- ifelse(pf$valid_balance == "PASS", "Balanced at baseline (valid)",
                   "Imbalanced at baseline (invalid)")
FIG(ggplot(pf, aes(hr_full, outcome, colour = valid)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey45") +
  geom_errorbarh(aes(xmin = lo_full, xmax = hi_full), height = .2, linewidth = .5) +
  geom_point(aes(size = events_iih + events_ctl)) +
  geom_text(aes(x = 11, label = paste0(events_iih + events_ctl, " ev")), hjust = 1,
            size = 2.8, colour = "grey30") +
  scale_x_log10(breaks = c(.25,.5,1,2,4,8), limits = c(.1, 12)) +
  scale_size_continuous(range = c(1.5,3.8), guide = "none") +
  scale_colour_manual(values = c(`Balanced at baseline (valid)` = COL[["accent"]],
                                 `Imbalanced at baseline (invalid)` = COL[["warn"]])) +
  labs(x = "Hazard ratio (log scale)", y = NULL,
       title = "Negative-control panel",
       subtitle = "Each should sit at 1 if the design is specific to disease rather than to contact",
       caption = "Only limb fracture is balanced at baseline. The two acute, emergency-presenting outcomes (fracture, appendicitis) show no excess; the four elective or ambulatory ones do. Fracture and appendicitis rest on 2 and 5 exposed events, so each null is weak alone.") +
  theme_pub(), "F3_negative_control_panel", 10, 5)

## --- F4 cumulative incidence with competing death ---------------------------
s3 <- H$s3; aj <- H$aj
g <- seq(0,3,by=.02); sm <- summary(aj, times = g, extend = TRUE)
ks <- which(aj$states=="seizure"); kd <- which(aj$states=="death")
arm <- ifelse(grepl("iih=1", as.character(sm$strata)), "IIH", "Non-IIH control")
cifd <- rbind(
  data.frame(t=sm$time, arm=arm, pct=100*sm$pstate[,ks], lo=100*sm$lower[,ks],
             hi=100*sm$upper[,ks], event="Seizure or epilepsy"),
  data.frame(t=sm$time, arm=arm, pct=100*sm$pstate[,kd], lo=NA, hi=NA,
             event="Death (competing event)"))
cifd$event <- factor(cifd$event, levels=c("Seizure or epilepsy","Death (competing event)"))
FIG(ggplot(cifd, aes(t, pct, colour=arm, fill=arm)) +
  geom_ribbon(aes(ymin=lo, ymax=hi), alpha=.15, colour=NA) +
  geom_step(linewidth=.85) + facet_wrap(~event, scales="free_y") +
  scale_colour_manual(values=COHORT_COL) + scale_fill_manual(values=COHORT_COL) +
  labs(x="Years since day 180", y="Cumulative incidence (%)",
       title="Absolute risk, with death treated as a competing event",
       subtitle=sprintf("Aalen-Johansen. 3-year risk %.2f%% vs %.2f%%; difference %.2f pp, NNH %d.",
         H$rd$iih_pct, H$rd$control_pct, H$rd$estimate, H$rd$nnh),
       caption="1 - Kaplan-Meier is not shown: it would overstate risk by treating the deceased as still able to have a seizure.") +
  theme_pub(), "F4_cumulative_incidence", 9.5, 5)

## --- F5 timing ---------------------------------------------------------------
lr <- H$lat_raw
FIG(ggplot(lr, aes(y, cohort, fill=cohort)) +
  geom_violin(alpha=.32, colour=NA, scale="width") +
  geom_boxplot(width=.15, outlier.size=.7, alpha=.9) +
  geom_vline(xintercept=3, linetype=2, colour="grey40") +
  scale_fill_manual(values=COHORT_COL, guide="none") +
  labs(x="Years from index to first seizure", y=NULL,
       title="Timing argues against a detection artefact",
       subtitle=sprintf("Median %.2f y in IIH vs %.2f y in controls (Wilcoxon p = %s); %.0f%% of IIH events fall within 3 years against %.0f%% of control events.",
         H$lat$median_y[2], H$lat$median_y[1], H$lat$wilcoxon_p[1],
         H$lat$pct_within_3y[2], H$lat$pct_within_3y[1]),
       caption="A work-up artefact would cluster events immediately after diagnosis. These do the opposite. Conditional on having an event, so not an effect estimate.") +
  theme_pub(), "F5_timing", 9, 4.4)

## --- F6 balance --------------------------------------------------------------
b <- H$bal
b$variable <- factor(b$variable, levels=unique(b$variable[order(abs(b$smd))]))
b$cohort <- factor(b$cohort, levels=c("FULL","ENGAGED"),
                   labels=c("Full cohort","Engagement-restricted (primary)"))
FIG(ggplot(b, aes(abs(smd), variable, colour=cohort)) +
  geom_vline(xintercept=.1, linetype=2, colour="grey45") +
  geom_point(size=3, position=position_dodge(.45)) +
  scale_colour_manual(values=c(`Full cohort`=COL[["neutral"]],
                               `Engagement-restricted (primary)`=COL[["accent"]])) +
  labs(x="|Standardised mean difference|", y=NULL,
       title="Covariate balance",
       subtitle="Dashed line = 0.1. The engagement restriction is what the protocol specified and the extract did not achieve.",
       caption="Restricting controls to those with a pre-index encounter cuts the contact imbalance from 0.68 to 0.32 and fixes hypertension. Sleep apnoea and PCOS remain imbalanced and are adjusted for in the models.") +
  theme_pub(), "F6_balance", 9.5, 5)

## --- F7 subgroups -------------------------------------------------------------
sg <- H$sub[!is.na(H$sub$hr), ]
sg$lab <- sprintf("%s  (%d events)", sg$model, sg$events)
sg$ip <- ifelse(is.na(sg$interaction_p), "", paste0("interaction p = ", sg$interaction_p))
sg$modifier <- factor(sg$modifier, levels=c("Overall","Sex","Age","BMI","Calendar period"))
sg <- sg[order(sg$modifier), ]; sg$lab <- factor(sg$lab, levels=rev(sg$lab))
FIG(ggplot(sg, aes(hr, lab)) +
  geom_vline(xintercept=H$spec$hr[1], linetype=3, colour=COL[["accent"]]) +
  geom_vline(xintercept=1, linetype=2, colour="grey45") +
  geom_errorbarh(aes(xmin=lo, xmax=hi), height=.2, linewidth=.5, colour=COL[["control"]]) +
  geom_point(aes(size=events), colour=COL[["iih"]]) +
  geom_text(aes(x=42, label=ip), hjust=1, size=2.8, colour="grey20") +
  facet_grid(modifier ~ ., scales="free_y", space="free_y", switch="y") +
  scale_x_log10(breaks=c(1,2,5,10,20), limits=c(.7,45)) +
  scale_size_continuous(range=c(1.5,3.5), guide="none") +
  labs(x="Hazard ratio (log scale)", y=NULL,
       title="Effect modification, tested by interaction",
       subtitle="Dotted green = overall estimate. Subgroup estimates are descriptive; only the interaction p-value tests modification.",
       caption="No interaction is significant. With 74 events power is low, so this shows homogeneity is not contradicted rather than that it holds.") +
  theme_pub() + theme(strip.placement="outside",
    strip.text.y.left=element_text(angle=0, hjust=1), panel.spacing.y=unit(.15,"lines")),
  "F7_subgroups", 10, 5.5)

## --- F8 tipping point ----------------------------------------------------------
tp <- H$tip
FIG(ggplot(tp, aes(pct_hidden, hr)) +
  geom_hline(yintercept=1, linetype=2, colour="grey40") +
  geom_ribbon(aes(ymin=lo, ymax=hi), alpha=.2, fill=COL[["control"]]) +
  geom_line(linewidth=.85, colour=COL[["iih"]]) +
  geom_point(size=2.4, colour=COL[["iih"]]) + scale_y_log10() +
  labs(x="% of censored controls assumed to have an unrecorded seizure",
       y="Hazard ratio (log scale)",
       title="How much unrecorded seizure in controls would erase the result?",
       subtitle="The null is reached at roughly 2% of censored controls",
       caption="Hidden events are added to controls only, which is the worst case. The negative-control panel bears on how plausible this is: outcomes needing no care-seeking showed no excess.") +
  theme_pub(), "F8_tipping_point", 8.5, 4.8)
log_msg("H2 complete")
