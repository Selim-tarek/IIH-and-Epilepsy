## K18_more_figures.R ---------------------------------------------------------
##   K_F4  baseline imbalance against apparent post-index effect, negative controls
##   K_F5  timing of incident events
##   K_F6  of the IIH arm, how many reached each stage of severity
##
## Palette as before: categorical slots 1 and 2 for arms (#2a78d6, #eb6834),
## a single-hue ordinal ramp for severity, grey for anything not comparable.

source("R/00_setup.R"); suppressMessages({library(ggplot2); library(survival)})
log_msg("=== K18 further figures ===")
V  <- readRDS(file.path(PATH$derived, "K15_final_visits.rds"))
NC <- readRDS(file.path(PATH$derived, "K17_nc.rds"))
a <- V$a; ae <- V$ae
IIH <- "#2a78d6"; CTL <- "#eb6834"; INK2 <- "#52514e"
D1 <- "#184f95"; D2 <- "#3b7dd8"; D3 <- "#86b6ef"

## ---- K_F4 calibration ----------------------------------------------------------
P <- NC$P; P <- P[!is.na(P$hr), ]
sz <- read.csv(file.path(PATH$tables, "K_T38_FINAL_results_visits.csv"))[1, ]
szhr <- as.numeric(sub(" .*","",sz$HR))
gr <- data.frame(x = exp(seq(log(.45), log(3.6), length.out=120)))
pp <- as.data.frame(stats::predict(NC$fit, data.frame(baseline_ratio=gr$x), interval="prediction"))
gr <- cbind(gr, exp(pp))
p4 <- ggplot() +
  geom_ribbon(data=gr, aes(x, ymin=lwr, ymax=upr), fill="grey70", alpha=.16) +
  geom_line(data=gr, aes(x, fit), colour="grey35", linewidth=.6) +
  geom_hline(yintercept=1, linetype=3, colour="grey55", linewidth=.4) +
  geom_vline(xintercept=1, linetype=3, colour="grey55", linewidth=.4) +
  geom_errorbar(data=P, aes(x=baseline_ratio, ymin=lo, ymax=hi, colour=balanced),
                width=0, linewidth=.5, alpha=.7) +
  geom_point(data=P, aes(baseline_ratio, hr, colour=balanced), size=3) +
  geom_text(data=P, aes(baseline_ratio, hr, label=outcome), vjust=-1.1, size=3, colour=INK2) +
  annotate("point", x=1, y=szhr, size=4.2, shape=18, colour=IIH) +
  annotate("text", x=1.02, y=szhr, label="  SEIZURE / EPILEPSY", hjust=0, size=3.3,
           fontface="bold", colour=IIH) +
  scale_colour_manual(values=c(PASS="#0ca30c", FAIL=CTL),
                      labels=c(FAIL="baseline imbalanced (uninformative)",
                               PASS="baseline balanced"), name=NULL) +
  scale_x_log10(breaks=c(.5,1,1.5,2,3)) + scale_y_log10(breaks=c(.5,1,2,3,5)) +
  labs(title="Baseline imbalance and apparent post-index effect, negative controls",
       subtitle="Each point is an outcome with no plausible causal link to IIH. Both axes log scale.",
       x="Baseline prevalence ratio, IIH / comparator (before index)",
       y="Post-index hazard ratio",
       caption=paste(
        "Recomputed on the rebuilt matched cohort; the previously published version used the earlier, arm-asymmetric matching and",
        "does not carry over. THE CALIBRATION ARGUMENT DOES NOT SURVIVE THE REBUILD. Across five estimable controls the",
        "relationship between baseline imbalance and apparent effect is weak and not significant (r = 0.28, p = 0.65; slope 0.48,",
        "SE 0.94), so the predicted detection-only hazard ratio at baseline balance is 1.51 with a useless interval (0.07 to 30.8).",
        "Five of six controls are imbalanced at baseline and so cannot inform specificity at all; the one balanced control, limb",
        "fracture, has too few events to estimate. Several controls sit at hazard ratios of 2.0 to 3.1, close to the seizure",
        "estimate itself. This panel should be read as evidence that the negative-control approach cannot adjudicate specificity",
        "in these data, not as support for the primary result.", sep="\n")) +
  theme_pub() + theme(legend.position="bottom")
save_fig(p4, "K_F4_negative_control_calibration", w=9.5, h=6.4)

## ---- K_F5 timing ---------------------------------------------------------------
tm <- data.frame(arm=ifelse(ae$iih==1,"IIH","Comparator"), day=ae$evday)
tm$arm <- factor(tm$arm, c("IIH","Comparator"))
med <- do.call(rbind, lapply(levels(tm$arm), function(k) data.frame(
  arm=k, med=median(tm$day[tm$arm==k]), n=sum(tm$arm==k))))
med$arm <- factor(med$arm, c("IIH","Comparator"))
p5 <- ggplot(tm, aes(day/365.25, fill=arm)) +
  geom_histogram(binwidth=.25, boundary=180/365.25, colour="white", linewidth=.35) +
  geom_vline(data=med, aes(xintercept=med/365.25, colour=arm), linetype=2, linewidth=.55,
             show.legend=FALSE) +
  geom_text(data=med, aes(x=med/365.25, y=Inf, colour=arm,
            label=sprintf(" median %.0f d", med)), vjust=1.6, hjust=0, size=3.1,
            show.legend=FALSE) +
  facet_wrap(~arm, ncol=1, scales="free_y") +
  scale_fill_manual(values=c(IIH=IIH, Comparator=CTL), guide="none") +
  scale_colour_manual(values=c(IIH=IIH, Comparator=CTL), guide="none") +
  scale_x_continuous(breaks=seq(0,3.5,.5), expand=expansion(add=c(.02,.02))) +
  labs(title="Timing of incident events",
       subtitle="Years from index. The 180-day washout means no event can fall before 0.49 years. Note the differing y scales.",
       x="Years from index date", y="Patients",
       caption=paste(
        "66 events in the IIH arm, 63 among comparators. Median latency 450 days (IQR 268 to 666) and 382 days (254 to 692).",
        "Events concentrate early in BOTH arms: 61% of IIH events and 67% of comparator events fall within the first year after",
        "the washout, tailing off thereafter (IIH 18 then 8 events in years two and three; comparators 13 then 8). Early",
        "concentration in a single arm would suggest prevalent disease being recorded late, or surveillance triggered by the",
        "index event. Seen equally in both arms it cannot distinguish those explanations from a genuine early hazard -- it",
        "neither supports nor undermines the primary result. What the panel does show is that the two distributions have the",
        "same shape: the arms differ in how MANY events occur, not in when they occur.", sep="\n")) +
  theme_pub() + theme(strip.text=element_text(face="bold"))
save_fig(p5, "K_F5_timing_of_events", w=8.6, h=6)

## ---- K_F6 severity cascade in the IIH arm ---------------------------------------
ii <- ae[ae$iih==1, ]
ASM <- c("levetiracetam","lamotrigine","carbamazepine","oxcarbazepine","valproa","divalproex",
 "phenytoin","fosphenytoin","lacosamide","zonisamide","perampanel","brivaracetam","felbamate",
 "rufinamide","vigabatrin","tiagabine","primidone","ethosuximide","phenobarb","eslicarbazepine","cenobamate")
isa <- function(x){ z <- tolower(x); Reduce(`|`, lapply(ASM, function(q) grepl(q, z, fixed=TRUE))) }
mc <- utils::read.csv("data-raw/MDE_Medications_cases_22.csv", colClasses="character")
md <- utils::read.csv("data-raw/IIH_medications_detail.csv", colClasses="character")
M <- rbind(data.frame(mrn=trimws(mc[[1]]), st=as.Date(substr(mc$Started.Date,1,10)),
                      en=as.Date(substr(mc$Ended.Date,1,10)), g=paste(mc$Medication.Generic.Name, mc$Medication.Name)),
           data.frame(mrn=trimws(md$clinic_number), st=as.Date(substr(md$start_date,1,10)),
                      en=as.Date(substr(md$end_date,1,10)), g=paste(md$asm_generic, md$medication_name)))
M <- M[isa(M$g) & !is.na(M$st), ]; FR <- as.Date("2026-09-03")
M$en[!is.na(M$en) & M$en >= as.Date("9999-01-01")] <- FR
M$en[!is.na(M$en) & (M$en > FR | M$en < M$st)] <- NA
sp <- tapply(seq_len(nrow(M)), M$mrn, function(k){
  s1 <- as.numeric(max(M$st[k])-min(M$st[k]))
  s2 <- suppressWarnings(max(as.numeric(M$en[k]-M$st[k]), na.rm=TRUE))
  max(s1, ifelse(is.finite(s2), s2, -1)) })
CH <- names(sp)[sp >= 180]
n_all <- sum(a$iih==1); n_ev <- nrow(ii); n_epi <- sum(ii$epi); n_asm <- sum(ii$mrn %in% CH)
CAS <- data.frame(
  stage=factor(c("Patients with IIH","Had a seizure","Recurrent / established epilepsy",
                 "On indefinite antiseizure therapy"),
        levels=rev(c("Patients with IIH","Had a seizure","Recurrent / established epilepsy",
                     "On indefinite antiseizure therapy"))),
  n=c(n_all, n_ev, n_epi, n_asm))
CAS$pct_of_cohort <- 100*CAS$n/n_all
CAS$lab <- c(sprintf("%s", format(n_all, big.mark=",")),
             sprintf("%d  (%.1f%% of the cohort)", n_ev, 100*n_ev/n_all),
             sprintf("%d  (%.0f%% of those who seized)", n_epi, 100*n_epi/n_ev),
             sprintf("%d  (%.0f%% of those who seized)", n_asm, 100*n_asm/n_ev))
CAS$fill <- c("cohort","sz","epi","asm")
p6 <- ggplot(CAS, aes(n, stage, fill=fill)) +
  geom_col(width=.62) +
  geom_text(aes(label=lab), hjust=-.04, size=3.3, colour=INK2) +
  scale_fill_manual(values=c(cohort="#c9cdd1", sz=D3, epi=D2, asm=D1), guide="none") +
  scale_x_log10(breaks=c(10,30,100,300,1000,3000), expand=expansion(mult=c(0,.42))) +
  labs(title="How far along the severity gradient the IIH arm travelled",
       subtitle="Counts within the matched IIH arm. Horizontal scale is logarithmic so the small stages remain visible.",
       x="Patients (log scale)", y=NULL,
       caption=paste(
        "Of 2,138 patients with IIH followed after the washout, 66 had an incident seizure, 41 of those met criteria for",
        "recurrent or established epilepsy, and 13 were on antiseizure medication for 180 days or more. All 13 fall inside",
        "the 41: nobody was treated indefinitely without also meeting the epilepsy criteria.",
        "The medication figure is a FLOOR, not a count. Prescribing data for this arm records inpatient administrations rather",
        "than outpatient prescriptions, so chronic community treatment is largely invisible; 19 patients in the whole IIH arm",
        "meet the 180-day threshold at all. Read 13 as the number that can be demonstrated, not the number that occurred.",
        sep="\n")) +
  theme_pub() + theme(panel.grid.major.y=element_blank())
save_fig(p6, "K_F6_severity_cascade", w=9.4, h=5)
write_tab(CAS[, c("stage","n","pct_of_cohort")], "K_T44_severity_cascade")
log_msg("K18 complete")
