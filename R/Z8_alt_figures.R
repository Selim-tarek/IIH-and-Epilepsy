## Z8_alt_figures.R -----------------------------------------------------------
## Candidate replacement figures.
##
## ALT-3: one slopegraph replacing the current two-panel Figure 3. Every outcome
## is drawn individually from its unadjusted to its healthcare-contact-adjusted
## hazard ratio. It does two jobs at once that currently need two panels plus a
## table: the left-hand column shows where seizure sits among the controls when
## unadjusted (mid-pack - the unfavourable fact, shown rather than buried), and
## the slopes show that all 11 controls fall toward the null while seizure rises.
## No medians, no cherry-picking: all 12 outcomes are visible.
##
## ALT-1: STROBE/RECORD cohort-assembly flow diagram, currently absent.

source("R/00_setup.R"); suppressMessages(library(ggplot2))
log_msg("=== Z8 alternative figures ===")
IIH_COL <- "#2a78d6"; CTL_COL <- "#eb6834"; INK <- "#1a1a1a"; MUTED <- "#595959"
OUT <- "outputs/figures_publication"

th <- function(base = 9) theme_classic(base_size = base) +
  theme(axis.text = element_text(colour = INK, size = base),
        axis.title = element_text(colour = INK, size = base + 0.5),
        axis.line = element_line(colour = "#404040", linewidth = 0.35),
        axis.ticks = element_line(colour = "#404040", linewidth = 0.35),
        plot.title = element_text(colour = INK, size = base + 1.5, face = "bold", hjust = 0),
        plot.subtitle = element_text(colour = MUTED, size = base - 0.5, hjust = 0),
        plot.caption = element_text(colour = MUTED, size = base - 1.5, hjust = 0),
        legend.position = "none", plot.margin = margin(6, 10, 6, 6))

save3 <- function(p, name, w_mm, h_mm) {
  w <- w_mm/25.4; h <- h_mm/25.4
  ggsave(file.path(OUT, paste0(name, ".pdf")), p, width=w, height=h, units="in", device=grDevices::cairo_pdf)
  ggsave(file.path(OUT, paste0(name, ".tiff")), p, width=w, height=h, units="in", dpi=600, compression="lzw")
  ggsave(file.path(OUT, paste0(name, ".png")), p, width=w, height=h, units="in", dpi=600)
  log_msg("wrote ", name, " (pdf / tiff / png 600dpi)")
}

## ---- ALT-3 slopegraph -------------------------------------------------------
d <- utils::read.csv(file.path(PATH$tables, "K_T47_contact_adjustment.csv"),
                     stringsAsFactors = FALSE)
d$outcome[d$outcome == "SEIZURE OR EPILEPSY"] <- "Seizure or epilepsy"
d$is_sz <- d$outcome == "Seizure or epilepsy"
d$outcome <- sub("Fracture, excl. skull/face", "Fracture", d$outcome)
d$outcome <- sub("Renal/ureteric stone", "Renal stone", d$outcome)
d$outcome <- sub("Upper respiratory infection", "URTI", d$outcome)
d$outcome <- sub("Otitis media or externa", "Otitis", d$outcome)
d$outcome <- sub("Laceration or open wound", "Laceration", d$outcome)
d$outcome <- sub("Acute appendicitis", "Appendicitis", d$outcome)
d$outcome <- sub("Contact dermatitis", "Dermatitis", d$outcome)
d$outcome <- sub("Sprain or strain", "Sprain", d$outcome)
d$outcome <- sub("Carpal tunnel", "Carpal tunnel", d$outcome)

long <- rbind(
  data.frame(outcome=d$outcome, is_sz=d$is_sz, x=1, hr=d$hr_unadj),
  data.frame(outcome=d$outcome, is_sz=d$is_sz, x=2, hr=d$hr_adj))

## Label de-collision: points are plotted at their true value, but the text is
## pushed apart on the log scale so that near-identical estimates stay legible.
spread <- function(v, gap = 0.052) {
  o <- order(v); y <- log(v[o])
  for (i in 2:length(y)) if (y[i] - y[i-1] < gap) y[i] <- y[i-1] + gap
  ## re-centre so the block is not pushed systematically upward
  y <- y - (mean(y) - mean(log(v[o])))
  out <- numeric(length(v)); out[o] <- exp(y); out
}
long$ly <- NA_real_
for (k in 1:2) long$ly[long$x == k] <- spread(long$hr[long$x == k])

p <- ggplot(long, aes(x, hr, group = outcome)) +
  geom_hline(yintercept = 1, colour = "#9a9a9a", linewidth = 0.4) +
  geom_line(data = subset(long, !is_sz), colour = CTL_COL, alpha = 0.5, linewidth = 0.5) +
  geom_point(data = subset(long, !is_sz), colour = CTL_COL, alpha = 0.8, size = 1.4) +
  geom_line(data = subset(long, is_sz), colour = IIH_COL, linewidth = 1.3) +
  geom_point(data = subset(long, is_sz), colour = IIH_COL, size = 2.7, shape = 18) +
  geom_text(data = subset(long, x == 1 & !is_sz),
            aes(x = 0.96, y = ly, label = sprintf("%s  %.2f", outcome, hr)),
            hjust = 1, size = 2.3, colour = "#8a4a2c") +
  geom_text(data = subset(long, x == 1 & is_sz),
            aes(x = 0.96, y = ly, label = sprintf("%s  %.2f", outcome, hr)),
            hjust = 1, size = 2.75, fontface = "bold", colour = IIH_COL) +
  geom_text(data = subset(long, x == 2 & !is_sz),
            aes(x = 2.04, y = ly, label = sprintf("%.2f", hr)),
            hjust = 0, size = 2.3, colour = "#8a4a2c") +
  geom_text(data = subset(long, x == 2 & is_sz),
            aes(x = 2.04, y = ly, label = sprintf("%.2f", hr)),
            hjust = 0, size = 2.75, fontface = "bold", colour = IIH_COL) +
  annotate("text", x = 1, y = 5.9, label = "Unadjusted",
           size = 3, fontface = "bold", colour = INK) +
  annotate("text", x = 2, y = 5.9, label = "Contact-adjusted",
           size = 3, fontface = "bold", colour = INK) +
  scale_x_continuous(NULL, limits = c(0.40, 2.26), breaks = NULL, expand = c(0, 0)) +
  scale_y_continuous("Hazard ratio, log scale", trans = "log",
                     breaks = c(0.8, 1, 1.5, 2, 3, 4, 5), limits = c(0.76, 6.4)) +
  labs(title = "Every negative control falls toward the null; seizure rises",
       subtitle = "All 12 outcomes individually. Orange, negative controls; blue, the primary outcome",
       caption = "Negative controls change by -18.8% to -42.6%, all toward the null; the seizure estimate changes by +12.6%.\nAn outcome generated purely by differential detection would be expected to behave as the controls do.") +
  th()
save3(p, "ALT_Figure_3_slopegraph", 150, 125)

## ---- ALT-1 cohort flow ------------------------------------------------------
fl <- data.frame(
  y = 6:1,
  lab = c("IIH patients with a diagnostic lumbar puncture",
          "Engaged: >=1 clinical encounter in the 12 months before index",
          "Matched to >=1 comparator (98.8%)",
          "Contributed follow-up beyond the 180-day washout",
          "Matched comparators used",
          "ANALYTIC COHORT"),
  n = c("2,618", "2,520", "2,490", "2,138", "5,743", "2,138 IIH + 5,743 comparators"),
  side = c("iih","iih","iih","iih","ctl","both"), stringsAsFactors = FALSE)
fl$fill <- ifelse(fl$side == "iih", "#dce8f7", ifelse(fl$side == "ctl", "#fbe2d6", "#eef1f4"))

f <- ggplot(fl) +
  geom_rect(aes(xmin = 0, xmax = 10, ymin = y - 0.34, ymax = y + 0.34, fill = I(fill)),
            colour = "#9aa4b0", linewidth = 0.3) +
  geom_text(aes(x = 0.35, y = y, label = lab), hjust = 0, size = 2.85, colour = INK) +
  geom_text(aes(x = 9.65, y = y, label = n), hjust = 1, size = 2.85,
            fontface = "bold", colour = INK) +
  geom_segment(data = data.frame(y = c(6,5,4)), aes(x = 5, xend = 5, y = y - 0.36, yend = y - 0.64),
               arrow = arrow(length = unit(1.6, "mm"), type = "closed"),
               colour = "#6a6a6a", linewidth = 0.35) +
  annotate("text", x = 10.25, y = 5.5, label = "98 excluded", hjust = 0, size = 2.4, colour = MUTED) +
  annotate("text", x = 10.25, y = 4.5, label = "30 unmatched", hjust = 0, size = 2.4, colour = MUTED) +
  annotate("text", x = 10.25, y = 3.5, label = "352 no post-washout\nfollow-up", hjust = 0, size = 2.4, colour = MUTED) +
  scale_x_continuous(NULL, limits = c(0, 13.6), breaks = NULL, expand = c(0, 0)) +
  scale_y_continuous(NULL, limits = c(0.45, 6.75), breaks = NULL, expand = c(0, 0)) +
  labs(title = "Cohort assembly",
       caption = "Comparators inherited the index date of their matched case; eligibility, washout and the\nprevalent-seizure exclusion were evaluated at that shared date.") +
  theme_void(base_size = 9) +
  theme(plot.title = element_text(face = "bold", size = 10.5, hjust = 0, colour = INK),
        plot.caption = element_text(size = 7, hjust = 0, colour = MUTED),
        plot.margin = margin(8, 8, 8, 8))
save3(f, "ALT_Figure_1_cohort_flow", 165, 95)
log_msg("Z8 complete")
