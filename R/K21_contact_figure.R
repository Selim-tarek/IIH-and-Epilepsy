## K21_contact_figure.R -------------------------------------------------------
##   K_F7  what adjusting for healthcare-seeking does to each outcome
##   K_F8  calibration: baseline imbalance against apparent effect, 11 controls
##
## K_F7 is the discriminating test. Pre-index visit count proxies
## healthcare-seeking and is not caused by the outcome, so adjusting for it is
## legitimate; post-index visits are caused by the outcome and adjusting for
## them would be collider bias. A detection-driven association shrinks toward
## the null under this adjustment; a real one does not.

source("R/00_setup.R"); suppressMessages(library(ggplot2))
log_msg("=== K21 contact figures ===")
K <- readRDS(file.path(PATH$derived, "K20_contact.rds"))
out <- K$out; NCP <- K$NCP; SZ <- K$SZ
IIH <- "#2a78d6"; CTL <- "#eb6834"; INK2 <- "#52514e"

## ---- K_F7 slope chart -----------------------------------------------------------
D <- out[, c("outcome","hr_unadj","hr_adj","pct_change")]
D$is_sz <- D$outcome == "SEIZURE OR EPILEPSY"
D <- D[order(D$is_sz, -D$pct_change), ]
D$outcome <- factor(D$outcome, levels=D$outcome)
L <- rbind(data.frame(outcome=D$outcome, hr=D$hr_unadj, when="Unadjusted", is_sz=D$is_sz),
           data.frame(outcome=D$outcome, hr=D$hr_adj,  when="Adjusted for healthcare-seeking", is_sz=D$is_sz))
L$when <- factor(L$when, c("Unadjusted","Adjusted for healthcare-seeking"))
p7 <- ggplot(L, aes(hr, outcome)) +
  geom_vline(xintercept=1, linetype=2, colour="grey55", linewidth=.4) +
  ## Explicit segments, not geom_line: geom_line re-orders points by x, so the
  ## arrowhead landed on whichever estimate was larger rather than on the
  ## adjusted one, reversing the direction the figure is about.
  geom_segment(data=D, aes(x=hr_unadj, xend=hr_adj, y=outcome, yend=outcome, colour=is_sz),
               linewidth=.7, arrow=grid::arrow(length=unit(.10,"in"), type="closed")) +
  geom_point(aes(colour=is_sz, shape=when), size=2.5) +
  geom_text(data=D, aes(x=pmax(hr_unadj, hr_adj), y=outcome,
            label=sprintf("%+.0f%%", pct_change), colour=is_sz),
            hjust=-.28, size=3, show.legend=FALSE) +
  scale_colour_manual(values=c(`FALSE`=CTL, `TRUE`=IIH), guide="none") +
  scale_shape_manual(values=c(Unadjusted=1, `Adjusted for healthcare-seeking`=19), name=NULL) +
  scale_x_log10(breaks=c(.5,1,2,3,5,8), limits=c(.45, 11)) +
  coord_cartesian(clip="off") +
  labs(title="The seizure association is the only one that does not shrink",
       subtitle="Arrows run from the unadjusted hazard ratio to the hazard ratio adjusted for pre-index visit count.",
       x="Hazard ratio (log scale)", y=NULL,
       caption=paste(
        "Pre-index visit count proxies healthcare-seeking. It is not caused by the outcome, so adjusting for it is legitimate;",
        "post-index visits ARE caused by the outcome, and adjusting for those would be collider bias.",
        "All eleven negative controls move toward the null, by 19% to 43% (median 29%). The seizure outcome moves the other way,",
        "by +13%. It is the only one of twelve to do so. If the seizure excess were produced by patients with IIH simply being",
        "seen more often, it should have shrunk like the rest.",
        "This does not exclude confounding by healthcare contact altogether: the adjustment is imperfect, and a single",
        "pre-index count cannot capture everything about how intensively a patient is observed.", sep="\n")) +
  theme_pub() + theme(legend.position="bottom", panel.grid.major.y=element_blank())
save_fig(p7, "K_F7_contact_adjustment", w=10, h=6.4)

## ---- K_F8 calibration ------------------------------------------------------------
gr <- data.frame(x=exp(seq(log(1), log(5.4), length.out=120)))
pp <- as.data.frame(stats::predict(K$fit, data.frame(baseline_ratio=gr$x), interval="prediction"))
gr <- cbind(gr, exp(pp))
p8 <- ggplot() +
  geom_ribbon(data=gr, aes(x, ymin=lwr, ymax=upr), fill="grey70", alpha=.16) +
  geom_line(data=gr, aes(x, fit), colour="grey35", linewidth=.6) +
  geom_hline(yintercept=1, linetype=3, colour="grey55", linewidth=.4) +
  geom_errorbar(data=NCP, aes(x=baseline_ratio, ymin=lo_unadj, ymax=hi_unadj),
                width=0, linewidth=.45, colour=CTL, alpha=.65) +
  geom_point(data=NCP, aes(baseline_ratio, hr_unadj), size=2.6, colour=CTL) +
  geom_text(data=NCP, aes(baseline_ratio, hr_unadj, label=outcome),
            vjust=-1.05, size=2.7, colour=INK2) +
  annotate("errorbar", x=1, ymin=SZ$lo_unadj, ymax=SZ$hi_unadj, width=0,
           linewidth=.7, colour=IIH) +
  annotate("point", x=1, y=SZ$hr_unadj, size=4, shape=18, colour=IIH) +
  annotate("text", x=1.03, y=SZ$hr_unadj, label="  SEIZURE / EPILEPSY", hjust=0,
           size=3.2, fontface="bold", colour=IIH) +
  scale_x_log10(breaks=c(1,1.5,2,3,5)) + scale_y_log10(breaks=c(.5,1,2,3,5,8)) +
  labs(title="Apparent effect scales with baseline imbalance across negative controls",
       subtitle="Eleven outcomes with no plausible causal link to IIH. Both axes log scale; band is the 95% prediction interval.",
       x="Baseline prevalence ratio, IIH / comparator (before index)",
       y="Post-index hazard ratio",
       caption=paste(
        "The relationship is real (r = 0.66, p = 0.026; slope 0.84, SE 0.31), which is what detection bias looks like: the more a",
        "condition was already over-recorded in the IIH arm, the larger its apparent post-index excess. Extrapolating to perfect",
        "baseline balance predicts a detection-only hazard ratio of 1.04 (0.37 to 2.90).",
        "Seizure is plotted at a ratio of 1 because prior seizure was an exclusion in both arms. Its estimate of 2.28 lies above",
        "the predicted 1.04 but INSIDE that prediction interval, so calibration alone cannot establish that the association",
        "exceeds detection bias. The adjustment test in the companion figure is the stronger evidence.", sep="\n")) +
  theme_pub()
save_fig(p8, "K_F8_calibration_v2", w=9.5, h=6.2)
log_msg("K21 complete")
