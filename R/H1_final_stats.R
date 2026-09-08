## H1_final_stats.R -----------------------------------------------------------
## FINAL statistics. Primary cohort is the engagement-restricted one: controls
## with >=1 encounter in the 12 months before index, which is what protocol
## v2.0 specified and the extract did not achieve (55.7% of controls had zero).
## The full cohort is retained throughout as a secondary analysis.

source("R/00_setup.R")
log_msg("=== H1 final statistics ===")
d0 <- readRDS(file.path(PATH$derived, "G1_master.rds"))
G2 <- readRDS(file.path(PATH$derived, "G2_results.rds"))
PANEL <- readRDS(file.path(PATH$derived, "G5_panel.rds"))
TAU <- 3
d <- d0[d0$engaged, ]              # PRIMARY
dF <- d0                            # secondary

cut_s <- function(dat, tau) {
  dat$t <- pmin(dat$t_y, tau)
  dat$ev <- ifelse(dat$t_y > tau, 0L, as.integer(dat$event))
  dat$evc <- ifelse(dat$t_y > tau, 0L,
                    ifelse(dat$event == 1, 1L, ifelse(dat$died == 1, 2L, 0L)))
  dat[dat$t > 0, ]
}
cox <- function(dat, tau = TAU, rhs = "iih", strat = FALSE, wts = NULL, label = "") {
  s <- cut_s(dat, tau)
  f <- stats::as.formula(paste("Surv(t, ev) ~", rhs, if (strat) "+ strata(match_set)" else ""))
  fit <- try(if (strat) survival::coxph(f, data = s)
             else if (!is.null(wts)) survival::coxph(f, data = s, weights = s[[wts]],
                          cluster = s$match_set, robust = TRUE)
             else survival::coxph(f, data = s, cluster = s$match_set, robust = TRUE), silent = TRUE)
  if (inherits(fit, "try-error") || !is.finite(stats::coef(fit)[1]))
    return(data.frame(model = label, n = nrow(s), events = sum(s$ev), hr = NA, lo = NA,
                      hi = NA, estimate = "not estimable", p = NA))
  sm <- summary(fit)
  data.frame(model = label, n = fit$n, events = fit$nevent,
             hr = sm$conf.int[1,1], lo = sm$conf.int[1,3], hi = sm$conf.int[1,4],
             estimate = fmt_est(sm$conf.int[1,1], sm$conf.int[1,3], sm$conf.int[1,4]),
             p = fmt_p(sm$coefficients[1, ncol(sm$coefficients)]), stringsAsFactors = FALSE)
}

## ---- T1 primary and sensitivity specifications ------------------------------
ps <- d[stats::complete.cases(d[, c("age_index","bmi_index","sex","index_year")]), ]
psf <- stats::glm(iih ~ age_index + bmi_index + sex + index_year, family = stats::binomial, data = ps)
ps$psv <- stats::fitted(psf); pm <- mean(ps$iih)
ps$iptw <- ifelse(ps$iih == 1, pm/ps$psv, (1-pm)/(1-ps$psv))
qq <- stats::quantile(ps$iptw, c(.01,.99)); ps$iptw_trim <- pmin(pmax(ps$iptw, qq[1]), qq[2])
q3 <- stats::quantile(d$enc_post[d$iih == 0], .75, na.rm = TRUE)

spec <- rbind(
  cox(d, label = "PRIMARY: Cox, 3-year"),
  cox(d, strat = TRUE, label = "Stratified by matched set"),
  cox(ps, wts = "iptw_trim", label = "IPTW (stabilised, trimmed)"),
  cox(d, rhs = "iih + age_index + bmi_index + sex", label = "+ age, BMI, sex"),
  cox(d, rhs = "iih + age_index + bmi_index + sex + osa + htn + pcos", label = "+ comorbidity"),
  cox(d, rhs = "iih + age_index + bmi_index + sex + osa + htn + pcos + smoking_final", label = "+ smoking"),
  cox(d, rhs = "iih + log1p(enc_pre12)", label = "+ pre-index contact"),
  cox(d, rhs = "iih + log1p(enc_post)", label = "+ post-index contact (BOUND ONLY)"),
  cox(d[d$sex == "F", ], label = "Female sets"),
  cox(d[d$sex == "M", ], label = "Male sets"),
  cox(d[which(d$iih == 1 | d$enc_post >= q3), ], label = "Controls in top quartile of post-index contact"),
  cox(d[d$index_year >= 2010, ], label = "Index year >= 2010"),
  cox(d, tau = 5, label = "5-year horizon"),
  cox(d, tau = Inf, label = "Full follow-up"),
  cox(dF, label = "SECONDARY: full cohort (unrestricted controls)"))
write_tab(spec[, c("model","n","events","estimate","p")], "H_T1_specifications")
print(spec[, c("model","n","events","estimate","p")])

## ---- T2 rates ---------------------------------------------------------------
rates <- do.call(rbind, lapply(list(list(d,"Engagement-restricted"), list(dF,"Full cohort")),
  function(z) do.call(rbind, lapply(c(1,0), function(g) {
    s <- cut_s(z[[1]], TAU); s <- s[s$iih == g, ]; r <- pois_rate_ci(sum(s$ev), sum(s$t))
    data.frame(cohort = z[[2]], arm = ifelse(g==1,"IIH","Control"), n = nrow(s),
               events = sum(s$ev), py = round(sum(s$t)), rate = round(r[["rate"]],2),
               lo = round(r[["lo"]],2), hi = round(r[["hi"]],2)) }))))
irr <- irr_exact(rates$events[1], rates$py[1], rates$events[2], rates$py[2])
write_tab(rates, "H_T2_rates")
print(rates)

## ---- T3 absolute risk, competing death --------------------------------------
s3 <- cut_s(d, TAU); s3$evf <- factor(s3$evc, 0:2, c("censored","seizure","death"))
aj <- survival::survfit(Surv(t, evf) ~ iih, data = s3, id = seq_len(nrow(s3)))
ks <- which(aj$states == "seizure")
sm <- summary(aj, times = c(1,2,3), extend = TRUE)
cif <- data.frame(arm = ifelse(grepl("iih=1", as.character(sm$strata)), "IIH", "Control"),
                  time_y = sm$time, cif_pct = round(100*sm$pstate[,ks],3),
                  se = round(100*sm$std.err[,ks],3),
                  lo = round(100*sm$lower[,ks],3), hi = round(100*sm$upper[,ks],3))
write_tab(cif, "H_T3_cumulative_incidence")
i1 <- which(cif$arm=="IIH" & cif$time_y==3); i0 <- which(cif$arm=="Control" & cif$time_y==3)
est <- cif$cif_pct[i1]-cif$cif_pct[i0]; sed <- sqrt(cif$se[i1]^2+cif$se[i0]^2)
rd <- data.frame(measure="3-year absolute risk difference (pp)",
                 iih_pct=cif$cif_pct[i1], control_pct=cif$cif_pct[i0],
                 estimate=round(est,2), lo=round(est-1.96*sed,2), hi=round(est+1.96*sed,2),
                 nnh=round(100/est))
write_tab(rd, "H_T4_risk_difference"); print(rd)

## Fine-Gray and cause-specific death
fg <- survival::coxph(Surv(fgstart,fgstop,fgstatus) ~ iih, weights = fgwt,
        data = survival::finegray(Surv(t,evf) ~ ., data = s3, etype = "seizure"))
csd <- survival::coxph(Surv(t, evc==2) ~ iih, data = s3, cluster = s3$match_set, robust = TRUE)
sfg <- summary(fg); scd <- summary(csd)
cr <- data.frame(estimand = c("Cause-specific HR, seizure (primary)",
                              "Subdistribution HR (Fine-Gray)",
                              "Cause-specific HR, death (competing)"),
  estimate = c(spec$estimate[1],
    fmt_est(sfg$conf.int[1,1], sfg$conf.int[1,3], sfg$conf.int[1,4]),
    fmt_est(scd$conf.int[1,1], scd$conf.int[1,3], scd$conf.int[1,4])))
write_tab(cr, "H_T5_competing_risk"); print(cr)

## ---- T6 PH, E-value, RMTL ---------------------------------------------------
ph <- do.call(rbind, lapply(c(3,5,Inf), function(tau) {
  s <- cut_s(d, tau); z <- survival::cox.zph(survival::coxph(Surv(t,ev)~iih, data=s))
  data.frame(horizon=tau, chisq=round(z$table["iih","chisq"],2), p=signif(z$table["iih","p"],3),
             conclusion=ifelse(z$table["iih","p"]<.05,"PH VIOLATED","PH not rejected")) }))
write_tab(ph, "H_T6_ph"); print(ph)
ev <- evalue_hr(spec$hr[1], spec$lo[1], spec$hi[1])
write_tab(data.frame(quantity=c("E-value, point","E-value, CI limit"), value=round(ev,2)),
          "H_T7_evalue")

rmtl <- function(dat) { dat$evf <- factor(dat$evc,0:2,c("censored","seizure","death"))
  f <- survival::survfit(Surv(t,evf)~iih, data=dat, id=seq_len(nrow(dat)))
  g <- seq(0,TAU,by=.01); s2 <- summary(f, times=g, extend=TRUE)
  kk <- which(f$states=="seizure"); st <- as.character(s2$strata)
  vapply(c("iih=0","iih=1"), function(z){ y <- s2$pstate[st==z,kk]
    sum((utils::head(y,-1)+utils::tail(y,-1))/2*diff(g)) }, numeric(1)) }
obs <- rmtl(s3); set.seed(SEED)
sets <- unique(s3$match_set); idx <- split(seq_len(nrow(s3)), s3$match_set)
bt <- vapply(seq_len(400), function(b){ pk <- sample(sets, length(sets), replace=TRUE)
  d2 <- s3[unlist(idx[pk], use.names=FALSE),]; d2$match_set <- rep(seq_along(pk), lengths(idx[pk]))
  o <- try(rmtl(d2), silent=TRUE); if (inherits(o,"try-error")||length(o)!=2) c(NA,NA,NA) else c(o,o[2]-o[1]) },
  numeric(3))
rm_tab <- data.frame(quantity=c("Control","IIH","Difference"),
  days=round(c(obs[1],obs[2],obs[2]-obs[1])*365.25,2),
  lo=round(apply(bt,1,stats::quantile,.025,na.rm=TRUE)*365.25,2),
  hi=round(apply(bt,1,stats::quantile,.975,na.rm=TRUE)*365.25,2))
rm_tab$estimate <- fmt_est(rm_tab$days, rm_tab$lo, rm_tab$hi)
write_tab(rm_tab, "H_T8_rmtl"); print(rm_tab[,c("quantity","estimate")])

## ---- T9 timing ---------------------------------------------------------------
lat <- d[d$event == 1, c("cohort","lat_days")]; lat$y <- lat$lat_days/365.25
lt <- do.call(rbind, lapply(levels(lat$cohort), function(k){ x <- lat$y[lat$cohort==k]
  data.frame(cohort=k, n=length(x), median_y=round(stats::median(x),2),
             q1=round(stats::quantile(x,.25),2), q3=round(stats::quantile(x,.75),2),
             pct_within_3y=round(100*mean(x<=3),1)) }))
lt$wilcoxon_p <- c(signif(stats::wilcox.test(y ~ cohort, data=lat)$p.value,3), NA)
write_tab(lt, "H_T9_latency"); print(lt)

## ---- T10 subgroups -----------------------------------------------------------
d$g_sex <- ifelse(d$sex=="F","Female","Male")
d$g_age <- ifelse(d$age_index<35,"Age <35","Age >=35")
d$g_bmi <- ifelse(d$bmi_index<35,"BMI <35","BMI >=35")
d$g_era <- ifelse(d$index_year<2015,"Index <2015","Index >=2015")
sgv <- c(g_sex="Sex", g_age="Age", g_bmi="BMI", g_era="Calendar period")
intp <- function(v){ s <- cut_s(d,TAU); s$m <- factor(s[[v]])
  f <- try(survival::coxph(Surv(t,ev)~iih*m, data=s, cluster=s$match_set, robust=TRUE), silent=TRUE)
  if (inherits(f,"try-error")) return(NA); b <- stats::coef(f); k <- grep("^iih:", names(b))
  if (!length(k)||any(!is.finite(b[k]))) return(NA); V <- f$var[k,k,drop=FALSE]
  if (abs(det(V))<1e-12) return(NA)
  signif(stats::pchisq(as.numeric(t(b[k])%*%solve(V)%*%b[k]), length(k), lower.tail=FALSE),3) }
sub <- do.call(rbind, lapply(names(sgv), function(v){
  lv <- sort(unique(stats::na.omit(d[[v]])))
  r <- do.call(rbind, lapply(lv, function(l) cox(d[which(d[[v]]==l),], label=l)))
  r$modifier <- sgv[[v]]; r$interaction_p <- c(intp(v), rep(NA,nrow(r)-1)); r }))
ov <- cox(d, label="Overall"); ov$modifier <- "Overall"; ov$interaction_p <- NA
sub <- rbind(ov, sub)
write_tab(sub[,c("modifier","model","n","events","estimate","interaction_p")], "H_T10_subgroups")
print(sub[,c("modifier","model","events","estimate","interaction_p")])

## ---- T11 tipping point --------------------------------------------------------
base <- cut_s(d, TAU)
tip <- do.call(rbind, lapply(c(0,.005,.01,.02,.05), function(fr){ set.seed(SEED)
  ss <- base; cc <- which(ss$iih==0 & ss$ev==0); k <- round(fr*length(cc))
  if (k>0){ h <- sample(cc,k); ss$ev[h] <- 1L; ss$t[h] <- stats::runif(k)*ss$t[h] }
  f <- survival::coxph(Surv(t,ev)~iih, data=ss, cluster=ss$match_set, robust=TRUE); s2 <- summary(f)
  data.frame(pct_hidden=100*fr, added=k, hr=round(s2$conf.int[1,1],2),
             lo=round(s2$conf.int[1,3],2), hi=round(s2$conf.int[1,4],2),
             crosses_null=s2$conf.int[1,3]<1) }))
write_tab(tip, "H_T11_tipping_point"); print(tip)

saveRDS(list(spec=spec, rates=rates, cif=cif, rd=rd, cr=cr, ph=ph, ev=ev, rmtl=rm_tab,
             lat=lt, lat_raw=lat, sub=sub, tip=tip, s3=s3, aj=aj, panel=PANEL,
             bal=G2$bal, prev=G2$prev, irr=irr),
        file.path(PATH$derived, "H1_final.rds"))
log_msg("H1 complete")
