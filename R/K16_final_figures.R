## K16_final_figures.R --------------------------------------------------------
## Figures and supplement for the final analysis.
##
##   K_F1  cumulative incidence of seizure or epilepsy, by arm, with numbers
##         at risk. Aalen-Johansen with death as a competing risk, never 1-KM.
##   K_F2  forest plot of all eight specifications, both encounter definitions.
##   K_F3  of the patients who had a seizure, how many had recurrent disease.
##   K_S1  supplement: every encounter type and how it was classified.
##
## COLOUR. Arms are an identity contrast and take validated categorical slots 1
## and 2 (#2a78d6 blue, #eb6834 orange; worst adjacent CVD delta-E 24.7,
## normal-vision 33.6). Epilepsy versus single seizure is ordinal -- one event,
## then recurrence -- so it takes a single-hue two-step ramp light to dark
## (#86b6ef to #184f95, light-end contrast 2.06:1, above the 2:1 ordinal
## floor). Both were checked with the palette validator rather than by eye, and
## every series is directly labelled so identity never rests on colour alone.

source("R/00_setup.R"); suppressMessages({library(survival); library(ggplot2)})
log_msg("=== K16 final figures ===")
V <- readRDS(file.path(PATH$derived, "K15_final_visits.rds"))
A <- readRDS(file.path(PATH$derived, "K15_final_all.rds"))
TAU <- 3
IIH <- "#2a78d6"; CTL <- "#eb6834"; EPI <- "#184f95"; SGL <- "#86b6ef"
INK <- "#0b0b0b"; INK2 <- "#52514e"

## ---- K_F1 cumulative incidence ------------------------------------------------
cif_df <- function(dat) {
  dat$dd <- as.numeric(dat$death_date - dat$index_date)
  dat$cr <- factor(ifelse(dat$ev==1,"seizure",
                   ifelse(!is.na(dat$dd) & dat$dd<=dat$open,"death","censor")),
                   levels=c("censor","seizure","death"))
  fs <- survfit(Surv(t, cr) ~ iih, data=dat)
  k <- which(fs$states == "seizure")
  sm <- summary(fs, times=seq(0, TAU, by=0.05), extend=TRUE)
  data.frame(time=sm$time, arm=ifelse(sub(".*=","",as.character(sm$strata))=="1","IIH","Comparator"),
             cif=100*sm$pstate[,k], lo=100*pmax(0, sm$lower[,k]), hi=100*pmin(1, sm$upper[,k]))
}
C1 <- cif_df(V$a); C1$arm <- factor(C1$arm, c("IIH","Comparator"))
atrisk <- do.call(rbind, lapply(c(1,0), function(g) data.frame(
  arm=ifelse(g==1,"IIH","Comparator"),
  time=0:TAU,
  n=vapply(0:TAU, function(tt) sum(V$a$iih==g & V$a$t >= tt), numeric(1)))))
atrisk$arm <- factor(atrisk$arm, c("IIH","Comparator"))
lab1 <- C1[C1$time == TAU, ]
p1 <- ggplot(C1, aes(time, cif, colour=arm, fill=arm)) +
  geom_ribbon(aes(ymin=lo, ymax=hi), alpha=.13, colour=NA) +
  geom_step(linewidth=.9) +
  geom_text(data=lab1, aes(x=TAU+.04, y=cif, label=sprintf("%s  %.2f%%", arm, cif)),
            hjust=0, size=3.4, fontface="bold", show.legend=FALSE) +
  scale_colour_manual(values=c(IIH=IIH, Comparator=CTL), guide="none") +
  scale_fill_manual(values=c(IIH=IIH, Comparator=CTL), guide="none") +
  scale_x_continuous(breaks=0:TAU, limits=c(0, TAU+1.15), expand=expansion(add=c(.02,0))) +
  scale_y_continuous(expand=expansion(c(0,.06))) +
  coord_cartesian(clip="off") +
  labs(title="Cumulative incidence of seizure or epilepsy after IIH",
       subtitle="Aalen-Johansen estimate with death as a competing risk. Shaded bands are 95% confidence intervals.",
       x="Years from end of the 180-day washout", y="Cumulative incidence (%)",
       caption=paste(
        "Matched cohort, engagement-restricted, clinical visits only. Outcome ascertained identically in both arms: a qualifying",
        "seizure code after the washout, or antiseizure medication continued 180 days or more.",
        "Hazard ratio 2.28 (95% CI 1.62 to 3.22), p = 2.6 x 10^-6. Proportional hazards p = 0.94.", sep="\n")) +
  theme_pub() + theme(plot.margin=margin(6,80,6,6))
save_fig(p1, "K_F1_cumulative_incidence", w=9, h=5.6)

nr <- reshape(atrisk, idvar="arm", timevar="time", direction="wide")
write_tab(nr, "K_S2_numbers_at_risk")

## ---- K_F2 forest --------------------------------------------------------------
mk <- function(x, enc) { z <- x$sens; z$enc <- enc
  z$hr <- as.numeric(sub(" .*","",z$HR))
  ci <- regmatches(z$HR, regexpr("\\(.*\\)", z$HR))
  z$lo <- as.numeric(sub("\\((.*) to .*","\\1", ci)); z$hi <- as.numeric(sub(".* to (.*)\\)","\\1", ci))
  z }
F2 <- rbind(mk(V,"Clinical visits only"), mk(A,"All encounter rows"))
F2$analysis <- sub("PRIMARY: ", "", F2$analysis)
F2$lab <- factor(F2$analysis, levels=rev(unique(F2$analysis)))
F2$enc <- factor(F2$enc, c("Clinical visits only","All encounter rows"))
p2 <- ggplot(F2, aes(hr, lab, colour=enc)) +
  geom_vline(xintercept=1, linetype=2, colour="grey55", linewidth=.4) +
  geom_errorbarh(aes(xmin=lo, xmax=hi), height=.16, linewidth=.55,
                 position=position_dodge(.55)) +
  geom_point(size=2.6, position=position_dodge(.55)) +
  ## Estimates in a fixed column. position_dodge does not separate text on a
  ## discrete y axis -- the two labels landed on top of each other -- so the
  ## rows are nudged explicitly by the same offset the dodge gives the marks.
  geom_text(data=subset(F2, enc=="Clinical visits only"),
            aes(x=5.6, label=sprintf("%.2f (%.2f to %.2f)", hr, lo, hi)),
            position=position_nudge(y=-.14), hjust=0, size=2.9, colour=INK2) +
  geom_text(data=subset(F2, enc=="All encounter rows"),
            aes(x=5.6, label=sprintf("%.2f (%.2f to %.2f)", hr, lo, hi)),
            position=position_nudge(y=.14), hjust=0, size=2.9, colour=INK2) +
  scale_colour_manual(values=c("Clinical visits only"=IIH, "All encounter rows"=CTL), name=NULL) +
  scale_x_log10(breaks=c(1,2,3,5), limits=c(.9, 13)) +
  coord_cartesian(clip="off") +
  labs(title="Every specification points the same way",
       subtitle="Hazard ratio for seizure or epilepsy, IIH versus matched comparators. Log scale.",
       x="Hazard ratio (log scale)", y=NULL,
       caption=paste(
        "Eight specifications: four outcome definitions crossed with two encounter definitions. All are significant, and all fall",
        "between 1.9 and 2.9. The epilepsy-specific-code row is the one that matters most: under the arm-asymmetric ascertainment",
        "of the submitted analysis it read 0.50 and pointed the other way, and with both arms scored identically it agrees with",
        "the primary. Clinical visits only is the proposed primary because it is the more conservative of the two.", sep="\n")) +
  theme_pub() + theme(legend.position="bottom", panel.grid.major.y=element_blank())
save_fig(p2, "K_F2_forest_specifications", w=10, h=5.2)

## ---- K_F3 secondary -----------------------------------------------------------
S <- V$sec
S$n <- S$with_event
D <- do.call(rbind, lapply(seq_len(nrow(S)), function(i) data.frame(
  arm=S$arm[i], cls=c("Epilepsy (recurrent)","Single seizure"),
  k=c(S$recurrent_or_epilepsy[i], S$single_seizure[i]), n=S$n[i])))
D$pct <- 100*D$k/D$n
D$arm <- factor(D$arm, c("IIH","Comparator")); D$cls <- factor(D$cls, c("Epilepsy (recurrent)","Single seizure"))
p3 <- ggplot(D, aes(arm, pct, fill=cls)) +
  geom_col(width=.55, colour="#fcfcfb", linewidth=1) +
  geom_text(aes(label=sprintf("%d (%.0f%%)", k, pct)), position=position_stack(vjust=.5),
            colour="white", fontface="bold", size=3.5) +
  ## Direct labels to the RIGHT of both bars: placed between them they ran into
  ## the comparator bar.
  annotate("text", x=2.34, y=76, label="Epilepsy (recurrent)", hjust=0, size=3.4, colour=INK2) +
  annotate("text", x=2.34, y=24, label="Single seizure", hjust=0, size=3.4, colour=INK2) +
  scale_fill_manual(values=c("Epilepsy (recurrent)"=EPI, "Single seizure"=SGL), guide="none") +
  scale_x_discrete(expand=expansion(add=c(.55,1.25))) +
  scale_y_continuous(expand=expansion(c(0,.04))) +
  coord_cartesian(clip="off") +
  labs(title="Of the patients who had a seizure, how many had recurrent disease",
       subtitle="Recurrent = two or more coded seizures 30+ days apart, an epilepsy-specific code, or indefinite antiseizure therapy.",
       x=NULL, y="Percent of patients with an event",
       caption=paste(
        "Outcome-positive patients only: 66 with IIH, 63 comparators. Both arms classified by the same rule on the same clock.",
        "The difference between the arms is in how OFTEN seizures occur, not in how likely they are to recur once they do:",
        "the confidence intervals on these proportions overlap (62%, 49 to 74, against 51%, 38 to 64).", sep="\n")) +
  theme_pub()
save_fig(p3, "K_F3_recurrent_vs_single", w=7.6, h=5.4)

## ---- K_S1 encounter type supplement -------------------------------------------
ADMIN <- paste0("^(Patient Message|Clinical Communication|History|Orders Only|",
  "Recurring Plan|Reconciled Outside Data|Account-less|Refill|Wait List|",
  "Ancillary Orders|Letter \\(Out\\)|Historical Appointment|Documentation|",
  "Results Follow-Up|Transcribe Orders|Series|Silent Schedule|Abstract|",
  "OurPractice Advisory|Episode Changes|Dictaphone|Committee Review|",
  "Community Orders|Outside Material Tracking|Aria Results|Enrollment|Education|",
  "Patient Outreach|External Outreach|Patient Self-Triage|Remote Monitoring|",
  "CPAP Download|Prep for Case|Specialty Pharmacy|Internal E-Consult|Admin Visit)|",
  "Conversion Encounter|^Erroneous|^Historic|^Clinical Support")
ca <- utils::read.csv("data-raw/MDE_Encounters_types_full.csv", colClasses="character")
co <- utils::read.csv("data-raw/MDE_Encounters_controls_typed.csv", colClasses="character")
ta <- table(trimws(ca[[2]])); tb <- table(trimws(co[[6]]))
u <- sort(union(names(ta), names(tb)))
sup <- data.frame(encounter_type=u, case_rows=as.integer(ta[u]), comparator_rows=as.integer(tb[u]))
sup[is.na(sup)] <- 0L
sup$classified_as <- ifelse(grepl(ADMIN, sup$encounter_type), "administrative (excluded)", "clinical visit (counted)")
sup <- sup[order(-(sup$case_rows + sup$comparator_rows)), ]
write_tab(sup, "K_S1_encounter_type_classification")
log_msg("encounter types: ", sum(sup$classified_as=="clinical visit (counted)"), " counted, ",
        sum(sup$classified_as!="clinical visit (counted)"), " excluded")
log_msg("K16 complete")
