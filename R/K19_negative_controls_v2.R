## K19_negative_controls_v2.R -------------------------------------------------
## Second negative-control panel, screened as pre-specified.
##
## ORDER MATTERS AND IS FOLLOWED HERE. Baseline balance is computed first and
## decides inclusion; the post-index hazard ratio is computed for every group
## so that the screen is auditable, but only balanced groups with adequate
## events are admitted to the panel. Every group pulled is reported, including
## the discards and the reason, so the screen is visible rather than implied.
##
## Admission criteria, fixed in advance (report/NEGATIVE_CONTROL_CODES.md):
##   1. baseline prevalence not significantly different between arms (p >= 0.05)
##   2. at least 25 events per arm
##
## Groups supplied: upper respiratory infection, otitis, sprains and strains,
## laceration and open wound of the limbs, contact dermatitis. Fractures -- the
## candidate most likely to succeed, being a broadening of the one outcome that
## balanced in the first panel -- were not supplied and are still outstanding.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K19 second negative-control panel ===")
V <- readRDS(file.path(PATH$derived, "K15_final_visits.rds")); a <- V$a
W <- 180; TAU <- 3

GRP <- list(
  "Upper respiratory infection" = list(f="NC2_dx_13.csv",
      pat="^J0[0-6]|^J09|^J1[01]|^J2[01]|^46[0-6]|^487|^488"),
  "Otitis media or externa"     = list(f="NC2_dx_14.csv",
      pat="^H6[0567]|^380\\.1|^38[12]"),
  "Sprain or strain"            = list(f="NC2_dx_16.csv",
      pat="^S[1-9]3|^84[0-8]"),
  "Laceration or open wound"    = list(f="NC2_dx_17.csv",
      pat="^S[4-9]1|^88[0-4]|^89[0-4]"),
  "Contact dermatitis"          = list(f="NC2_dx_18.csv",
      pat="^L2[345]|^692"),
  ## Fractures excluding skull and face -- the broadening of the one outcome
  ## that balanced in the first panel, and the strongest a priori candidate.
  "Fracture, excluding skull/face" = list(f="NC2_dx_20.csv",
      pat="^S[1-9]2|^8(0[5-9]|1[0-9]|2[0-9])"))

rows <- list()
for (nm in names(GRP)) {
  x <- utils::read.csv(file.path("data-raw", GRP[[nm]]$f), colClasses="character")
  ## Column order is not consistent between extracts: most are
  ## (mrn, system, code, description, date) but Diagnosis_20 is
  ## (mrn, date, system, code, description). Locate by header rather than
  ## position, so a reordered file cannot silently misread dates as codes.
  hn <- tolower(names(x))
  names(x)[grep("clinic", hn)[1]] <- "mrn"
  names(x)[grep("code$|diagnosis.code$", hn)[1]] <- "code"
  names(x)[grep("date", hn)[1]] <- "date"
  assert(all(c("mrn","code","date") %in% names(x)),
         paste("could not locate columns in", GRP[[nm]]$f))
  x$mrn <- trimws(x$mrn); x$date <- as.Date(substr(x$date,1,10))
  cov <- c(sum(unique(x$mrn) %in% a$mrn[a$iih==1]), sum(unique(x$mrn) %in% a$mrn[a$iih==0]))
  x <- x[grepl(GRP[[nm]]$pat, x$code) & !is.na(x$date), ]
  x$day <- as.numeric(x$date - a$index_date[match(x$mrn, a$mrn)])
  x <- x[!is.na(x$day), ]
  ## 1. baseline
  pre <- unique(x$mrn[x$day <= W])
  k1 <- sum(a$mrn[a$iih==1] %in% pre); n1 <- sum(a$iih==1)
  k0 <- sum(a$mrn[a$iih==0] %in% pre); n0 <- sum(a$iih==0)
  ft <- stats::fisher.test(matrix(c(k1, n1-k1, k0, n0-k0), 2))
  ## 2. post-index
  post <- tapply(x$day[x$day > W], x$mrn[x$day > W], min)
  s <- a[!(a$mrn %in% pre), ]
  dd <- as.numeric(post[s$mrn])
  s$ev2 <- as.integer(!is.na(dd) & dd <= s$open + 1e-6)
  s$t2  <- (ifelse(s$ev2==1, dd, s$open) - W)/365.25
  s <- s[s$t2 > 0, ]
  e1 <- sum(s$ev2[s$iih==1]); e0 <- sum(s$ev2[s$iih==0])
  hr <- c(NA,NA,NA)
  if (e1 >= 3 && e0 >= 3) { m <- coxph(Surv(t2,ev2) ~ iih, data=s, cluster=match_set)
    ss <- summary(m); if (abs(ss$coef[1,1]) <= 5) hr <- ss$conf.int[c(1,3,4)] }
  bal <- ft$p.value >= .05
  pw  <- e1 >= 25 && e0 >= 25
  rows[[nm]] <- data.frame(outcome=nm,
    patients_in_file_iih=cov[1], patients_in_file_ctl=cov[2],
    baseline_iih_pct=round(100*k1/n1,2), baseline_ctl_pct=round(100*k0/n0,2),
    baseline_ratio=round((k1/n1)/(k0/n0),2), baseline_p=signif(ft$p.value,3),
    events_iih=e1, events_ctl=e0,
    hr=hr[1], lo=hr[2], hi=hr[3],
    estimate=if (is.na(hr[1])) "not estimable" else fmt_est(hr[1], hr[2], hr[3]),
    verdict=if (!bal) "EXCLUDED - baseline imbalanced"
            else if (!pw) "EXCLUDED - too few events"
            else "ADMITTED")
}
P <- do.call(rbind, rows)
write_tab(P, "K_T45_negative_controls_v2")
print(P[, c("outcome","baseline_iih_pct","baseline_ctl_pct","baseline_ratio","baseline_p",
            "events_iih","events_ctl","estimate","verdict")], row.names=FALSE)
saveRDS(P, file.path(PATH$derived, "K19_nc2.rds"))
log_msg("admitted: ", sum(P$verdict == "ADMITTED"), " of ", nrow(P))
log_msg("K19 complete")
