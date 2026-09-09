## J4_figure.R ----------------------------------------------------------------
## Figures for the secondary outcome: of the patients who had a seizure, how
## many went on to recurrent / established epilepsy rather than a single event.
##
##   J_F1  unit chart -- one square per outcome-positive patient, split by
##         epilepsy vs single seizure. This is the headline figure.
##   J_F2  absolute risk per 1,000 patients, so the split maps back onto the
##         whole cohort rather than onto the seizure subgroup alone.
##   J_F3  which channel of evidence identified epilepsy.
##
## COLOUR. Epilepsy vs single seizure is an ORDINAL contrast (one event, then
## recurrence), so it takes a single-hue two-step ramp, light to dark, rather
## than two categorical hues -- the darker step reads as "more disease" without
## having to consult the legend. Steps are the validated ordinal pair
## #86b6ef / #184f95 (light-end contrast 2.06:1 against the surface, above the
## 2:1 ordinal floor). Arm identity, where it is the thing being compared
## (J_F3), takes categorical slots 1 and 2, #2a78d6 / #eb6834: worst adjacent
## CVD delta-E 24.7, normal-vision 33.6. Both palettes were checked with the
## validator rather than by eye.
##
## The control arm in J_F1 and J_F2 is drawn in neutral grey, not in the ramp,
## and labelled on the plot. Its 98% epilepsy fraction is an artefact of how
## the control outcome was ascertained (63 of 64 carry an epilepsy-specific
## code), so putting it in the same colours as the IIH bars would invite
## exactly the comparison the data cannot support. Grey is the one honest
## encoding: present, but visibly not part of the comparison.

source("R/00_setup.R"); suppressMessages(library(ggplot2))
log_msg("=== J4 figures ===")
P <- readRDS(file.path(PATH$derived, "J1_phenotype.rds"))$code
E <- readRDS(file.path(PATH$derived, "J3_event_classification.rds"))

EPI  <- "#184f95"; SGL  <- "#86b6ef"       # ordinal ramp, dark = recurrent
EPIG <- "#5f6368"; SGLG <- "#c6c9cc"       # neutral pair for the control arm
INK  <- "#0b0b0b"; INK2 <- "#52514e"

## ---- J_F1  unit chart -------------------------------------------------------
## One square per patient. Squares are laid out in columns of ten so a reader
## can count them, and each arm's block is its own facet with its own count.
COLS <- 10
unit <- do.call(rbind, lapply(c(1,0), function(g){
  s <- E[E$iih==g, ]
  k <- sum(s$epilepsy); n <- nrow(s)
  cls <- rep(c("Epilepsy (recurrent)","Single seizure"), c(k, n-k))
  data.frame(arm=ifelse(g==1,"IIH","Control"),
             i=seq_len(n), cls=cls,
             col=(seq_len(n)-1) %% COLS, row=(seq_len(n)-1) %/% COLS,
             key=paste0(ifelse(g==1,"IIH","Control"), "|", cls)) }))
unit$arm <- factor(unit$arm, c("IIH","Control"))
lab <- do.call(rbind, lapply(c(1,0), function(g){
  s <- E[E$iih==g, ]
  data.frame(arm=ifelse(g==1,"IIH","Control"),
             txt=sprintf("%d of %d had epilepsy  (%.0f%%)", sum(s$epilepsy), nrow(s),
                         100*mean(s$epilepsy))) }))
lab$arm <- factor(lab$arm, c("IIH","Control"))
## Direct labels beside each block, so identity never rests on colour alone
## (and no legend box is needed). Placed at the vertical midpoint of each
## group's rows, in ink rather than in the series colour.
band <- do.call(rbind, lapply(c(1,0), function(g){
  s <- E[E$iih==g, ]; k <- sum(s$epilepsy); n <- nrow(s)
  mid <- function(a, b) -((a + b - 2)/2) %/% 1
  data.frame(arm=ifelse(g==1,"IIH","Control"),
             y=c(-mean(((seq_len(k))-1) %/% COLS), -mean(((k+seq_len(n-k))-1) %/% COLS)),
             txt=c(sprintf("Epilepsy\n(recurrent)  %d", k),
                   sprintf("Single seizure  %d", n-k))) }))
band$arm <- factor(band$arm, c("IIH","Control"))
nc <- data.frame(arm=factor("Control", c("IIH","Control")),
                 txt="not comparable\nto the IIH block\n(see caption)")
KEY <- c("IIH|Epilepsy (recurrent)"=EPI,  "IIH|Single seizure"=SGL,
         "Control|Epilepsy (recurrent)"=EPIG, "Control|Single seizure"=SGLG)

p1 <- ggplot(unit, aes(col, -row, fill=key)) +
  geom_tile(width=.86, height=.86, colour="#fcfcfb", linewidth=.9) +
  geom_text(data=lab, aes(x=(COLS-1)/2, y=1.05, label=txt), inherit.aes=FALSE,
            size=3.7, fontface="bold", colour=INK) +
  geom_text(data=band, aes(x=COLS - 0.3, y=y, label=txt), inherit.aes=FALSE,
            hjust=0, size=3.2, colour=INK2, lineheight=.95) +
  geom_text(data=nc, aes(x=(COLS-1)/2, y=-9.2, label=txt), inherit.aes=FALSE,
            size=3.2, fontface="italic", colour=INK2, lineheight=1) +
  facet_wrap(~arm, ncol=2) +
  scale_fill_manual(values=KEY, guide="none") +
  scale_x_continuous(expand=expansion(add=c(.6, 4.6))) +
  coord_equal(clip="off") +
  labs(title="Of the patients who had a seizure, how many went on to epilepsy",
       subtitle="One square = one patient. Dark = recurrent or established epilepsy; light = a single seizure event.",
       x=NULL, y=NULL,
       caption=paste(
        "Outcome-positive patients only (IIH 102, control 64). Epilepsy = two or more coded seizures at least 30 days apart, OR an",
        "epilepsy-specific G40/345 code or established-disease descriptor, OR antiseizure medication continued 180 days or more.",
        "Ascertained from index to last attended encounter, not to the seizure, since recurrence occurs after the first event.",
        "The control block is drawn in grey because its 98% is NOT comparable to the IIH figure: 63 of its 64 patients carry an",
        "epilepsy-specific code, consistent with the control outcome having required stronger evidence before it was called.",
        "Topiramate, gabapentin and clobazam are excluded from the medication channel, being IIH and pain therapies.", sep="\n")) +
  theme_pub() +
  theme(axis.text=element_blank(), axis.ticks=element_blank(),
        panel.grid=element_blank(), panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(), panel.border=element_blank(),
        strip.text=element_text(face="bold", size=11),
        plot.margin=margin(6,14,6,6))
save_fig(p1, "J_F1_epilepsy_vs_single_seizure", w=11, h=6.6)

## ---- J_F2  absolute risk per 1,000 ------------------------------------------
## The unit chart conditions on having had a seizure. This puts the same split
## back on the cohort denominator, which is what a clinician counselling an
## unselected IIH patient actually needs.
a <- P[P$fu_seizure_end_day > 180, ]
R <- do.call(rbind, lapply(c(1,0), function(g){
  s <- a[a$iih==g, ]; n <- nrow(s)
  ep <- sum(E$epilepsy[E$iih==g]); sg <- sum(!E$epilepsy[E$iih==g])
  data.frame(arm=ifelse(g==1,"IIH","Control"), n=n,
             cls=c("Epilepsy (recurrent)","Single seizure"),
             per1000=1000*c(ep, sg)/n, k=c(ep, sg)) }))
R$arm <- factor(R$arm, c("IIH","Control"))
R$key <- paste0(R$arm, "|", R$cls)
tot <- aggregate(per1000 ~ arm + n, R, sum)
p2 <- ggplot(R, aes(arm, per1000, fill=key)) +
  geom_col(width=.45, colour="#fcfcfb", linewidth=1.1) +
  geom_text(data=subset(R, per1000 >= 3), aes(label=sprintf("%.1f", per1000)),
            position=position_stack(vjust=.5), colour="white", fontface="bold", size=3.6) +
  geom_text(data=tot, aes(x=arm, y=per1000, label=sprintf("%.1f per 1,000\n(n = %s)",
            per1000, format(n, big.mark=","))), inherit.aes=FALSE, vjust=-.4,
            size=3.3, colour=INK2, lineheight=.95) +
  ## Direct labels at explicit coordinates to the right of the IIH stack --
  ## nudging from the bar centre collided with the value labels. The single
  ## control non-epilepsy patient (0.1 per 1,000) is too shallow to label in
  ## place and is called out beside the bar instead.
  annotate("text", x=1.27, y=27.5, label="Epilepsy (recurrent)",
           hjust=0, size=3.4, colour=INK2) +
  annotate("text", x=1.27, y=8, label="Single seizure",
           hjust=0, size=3.4, colour=INK2) +
  annotate("segment", x=2.27, xend=2.13, y=3.4, yend=0.4, linewidth=.3, colour=INK2) +
  annotate("text", x=2.29, y=3.7, label="0.1  single seizure",
           hjust=0, size=3.2, colour=INK2) +
  scale_fill_manual(values=KEY, guide="none") +
  scale_x_discrete(expand=expansion(add=c(.55, 1.15))) +
  scale_y_continuous(expand=expansion(c(0,.24))) +
  coord_cartesian(clip="off") +
  labs(title="Absolute risk in the whole cohort, per 1,000 patients",
       subtitle="The same split, on the cohort denominator rather than on the seizure subgroup.",
       x=NULL, y="Patients per 1,000",
       caption=paste(
        "Numerators are the outcome-positive patients classified in the unit chart; denominators are all patients at risk after the",
        "symmetric 180-day washout. Control bars in grey, for the reason given above: the split within the control arm is not a",
        "comparable quantity, though the control total is.", sep="\n")) +
  theme_pub()
save_fig(p2, "J_F2_absolute_risk_split", w=8, h=5.2)

## ---- J_F3  evidence channels ------------------------------------------------
## Here the arms ARE the comparison, so this figure uses the categorical pair.
C <- do.call(rbind, lapply(c(1,0), function(g){
  s <- E[E$iih==g, ]
  data.frame(arm=ifelse(g==1,"IIH","Control"),
             ch=c("Recurrence\n2+ coded seizures, 30+ days apart",
                  "Epilepsy-specific code\nG40 / 345",
                  "Indefinite antiseizure medication\n180+ days"),
             k=c(sum(s$ch_recurrence), sum(s$ch_epilepsy_code), sum(s$ch_chronic_asm)),
             n=nrow(s)) }))
C$arm <- factor(C$arm, c("IIH","Control")); C$ch <- factor(C$ch, rev(unique(C$ch)))
C$pct <- 100*C$k/C$n
p3 <- ggplot(C, aes(pct, ch, fill=arm)) +
  geom_col(position=position_dodge(.72), width=.6) +
  geom_text(aes(label=sprintf("%d/%d", k, n)), position=position_dodge(.72),
            hjust=-.18, size=3.2, colour=INK2) +
  scale_fill_manual(values=c(IIH="#2a78d6", Control="#eb6834"), name=NULL) +
  scale_x_continuous(expand=expansion(c(0,.16))) +
  labs(title="Which evidence identified epilepsy",
       subtitle="Percent of outcome-positive patients in each arm. Channels overlap; meeting any one is sufficient.",
       x="Percent of outcome-positive patients", y=NULL,
       caption=paste(
        "The medication channel is not comparable between arms: only 17 of 102 IIH patients have any antiseizure medication record",
        "against 48 of 64 controls, and the commonest agent recorded in cases is fosphenytoin, an intravenous acute-seizure drug.",
        "The case medication file records inpatient administrations; the control file records outpatient prescriptions.", sep="\n")) +
  theme_pub() + theme(legend.position="bottom", panel.grid.major.y=element_blank())
save_fig(p3, "J_F3_epilepsy_evidence_channels", w=9, h=5.4)
log_msg("J4 complete")
