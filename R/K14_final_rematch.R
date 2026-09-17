## K14_final_rematch.R --------------------------------------------------------
## FINAL RE-MATCH: both arms on dated encounters, with BMI measurement dates.
##
## New inputs
##   data-raw/MDE_Encounters_cases.csv     dated encounters, all 2,618 cases
##   data-raw/MDE_Encounters_controls.csv  dated encounters, all 9,122 controls
##   data-raw/MDE_Flowsheets_BMI.csv       dated BMI, 11,737 of 11,740 patients
##
## This removes the last arm-asymmetry: engagement, the at-risk window and
## censoring are now derived from ONE encounter definition applied to both arms,
## rather than from dated encounters for controls and a single stored
## last_encounter_date for cases. Per the investigator's instruction, encounter
## quantities are rebuilt from these files rather than reusing enc_pre12, whose
## provenance is unknown.
##
## ############################################################################
## # TRUNCATION WARNING -- READ BEFORE QUOTING ANY NUMBER BELOW               #
## # The case encounter file contains exactly 1,048,575 data rows, which is   #
## # precisely Excel's maximum (1,048,576 including the header). A source      #
## # query returning more rows would have been silently cut at that ceiling.   #
## # Evidence against truncation: all 2,618 cases appear; encounters per       #
## # calendar year rise smoothly with no cliff at either end; the file         #
## # reproduces the master engagement flag for 96.5% of cases against 99.5%    #
## # stored. Evidence for it: the exact equality with the limit, which is not  #
## # plausibly coincidental. I cannot resolve this from the data. The file     #
## # should be re-exported as CSV, which has no row limit, and these numbers   #
## # re-run. Until then every case-side encounter quantity here is PROVISIONAL #
## # and may be based on an incomplete record.                                 #
## ############################################################################
##
## Matching, per protocol section 3, against candidate index date I of the case:
##   eligibility  encounter day in [I-365, I-1]; no qualifying seizure code and
##                no chronic antiseizure therapy on or before I+180; at-risk
##                window extends beyond I+180
##   tier 1       sex exact; race exact where both recorded; age +/-3; BMI +/-3;
##                and for females a BMI measurement within +/-2 calendar years
##                of the case's BMI measurement year
##   ladder       drop race -> drop the BMI-year rule -> BMI +/-5 -> age +/-5
##   Sex is never relaxed. Cases in randomised order, nearest neighbour on BMI
##   then age, without replacement, matched in passes so every case gets one
##   control before any case gets a second.
##
## The BMI-year rule is implemented as "the control has some plausible BMI
## measurement within +/-2 calendar years of the case's", rather than "the
## control's BMI measurement nearest I falls in that window". The protocol says
## "BMI calendar year +/-2" without specifying which measurement; this reading
## is the one that does not depend on the index date being settled first, which
## matters because the index date is what matching is choosing.
##
## Implausible BMI values (below 10 or above 100 kg/m2, 31.3% of flowsheet rows,
## including many zeros) are discarded before any of this.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K14 final re-match, both arms on dated encounters ===")
set.seed(SEED)
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds"))
W <- 180; TAU <- 3; FR <- as.Date("2026-09-03")

rd_enc <- function(p){ x <- utils::read.csv(p, colClasses="character")
  data.frame(mrn=trimws(x[[1]]), d=as.Date(substr(x[[3]],1,10)), stringsAsFactors=FALSE) }
EN <- rbind(rd_enc(file.path("data-raw","MDE_Encounters_cases.csv")),
            rd_enc(file.path("data-raw","MDE_Encounters_controls.csv")))
EN <- unique(EN[!is.na(EN$d) & EN$mrn %in% d0$mrn, ])
EN$dn <- as.numeric(EN$d); EN <- EN[order(EN$dn), ]
last_enc <- tapply(EN$dn, EN$mrn, max)
log_msg("encounter-days ", nrow(EN), " across ", length(unique(EN$mrn)), " patients")
assert(all(d0$mrn %in% names(last_enc)), "a cohort member has no encounters at all")

## ---- BMI measurement years ---------------------------------------------------
FL <- utils::read.csv(file.path("data-raw","MDE_Flowsheets_BMI.csv"), colClasses="character")
names(FL) <- c("mrn","row","upd","type","rtext","rval","comm","cap","unit")
FL <- data.frame(mrn=trimws(FL$mrn), v=suppressWarnings(as.numeric(FL$rval)),
                 d=as.Date(substr(FL$cap,1,10)), stringsAsFactors=FALSE)
FL <- FL[!is.na(FL$v) & FL$v >= 10 & FL$v <= 100 & !is.na(FL$d) & FL$mrn %in% d0$mrn, ]
bmi_years <- tapply(as.integer(format(FL$d, "%Y")), FL$mrn, function(z) sort(unique(z)))
## the case's own BMI year: the plausible measurement nearest its index date
FLc <- FL[FL$mrn %in% d0$mrn[d0$iih==1], ]
FLc$rel <- abs(as.numeric(FLc$d - d0$index_date[match(FLc$mrn, d0$mrn)]))
FLc <- FLc[order(FLc$mrn, FLc$rel), ]; FLc <- FLc[!duplicated(FLc$mrn), ]
case_bmi_year <- setNames(as.integer(format(FLc$d, "%Y")), FLc$mrn)

## ---- seizure and medication evidence (definition unchanged from K9) ---------
dx <- utils::read.csv(file.path("data-raw","SZ_dx_62.csv"), colClasses="character")
names(dx) <- c("mrn","s","code","desc","date")
cn <- utils::read.csv(file.path("data-raw","SZ_conditions_10.csv"), colClasses="character")
names(cn) <- c("mrn","s","code","desc","on","rec")
o <- as.Date(substr(cn$on,1,10)); r <- as.Date(substr(cn$rec,1,10))
e <- rbind(data.frame(mrn=trimws(dx$mrn), code=dx$code, desc=dx$desc, date=as.Date(substr(dx$date,1,10))),
           data.frame(mrn=trimws(cn$mrn), code=cn$code, desc=cn$desc,
                      date=as.Date(ifelse(is.na(o), r, o), origin="1970-01-01")))
e <- e[e$mrn %in% d0$mrn & !is.na(e$date), ]
exc <- grepl("^F44|^300\\.11|^R56\\.1|^780\\.33|^780\\.32|^Z82|^G43|^E936|^966", e$code) |
       grepl("febrile|non.epileptic|psychogenic|conversion|family history|migraine|poisoning|adverse",
             e$desc, ignore.case=TRUE)
e$sz <- grepl("^G40|^345|^0345|^R56|^780\\.39|^07703", e$code) & !exc
e$spell <- grepl("spells", e$desc, ignore.case=TRUE)
ASM <- c("levetiracetam","lamotrigine","carbamazepine","oxcarbazepine","valproa","divalproex",
 "phenytoin","fosphenytoin","lacosamide","zonisamide","perampanel","brivaracetam","felbamate",
 "rufinamide","vigabatrin","tiagabine","primidone","ethosuximide","phenobarb","eslicarbazepine","cenobamate")
isa <- function(x){ z <- tolower(x); Reduce(`|`, lapply(ASM, function(a) grepl(a, z, fixed=TRUE))) }
mc <- utils::read.csv(file.path("data-raw","MDE_Medications_cases_22.csv"), colClasses="character")
md <- utils::read.csv(file.path("data-raw","IIH_medications_detail.csv"), colClasses="character")
M <- rbind(data.frame(mrn=trimws(mc[[1]]), st=as.Date(substr(mc$Started.Date,1,10)),
                      en=as.Date(substr(mc$Ended.Date,1,10)),
                      g=paste(mc$Medication.Generic.Name, mc$Medication.Name)),
           data.frame(mrn=trimws(md$clinic_number), st=as.Date(substr(md$start_date,1,10)),
                      en=as.Date(substr(md$end_date,1,10)),
                      g=paste(md$asm_generic, md$medication_name)))
M <- M[isa(M$g) & !is.na(M$st) & M$mrn %in% d0$mrn, ]
M$en[!is.na(M$en) & M$en >= as.Date("9999-01-01")] <- FR
M$en[!is.na(M$en) & (M$en > FR | M$en < M$st)] <- NA
spn <- tapply(seq_len(nrow(M)), M$mrn, function(k){
  s1 <- as.numeric(max(M$st[k]) - min(M$st[k]))
  s2 <- suppressWarnings(max(as.numeric(M$en[k] - M$st[k]), na.rm=TRUE))
  max(s1, ifelse(is.finite(s2), s2, -1)) })
CHRONIC <- names(spn)[spn >= 180]
asm_days <- tapply(as.numeric(M$st[M$mrn %in% CHRONIC]), M$mrn[M$mrn %in% CHRONIC], sort)
SZ <- e[e$sz, ]
sz_days  <- tapply(as.numeric(SZ$date), SZ$mrn, function(z) z)
sz_spell <- tapply(SZ$spell, SZ$mrn, function(z) z)

## ---- matching ----------------------------------------------------------------
cases <- d0[d0$iih == 1, ]
ctl   <- d0[d0$iih == 0, ]
ctl$dn_last <- as.numeric(last_enc[ctl$mrn]); ctl$dn_death <- as.numeric(ctl$death_date)
ctl$used <- FALSE
f_sz  <- vapply(ctl$mrn, function(m){ v <- sz_days[[m]];  if (is.null(v)) Inf else min(v) }, numeric(1))
f_asm <- vapply(ctl$mrn, function(m){ v <- asm_days[[m]]; if (is.null(v)) Inf else min(v) }, numeric(1))
ctl_by <- bmi_years[ctl$mrn]

## Cases must themselves be engaged, on the same definition.
cases$eng <- vapply(seq_len(nrow(cases)), function(i) FALSE, logical(1))
I0 <- as.numeric(cases$index_date)
for (i in seq_len(nrow(cases))) {
  lo <- findInterval(I0[i] - 365, EN$dn, left.open=TRUE) + 1L; hi <- findInterval(I0[i] - 1, EN$dn)
  cases$eng[i] <- hi >= lo && cases$mrn[i] %in% EN$mrn[lo:hi]
}
log_msg("cases engaged on the rebuilt definition: ", sum(cases$eng), " of ", nrow(cases))
cases <- cases[cases$eng, ]

TIERS <- list(list(race=TRUE,  byr=TRUE,  age=3, bmi=3),
              list(race=FALSE, byr=TRUE,  age=3, bmi=3),
              list(race=FALSE, byr=FALSE, age=3, bmi=3),
              list(race=FALSE, byr=FALSE, age=3, bmi=5),
              list(race=FALSE, byr=FALSE, age=5, bmi=5))
ord <- sample(nrow(cases))
csets <- rep(NA_integer_, nrow(cases)); ctlset <- rep(NA_integer_, nrow(ctl))
tier_of <- rep(NA_integer_, nrow(cases))
pick <- function(ii) {
  ca <- cases[ii, ]; I <- as.numeric(ca$index_date)
  lo <- findInterval(I - 365, EN$dn, left.open=TRUE) + 1L; hi <- findInterval(I - 1, EN$dn)
  if (hi < lo) return(NULL)
  elig <- unique(EN$mrn[lo:hi])
  ok0 <- !ctl$used & (ctl$mrn %in% elig) & f_sz > I + W & f_asm > I + W &
         pmin(ifelse(is.na(ctl$dn_death), Inf, ctl$dn_death), ctl$dn_last, as.numeric(FR)) > I + W
  cby <- case_bmi_year[ca$mrn]
  for (ti in seq_along(TIERS)) {
    T <- TIERS[[ti]]
    ok <- ok0 & ctl$sex == ca$sex &
          abs(ctl$age_index - ca$age_index) <= T$age &
          abs(ctl$bmi_index - ca$bmi_index) <= T$bmi
    if (T$race && !is.na(ca$race) && ca$race != "")
      ok <- ok & (is.na(ctl$race) | ctl$race == "" | ctl$race == ca$race)
    if (T$byr && !is.na(ca$sex) && ca$sex == "F" && !is.na(cby))
      ok <- ok & vapply(ctl_by, function(z) !is.null(z) && any(abs(z - cby) <= 2), logical(1))
    ok[is.na(ok)] <- FALSE
    cand <- which(ok)
    if (length(cand)) {
      oo <- order(abs(ctl$bmi_index[cand] - ca$bmi_index), abs(ctl$age_index[cand] - ca$age_index))
      return(list(idx=cand[oo][1], tier=ti))
    }
  }
  NULL
}
sid <- 0L
for (pass in 1:4) {
  for (ii in ord) {
    if (pass > 1 && is.na(csets[ii])) next
    b <- pick(ii); if (is.null(b)) next
    if (pass == 1) { sid <- sid + 1L; csets[ii] <- sid; tier_of[ii] <- b$tier }
    ctl$used[b$idx] <- TRUE; ctlset[b$idx] <- csets[ii]
  }
  log_msg("pass ", pass, ": cases ", sum(!is.na(csets)), " controls ", sum(!is.na(ctlset)))
}

cs <- cases[!is.na(csets), ]; cs$ms <- csets[!is.na(csets)]
cc <- ctl[!is.na(ctlset), ];  cc$ms <- ctlset[!is.na(ctlset)]
cc$index_date <- cs$index_date[match(cc$ms, cs$ms)]          # protocol 2.3
endday <- function(mrn, idx) pmin(pmin(as.numeric(last_enc[mrn]),
  ifelse(is.na(d0$death_date[match(mrn, d0$mrn)]), Inf, as.numeric(d0$death_date[match(mrn, d0$mrn)])),
  as.numeric(FR)) - idx, W + TAU*365.25)
cc$open <- endday(cc$mrn, as.numeric(cc$index_date))
cs$open <- endday(cs$mrn, as.numeric(cs$index_date))
keep <- intersect(names(cs), names(cc)); m <- rbind(cs[, keep], cc[, keep]); m$match_set <- m$ms

## ---- outcome ------------------------------------------------------------------
ev_day <- function(mrn, idx, open) {
  v <- sz_days[[mrn]]; sp <- sz_spell[[mrn]]
  cd <- Inf
  if (!is.null(v)) {
    rel <- v - idx; k <- rel > W & rel <= open + 1e-6
    if (any(k) && all(sp[k]) && !(mrn %in% CHRONIC)) k[] <- FALSE   # Spells rule
    if (any(k)) cd <- min(rel[k])
  }
  if (mrn %in% CHRONIC) { a <- asm_days[[mrn]] - idx; a <- a[a > W & a <= open + 1e-6]
                          if (length(a)) cd <- min(cd, min(a)) }
  if (is.infinite(cd)) NA_real_ else cd
}
m$evday <- mapply(ev_day, m$mrn, as.numeric(m$index_date), m$open)
m$ev <- as.integer(!is.na(m$evday) & m$evday <= m$open + 1e-6)
m$t  <- (ifelse(m$ev == 1, m$evday, m$open) - W)/365.25
a <- m[m$t > 0, ]
fitm <- coxph(Surv(t, ev) ~ iih, data=a, cluster=match_set); s <- summary(fitm)
ph <- tryCatch(signif(cox.zph(fitm)$table["iih","p"],3), error=function(z) NA)
rt <- function(g){ x <- a[a$iih==g,]; ci <- stats::poisson.test(sum(x$ev), sum(x$t))$conf.int
                   sprintf("%.2f (%.2f to %.2f)", 1000*sum(x$ev)/sum(x$t), 1000*ci[1], 1000*ci[2]) }
a$dday <- as.numeric(a$death_date - a$index_date)
a$cr <- factor(ifelse(a$ev==1,"seizure", ifelse(!is.na(a$dday) & a$dday<=a$open,"death","censor")),
               levels=c("censor","seizure","death"))
fs <- survfit(Surv(t, cr) ~ iih, data=a); sm <- summary(fs, times=TAU, extend=TRUE)
cif <- 100*sm$pstate[, which(fs$states=="seizure")]
out <- data.frame(cohort="Final re-match, both arms on dated encounters",
  iih=sprintf("%d/%d", sum(a$ev[a$iih==1]), sum(a$iih==1)),
  comparator=sprintf("%d/%d", sum(a$ev[a$iih==0]), sum(a$iih==0)),
  iih_rate=rt(1), ctl_rate=rt(0),
  HR=fmt_est(s$conf.int[1], s$conf.int[3], s$conf.int[4]), p=signif(s$coef[1,6],4), ph_p=ph,
  cif3_iih=round(cif[2],2), cif3_ctl=round(cif[1],2),
  risk_diff_pp=round(cif[2]-cif[1],2), NNH=round(100/(cif[2]-cif[1])))
write_tab(out, "K_T34_final_rematch"); print(out, row.names=FALSE)
flow <- data.frame(quantity=c("cases engaged & eligible","cases matched","cases unmatched",
                              "controls used","mean controls per case","tier-1 matches"),
  value=c(nrow(cases), sum(!is.na(csets)), sum(is.na(csets)), sum(!is.na(ctlset)),
          round(sum(!is.na(ctlset))/sum(!is.na(csets)),2), sum(tier_of==1, na.rm=TRUE)))
write_tab(flow, "K_T35_final_flow"); print(flow, row.names=FALSE)
bal <- rbind(
  data.frame(variable="age", iih=round(mean(m$age_index[m$iih==1],na.rm=TRUE),2),
             control=round(mean(m$age_index[m$iih==0],na.rm=TRUE),2), smd=round(smd_cont(m$age_index,m$iih),4)),
  data.frame(variable="BMI", iih=round(mean(m$bmi_index[m$iih==1],na.rm=TRUE),2),
             control=round(mean(m$bmi_index[m$iih==0],na.rm=TRUE),2), smd=round(smd_cont(m$bmi_index,m$iih),4)),
  data.frame(variable="female", iih=round(mean(m$sex[m$iih==1]=="F"),3),
             control=round(mean(m$sex[m$iih==0]=="F"),3), smd=round(smd_bin(m$sex=="F",m$iih),4)))
write_tab(bal, "K_T36_final_balance"); print(bal, row.names=FALSE)
saveRDS(a, file.path(PATH$derived, "K14_final.rds"))
log_msg("K14 complete")
