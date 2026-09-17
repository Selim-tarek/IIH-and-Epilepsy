## K15_final_analysis.R -------------------------------------------------------
## FINAL ANALYSIS, run from scratch.
##
## Cohort, matching and outcome are all rebuilt here from source files. Nothing
## is inherited from the submitted analysis except the patient list, their index
## dates, and the baseline covariates used for matching.
##
## TWO LIMITATIONS STAND, both awaiting data, both stated in the output:
##
##  1. The case encounter export is truncated. Encounters_3 and Encounters_4
##     each hold exactly 1,048,575 rows, Excel's maximum, and they are NOT the
##     same rows: 925,159 shared, 123,416 unique to one, 76,608 to the other.
##     Their UNION is used here, which recovers about 76,600 encounters that
##     neither file alone contains and is strictly closer to complete than
##     either -- but it is still not known to be complete. A CSV re-export
##     would settle it.
##
##  2. Encounter Type exists for cases but not comparators. 60% of case rows are
##     patient messages, orders, refills and conversion encounters rather than
##     visits. Cases are therefore NOT filtered to clinical visits, because
##     comparators cannot be filtered the same way and a one-sided filter would
##     recreate the very asymmetry this analysis exists to remove. If the type
##     column is supplied for comparators, both arms should be restricted to
##     visits and this re-run.
##
## OUTCOME (identical in both arms): a qualifying seizure code after the 180-day
## washout, or antiseizure medication continued 180+ days. Codes G40/345/R56.9/
## 780.39 count; F44.5, R56.1, 780.32/.33, Z82, G43, E936/966 and febrile,
## psychogenic, conversion, family-history, migraine and adverse-effect
## descriptors do not. "Spells Neurological" counts only with chronic therapy.
## Topiramate, acetazolamide, gabapentin, pregabalin and benzodiazepines are not
## antiseizure evidence.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== K15 FINAL ANALYSIS ===")
set.seed(SEED)
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds"))
W <- 180; TAU <- 3; FR <- as.Date("2026-09-03")

rd <- function(p, dcol) { x <- utils::read.csv(p, colClasses="character")
  data.frame(mrn=trimws(x[[1]]), d=as.Date(substr(x[[dcol]],1,10)), stringsAsFactors=FALSE) }
EN <- unique(rbind(rd("data-raw/MDE_Encounters_cases.csv", 3),
                   rd("data-raw/MDE_Encounters_types.csv", 3),
                   rd("data-raw/MDE_Encounters_controls.csv", 3)))
EN <- EN[!is.na(EN$d) & EN$mrn %in% d0$mrn, ]
EN$dn <- as.numeric(EN$d); EN <- EN[order(EN$dn), ]
last_enc <- tapply(EN$dn, EN$mrn, max)
log_msg("encounter-days ", nrow(EN), " across ", length(unique(EN$mrn)), " patients")
assert(all(d0$mrn %in% names(last_enc)), "a cohort member has no encounters")

FL <- utils::read.csv("data-raw/MDE_Flowsheets_BMI.csv", colClasses="character")
FL <- data.frame(mrn=trimws(FL[[1]]), v=suppressWarnings(as.numeric(FL[[6]])),
                 d=as.Date(substr(FL[[8]],1,10)), stringsAsFactors=FALSE)
FL <- FL[!is.na(FL$v) & FL$v >= 10 & FL$v <= 100 & !is.na(FL$d) & FL$mrn %in% d0$mrn, ]
bmi_years <- tapply(as.integer(format(FL$d,"%Y")), FL$mrn, function(z) sort(unique(z)))
FLc <- FL[FL$mrn %in% d0$mrn[d0$iih==1], ]
FLc$rel <- abs(as.numeric(FLc$d - d0$index_date[match(FLc$mrn, d0$mrn)]))
FLc <- FLc[order(FLc$mrn, FLc$rel), ]; FLc <- FLc[!duplicated(FLc$mrn), ]
case_bmi_year <- setNames(as.integer(format(FLc$d,"%Y")), FLc$mrn)

dx <- utils::read.csv("data-raw/SZ_dx_62.csv", colClasses="character"); names(dx) <- c("mrn","s","code","desc","date")
cn <- utils::read.csv("data-raw/SZ_conditions_10.csv", colClasses="character"); names(cn) <- c("mrn","s","code","desc","on","rec")
o <- as.Date(substr(cn$on,1,10)); r <- as.Date(substr(cn$rec,1,10))
e <- rbind(data.frame(mrn=trimws(dx$mrn), code=dx$code, desc=dx$desc, date=as.Date(substr(dx$date,1,10))),
           data.frame(mrn=trimws(cn$mrn), code=cn$code, desc=cn$desc,
                      date=as.Date(ifelse(is.na(o), r, o), origin="1970-01-01")))
e <- e[e$mrn %in% d0$mrn & !is.na(e$date), ]
exc <- grepl("^F44|^300\\.11|^R56\\.1|^780\\.33|^780\\.32|^Z82|^G43|^E936|^966", e$code) |
       grepl("febrile|non.epileptic|psychogenic|conversion|family history|migraine|poisoning|adverse",
             e$desc, ignore.case=TRUE)
e$g40 <- grepl("^G40|^345|^0345", e$code) & !exc
e$sz  <- (grepl("^R56|^780\\.39|^07703", e$code) & !exc) | e$g40
e$spell <- grepl("spells", e$desc, ignore.case=TRUE)
ASM <- c("levetiracetam","lamotrigine","carbamazepine","oxcarbazepine","valproa","divalproex",
 "phenytoin","fosphenytoin","lacosamide","zonisamide","perampanel","brivaracetam","felbamate",
 "rufinamide","vigabatrin","tiagabine","primidone","ethosuximide","phenobarb","eslicarbazepine","cenobamate")
isa <- function(x){ z <- tolower(x); Reduce(`|`, lapply(ASM, function(a) grepl(a, z, fixed=TRUE))) }
mc <- utils::read.csv("data-raw/MDE_Medications_cases_22.csv", colClasses="character")
md <- utils::read.csv("data-raw/IIH_medications_detail.csv", colClasses="character")
M <- rbind(data.frame(mrn=trimws(mc[[1]]), st=as.Date(substr(mc$Started.Date,1,10)),
                      en=as.Date(substr(mc$Ended.Date,1,10)), g=paste(mc$Medication.Generic.Name, mc$Medication.Name)),
           data.frame(mrn=trimws(md$clinic_number), st=as.Date(substr(md$start_date,1,10)),
                      en=as.Date(substr(md$end_date,1,10)), g=paste(md$asm_generic, md$medication_name)))
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
G4 <- e[e$g40, ]; g40_days <- tapply(as.numeric(G4$date), G4$mrn, function(z) z)

## ---- matching -----------------------------------------------------------------
cases <- d0[d0$iih == 1, ]; ctl <- d0[d0$iih == 0, ]
I0 <- as.numeric(cases$index_date)
cases$eng <- vapply(seq_len(nrow(cases)), function(i){
  lo <- findInterval(I0[i]-365, EN$dn, left.open=TRUE)+1L; hi <- findInterval(I0[i]-1, EN$dn)
  hi >= lo && cases$mrn[i] %in% EN$mrn[lo:hi] }, logical(1))
log_msg("cases engaged: ", sum(cases$eng), " of ", nrow(cases))
cases <- cases[cases$eng, ]
ctl$dn_last <- as.numeric(last_enc[ctl$mrn]); ctl$dn_death <- as.numeric(ctl$death_date); ctl$used <- FALSE
f_sz  <- vapply(ctl$mrn, function(m){ v <- sz_days[[m]];  if (is.null(v)) Inf else min(v) }, numeric(1))
f_asm <- vapply(ctl$mrn, function(m){ v <- asm_days[[m]]; if (is.null(v)) Inf else min(v) }, numeric(1))
ctl_by <- bmi_years[ctl$mrn]
TIERS <- list(list(race=TRUE,byr=TRUE,age=3,bmi=3), list(race=FALSE,byr=TRUE,age=3,bmi=3),
              list(race=FALSE,byr=FALSE,age=3,bmi=3), list(race=FALSE,byr=FALSE,age=3,bmi=5),
              list(race=FALSE,byr=FALSE,age=5,bmi=5))
ord <- sample(nrow(cases))
csets <- rep(NA_integer_, nrow(cases)); ctlset <- rep(NA_integer_, nrow(ctl)); tier_of <- rep(NA_integer_, nrow(cases))
pick <- function(ii){ ca <- cases[ii,]; I <- as.numeric(ca$index_date)
  lo <- findInterval(I-365, EN$dn, left.open=TRUE)+1L; hi <- findInterval(I-1, EN$dn)
  if (hi < lo) return(NULL)
  elig <- unique(EN$mrn[lo:hi])
  ok0 <- !ctl$used & (ctl$mrn %in% elig) & f_sz > I+W & f_asm > I+W &
         pmin(ifelse(is.na(ctl$dn_death), Inf, ctl$dn_death), ctl$dn_last, as.numeric(FR)) > I+W
  cby <- case_bmi_year[ca$mrn]
  for (ti in seq_along(TIERS)) { T <- TIERS[[ti]]
    ok <- ok0 & ctl$sex == ca$sex & abs(ctl$age_index-ca$age_index) <= T$age &
          abs(ctl$bmi_index-ca$bmi_index) <= T$bmi
    if (T$race && !is.na(ca$race) && ca$race != "")
      ok <- ok & (is.na(ctl$race) | ctl$race == "" | ctl$race == ca$race)
    if (T$byr && !is.na(ca$sex) && ca$sex == "F" && !is.na(cby))
      ok <- ok & vapply(ctl_by, function(z) !is.null(z) && any(abs(z-cby) <= 2), logical(1))
    ok[is.na(ok)] <- FALSE; cand <- which(ok)
    if (length(cand)) { oo <- order(abs(ctl$bmi_index[cand]-ca$bmi_index), abs(ctl$age_index[cand]-ca$age_index))
                        return(list(idx=cand[oo][1], tier=ti)) } }
  NULL }
sid <- 0L
for (pass in 1:4) { for (ii in ord) {
    if (pass > 1 && is.na(csets[ii])) next
    b <- pick(ii); if (is.null(b)) next
    if (pass == 1) { sid <- sid+1L; csets[ii] <- sid; tier_of[ii] <- b$tier }
    ctl$used[b$idx] <- TRUE; ctlset[b$idx] <- csets[ii] }
  log_msg("pass ", pass, ": cases ", sum(!is.na(csets)), " controls ", sum(!is.na(ctlset))) }
cs <- cases[!is.na(csets),]; cs$ms <- csets[!is.na(csets)]
cc <- ctl[!is.na(ctlset),];  cc$ms <- ctlset[!is.na(ctlset)]
cc$index_date <- cs$index_date[match(cc$ms, cs$ms)]
endd <- function(mrn, idx) pmin(pmin(as.numeric(last_enc[mrn]),
  ifelse(is.na(d0$death_date[match(mrn,d0$mrn)]), Inf, as.numeric(d0$death_date[match(mrn,d0$mrn)])),
  as.numeric(FR)) - idx, W + TAU*365.25)
cc$open <- endd(cc$mrn, as.numeric(cc$index_date)); cs$open <- endd(cs$mrn, as.numeric(cs$index_date))
kp <- intersect(names(cs), names(cc)); m <- rbind(cs[,kp], cc[,kp]); m$match_set <- m$ms

## ---- outcome --------------------------------------------------------------------
ev_day <- function(mrn, idx, open, codes_only=FALSE, g40_only=FALSE) {
  v <- if (g40_only) g40_days[[mrn]] else sz_days[[mrn]]
  sp <- if (g40_only) NULL else sz_spell[[mrn]]
  cd <- Inf
  if (!is.null(v)) { rel <- v - idx; k <- rel > W & rel <= open + 1e-6
    if (!g40_only && any(k) && all(sp[k]) && !(mrn %in% CHRONIC)) k[] <- FALSE
    if (any(k)) cd <- min(rel[k]) }
  if (!codes_only && mrn %in% CHRONIC) { a <- asm_days[[mrn]] - idx; a <- a[a > W & a <= open + 1e-6]
    if (length(a)) cd <- min(cd, min(a)) }
  if (is.infinite(cd)) NA_real_ else cd }
mk <- function(dat, ...) { dat$evday <- mapply(ev_day, dat$mrn, as.numeric(dat$index_date), dat$open, ...)
  dat$ev <- as.integer(!is.na(dat$evday) & dat$evday <= dat$open + 1e-6)
  dat$t <- (ifelse(dat$ev==1, dat$evday, dat$open) - W)/365.25
  dat[dat$t > 0, ] }
a <- mk(m)
report <- function(dat, lab) {
  f <- coxph(Surv(t,ev) ~ iih, data=dat, cluster=match_set); s <- summary(f)
  ph <- tryCatch(signif(cox.zph(f)$table["iih","p"],3), error=function(z) NA)
  rt <- function(g){ x <- dat[dat$iih==g,]; ci <- stats::poisson.test(sum(x$ev), sum(x$t))$conf.int
                     sprintf("%.2f (%.2f to %.2f)", 1000*sum(x$ev)/sum(x$t), 1000*ci[1], 1000*ci[2]) }
  dat$dd <- as.numeric(dat$death_date - dat$index_date)
  dat$cr <- factor(ifelse(dat$ev==1,"seizure", ifelse(!is.na(dat$dd)&dat$dd<=dat$open,"death","censor")),
                   levels=c("censor","seizure","death"))
  fs <- survfit(Surv(t,cr) ~ iih, data=dat); sm <- summary(fs, times=TAU, extend=TRUE)
  cif <- 100*sm$pstate[, which(fs$states=="seizure")]
  data.frame(analysis=lab, iih=sprintf("%d/%d", sum(dat$ev[dat$iih==1]), sum(dat$iih==1)),
    comparator=sprintf("%d/%d", sum(dat$ev[dat$iih==0]), sum(dat$iih==0)),
    iih_rate=rt(1), ctl_rate=rt(0),
    HR=fmt_est(s$conf.int[1], s$conf.int[3], s$conf.int[4]), p=signif(s$coef[1,6],3), ph_p=ph,
    cif3_iih=round(cif[2],2), cif3_ctl=round(cif[1],2),
    risk_diff_pp=round(cif[2]-cif[1],2), NNH=round(100/(cif[2]-cif[1]))) }
main <- report(a, "PRIMARY: any seizure code or indefinite ASM")
## sensitivities
sens <- rbind(main,
  report(mk(m, codes_only=TRUE),  "Codes only, medication channel removed"),
  report(mk(m, g40_only=TRUE),    "Epilepsy-specific codes only (G40/345)"))
op <- d0$op_cmh2o; op[!is.na(op) & op < 6] <- NA          # implausible, per investigator
keep_op <- d0$mrn[d0$iih==1 & !is.na(op) & op >= 25]
sets_op <- m$match_set[m$iih==1 & m$mrn %in% keep_op]
sens <- rbind(sens, report(mk(m[m$match_set %in% sets_op, ]),
                           "Restricted to opening pressure >= 25 cmH2O"))
write_tab(sens, "K_T38_FINAL_results"); print(sens[,c("analysis","iih","comparator","HR","p")], row.names=FALSE)

## ---- secondary: epilepsy vs single ---------------------------------------------
epi <- function(mrn, idx, open){
  g <- g40_days[[mrn]]; if (!is.null(g) && any(g-idx > W & g-idx <= open)) return(TRUE)
  v <- sz_days[[mrn]]
  if (!is.null(v)) { u <- sort(unique(v[v-idx > W & v-idx <= open]))
                     if (length(u) >= 2 && (max(u)-min(u)) >= 30) return(TRUE) }
  mrn %in% CHRONIC }
ae <- a[a$ev==1, ]; ae$epi <- mapply(epi, ae$mrn, as.numeric(ae$index_date), ae$open)
sec <- do.call(rbind, lapply(c(1,0), function(g){ s <- ae[ae$iih==g,]
  ci <- stats::binom.test(sum(s$epi), nrow(s))$conf.int
  data.frame(arm=ifelse(g==1,"IIH","Comparator"), with_event=nrow(s),
    recurrent_or_epilepsy=sum(s$epi), single_seizure=sum(!s$epi),
    pct=sprintf("%.0f%% (%.0f to %.0f)", 100*mean(s$epi), 100*ci[1], 100*ci[2])) }))
write_tab(sec, "K_T39_FINAL_secondary"); print(sec, row.names=FALSE)

flow <- data.frame(quantity=c("IIH engaged & eligible","cases matched","cases unmatched",
                              "controls used","mean controls per case","tier-1 matches"),
  value=c(nrow(cases), sum(!is.na(csets)), sum(is.na(csets)), sum(!is.na(ctlset)),
          round(sum(!is.na(ctlset))/sum(!is.na(csets)),2), sum(tier_of==1, na.rm=TRUE)))
write_tab(flow, "K_T40_FINAL_flow"); print(flow, row.names=FALSE)
bal <- rbind(
  data.frame(variable="Age at index", iih=round(mean(m$age_index[m$iih==1],na.rm=TRUE),2),
             control=round(mean(m$age_index[m$iih==0],na.rm=TRUE),2), smd=round(smd_cont(m$age_index,m$iih),4)),
  data.frame(variable="BMI", iih=round(mean(m$bmi_index[m$iih==1],na.rm=TRUE),2),
             control=round(mean(m$bmi_index[m$iih==0],na.rm=TRUE),2), smd=round(smd_cont(m$bmi_index,m$iih),4)),
  data.frame(variable="Female", iih=round(mean(m$sex[m$iih==1]=="F"),3),
             control=round(mean(m$sex[m$iih==0]=="F"),3), smd=round(smd_bin(m$sex=="F",m$iih),4)))
write_tab(bal, "K_T41_FINAL_balance"); print(bal, row.names=FALSE)
saveRDS(list(a=a, ae=ae, sens=sens, sec=sec, flow=flow, bal=bal), file.path(PATH$derived,"K15_final.rds"))
log_msg("K15 complete")
