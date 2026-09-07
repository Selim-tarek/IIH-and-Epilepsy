################################################################################
## IIH -> INCIDENT SEIZURE / EPILEPSY : COMPLETE STANDALONE ANALYSIS
##
## Runs the entire analysis on IIH_MASTER_FINAL.xlsx and writes every table and
## figure to ./outputs. Nothing else is required -- no other scripts, no
## project structure.
##
## HOW TO RUN
##   1. Put this file and IIH_MASTER_FINAL.xlsx in the same folder.
##   2. Open R (or RStudio) in that folder.
##   3. source("IIH_analysis_standalone.R")
##
##   Or from a terminal:  Rscript IIH_analysis_standalone.R
##
## If the workbook is somewhere else, set DATA_FILE below.
##
## Requires R >= 4.0. Missing packages are installed automatically unless you
## set AUTO_INSTALL <- FALSE.
################################################################################

## ============================ CONFIGURATION ================================ ##
DATA_FILE    <- "IIH_MASTER_FINAL.xlsx"   # path to the workbook
OUT_DIR      <- "outputs"                 # everything is written here
TAU          <- 3                         # primary horizon, years after day 180
SEED         <- 20250906
BOOT_REPS    <- 400                       # cluster bootstrap for RMTL; lower = faster
AUTO_INSTALL <- TRUE                      # install missing packages
MED_SUMMARY  <- "IIH_medications_patient_summary.csv"  # optional
MED_DETAIL   <- "IIH_medications_detail.csv"           # optional
## =========================================================================== ##

set.seed(SEED)
options(stringsAsFactors = FALSE, warn = 1)

## ---- packages --------------------------------------------------------------
need <- c("survival", "readxl", "ggplot2")
miss <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss)) {
  if (!AUTO_INSTALL)
    stop("Missing packages: ", paste(miss, collapse = ", "),
         "\nInstall them, or set AUTO_INSTALL <- TRUE.")
  message("Installing: ", paste(miss, collapse = ", "))
  install.packages(miss, repos = "https://cloud.r-project.org")
}
suppressPackageStartupMessages({ library(survival); library(ggplot2) })

dir.create(file.path(OUT_DIR, "tables"),  recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(OUT_DIR, "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(OUT_DIR, "logs"),    recursive = TRUE, showWarnings = FALSE)

say <- function(...) cat("[", format(Sys.time(), "%H:%M:%S"), "] ", ..., "\n", sep = "")
wr  <- function(x, name) {
  utils::write.csv(x, file.path(OUT_DIR, "tables", paste0(name, ".csv")), row.names = FALSE)
  say("table  ", name, " (", nrow(x), " rows)")
}
assert <- function(cond, msg) {
  if (!isTRUE(all(cond))) stop("ASSERTION FAILED: ", msg, call. = FALSE)
}

## ---- house style -----------------------------------------------------------
COL <- c(control = "#4C72B0", iih = "#D1495B", neutral = "#7F7F7F",
         accent = "#2A9D8F", warn = "#E9C46A")
COHORT_COL <- c("Non-IIH control" = COL[["control"]], "IIH" = COL[["iih"]])
theme_pub <- function(base_size = 11) {
  theme_bw(base_size = base_size) +
    theme(panel.grid.minor = element_blank(),
          panel.grid.major = element_line(linewidth = 0.25, colour = "grey88"),
          panel.border = element_rect(colour = "grey30", linewidth = 0.4),
          strip.background = element_rect(fill = "grey94", colour = "grey30"),
          plot.title = element_text(face = "bold", size = base_size + 1),
          plot.subtitle = element_text(colour = "grey25", size = base_size - 1),
          plot.caption = element_text(colour = "grey35", size = base_size - 2, hjust = 0),
          legend.position = "bottom", legend.title = element_blank())
}
sav <- function(p, name, w = 8, h = 5.5) {
  ggsave(file.path(OUT_DIR, "figures", paste0(name, ".png")), p, width = w, height = h, dpi = 300)
  ggsave(file.path(OUT_DIR, "figures", paste0(name, ".pdf")), p, width = w, height = h)
  say("figure ", name)
}

## ---- statistical helpers ---------------------------------------------------
## Missing-value codes. 88 = not applicable / not assessable, 99 = unknown after
## searching, blank = never extracted for that cohort. These are kept distinct:
## an unassessable scan is NOT a negative scan and must never be imputed as one.
MISS_UNKNOWN <- 99L; MISS_NOTAPPLIC <- 88L
num_clean <- function(x) { x <- suppressWarnings(as.numeric(trimws(as.character(x))))
                           x[x %in% c(MISS_UNKNOWN, MISS_NOTAPPLIC)] <- NA_real_; x }
num_raw   <- function(x) suppressWarnings(as.numeric(trimws(as.character(x))))
chr_clean <- function(x) { x <- trimws(as.character(x)); x[x == "" | x == "NA"] <- NA; x }
date_clean<- function(x) { x <- trimws(as.character(x)); x[x == ""] <- NA; as.Date(substr(x, 1, 10)) }

smd_cont <- function(x, g) {
  m1 <- mean(x[g==1], na.rm=TRUE); m0 <- mean(x[g==0], na.rm=TRUE)
  den <- sqrt((var(x[g==1], na.rm=TRUE) + var(x[g==0], na.rm=TRUE)) / 2)
  if (!is.finite(den) || den == 0) NA_real_ else (m1 - m0) / den
}
smd_bin <- function(x, g) {
  p1 <- mean(x[g==1], na.rm=TRUE); p0 <- mean(x[g==0], na.rm=TRUE)
  den <- sqrt((p1*(1-p1) + p0*(1-p0)) / 2)
  if (!is.finite(den) || den == 0) NA_real_ else (p1 - p0) / den
}
## Exact (Garwood) Poisson interval for a rate.
pois_rate_ci <- function(e, pt, per = 1000, conf = 0.95) {
  a <- (1 - conf) / 2
  lo <- if (e == 0) 0 else qchisq(a, 2*e)/2
  c(rate = per*e/pt, lo = per*lo/pt, hi = per*qchisq(1-a, 2*(e+1))/2/pt)
}
## Exact conditional (binomial) test for an incidence-rate ratio.
irr_exact <- function(e1, t1, e0, t0) {
  bt <- binom.test(e1, e1 + e0, p = t1/(t1 + t0)); f <- t0/t1
  cv <- function(p) p/(1-p)*f
  c(irr = cv(e1/(e1+e0)), lo = cv(bt$conf.int[1]), hi = cv(bt$conf.int[2]), p = bt$p.value)
}
## E-value (VanderWeele & Ding), rare-outcome HR approximation.
evalue_hr <- function(hr, lo, hi) {
  f <- function(r) { r <- if (r < 1) 1/r else r; r + sqrt(r*(r-1)) }
  lim <- if (hr > 1) lo else hi
  c(point = f(hr), ci = if ((hr > 1 && lim <= 1) || (hr < 1 && lim >= 1)) 1 else f(lim))
}
fmt_est <- function(e, l, u, d = 2)
  sprintf(paste0("%.",d,"f (%.",d,"f to %.",d,"f)"), e, l, u)
fmt_p <- function(p) ifelse(is.na(p), NA, ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))

################################################################################
## 1. IMPORT AND AUDIT
################################################################################
say("=== 1. import ===")
assert(file.exists(DATA_FILE), paste("workbook not found:", DATA_FILE,
       "-- set DATA_FILE at the top of this script"))
CUTOFF <- as.Date("2026-09-03")   # data cutoff stated in the Source_Manifest sheet

## Sheets carry banner rows above the real header.
rd <- function(sheet, skip) as.data.frame(readxl::read_excel(
        DATA_FILE, sheet = sheet, skip = skip, col_types = "text", .name_repair = "minimal"))
raw  <- rd("Analysis_Cohort", 4)
excl <- rd("Excluded_from_analysis", 2)
raw  <- raw[!is.na(raw$record_id) & raw$record_id != "", ]
excl <- excl[!is.na(excl$record_id) & excl$record_id != "", ]
say("cohort: ", nrow(raw), " rows x ", ncol(raw), " cols | excluded sheet: ", nrow(excl))

d <- data.frame(row.names = seq_len(nrow(raw)))
d$record_id <- chr_clean(raw$record_id)
d$match_set <- chr_clean(raw$match_set)
d$match_tier<- chr_clean(raw$match_tier)
d$iih       <- num_raw(raw$group)
d$cohort    <- factor(ifelse(d$iih == 1, "IIH", "Non-IIH control"),
                      levels = c("Non-IIH control", "IIH"))
d$index_date     <- date_clean(raw$index_date)
d$last_encounter <- date_clean(raw$last_encounter)
d$death_date     <- date_clean(raw$death_date)
d$seizure_date   <- date_clean(raw$seizure_date)
d$index_year <- as.integer(format(d$index_date, "%Y"))
d$sex        <- factor(chr_clean(raw$sex), levels = c("F", "M"))
d$age_index  <- num_clean(raw$age_index)
d$bmi_index  <- num_clean(raw$bmi_index)

## Outcome and time. `event` is the outcome AFTER the symmetric 180-day washout;
## t_y is post-washout person-time to event, death, or last ATTENDED encounter.
d$event    <- num_clean(raw$event)
d$lat_days <- num_clean(raw$lat_days)
d$t_y      <- num_clean(raw$t_y)
d$e3 <- num_clean(raw$e3); d$t3 <- num_clean(raw$t3)
d$censoring_verifiable <- num_clean(raw$censoring_verifiable)
d$carpal_incident      <- num_clean(raw$carpal_incident)
d$died <- as.integer(!is.na(d$death_date))
d$osa <- num_clean(raw$osa); d$pcos <- num_clean(raw$pcos); d$htn <- num_clean(raw$htn)
d$smoking   <- chr_clean(raw$smoking)
d$shunt <- num_clean(raw$shunt); d$stent <- num_clean(raw$stent)
d$op_cmh2o  <- num_clean(raw$op_cmh2o)
d$enc_pre12 <- num_clean(raw$enc_pre12)
d$enc_post  <- num_clean(raw$enc_post)
d$enceph_index <- ifelse(num_raw(raw$enceph_index) %in% 0:1,
                         num_raw(raw$enceph_index), NA_real_)
d$enceph_status <- factor(ifelse(
  is.na(chr_clean(raw$enceph_index)), "not_extracted",
  ifelse(num_raw(raw$enceph_index) == MISS_NOTAPPLIC, "not_assessable",
  ifelse(num_raw(raw$enceph_index) == MISS_UNKNOWN, "unknown_after_search", "assessed"))))

## ---- assertions: verify, do not trust --------------------------------------
assert(!any(duplicated(d$record_id)), "record_id not unique")
assert(all(d$iih %in% c(0,1)), "group not 0/1")
assert(all(!is.na(d$t_y)) && all(d$t_y > 0), "missing or non-positive t_y")
assert(all(!is.na(d$event)), "missing outcome")
assert(all(d$censoring_verifiable == 1), "a row has unverifiable censoring")
assert(sum(d$last_encounter > CUTOFF, na.rm=TRUE) == 0, "encounter after cutoff")
assert(sum(d$seizure_date  > CUTOFF, na.rm=TRUE) == 0, "seizure after cutoff")
assert(all(d$lat_days >= 180, na.rm=TRUE), "an event falls inside the 180-day washout")
assert(all(d$match_set[d$iih==1] == d$record_id[d$iih==1]), "case match_set != record_id")
assert(all(d$match_set[d$iih==0] %in% d$record_id[d$iih==1]), "control points at no case")
assert(max(abs(pmin(d$t_y,3) - d$t3)) < 1e-6, "supplied t3 != pmin(t_y,3)")
assert(all(ifelse(d$t_y > 3, 0, d$event) == d$e3), "supplied e3 != 3-year truncated event")
say("all structural assertions passed")

## Washout symmetry -- the defect this workbook fixes.
wash <- do.call(rbind, lapply(c(1,0), function(g) {
  s <- d[d$iih == g & d$event == 1, ]
  data.frame(cohort = ifelse(g==1,"IIH","Non-IIH control"), events = nrow(s),
             earliest_event_day = min(s$lat_days), latest_event_day = max(s$lat_days))
}))
wr(wash, "S1_washout_symmetry"); print(wash)

n_per <- table(factor(d$match_set[d$iih==0], levels = d$record_id[d$iih==1]))
ratio <- as.data.frame(table(controls_in_set = as.integer(n_per)))
names(ratio) <- c("controls_in_set","n_cases")
ratio$pct <- round(100*ratio$n_cases/sum(ratio$n_cases),1)
wr(ratio, "T2b_matching_ratio")
say("mean controls/case = ", sprintf("%.2f", mean(as.integer(n_per))),
    " | full 1:4 sets = ", sprintf("%.1f%%", 100*mean(as.integer(n_per)==4)))

flow <- rbind(
  data.frame(step="Final matched cohort", n=nrow(d)),
  data.frame(step="  IIH cases", n=sum(d$iih==1)),
  data.frame(step="  Matched controls", n=sum(d$iih==0)),
  do.call(rbind, lapply(split(excl, excl$reason), function(s)
    data.frame(step=paste0("Excluded: ", s$reason[1]), n=nrow(s)))))
wr(flow, "T2_cohort_flow"); print(flow)

## Truncate at tau years of post-washout time.
cut_at <- function(dat, tau) {
  dat$t   <- pmin(dat$t_y, tau)
  dat$ev  <- ifelse(dat$t_y > tau, 0L, as.integer(dat$event))
  dat$evc <- ifelse(dat$t_y > tau, 0L,
                    ifelse(dat$event == 1, 1L, ifelse(dat$died == 1, 2L, 0L)))
  dat
}
a <- d

################################################################################
## 2. BASELINE TABLE AND BALANCE
################################################################################
say("=== 2. balance ===")
BR <- list()
addc <- function(v, lab) { x <- a[[v]]; g <- a$iih
  BR[[lab]] <<- data.frame(variable=lab,
    iih=sprintf("%.1f (%.1f)", mean(x[g==1],na.rm=TRUE), sd(x[g==1],na.rm=TRUE)),
    control=sprintf("%.1f (%.1f)", mean(x[g==0],na.rm=TRUE), sd(x[g==0],na.rm=TRUE)),
    smd=round(smd_cont(x,g),3)) }
addb <- function(v, lab, pos=1) { x <- as.numeric(a[[v]] == pos); g <- a$iih
  BR[[lab]] <<- data.frame(variable=lab,
    iih=sprintf("%d (%.1f%%)", sum(x[g==1],na.rm=TRUE), 100*mean(x[g==1],na.rm=TRUE)),
    control=sprintf("%d (%.1f%%)", sum(x[g==0],na.rm=TRUE), 100*mean(x[g==0],na.rm=TRUE)),
    smd=round(smd_bin(x,g),3)) }
addc("age_index","Age at index, y"); addc("bmi_index","BMI, kg/m2")
addb("sex","Female","F"); addc("index_year","Index year")
addb("osa","Obstructive sleep apnoea"); addb("htn","Hypertension"); addb("pcos","PCOS")
addc("enc_pre12","Encounters, 12 mo pre-index")
addc("enc_post","Encounters post-index (POST-EXPOSURE)")
addc("t_y","Post-washout follow-up, y (POST-EXPOSURE)")
bal <- do.call(rbind, BR); rownames(bal) <- NULL
bal$balance <- ifelse(abs(bal$smd) < 0.1, "balanced (|SMD|<0.1)", "IMBALANCED")
wr(bal, "T1_baseline_balance"); print(bal)

################################################################################
## 3. INCIDENCE RATES
################################################################################
say("=== 3. incidence ===")
rate_block <- function(tau, label) {
  s <- cut_at(a, tau)
  out <- do.call(rbind, lapply(c(0,1), function(g) {
    ss <- s[s$iih==g,]; r <- pois_rate_ci(sum(ss$ev), sum(ss$t))
    data.frame(horizon=label, cohort=ifelse(g==1,"IIH","Non-IIH control"),
               n=nrow(ss), events=sum(ss$ev), person_years=round(sum(ss$t),1),
               rate_per_1000py=round(r[["rate"]],2),
               rate_lo=round(r[["lo"]],2), rate_hi=round(r[["hi"]],2)) }))
  ir <- irr_exact(sum(s$ev[s$iih==1]), sum(s$t[s$iih==1]),
                  sum(s$ev[s$iih==0]), sum(s$t[s$iih==0]))
  out$irr <- c(NA, round(ir[["irr"]],2)); out$irr_lo <- c(NA, round(ir[["lo"]],2))
  out$irr_hi <- c(NA, round(ir[["hi"]],2)); out$irr_p <- c(NA, signif(ir[["p"]],3))
  out
}
rates <- rbind(rate_block(3,"3 years (primary)"), rate_block(5,"5 years"),
               rate_block(Inf,"full follow-up"))
wr(rates, "T3_incidence_rates"); print(rates)

################################################################################
## 4. COX MODELS
################################################################################
say("=== 4. Cox models ===")
## Variance: matched sets are the unit of dependence, and matching is
## variable-ratio, so unstratified models use a robust sandwich clustered on
## match_set rather than assuming a fixed 1:4 design.
fitc <- function(dat, tau, rhs, label, strat = FALSE, wts = NULL, note = "") {
  s <- cut_at(dat, tau)
  f <- as.formula(paste("Surv(t, ev) ~", rhs, if (strat) "+ strata(match_set)" else ""))
  fit <- if (strat) coxph(f, data=s, ties="efron")
         else if (!is.null(wts)) coxph(f, data=s, weights=s[[wts]],
                                       cluster=s$match_set, robust=TRUE, ties="efron")
         else coxph(f, data=s, cluster=s$match_set, robust=TRUE, ties="efron")
  sm <- summary(fit)
  data.frame(model=label, horizon_y=tau, n=fit$n, events=fit$nevent,
             hr=round(sm$conf.int[1,1],2), lo=round(sm$conf.int[1,3],2),
             hi=round(sm$conf.int[1,4],2),
             p=signif(sm$coefficients[1, ncol(sm$coefficients)],3), note=note)
}
## Propensity score for IPTW and as a balance diagnostic.
ps <- a[complete.cases(a[,c("age_index","bmi_index","sex","index_year")]),]
psf <- glm(iih ~ age_index + bmi_index + sex + index_year, family=binomial, data=ps)
ps$ps <- fitted(psf)
cstat <- { r <- rank(ps$ps); n1 <- sum(ps$iih==1); n0 <- sum(ps$iih==0)
           (sum(r[ps$iih==1]) - n1*(n1+1)/2)/(n1*n0) }
pm <- mean(ps$iih)
ps$iptw <- ifelse(ps$iih==1, pm/ps$ps, (1-pm)/(1-ps$ps))
qq <- quantile(ps$iptw, c(.01,.99)); ps$iptw_trim <- pmin(pmax(ps$iptw, qq[1]), qq[2])
say("propensity c-statistic = ", sprintf("%.3f", cstat))

models <- rbind(
  fitc(a, 3, "iih", "Cox, 3-year (PRIMARY)", note="robust SE clustered on match_set"),
  fitc(a, 3, "iih", "Cox stratified by matched set", strat=TRUE, note="conditional"),
  fitc(ps,3, "iih", "Cox, IPTW (stabilised, trimmed)", wts="iptw_trim", note="marginal"),
  fitc(a, 3, "iih + age_index + bmi_index + sex", "Cox + age/BMI/sex"),
  fitc(a, 5, "iih", "Cox, 5-year"),
  fitc(a, Inf,"iih", "Cox, full follow-up"))
models$estimate <- fmt_est(models$hr, models$lo, models$hi)
wr(models, "T4a_cox_models"); print(models[,c("model","n","events","estimate","p")])

## ---- proportional hazards ---------------------------------------------------
ph <- do.call(rbind, lapply(c(3,5,Inf), function(tau) {
  s <- cut_at(a, tau); z <- cox.zph(coxph(Surv(t, ev) ~ iih, data=s))
  data.frame(horizon_y=tau, chisq=round(z$table["iih","chisq"],2),
             df=z$table["iih","df"], p_ph=signif(z$table["iih","p"],3),
             conclusion=ifelse(z$table["iih","p"]<0.05,"PH VIOLATED","PH not rejected")) }))
wr(ph, "S6_ph_assumption"); print(ph)
pdf(file.path(OUT_DIR,"figures","schoenfeld.pdf"), width=7, height=5)
for (tau in c(3,5,Inf)) { s <- cut_at(a,tau)
  plot(cox.zph(coxph(Surv(t,ev)~iih,data=s)), main=paste("Schoenfeld, horizon",tau,"y"))
  abline(h=0, lty=2, col="grey50") }
invisible(dev.off())

################################################################################
## 5. MULTIVARIABLE COX REGRESSION
################################################################################
say("=== 5. multivariable Cox ===")
s3 <- cut_at(a, TAU)
s3$log_enc_pre <- log1p(s3$enc_pre12)

## SMOKING IS EXCLUDED, DELIBERATELY.
## Detailed status (Never/Former/Current) exists for IIH cases only; every
## control is coded "Unknown". Smoking is therefore perfectly nested within the
## exposure -- a Current or Former smoker can only be a case -- so its
## coefficients are unidentified and the fit hits separation. Including it does
## not adjust for smoking; it re-estimates the exposure effect inside a
## case-only stratum and inflates the exposure standard error. Residual
## confounding by smoking consequently remains, and is a stated limitation.
smk <- as.data.frame.matrix(table(ifelse(is.na(s3$smoking),"Unknown",s3$smoking), s3$cohort))
smk$level <- rownames(smk); rownames(smk) <- NULL
smk$usable <- "NO -- level is case-only or control-only"
wr(smk[,c("level","Non-IIH control","IIH","usable")], "T14j_smoking_not_adjustable")

FULL <- "iih + age_index + bmi_index + sex + osa + htn + pcos + log_enc_pre"
PARS <- "iih + age_index + bmi_index + sex + osa + htn + pcos"
fit_full  <- coxph(as.formula(paste("Surv(t,ev) ~",FULL)), data=s3,
                   cluster=s3$match_set, robust=TRUE, ties="efron", x=TRUE)
fit_pars  <- coxph(as.formula(paste("Surv(t,ev) ~",PARS)), data=s3,
                   cluster=s3$match_set, robust=TRUE, ties="efron", x=TRUE)
fit_strat <- coxph(as.formula(paste("Surv(t,ev) ~",FULL,"+ strata(match_set)")),
                   data=s3, ties="efron")
fit_crude <- coxph(Surv(t,ev) ~ iih, data=s3, cluster=s3$match_set, robust=TRUE)

epv <- data.frame(quantity=c("Events at 3 years","Parameters","Events per parameter",
                             "Rule-of-thumb minimum"),
                  value=c(fit_full$nevent, length(coef(fit_full)),
                          round(fit_full$nevent/length(coef(fit_full)),1), 10))
wr(epv, "T14a_events_per_parameter"); print(epv)

tidy_cox <- function(fit, lab) { sm <- summary(fit); ci <- sm$conf.int; co <- sm$coefficients
  data.frame(model=lab, term=rownames(co), hr=round(ci[,1],3), lo=round(ci[,3],3),
             hi=round(ci[,4],3), se=round(co[,"se(coef)"],4),
             z=round(co[,ncol(co)-1],2), p=co[,ncol(co)], row.names=NULL) }
mv <- rbind(tidy_cox(fit_full,"multivariable (full)"),
            tidy_cox(fit_pars,"multivariable (parsimonious)"),
            tidy_cox(fit_strat,"stratified by matched set"))
mv$estimate <- fmt_est(mv$hr, mv$lo, mv$hi); mv$p_fmt <- fmt_p(mv$p)
wr(mv[,c("model","term","estimate","se","z","p_fmt")], "T14c_multivariable_cox")
print(mv[mv$model=="multivariable (full)", c("term","estimate","p_fmt")], row.names=FALSE)

exp_row <- function(fit, lab) { sm <- summary(fit); i <- which(rownames(sm$conf.int)=="iih")
  data.frame(model=lab, n=fit$n, events=fit$nevent,
             estimate=fmt_est(sm$conf.int[i,1], sm$conf.int[i,3], sm$conf.int[i,4]),
             p=fmt_p(sm$coefficients[i, ncol(sm$coefficients)])) }
compare <- rbind(exp_row(fit_crude,"Crude (matched design only) -- PRIMARY"),
                 exp_row(fit_pars, "Adjusted: + age, BMI, sex, OSA, HTN, PCOS"),
                 exp_row(fit_full, "Adjusted: + pre-index healthcare contact"),
                 exp_row(fit_strat,"Adjusted, stratified by matched set"))
wr(compare, "T14d_exposure_across_models"); print(compare)

## Diagnostics: PH per term, linearity, collinearity, influence, block tests.
zf <- cox.zph(coxph(as.formula(paste("Surv(t,ev) ~",FULL)), data=s3))
pht <- as.data.frame(zf$table); pht$term <- rownames(pht); rownames(pht) <- NULL
pht <- pht[,c("term","chisq","df","p")]; pht$chisq <- round(pht$chisq,2)
pht$p <- signif(pht$p,3)
pht$conclusion <- ifelse(pht$p < 0.05, "PH VIOLATED", "PH not rejected")
wr(pht, "T14e_ph_by_term"); print(pht)

rcs <- function(x, k) { kn <- length(k); out <- matrix(x, ncol=1)
  for (j in seq_len(kn-2)) { num <- pmax(x-k[j],0)^3 -
      pmax(x-k[kn-1],0)^3*(k[kn]-k[j])/(k[kn]-k[kn-1]) +
      pmax(x-k[kn],0)^3*(k[kn-1]-k[j])/(k[kn]-k[kn-1])
    out <- cbind(out, num/(k[kn]-k[1])^2) }
  out }
lin <- do.call(rbind, lapply(c("age_index","bmi_index"), function(v) {
  kn <- quantile(s3[[v]], c(.1,.5,.9), na.rm=TRUE); B <- rcs(s3[[v]], kn)
  dd <- s3; dd$b1 <- B[,1]; dd$b2 <- B[,2]
  l <- 2*(coxph(Surv(t,ev)~iih+b1+b2,data=dd)$loglik[2] -
          coxph(Surv(t,ev)~iih+b1,   data=dd)$loglik[2])
  data.frame(covariate=v, knots=paste(round(kn,1),collapse=", "),
             lrt_chisq=round(l,2), df=1, p_nonlinearity=signif(pchisq(l,1,lower.tail=FALSE),3),
             conclusion=ifelse(pchisq(l,1,lower.tail=FALSE)<0.05,
                               "non-linear -- consider a spline","linear term adequate")) }))
wr(lin, "T14f_linearity_checks"); print(lin)

X <- fit_full$x; keep <- colnames(X)[apply(X,2,sd) > 0]
iv <- try(solve(cor(X[,keep,drop=FALSE])), silent=TRUE)
if (!inherits(iv,"try-error")) {
  vf <- data.frame(term=keep, vif=round(diag(iv),2),
                   interpretation=ifelse(diag(iv)>5,"HIGH -- unstable","acceptable"),
                   row.names=NULL)
  wr(vf, "T14g_collinearity_vif"); print(vf)
}
db <- residuals(fit_full, type="dfbeta"); ii <- which(names(coef(fit_full))=="iih")
infl <- data.frame(metric=c("Largest |dfbeta| for IIH","As % of the coefficient",
                            "Patients with |dfbeta| > 10% of coefficient"),
  value=c(signif(max(abs(db[,ii])),3),
          paste0(round(100*max(abs(db[,ii]))/abs(coef(fit_full)[ii]),2),"%"),
          sum(abs(db[,ii]) > 0.1*abs(coef(fit_full)[ii]))))
wr(infl, "T14h_influence"); print(infl)

wald <- function(fit, rx, lab) { b <- coef(fit); k <- grep(rx, names(b))
  if (!length(k)) return(NULL); V <- fit$var[k,k,drop=FALSE]
  W <- as.numeric(t(b[k]) %*% solve(V) %*% b[k])
  data.frame(block=lab, df=length(k), wald_chisq=round(W,2),
             p=signif(pchisq(W,length(k),lower.tail=FALSE),3)) }
blocks <- do.call(rbind, list(
  wald(fit_full,"^iih$","Exposure (IIH)"),
  wald(fit_full,"^(age_index|bmi_index|sexM)$","Matched covariates"),
  wald(fit_full,"^(osa|htn|pcos)$","Comorbidity"),
  wald(fit_full,"^log_enc_pre$","Pre-index healthcare contact")))
wr(blocks, "T14i_wald_blocks"); print(blocks)

################################################################################
## 6. COMPETING RISKS AND ABSOLUTE RISK
################################################################################
say("=== 6. competing risks ===")
s3$evf <- factor(s3$evc, levels=0:2, labels=c("censored","seizure","death"))
cs_d <- coxph(Surv(t, evc==2) ~ iih, data=s3, cluster=s3$match_set, robust=TRUE)
fgd  <- finegray(Surv(t, evf) ~ ., data=s3, etype="seizure")
fg   <- coxph(Surv(fgstart,fgstop,fgstatus) ~ iih, weights=fgwt, data=fgd,
              cluster=fgd$match_set, robust=TRUE)
sdm <- summary(cs_d); sfg <- summary(fg)
cr <- data.frame(
  estimand=c("Cause-specific HR, seizure (PRIMARY)",
             "Cause-specific HR, death (competing event)",
             "Subdistribution HR, seizure (Fine-Gray)"),
  hr=c(models$hr[1], round(sdm$conf.int[1,1],2), round(sfg$conf.int[1,1],2)),
  lo=c(models$lo[1], round(sdm$conf.int[1,3],2), round(sfg$conf.int[1,3],2)),
  hi=c(models$hi[1], round(sdm$conf.int[1,4],2), round(sfg$conf.int[1,4],2)),
  interpretation=c("Rate among those still alive and seizure-free -- aetiological",
                   "Whether IIH also alters mortality",
                   "Effect on cumulative INCIDENCE with death in the risk set -- prognostic"))
cr$estimate <- fmt_est(cr$hr, cr$lo, cr$hi)
wr(cr, "T4b_competing_risk"); print(cr[,c("estimand","estimate")])

## Absolute risk by Aalen-Johansen, NOT 1 - Kaplan-Meier: KM would overstate
## risk by treating the deceased as still able to have a seizure.
aj <- survfit(Surv(t, evf) ~ iih, data=s3, id=seq_len(nrow(s3)))
ks <- which(aj$states == "seizure")
sm <- summary(aj, times=c(1,2,3), extend=TRUE)
cif <- data.frame(cohort=ifelse(grepl("iih=1",as.character(sm$strata)),"IIH","Non-IIH control"),
                  time_y=sm$time, cif_pct=round(100*sm$pstate[,ks],3),
                  se_pct=round(100*sm$std.err[,ks],3))
wr(cif, "T4c_cumulative_incidence")
i1 <- which(cif$cohort=="IIH" & cif$time_y==3); i0 <- which(cif$cohort!="IIH" & cif$time_y==3)
est <- cif$cif_pct[i1]-cif$cif_pct[i0]; se <- sqrt(cif$se_pct[i1]^2+cif$se_pct[i0]^2)
rd <- data.frame(measure="3-year absolute risk difference (percentage points)",
                 iih_risk_pct=cif$cif_pct[i1], control_risk_pct=cif$cif_pct[i0],
                 estimate=round(est,2), lo=round(est-1.96*se,2), hi=round(est+1.96*se,2),
                 number_needed_to_harm=round(100/est))
wr(rd, "T4d_risk_difference"); print(rd)

ev <- evalue_hr(models$hr[1], models$lo[1], models$hi[1])
wr(data.frame(quantity=c("E-value, point estimate","E-value, CI limit nearest null"),
              value=round(ev,2),
              plain_language=c(
  sprintf("An unmeasured confounder would need associations of at least %.2f with BOTH exposure and outcome, beyond age/sex/BMI, to explain this away.", ev[[1]]),
  sprintf("To pull the CI to the null it would need associations of at least %.2f each.", ev[[2]]))),
   "T4e_evalue")

################################################################################
## 7. NEGATIVE CONTROL, TIMING, SUBGROUPS
################################################################################
say("=== 7. negative control, timing, subgroups ===")
## Carpal tunnel has no plausible causal link to IIH and is ascertained the same
## way. If the design merely measured healthcare contact, it would be elevated
## too. Female sets only: not extracted for male controls.
nc <- a[!is.na(a$carpal_incident) & a$sex=="F",]; nc$event <- nc$carpal_incident
neg <- rbind(
  cbind(outcome="Incident seizure/epilepsy (positive outcome)",
        fitc(a[a$sex=="F",],3,"iih","x")[,c("n","events","hr","lo","hi","p")]),
  cbind(outcome="Incident carpal tunnel syndrome (NEGATIVE CONTROL)",
        fitc(nc,3,"iih","x")[,c("n","events","hr","lo","hi","p")]))
neg$estimate <- fmt_est(neg$hr,neg$lo,neg$hi); neg$p <- fmt_p(neg$p)
wr(neg, "T5a_negative_control"); print(neg[,c("outcome","n","events","estimate","p")])

sp <- survSplit(Surv(t,ev) ~ ., data=cut_at(a,Inf), cut=c(2,5), episode="period")
sp$period <- factor(sp$period, labels=c("0.5-2 y","2-5 y",">5 y"))
tsp <- do.call(rbind, lapply(levels(sp$period), function(p) {
  ss <- sp[sp$period==p,]
  f <- coxph(Surv(tstart,t,ev)~iih, data=ss, cluster=ss$match_set, robust=TRUE)
  sm2 <- summary(f)
  data.frame(period=p, events=f$nevent, hr=round(sm2$conf.int[1,1],2),
             lo=round(sm2$conf.int[1,3],2), hi=round(sm2$conf.int[1,4],2)) }))
tsp$estimate <- fmt_est(tsp$hr,tsp$lo,tsp$hi)
wr(tsp, "T5b_time_split"); print(tsp[,c("period","events","estimate")])

a$grp_sex <- ifelse(a$sex=="F","Female","Male")
a$grp_age <- ifelse(a$age_index<35,"Age <35 y","Age >=35 y")
a$grp_bmi <- ifelse(a$bmi_index<35,"BMI <35","BMI >=35")
a$grp_era <- ifelse(a$index_year<2015,"Index <2015","Index >=2015")
mp <- median(a$enc_pre12, na.rm=TRUE)
a$grp_surv <- ifelse(a$enc_pre12<mp, paste0("Pre-index enc <",mp), paste0("Pre-index enc >=",mp))
sg_row <- function(dat, lab) { s <- cut_at(dat, TAU)
  if (sum(s$ev)<8 || length(unique(s$iih))<2)
    return(data.frame(subgroup=lab,n=nrow(s),events=sum(s$ev),hr=NA,lo=NA,hi=NA))
  f <- try(coxph(Surv(t,ev)~iih,data=s,cluster=s$match_set,robust=TRUE), silent=TRUE)
  if (inherits(f,"try-error") || !is.finite(coef(f)[1]))
    return(data.frame(subgroup=lab,n=nrow(s),events=sum(s$ev),hr=NA,lo=NA,hi=NA))
  sm2 <- summary(f)
  data.frame(subgroup=lab,n=f$n,events=f$nevent,hr=sm2$conf.int[1,1],
             lo=sm2$conf.int[1,3],hi=sm2$conf.int[1,4]) }
## Effect modification is judged by the interaction test, NEVER by comparing
## which subgroup happened to reach significance.
int_p <- function(v) { s <- cut_at(a,TAU); s$mod <- factor(s[[v]])
  f <- try(coxph(Surv(t,ev)~iih*mod,data=s,cluster=s$match_set,robust=TRUE),silent=TRUE)
  if (inherits(f,"try-error")) return(NA_real_)
  b <- coef(f); k <- grep("^iih:",names(b))
  if (!length(k) || any(!is.finite(b[k]))) return(NA_real_)
  V <- f$var[k,k,drop=FALSE]; if (abs(det(V))<1e-12) return(NA_real_)
  signif(pchisq(as.numeric(t(b[k])%*%solve(V)%*%b[k]),length(k),lower.tail=FALSE),3) }
sgv <- c(grp_sex="Sex", grp_age="Age at index", grp_bmi="BMI at index",
         grp_era="Calendar period", grp_surv="Baseline surveillance")
sub <- do.call(rbind, lapply(names(sgv), function(v) {
  lv <- sort(unique(na.omit(a[[v]])))
  r <- do.call(rbind, lapply(lv, function(l) sg_row(a[which(a[[v]]==l),], l)))
  r$modifier <- sgv[[v]]; r$interaction_p <- c(int_p(v), rep(NA,nrow(r)-1)); r }))
ov <- sg_row(a,"Overall"); ov$modifier <- "Overall"; ov$interaction_p <- NA
sub <- rbind(ov, sub)
sub$estimate <- ifelse(is.na(sub$hr),"not estimated",fmt_est(sub$hr,sub$lo,sub$hi))
wr(sub[,c("modifier","subgroup","n","events","estimate","interaction_p")],
   "T8_subgroup_interactions")
print(sub[,c("modifier","subgroup","events","estimate","interaction_p")], row.names=FALSE)

################################################################################
## 8. SENSITIVITY, TIPPING POINT, MISCLASSIFICATION, RMTL
################################################################################
say("=== 8. sensitivity ===")
res <- list()
addS <- function(lab, status, dat, tau=TAU, rhs="iih", strat=FALSE, wts=NULL, note="") {
  s <- cut_at(dat, tau)
  if (sum(s$ev) < 8) { res[[lab]] <<- data.frame(analysis=lab,status=status,n=nrow(s),
      events=sum(s$ev),estimate="too few events",p=NA,note=note); return(invisible()) }
  f <- as.formula(paste("Surv(t,ev) ~", rhs, if (strat) "+ strata(match_set)" else ""))
  fit <- try(if (strat) coxph(f,data=s)
             else if (!is.null(wts)) coxph(f,data=s,weights=s[[wts]],
                                           cluster=s$match_set,robust=TRUE)
             else coxph(f,data=s,cluster=s$match_set,robust=TRUE), silent=TRUE)
  if (inherits(fit,"try-error") || !is.finite(coef(fit)[1])) {
    res[[lab]] <<- data.frame(analysis=lab,status=status,n=nrow(s),events=sum(s$ev),
      estimate="did not converge",p=NA,note=note); return(invisible()) }
  sm2 <- summary(fit)
  res[[lab]] <<- data.frame(analysis=lab,status=status,n=fit$n,events=fit$nevent,
    estimate=fmt_est(sm2$conf.int[1,1],sm2$conf.int[1,3],sm2$conf.int[1,4]),
    p=fmt_p(sm2$coefficients[1,ncol(sm2$coefficients)]), note=note) }
addS("Primary: Cox, 3-year","PRE-SPECIFIED", a)
for (L in c(1,2)) { la <- a[a$t_y > L,]; la$t_y <- la$t_y - L
  addS(sprintf("Landmark: further %g year(s) after washout",L),"PRE-SPECIFIED", la) }
addS("Female sets only","PRE-SPECIFIED", a[a$sex=="F",])
addS("Male sets only","PRE-SPECIFIED", a[a$sex=="M",],
     note="Male matching used no calendar-year constraint.")
addS("Stratified by matched set","PRE-SPECIFIED", a, strat=TRUE)
addS("IPTW on propensity score","PRE-SPECIFIED", ps, wts="iptw_trim")
addS("Adjusted for pre-index encounters (valid confounder)","PROTOCOL-DERIVED", a,
     rhs="iih + log1p(enc_pre12)")
addS("Adjusted for post-index encounters (CONSERVATIVE BOUND ONLY)","PRE-SPECIFIED", a,
     rhs="iih + log1p(enc_post)",
     note="Mediator adjustment; NOT causal. A lower bound only.")
q3 <- quantile(a$enc_post[a$iih==0], .75, na.rm=TRUE)
addS("Controls in top quartile of post-index encounters","PRE-SPECIFIED",
     a[which(a$iih==1 | a$enc_post>=q3),])
addS("Full 1:4 sets only","POST HOC",
     a[a$match_set %in% names(which(table(a$match_set[a$iih==0])==4)),])
addS("Index year >= 2010","POST HOC", a[a$index_year>=2010,])
addS("5-year horizon","PRE-SPECIFIED", a, tau=5)
addS("Full follow-up","PRE-SPECIFIED", a, tau=Inf)
sens <- do.call(rbind, res); rownames(sens) <- NULL
wr(sens, "T6_sensitivity_analyses"); print(sens[,c("analysis","n","events","estimate","p")])

## Tipping point: hidden events are added to CONTROLS only -- the worst case.
base <- cut_at(a, TAU)
tip <- do.call(rbind, lapply(c(0,.005,.01,.02,.05,.10), function(fr) {
  set.seed(SEED); ss <- base; cc <- which(ss$iih==0 & ss$ev==0); k <- round(fr*length(cc))
  if (k>0) { h <- sample(cc,k); ss$ev[h] <- 1L; ss$t[h] <- runif(k)*ss$t[h] }
  f <- coxph(Surv(t,ev)~iih,data=ss,cluster=ss$match_set,robust=TRUE); sm2 <- summary(f)
  data.frame(pct_censored_controls_with_hidden_seizure=100*fr, hidden_events_added=k,
             hr=round(sm2$conf.int[1,1],2), lo=round(sm2$conf.int[1,3],2),
             hi=round(sm2$conf.int[1,4],2), crosses_null=sm2$conf.int[1,3]<1) }))
wr(tip, "T6b_tipping_point"); print(tip)

## Non-differential misclassification does not move a rate ratio; only
## differential detection does.
mis <- do.call(rbind, lapply(list(c(1,1),c(.9,.9),c(.8,.8),c(.9,.7),c(.9,.6)), function(z) {
  s <- cut_at(a,TAU)
  e1<-sum(s$ev[s$iih==1]); t1<-sum(s$t[s$iih==1]); e0<-sum(s$ev[s$iih==0]); t0<-sum(s$t[s$iih==0])
  data.frame(sensitivity_iih=z[1], sensitivity_control=z[2],
             scenario=ifelse(z[1]==z[2],"non-differential","DIFFERENTIAL (favours exposed)"),
             corrected_IRR=round((e1/z[1]/t1)/(e0/z[2]/t0),2)) }))
wr(mis, "T6c_outcome_misclassification"); print(mis)

## Restricted mean time lost: assumption-free companion to the hazard ratio.
say("bootstrapping RMTL (", BOOT_REPS, " reps) ...")
rmtl <- function(dat) { s <- dat
  s$evf <- factor(s$evc, levels=0:2, labels=c("censored","seizure","death"))
  f <- survfit(Surv(t,evf)~iih, data=s, id=seq_len(nrow(s)))
  g <- seq(0,TAU,by=.01); sm2 <- summary(f, times=g, extend=TRUE)
  kk <- which(f$states=="seizure"); st <- as.character(sm2$strata)
  vapply(c("iih=0","iih=1"), function(z) { y <- sm2$pstate[st==z,kk]
    sum((head(y,-1)+tail(y,-1))/2*diff(g)) }, numeric(1)) }
obs <- rmtl(s3)
set.seed(SEED); sets <- unique(s3$match_set); idx <- split(seq_len(nrow(s3)), s3$match_set)
boot <- vapply(seq_len(BOOT_REPS), function(b) {
  pick <- sample(sets, length(sets), replace=TRUE)
  d2 <- s3[unlist(idx[pick], use.names=FALSE),]
  d2$match_set <- rep(seq_along(pick), lengths(idx[pick]))
  o <- try(rmtl(d2), silent=TRUE)
  if (inherits(o,"try-error") || length(o)!=2) return(c(NA,NA,NA))
  c(o, o[2]-o[1]) }, numeric(3))
rm_tab <- data.frame(quantity=c("Non-IIH control","IIH","Difference (IIH - control)"),
  days_lost_over_3y=round(c(obs[1],obs[2],obs[2]-obs[1])*365.25,2),
  lo=round(apply(boot,1,quantile,.025,na.rm=TRUE)*365.25,2),
  hi=round(apply(boot,1,quantile,.975,na.rm=TRUE)*365.25,2))
rm_tab$estimate <- fmt_est(rm_tab$days_lost_over_3y, rm_tab$lo, rm_tab$hi)
wr(rm_tab, "T9_restricted_mean_time_lost"); print(rm_tab[,c("quantity","estimate")])

################################################################################
## 9. WITHIN-IIH EXPLORATORY (post hoc -- read the caveats)
################################################################################
say("=== 9. within-IIH exploratory ===")
iih <- a[a$iih==1,]
iih$surg <- factor(ifelse(iih$shunt==1 | iih$stent==1,"Surgical","No procedure"),
                   levels=c("No procedure","Surgical"))
sv <- cut_at(iih, TAU)
f1 <- coxph(Surv(t,ev)~surg, data=sv)
f2 <- coxph(Surv(t,ev)~op_cmh2o, data=cut_at(iih[!is.na(iih$op_cmh2o),], TAU))
c1 <- summary(f1); c2 <- summary(f2)
expl <- data.frame(
  analysis=c("Surgical (shunt/stent) vs none, within IIH",
             "Opening pressure, per 10 cmH2O, within IIH"),
  n=c(f1$n,f2$n), events=c(f1$nevent,f2$nevent),
  estimate=c(fmt_est(c1$conf.int[1,1],c1$conf.int[1,3],c1$conf.int[1,4]),
             fmt_est(c2$conf.int[1,1]^10,c2$conf.int[1,3]^10,c2$conf.int[1,4]^10)),
  p=fmt_p(c(c1$coefficients[1,5], c2$coefficients[1,5])),
  status="POST HOC EXPLORATORY",
  caveat=c("Shunt/stent is a POST-INDEX decision taken while the outcome accrues: immortal time plus conditioning on a post-exposure variable. No causal reading.",
           "Recorded in a subset of cases, and many measured values fall below the 25 cmH2O diagnostic threshold, so this indexes diagnostic accuracy as well as severity. Splines not fitted: too few events to place knots."))
wr(expl, "T5d_exploratory_within_iih"); print(expl[,c("analysis","n","events","estimate","p")])

## Encephalocele: DESCRIPTIVE ONLY. Assessable in a small minority of cases and
## in ZERO controls, so no mediation estimand is identifiable. "Not assessable"
## is never recoded as "absent".
enc <- data.frame(
  status=c("Present","Absent","Not assessable (88)","Unknown after search (99)","Not extracted"),
  n=c(sum(iih$enceph_index==1,na.rm=TRUE), sum(iih$enceph_index==0,na.rm=TRUE),
      sum(iih$enceph_status=="not_assessable"), sum(iih$enceph_status=="unknown_after_search"),
      sum(iih$enceph_status=="not_extracted")),
  incident_seizures=c(
    sum(iih$enceph_index==1 & iih$event==1,na.rm=TRUE),
    sum(iih$enceph_index==0 & iih$event==1,na.rm=TRUE),
    sum(iih$enceph_status=="not_assessable" & iih$event==1),
    sum(iih$enceph_status=="unknown_after_search" & iih$event==1),
    sum(iih$enceph_status=="not_extracted" & iih$event==1)))
wr(enc, "T5e_encephalocele_descriptive")

################################################################################
## 10. OPTIONAL: MEDICATION-ANCHORED TIPPING POINT
################################################################################
if (file.exists(MED_SUMMARY)) {
  say("=== 10. medications (optional, provisional) ===")
  ms <- utils::read.csv(MED_SUMMARY, colClasses="character", check.names=FALSE)
  sm3 <- merge(ms[ms$record_id %in% a$record_id[a$iih==0],
                  c("record_id","asm_ever","asm_list","first_asm_date")],
               a[,c("record_id","event","index_date","t_y")], by="record_id")
  disc <- sm3[sm3$asm_ever=="1" & sm3$event==0,]
  say("controls on an unambiguous ASM with no epilepsy code: ", nrow(disc),
      sprintf(" (%.2f%% of %d covered)", 100*nrow(disc)/max(1,nrow(sm3)), nrow(sm3)))
  sm3$asm_t <- as.numeric(as.Date(substr(sm3$first_asm_date,1,10)) - sm3$index_date)/365.25 -
               180/365.25
  cand <- sm3$record_id[sm3$asm_ever=="1" & sm3$event==0 & !is.na(sm3$asm_t) & sm3$asm_t>0]
  at <- setNames(sm3$asm_t, sm3$record_id)
  mt <- do.call(rbind, lapply(c(0,.25,.5,.75,1), function(fr) {
    set.seed(SEED); ss <- base
    h <- if (fr>0) sample(cand, round(fr*length(cand))) else character(0)
    i <- match(h, ss$record_id); i <- i[!is.na(i)]; ok <- 0
    if (length(i)) { te <- at[ss$record_id[i]]; w <- !is.na(te) & te>0 & te<=ss$t[i]
                     ss$ev[i[w]] <- 1L; ss$t[i[w]] <- te[w]; ok <- sum(w) }
    f <- coxph(Surv(t,ev)~iih,data=ss,cluster=ss$match_set,robust=TRUE); s4 <- summary(f)
    data.frame(pct_assumed_true=100*fr, events_added=ok, hr=round(s4$conf.int[1,1],2),
               lo=round(s4$conf.int[1,3],2), hi=round(s4$conf.int[1,4],2),
               crosses_null=s4$conf.int[1,3]<1) }))
  wr(mt, "T13b_anchored_tipping_point"); print(mt)
  if (file.exists(MED_DETAIL)) {
    det <- utils::read.csv(MED_DETAIL, colClasses="character", check.names=FALSE)
    mn <- tolower(det$medication_name)
    ## Verify, do not assume: gabapentin and pregabalin are NOT antiseizure
    ## medications here; topiramate and acetazolamide are IIH treatments.
    chk <- do.call(rbind, lapply(list(c("gabapentin","NOT an ASM"),c("pregabalin","NOT an ASM"),
        c("topiramate","NOT counted (IIH treatment)"),c("acetazolamide","NOT counted (IIH treatment)"),
        c("levetiracetam","counted"),c("zonisamide","counted"),c("lorazepam","NOT counted")),
      function(z) { i <- grepl(z[1], mn, fixed=TRUE)
        data.frame(drug=z[1], n_rows=sum(i),
                   class_assigned=paste(unique(det$medication_class[i]),collapse="; "),
                   counted_as_asm=paste(unique(det$asm_generic[i]!=""),collapse="/"),
                   protocol_expectation=z[2]) }))
    chk$agrees <- ifelse(chk$n_rows==0,"no rows",
      ifelse(grepl("NOT",chk$protocol_expectation)==grepl("FALSE",chk$counted_as_asm),"YES","REVIEW"))
    wr(chk, "T12c_asm_classification_check"); print(chk[,c("drug","n_rows","agrees")])
  }
} else say("medication files not found -- skipping optional section 10")

################################################################################
## 11. FIGURES
################################################################################
say("=== 11. figures ===")
pe <- function(x) { m <- regmatches(x, regexec("^([0-9.]+) \\(([0-9.]+) to ([0-9.]+)\\)$", x))
  t(vapply(m, function(z) if (length(z)==4) as.numeric(z[2:4]) else rep(NA_real_,3), numeric(3))) }

## F1 incidence rates
r <- rates; r$horizon <- factor(r$horizon, levels=unique(r$horizon))
sav(ggplot(r, aes(horizon, rate_per_1000py, colour=cohort, group=cohort)) +
  geom_errorbar(aes(ymin=rate_lo, ymax=rate_hi), width=.12,
                position=position_dodge(.35), linewidth=.6) +
  geom_point(size=3, position=position_dodge(.35)) +
  scale_colour_manual(values=COHORT_COL) +
  labs(x=NULL, y="Incident seizures per 1,000 person-years",
       title="Incidence of first seizure or epilepsy after the 180-day washout",
       subtitle="Exact (Garwood) Poisson 95% confidence intervals") + theme_pub(),
  "F1_incidence_rates", 7.5, 5)

## F2 cumulative incidence with competing death
g <- seq(0,3,by=.02); smf <- summary(aj, times=g, extend=TRUE)
kd <- which(aj$states=="death")
coh <- ifelse(grepl("iih=1", as.character(smf$strata)), "IIH", "Non-IIH control")
cifd <- rbind(
  data.frame(t=smf$time, cohort=coh, pct=100*smf$pstate[,ks],
             lo=100*smf$lower[,ks], hi=100*smf$upper[,ks], event="Seizure or epilepsy"),
  data.frame(t=smf$time, cohort=coh, pct=100*smf$pstate[,kd],
             lo=NA, hi=NA, event="Death (competing event)"))
cifd$event <- factor(cifd$event, levels=c("Seizure or epilepsy","Death (competing event)"))
sav(ggplot(cifd, aes(t, pct, colour=cohort, fill=cohort)) +
  geom_ribbon(aes(ymin=lo, ymax=hi), alpha=.15, colour=NA) +
  geom_step(linewidth=.8) + facet_wrap(~event, scales="free_y") +
  scale_colour_manual(values=COHORT_COL) + scale_fill_manual(values=COHORT_COL) +
  labs(x="Years since index (day 180 = 0)", y="Cumulative incidence (%)",
       title="Cumulative incidence of seizure, with death as a competing event",
       subtitle=sprintf("Aalen-Johansen. 3-year risk %.2f%% vs %.2f%%; difference %.2f pp, NNH %d",
                        rd$iih_risk_pct, rd$control_risk_pct, rd$estimate, rd$number_needed_to_harm),
       caption="1 - Kaplan-Meier is NOT shown: it would overstate absolute risk by treating the deceased as still at risk.") +
  theme_pub(), "F2_cumulative_incidence", 9, 5)

## F3 sensitivity forest
fs <- sens; e <- pe(fs$estimate); fs$hr <- e[,1]; fs$lo <- e[,2]; fs$hi <- e[,3]
fs <- fs[!is.na(fs$hr),]; fs$analysis <- factor(fs$analysis, levels=rev(fs$analysis))
fs$flag <- ifelse(grepl("Primary",fs$analysis),"primary",
           ifelse(grepl("CONSERVATIVE",fs$analysis),"bound","other"))
sav(ggplot(fs, aes(hr, analysis, colour=flag)) +
  geom_vline(xintercept=1, linetype=2, colour="grey45") +
  geom_errorbarh(aes(xmin=lo, xmax=hi), height=.22, linewidth=.5) +
  geom_point(aes(size=events)) + scale_x_log10(breaks=c(1,2,3,5,10,20)) +
  scale_size_continuous(range=c(1.4,3.6), guide="none") +
  scale_colour_manual(values=c(primary=COL[["iih"]], bound=COL[["warn"]], other=COL[["control"]]),
                      labels=c("Mediator-adjusted bound","Other specification","Primary")) +
  labs(x="Hazard ratio (log scale)", y=NULL,
       title="Sensitivity of the IIH-seizure association to specification",
       caption="The mediator-adjusted estimate (amber) is a conservative LOWER BOUND, not a causal estimate.") +
  theme_pub(), "F3_forest_sensitivity", 11, 6)

## F4 subgroup forest with interaction p-values
sg <- sub[!is.na(sub$hr),]
sg$lab <- sprintf("%s  (%d events)", ifelse(sg$modifier=="Overall","Overall",sg$subgroup), sg$events)
sg$ip <- ifelse(is.na(sg$interaction_p),"",paste0("interaction p = ",sg$interaction_p))
sg$modifier <- factor(sg$modifier, levels=c("Overall","Sex","Age at index","BMI at index",
                                            "Calendar period","Baseline surveillance"))
sg <- sg[order(sg$modifier),]; sg$lab <- factor(sg$lab, levels=rev(sg$lab))
sav(ggplot(sg, aes(hr, lab)) +
  geom_vline(xintercept=sub$hr[1], linetype=3, colour=COL[["accent"]]) +
  geom_vline(xintercept=1, linetype=2, colour="grey45") +
  geom_errorbarh(aes(xmin=lo, xmax=hi), height=.2, linewidth=.5, colour=COL[["control"]]) +
  geom_point(aes(size=events), colour=COL[["iih"]]) +
  geom_text(aes(x=95, label=ip), size=2.8, hjust=1, colour="grey20") +
  facet_grid(modifier ~ ., scales="free_y", space="free_y", switch="y") +
  scale_x_log10(breaks=c(1,2,5,10,20), limits=c(.25,100)) +
  scale_size_continuous(range=c(1.5,3.5), guide="none") +
  labs(x="Hazard ratio (log scale)", y=NULL, title="Effect modification, tested by interaction",
       subtitle="Subgroup HRs are descriptive; only the interaction p-value tests modification.",
       caption="Power to detect modification is low: a large interaction p-value does NOT establish a uniform effect.") +
  theme_pub() + theme(strip.placement="outside",
    strip.text.y.left=element_text(angle=0, hjust=1), panel.spacing.y=unit(.15,"lines")),
  "F4_subgroups", 11, 6)

## F5 negative control
nn <- neg; e2 <- pe(nn$estimate); nn$hr <- e2[,1]; nn$lo <- e2[,2]; nn$hi <- e2[,3]
nn$outcome <- factor(nn$outcome, levels=rev(nn$outcome))
sav(ggplot(nn, aes(hr, outcome)) +
  geom_vline(xintercept=1, linetype=2, colour="grey45") +
  geom_errorbarh(aes(xmin=lo, xmax=hi), height=.14, linewidth=.7, colour=COL[["iih"]]) +
  geom_point(size=3.4, colour=COL[["iih"]]) + scale_x_log10(breaks=c(.25,.5,1,2,4)) +
  labs(x="Hazard ratio (log scale)", y=NULL,
       title="Negative-control outcome: the specificity check",
       subtitle="Female matched sets, 3-year horizon",
       caption="If the design merely measured healthcare contact, carpal tunnel would be elevated too.") +
  theme_pub(), "F5_negative_control", 8.5, 3.8)

## F6 tipping point
sav(ggplot(tip, aes(pct_censored_controls_with_hidden_seizure, hr)) +
  geom_hline(yintercept=1, linetype=2, colour="grey40") +
  geom_ribbon(aes(ymin=lo, ymax=hi), alpha=.2, fill=COL[["control"]]) +
  geom_line(linewidth=.8, colour=COL[["iih"]]) + geom_point(size=2.4, colour=COL[["iih"]]) +
  scale_y_log10() +
  labs(x="% of censored controls assumed to have an unrecorded seizure",
       y="Hazard ratio (log scale)",
       title="How much hidden seizure in controls would erase the association?",
       caption="Hidden events are added to controls only -- the worst case by construction.") +
  theme_pub(), "F6_tipping_point", 7.5, 5)

## F7 multivariable Cox coefficient forest
lab <- c(iih="IIH (vs non-IIH control)", age_index="Age, per year",
         bmi_index="BMI, per kg/m2", sexM="Male (vs female)",
         osa="Obstructive sleep apnoea", htn="Hypertension", pcos="PCOS",
         log_enc_pre="Pre-index encounters, log(1+n)")
fp <- tidy_cox(fit_full,"full")
fp$label <- ifelse(is.na(lab[fp$term]), fp$term, lab[fp$term])
fp$grp <- ifelse(fp$term=="iih","Exposure","Covariate")
fp$label <- factor(fp$label, levels=rev(fp$label))
sav(ggplot(fp, aes(hr, label, colour=grp)) +
  geom_vline(xintercept=1, linetype=2, colour="grey45") +
  geom_errorbarh(aes(xmin=lo, xmax=hi), height=.2, linewidth=.5) +
  geom_point(size=2.8) + scale_x_log10(breaks=c(.5,1,2,5,10)) +
  scale_colour_manual(values=c(Exposure=COL[["iih"]], Covariate=COL[["control"]])) +
  labs(x="Adjusted hazard ratio (log scale)", y=NULL, title="Multivariable Cox regression",
       subtitle=sprintf("%d events, %d parameters (%.1f per parameter). Robust SE clustered on matched set.",
                        fit_full$nevent, length(coef(fit_full)),
                        fit_full$nevent/length(coef(fit_full))),
       caption="Post-index encounters are EXCLUDED: adjusting for them is mediator adjustment. Covariate HRs are adjusted associations, not causal effects of those covariates.") +
  theme_pub(), "F7_cox_multivariable_forest", 9, 5.5)

## F8 balance
b <- bal; b$post <- grepl("POST-EXPOSURE", b$variable)
b$variable <- factor(sub(" \\(POST-EXPOSURE\\)","",b$variable),
                     levels=sub(" \\(POST-EXPOSURE\\)","",b$variable)[order(abs(b$smd))])
sav(ggplot(b, aes(abs(smd), variable, colour=post)) +
  geom_vline(xintercept=.1, linetype=2, colour="grey45") +
  geom_segment(aes(x=0, xend=abs(smd), yend=variable), linewidth=.4) +
  geom_point(size=2.8) +
  scale_colour_manual(values=c(`FALSE`=COL[["control"]],`TRUE`=COL[["warn"]]),
                      labels=c("Baseline covariate","Post-index (imbalance expected)")) +
  labs(x="|Standardised mean difference|", y=NULL, title="Covariate balance after matching",
       subtitle=sprintf("Dashed line = 0.1. Propensity c-statistic %.3f.", cstat),
       caption="Comorbidity was never a matching target and remains imbalanced; it is adjusted in the multivariable model instead.") +
  theme_pub(), "F8_balance", 9, 5)

################################################################################
## 12. SESSION INFO AND SUMMARY
################################################################################
writeLines(capture.output(sessionInfo()), file.path(OUT_DIR,"logs","sessionInfo.txt"))
cat("\n",
"================================================================\n",
" ANALYSIS COMPLETE\n",
"================================================================\n",
sprintf(" Cohort           : %d IIH cases, %d matched controls\n",
        sum(a$iih==1), sum(a$iih==0)),
sprintf(" Primary HR       : %s  (%d events, 3-year horizon)\n",
        models$estimate[1], models$events[1]),
sprintf(" Adjusted HR      : %s\n", compare$estimate[3]),
sprintf(" Negative control : %s  <- should be null\n", neg$estimate[2]),
sprintf(" 3-year risk      : %.2f%% vs %.2f%%, NNH %d\n",
        rd$iih_risk_pct, rd$control_risk_pct, rd$number_needed_to_harm),
"\n",
sprintf(" Tables : %s\n", file.path(OUT_DIR,"tables")),
sprintf(" Figures: %s\n", file.path(OUT_DIR,"figures")),
"================================================================\n", sep="")
