## J4_figure.R ----------------------------------------------------------------
## Figures for the secondary outcome: of the patients who had a seizure, how
## many went on to recurrent / established epilepsy.
##
## J_F1  left  incidence of seizure in each arm (the primary outcome)
##       right of those seizures, epilepsy vs a single event
## J_F2  which channel of evidence identified epilepsy
##
## The control bar on the right of J_F1 is drawn in grey and annotated. It is
## not a comparable estimate: 63 of 64 outcome-positive controls carry an
## epilepsy-specific code, consistent with the control outcome having required
## stronger evidence to be called at all. Drawing it in the IIH colour would
## invite exactly the comparison the data cannot support.
##
## Built with facets rather than a panel-composition package: none is installed
## in this environment, and adding a dependency for layout alone is not worth
## the reproducibility cost.

source("R/00_setup.R"); suppressMessages(library(ggplot2))
log_msg("=== J4 figures ===")
P <- readRDS(file.path(PATH$derived, "J1_phenotype.rds"))$code
E <- readRDS(file.path(PATH$derived, "J3_event_classification.rds"))

PANEL <- c(a="Incident seizure, whole cohort",
           b="Of those seizures, how many became epilepsy")
FILLS <- c("Seizure"                        = "#B5443B",
           "Epilepsy (recurrent/established)"= "#8C2F27",
           "Single seizure"                  = "#E0A9A3",
           "Epilepsy (not comparable)"       = "#6E7379",
           "Single seizure (not comparable)" = "#C9CDD1")

## ---- left: incidence --------------------------------------------------------
a <- P[P$fu_seizure_end_day > 180, ]
A <- do.call(rbind, lapply(c(1,0), function(g){
  s <- a[a$iih==g, ]; ci <- stats::binom.test(sum(s$event), nrow(s))$conf.int
  data.frame(panel=PANEL["a"], arm=ifelse(g==1,"IIH","Control"), cls="Seizure",
             k=sum(s$event), n=nrow(s), pct=100*mean(s$event),
             lo=100*ci[1], hi=100*ci[2]) }))

## ---- right: epilepsy vs single ---------------------------------------------
B <- do.call(rbind, lapply(c(1,0), function(g){
  s <- E[E$iih==g, ]; nc <- g==0
  data.frame(panel=PANEL["b"], arm=ifelse(g==1,"IIH","Control"),
             cls=if (nc) c("Epilepsy (not comparable)","Single seizure (not comparable)")
                 else    c("Epilepsy (recurrent/established)","Single seizure"),
             k=c(sum(s$epilepsy), sum(!s$epilepsy)), n=nrow(s),
             pct=100*c(mean(s$epilepsy), mean(!s$epilepsy)),
             lo=NA_real_, hi=NA_real_) }))

D <- rbind(A, B)
D$arm   <- factor(D$arm, c("IIH","Control"))
D$panel <- factor(D$panel, PANEL)
D$cls   <- factor(D$cls, names(FILLS))
D$lab   <- ifelse(D$panel==PANEL["a"], sprintf("%.2f%%\n%d / %d", D$pct, D$k, D$n),
                                       sprintf("%d (%.0f%%)", D$k, D$pct))

p1 <- ggplot(D, aes(arm, pct, fill=cls)) +
  geom_col(width=.62, colour="white", linewidth=.4) +
  geom_errorbar(aes(ymin=lo, ymax=hi), width=.13, linewidth=.4, na.rm=TRUE) +
  geom_text(data=subset(D, panel==PANEL["a"]), aes(y=hi, label=lab),
            vjust=-0.35, size=3.3, lineheight=.95) +
  ## Segments large enough to hold a label get one inside; a sliver (the single
  ## non-epilepsy control) would have its label clipped, so it is called out
  ## beside the bar with a leader instead.
  geom_text(data=subset(D, panel==PANEL["b"] & pct >= 8), aes(label=lab),
            position=position_stack(vjust=.5), size=3.3,
            colour="white", fontface="bold") +
  geom_segment(data=subset(D, panel==PANEL["b"] & pct < 8),
               aes(x=as.numeric(arm)+.32, xend=as.numeric(arm)+.05, y=14, yend=pct/2),
               linewidth=.3, colour="grey35") +
  geom_text(data=subset(D, panel==PANEL["b"] & pct < 8),
            aes(x=as.numeric(arm)+.34, y=14, label=lab),
            hjust=0, size=3.1, colour="grey20") +
  facet_wrap(~panel, scales="free_y") +
  scale_fill_manual(values=FILLS, name=NULL) +
  ## Modest, symmetric padding: enough headroom for the left panel's labels
  ## without pushing the stacked right panel past 100%.
  scale_y_continuous(expand=expansion(c(.01,.14))) +
  coord_cartesian(clip="off") +
  labs(title="Seizure and epilepsy after idiopathic intracranial hypertension",
       subtitle="Left: risk of a first seizure. Right: among those who had one, how many had recurrent disease.",
       x=NULL, y="Percent",
       caption=paste(
        "Left panel: abstracted primary outcome, full cohort, symmetric 180-day washout, exact binomial intervals.",
        "Right panel: outcome-positive patients only. Epilepsy = 2+ coded seizures 30+ days apart, OR an epilepsy-specific G40/345 code",
        "or established-disease descriptor, OR antiseizure medication continued 180+ days; ascertained to last attended encounter, not to",
        "the seizure, since recurrence occurs after the first event. The control proportion is shown in grey because it is NOT comparable",
        "to the IIH proportion: 63 of 64 outcome-positive controls carry an epilepsy-specific code, consistent with the control outcome",
        "having required stronger evidence before it was called. Topiramate, gabapentin and clobazam are excluded from the medication",
        "channel, being IIH and pain therapies rather than seizure-specific.", sep="\n")) +
  theme_pub() + theme(legend.position="bottom")
save_fig(p1, "J_F1_epilepsy_vs_single_seizure", w=10, h=6.6)

## ---- channels ---------------------------------------------------------------
C <- do.call(rbind, lapply(c(1,0), function(g){
  s <- E[E$iih==g, ]
  data.frame(arm=ifelse(g==1,"IIH","Control"),
             ch=c("Recurrence\n2+ coded seizures\n30+ days apart",
                  "Epilepsy-specific code\nG40 / 345",
                  "Indefinite antiseizure\nmedication\n180+ days"),
             k=c(sum(s$ch_recurrence), sum(s$ch_epilepsy_code), sum(s$ch_chronic_asm)),
             n=nrow(s)) }))
C$arm <- factor(C$arm, c("IIH","Control")); C$ch <- factor(C$ch, unique(C$ch))
p2 <- ggplot(C, aes(ch, k, fill=arm)) +
  geom_col(position=position_dodge(.7), width=.6) +
  geom_text(aes(label=sprintf("%d/%d", k, n)), position=position_dodge(.7),
            vjust=-.4, size=3.1) +
  scale_fill_manual(values=c(IIH="#B5443B", Control="#4C6E9C"), name=NULL) +
  scale_y_continuous(expand=expansion(c(0,.2))) +
  labs(title="Which evidence identified epilepsy",
       subtitle="Among outcome-positive patients. Channels overlap; a patient meeting any one is classified as epilepsy.",
       x=NULL, y="Patients",
       caption=paste(
        "Denominators are the outcome-positive patients in each arm (IIH 102, control 64).",
        "The medication channel is not comparable between arms: only 17 of 102 IIH patients have any antiseizure medication record",
        "against 48 of 64 controls, and the commonest agent recorded in cases is fosphenytoin, an intravenous acute-seizure drug.",
        "The case medication file records inpatient administrations; the control file records outpatient prescriptions.", sep="\n")) +
  theme_pub() + theme(legend.position="bottom")
save_fig(p2, "J_F2_epilepsy_evidence_channels", w=9, h=5.8)
log_msg("J4 complete")
