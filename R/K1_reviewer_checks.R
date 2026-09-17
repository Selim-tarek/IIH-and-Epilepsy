## K1_reviewer_checks.R -------------------------------------------------------
## Verification of the nine points raised at peer review. Each block reproduces
## the number under dispute and records the verdict. Nothing here edits the
## manuscript; it establishes what the data actually say.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K1 reviewer checks ===")
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds"))
TAU <- 3; FREEZE <- as.Date("2026-09-03")
V <- list(); add <- function(pt, q, found, verdict) V[[length(V)+1]] <<-
  data.frame(point=pt, quantity=q, found=found, verdict=verdict)

## ---- 1. is the excess late? -------------------------------------------------
ci <- utils::read.csv(file.path(PATH$tables, "H_T3_cumulative_incidence.csv"))
g <- function(a,t) ci$cif_pct[ci$arm==a & ci$time_y==t]
e1 <- g("IIH",1)-g("Control",1); e3 <- g("IIH",3)-g("Control",3)
add(1, "share of the 3-year IIH risk present at 1 year",
    sprintf("%.2f%% of %.2f%% = %.0f%%", g("IIH",1), g("IIH",3), 100*g("IIH",1)/g("IIH",3)),
    "REVIEWER CORRECT - the excess is early, not late")
add(1, "share of the 3-year risk DIFFERENCE present at 1 year",
    sprintf("%.2f pp of %.2f pp = %.0f%%", e1, e3, 100*e1/e3), "REVIEWER CORRECT")

## ---- 2. do the timing percentages reconcile with the event counts? ----------
## They do not, because the two are measured from different origins: latency
## runs from the index date, the survival clock from the end of the 180-day
## washout. "Within 3 years" therefore means index+3y in one table and
## index+3.49y in the other.
d <- d0[d0$engaged, ]; ev <- d[d$event == 1, ]
n_lat <- c(sum(ev$iih==1 & ev$lat_days<=3*365.25), sum(ev$iih==0 & ev$lat_days<=3*365.25))
n_srv <- c(sum(ev$iih==1 & ev$t_y<=TAU),            sum(ev$iih==0 & ev$t_y<=TAU))
add(2, "events within 3 years, latency clock (from index)",
    sprintf("IIH %d, control %d", n_lat[1], n_lat[2]), "both tables are internally correct")
add(2, "events within 3 years, survival clock (from washout end)",
    sprintf("IIH %d, control %d", n_srv[1], n_srv[2]),
    "REVIEWER CORRECT that they disagree - cause is a clock-origin mismatch, not an event-count error")

## ---- 3. why does restriction lower the comparator rate? ---------------------
tr <- function(x){ x$ev <- as.integer(x$event==1 & x$t_y<=TAU); x$t <- pmin(x$t_y,TAU); x }
for (k in list(c("engaged","1"), c("not engaged","0"))) {
  s <- d0[d0$iih==0 & (d0$engaged == (k[2]=="1")), ]; s <- tr(s)
  add(3, sprintf("comparator rate, %s", k[1]),
      sprintf("%d events / %.0f py = %.2f per 1,000", sum(s$ev), sum(s$t), 1000*sum(s$ev)/sum(s$t)), "")
}
## The reviewer's proposed mechanism - unscreened prevalent seizures among
## comparators with no prior records - predicts that their events cluster soon
## after index. Test it.
ne <- d0[d0$iih==0 & !d0$engaged & d0$event==1, ]; en <- d0[d0$iih==0 & d0$engaged & d0$event==1, ]
add(3, "events within 1 year of index (prevalent-disease signature)",
    sprintf("not engaged %.0f%% (median %.0f d); engaged %.0f%% (median %.0f d)",
            100*mean(ne$lat_days<=365), median(ne$lat_days),
            100*mean(en$lat_days<=365), median(en$lat_days)),
    "REVIEWER'S EXPLANATION NOT SUPPORTED - no early clustering")
c0 <- d0[d0$iih==0, ]
add(3, "post-index encounters per comparator",
    sprintf("engaged %.0f; not engaged %.0f", mean(c0$enc_post[c0$engaged], na.rm=TRUE),
            mean(c0$enc_post[!c0$engaged], na.rm=TRUE)),
    "the excluded comparators are seen LESS often yet code seizures MORE often")

## ---- 4. where does the seizure outcome sit on the bias-trend line? ----------
dx <- utils::read.csv(file.path("data-raw","SZ_dx_62.csv"), colClasses="character")
names(dx) <- c("mrn","s","code","desc","date")
cn <- utils::read.csv(file.path("data-raw","SZ_conditions_10.csv"), colClasses="character")
names(cn) <- c("mrn","s","code","desc","on","rec")
o <- as.Date(substr(cn$on,1,10)); r <- as.Date(substr(cn$rec,1,10))
e <- rbind(data.frame(mrn=trimws(dx$mrn), code=dx$code, desc=dx$desc, date=as.Date(substr(dx$date,1,10))),
           data.frame(mrn=trimws(cn$mrn), code=cn$code, desc=cn$desc,
                      date=as.Date(ifelse(is.na(o), r, o), origin="1970-01-01")))
e <- e[e$mrn %in% d0$mrn & !is.na(e$date), ]
i <- match(e$mrn, d0$mrn); e$day <- as.numeric(e$date - d0$index_date[i]); e$iih <- d0$iih[i]
exc <- grepl("^F44\\.5|^300\\.11|^R56\\.1|^780\\.33|^780\\.32", e$code) |
       grepl("febrile|non.epileptic|psychogenic|conversion", e$desc, ignore.case=TRUE)
e$icd9 <- grepl("^345|^0345|^780\\.39|^07703", e$code); e$icd10 <- grepl("^G40|^R56", e$code)
e$q <- (e$icd9 | e$icd10) & !exc
pre <- unique(e$mrn[e$q & e$day <= 180])
pi_ <- 100*mean(d0$mrn[d0$iih==1] %in% pre); pc <- 100*mean(d0$mrn[d0$iih==0] %in% pre)
pan <- utils::read.csv(file.path(PATH$tables, "G_T11_negative_control_panel.csv"))
pan$ratio <- pan$baseline_iih_pct/pan$baseline_ctl_pct
pan$hr <- as.numeric(sub(" .*", "", pan$est_full))
fit <- stats::lm(log(hr) ~ log(ratio), data=pan)
pr <- function(x){ p <- stats::predict(fit, data.frame(ratio=x), interval="prediction")
                   sprintf("%.2f (%.2f to %.2f)", exp(p[1]), exp(p[2]), exp(p[3])) }
add(4, "measured baseline seizure prevalence ratio (pre-exclusion, same method as the controls)",
    sprintf("IIH %.2f%% vs control %.2f%% = ratio %.2f", pi_, pc, pi_/pc),
    "REVIEWER'S CONCERN REASONABLE BUT THE DIRECTION IS OPPOSITE - the ratio is below 1, not above")
add(4, "predicted detection-only HR", sprintf("at ratio 1.00: %s; at the measured ratio %.2f: %s",
    pr(1), pi_/pc, pr(pi_/pc)), "the calibration argument is unchanged; observed HR 5.58 sits far above either")

## ---- 6/8. was the outcome algorithm applied identically? -------------------
gd <- unique(e$mrn[!exc & grepl("^G40|^345|^0345", e$code) & e$day > 180])
for (a in c(1,0)) { s <- d0[d0$iih==a & d0$event==1, ]
  add(8, sprintf("%s primary events carrying a post-washout G40/345 code", ifelse(a==1,"IIH","comparator")),
      sprintf("%d of %d (%.0f%%)", sum(s$mrn %in% gd), nrow(s), 100*mean(s$mrn %in% gd)),
      if (a==1) "THE PROTOCOL REQUIRES AN EPILEPSY-SPECIFIC CODE - 70% of IIH events do not have one" else "") }
p <- e[e$q & e$day <= 180, ]
only9 <- setdiff(unique(p$mrn[p$icd9]), unique(p$mrn[p$icd10]))
add(8, "prevalent cases whose only pre-index evidence is ICD-9",
    sprintf("%d patients (IIH %d, control %d)", length(only9),
            sum(d0$iih[match(only9,d0$mrn)]==1), sum(d0$iih[match(only9,d0$mrn)]==0)),
    "REVIEWER PARTLY CORRECT - the protocol lists ICD-9, but a few prevalent cases leaked through")

## ---- 7. opening-pressure sensitivity ---------------------------------------
keep <- d$match_set[d$iih==1 & !is.na(d$op_cmh2o) & d$op_cmh2o >= 25]
s <- tr(d[d$match_set %in% keep, ]); s <- s[s$t > 0, ]
m <- coxph(Surv(t,ev) ~ iih, data=s, cluster=match_set); su <- summary(m)
add(7, "HR restricted to IIH with opening pressure >= 25 cmH2O",
    sprintf("%.2f (%.2f to %.2f); IIH %d (%d events), control %d (%d events)",
            su$conf.int[1], su$conf.int[3], su$conf.int[4],
            sum(s$iih==1), sum(s$ev[s$iih==1]), sum(s$iih==0), sum(s$ev[s$iih==0])),
    "ROBUST - essentially unchanged from the headline 5.58")
add(7, "opening pressure availability", sprintf("%d of %d IIH patients (%.0f%%), range %.0f-%.0f",
    sum(!is.na(d0$op_cmh2o[d0$iih==1])), sum(d0$iih==1), 100*mean(!is.na(d0$op_cmh2o[d0$iih==1])),
    min(d0$op_cmh2o[d0$iih==1], na.rm=TRUE), max(d0$op_cmh2o[d0$iih==1], na.rm=TRUE)),
    "note the implausible low values; the minimum recorded is 2 cmH2O")

## ---- 9. mortality ----------------------------------------------------------
end <- as.Date(ifelse(is.na(d0$death_date), FREEZE, d0$death_date), origin="1970-01-01")
d0$dt <- as.numeric(pmin(end, FREEZE) - d0$index_date)/365.25
dd <- d0[d0$engaged, ]; dd$ev <- as.integer(!is.na(dd$death_date) & dd$dt <= TAU)
dd$t <- pmin(dd$dt, TAU); dd <- dd[dd$t > 0, ]
m <- coxph(Surv(t,ev) ~ iih, data=dd, cluster=match_set); su <- summary(m)
add(9, "death rate to 3 years", sprintf("IIH %.2f vs control %.2f per 1,000 py; HR %.2f (%.2f to %.2f)",
    1000*sum(dd$ev[dd$iih==1])/sum(dd$t[dd$iih==1]), 1000*sum(dd$ev[dd$iih==0])/sum(dd$t[dd$iih==0]),
    su$conf.int[1], su$conf.int[3], su$conf.int[4]),
    "REVIEWER CORRECT - IIH patients die less than their matched comparators; needs comment")

out <- do.call(rbind, V)
write_tab(out, "K_T01_reviewer_checks"); print(out, row.names=FALSE)
log_msg("K1 complete")
