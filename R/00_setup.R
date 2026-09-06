## 00_setup.R -----------------------------------------------------------------
## IIH -> incident seizure/epilepsy matched cohort study
## Protocol: IIH_Epilepsy_Protocol_v2.md (v2.0)
## Sourced by every other script. Never loads raw data.

options(stringsAsFactors = FALSE, width = 120, warn = 1)
set.seed(20250906)
SEED <- 20250906

## Administrative data-freeze date. Records dated after this are not real
## follow-up: the export contains encounter and derived end-of-follow-up dates
## running to 2031-2038. All person-time is administratively censored here.
FREEZE_DATE <- as.Date("2026-08-31")

## ---- paths (all project-relative) ------------------------------------------
PATH <- list(
  raw      = file.path("data-raw", "IIH_MASTER_cases_and_controls_2.csv"),
  derived  = "data-derived",
  tables   = file.path("outputs", "tables"),
  figures  = file.path("outputs", "figures"),
  diag     = file.path("outputs", "diagnostics"),
  logs     = file.path("outputs", "logs"),
  report   = "report"
)
for (p in PATH[c("derived","tables","figures","diag","logs","report")]) {
  dir.create(p, showWarnings = FALSE, recursive = TRUE)
}

## ---- dependencies ----------------------------------------------------------
## Hard requirements. The pipeline is deliberately written against a small,
## stable dependency set so it runs on a clean machine. Optional packages are
## used only if present (has_pkg()) and never silently change an estimate.
REQUIRED <- c("survival")
OPTIONAL <- c("ggplot2", "data.table", "splines")

has_pkg <- function(p) requireNamespace(p, quietly = TRUE)

missing_req <- REQUIRED[!vapply(REQUIRED, has_pkg, logical(1))]
if (length(missing_req)) {
  stop("Missing required packages: ", paste(missing_req, collapse = ", "),
       "\nInstall with: install.packages(c(",
       paste(sprintf('"%s"', missing_req), collapse = ", "), "))")
}
suppressPackageStartupMessages(library(survival))
HAS_GG <- has_pkg("ggplot2")
if (HAS_GG) suppressPackageStartupMessages(library(ggplot2))

## ---- missing-value codes ---------------------------------------------------
## The source file uses THREE distinct kinds of absence. Conflating them is the
## single most common way to get this dataset wrong, so they are kept apart
## everywhere downstream:
##   ""  (blank) -> STRUCTURALLY ABSENT: the variable was never extracted for
##                  this group (e.g. every imaging variable in controls).
##                  Not missing-at-random. NEVER impute.
##   99          -> "unknown after searching" (looked for, not found/recorded)
##   88          -> "not applicable / not assessable" (e.g. imaging not
##                  technically capable of showing an encephalocele).
##                  An unassessable scan is NOT a negative scan.
MISS_UNKNOWN     <- 99L
MISS_NOTAPPLIC   <- 88L

## num_clean(): numeric conversion that refuses to turn 88/99 into data.
num_clean <- function(x, sentinels = c(MISS_UNKNOWN, MISS_NOTAPPLIC)) {
  x <- suppressWarnings(as.numeric(trimws(as.character(x))))
  x[x %in% sentinels] <- NA_real_
  x
}
## num_raw(): numeric conversion KEEPING sentinels (for auditing them).
num_raw <- function(x) suppressWarnings(as.numeric(trimws(as.character(x))))

## chr_clean(): blank -> NA, but 88/99 preserved as labelled levels.
chr_clean <- function(x) {
  x <- trimws(as.character(x)); x[x == ""] <- NA_character_; x
}

date_clean <- function(x) {
  x <- trimws(as.character(x)); x[x == ""] <- NA_character_
  as.Date(substr(x, 1, 10))
}

## ---- small statistical helpers (hand-rolled to avoid heavy deps) -----------

## Standardised mean difference. Continuous: Cohen-style pooled-SD form.
## Binary/categorical: multi-level SMD (Yang & Dalton). Returned unsigned=FALSE
## so direction is interpretable.
smd_cont <- function(x, g) {
  x1 <- x[g == 1]; x0 <- x[g == 0]
  m1 <- mean(x1, na.rm = TRUE); m0 <- mean(x0, na.rm = TRUE)
  v1 <- stats::var(x1, na.rm = TRUE); v0 <- stats::var(x0, na.rm = TRUE)
  den <- sqrt((v1 + v0) / 2)
  if (!is.finite(den) || den == 0) return(NA_real_)
  (m1 - m0) / den
}
smd_bin <- function(x, g) {
  p1 <- mean(x[g == 1], na.rm = TRUE); p0 <- mean(x[g == 0], na.rm = TRUE)
  den <- sqrt((p1 * (1 - p1) + p0 * (1 - p0)) / 2)
  if (!is.finite(den) || den == 0) return(NA_real_)
  (p1 - p0) / den
}

## Exact (Garwood) Poisson confidence interval for a rate.
pois_rate_ci <- function(events, ptime, per = 1000, conf = 0.95) {
  a <- (1 - conf) / 2
  lo <- if (events == 0) 0 else stats::qchisq(a, 2 * events) / 2
  hi <- stats::qchisq(1 - a, 2 * (events + 1)) / 2
  c(rate = per * events / ptime, lo = per * lo / ptime, hi = per * hi / ptime)
}

## Exact Poisson test for an incidence-rate ratio (binomial conditional test).
irr_exact <- function(e1, t1, e0, t0, conf = 0.95) {
  bt <- stats::binom.test(e1, e1 + e0, p = t1 / (t1 + t0), conf.level = conf)
  f  <- t0 / t1
  cnv <- function(p) p / (1 - p) * f
  c(irr = cnv(e1 / (e1 + e0)),
    lo  = cnv(bt$conf.int[1]), hi = cnv(bt$conf.int[2]), p = bt$p.value)
}

## E-value for an observed hazard ratio (VanderWeele & Ding), using the
## sqrt-approximation appropriate for a rare outcome (<15%) HR.
evalue_hr <- function(hr, lo, hi, rare = TRUE) {
  f <- function(r) { r <- if (r < 1) 1 / r else r; r + sqrt(r * (r - 1)) }
  bound <- if (rare) f(hr) else f(hr)
  ci_lim <- if (hr > 1) lo else hi
  c(point = bound,
    ci    = if ((hr > 1 && ci_lim <= 1) || (hr < 1 && ci_lim >= 1)) 1 else f(ci_lim))
}

fmt_est <- function(e, l, u, d = 2)
  sprintf(paste0("%.", d, "f (%.", d, "f to %.", d, "f)"), e, l, u)

fmt_p <- function(p) ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))

## ---- assertions ------------------------------------------------------------
assert <- function(cond, msg) {
  if (!isTRUE(all(cond))) stop("ASSERTION FAILED: ", msg, call. = FALSE)
  invisible(TRUE)
}

## ---- logging ---------------------------------------------------------------
log_msg <- function(...) {
  msg <- paste0("[", format(Sys.time(), "%H:%M:%S"), "] ", paste0(..., collapse = ""))
  cat(msg, "\n")
  cat(msg, "\n", file = file.path(PATH$logs, "pipeline.log"), append = TRUE)
}

write_tab <- function(x, name) {
  f <- file.path(PATH$tables, paste0(name, ".csv"))
  utils::write.csv(x, f, row.names = FALSE)
  log_msg("wrote ", f, " (", nrow(x), " rows)")
  invisible(f)
}

save_fig <- function(plot, name, w = 8, h = 5.5, dpi = 300) {
  if (!HAS_GG) { log_msg("ggplot2 absent; skipped figure ", name); return(invisible(NULL)) }
  ggplot2::ggsave(file.path(PATH$figures, paste0(name, ".png")), plot,
                  width = w, height = h, dpi = dpi)
  ggplot2::ggsave(file.path(PATH$figures, paste0(name, ".pdf")), plot,
                  width = w, height = h)
  log_msg("wrote figure ", name, " (.png/.pdf)")
}

## ---- house style -----------------------------------------------------------
## Grayscale-safe: the two cohort colours differ in lightness as well as hue.
COL <- c(control = "#4C72B0", iih = "#D1495B",
         neutral = "#7F7F7F", accent = "#2A9D8F", warn = "#E9C46A")
COHORT_COL <- c("Non-IIH control" = COL[["control"]], "IIH" = COL[["iih"]])

theme_pub <- function(base_size = 11) {
  if (!HAS_GG) return(NULL)
  ggplot2::theme_bw(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(linewidth = 0.25, colour = "grey88"),
      panel.border     = ggplot2::element_rect(colour = "grey30", linewidth = 0.4),
      strip.background = ggplot2::element_rect(fill = "grey94", colour = "grey30"),
      plot.title       = ggplot2::element_text(face = "bold", size = base_size + 1),
      plot.subtitle    = ggplot2::element_text(colour = "grey25", size = base_size - 1),
      plot.caption     = ggplot2::element_text(colour = "grey35", size = base_size - 2,
                                               hjust = 0),
      legend.position  = "bottom", legend.title = ggplot2::element_blank()
    )
}
