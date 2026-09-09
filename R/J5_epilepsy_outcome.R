## J5_epilepsy_outcome.R ------------------------------------------------------
## Epilepsy as an OUTCOME on the cohort denominator.
##
## J3 answered "of the patients who had a seizure, how many had epilepsy?" That
## is a conditional proportion, and its control value (63/64, 98%) invites a
## misreading: it does not mean controls had more epilepsy. It means the few
## controls whose seizures were captured were mostly established cases -- a
## statement about ascertainment, not about risk.
##
## The quantity that answers "who has more epilepsy" puts the same numerator
## over the whole arm, not over the seizure subgroup. This script does that.
##
## The single-seizure contrast is reported for completeness but is NOT a
## result: only one control in the entire cohort is classified as a single
## seizure, which produces an uninterpretable hazard ratio and is a direct
## consequence of the control outcome having required stronger evidence.

source("R/00_setup.R"); suppressMessages(library(survival))
log_msg("=== J5 epilepsy as an outcome ===")
P <- readRDS(file.path(PATH$derived, "J1_phenotype.rds"))$code
E <- readRDS(file.path(PATH$derived, "J3_event_classification.rds"))
P$epi <- as.integer(P$mrn %in% E$mrn[E$epilepsy])
P$sgl <- as.integer(P$event == 1 & P$epi == 0)

rows <- list()
for (eng in c(FALSE, TRUE)) {
  a <- P[P$fu_seizure_end_day > 180, ]; if (eng) a <- a[a$engaged, ]
  for (oc in c("epi","sgl")) {
    m <- coxph(stats::reformulate("iih", sprintf("Surv(t_y,%s)", oc)), data=a, cluster=match_set)
    s <- summary(m)
    hr <- if (min(tapply(a[[oc]], a$iih, sum)) < 5 || abs(s$coef[1,1]) > 5)
            c(NA,NA,NA) else s$conf.int[c(1,3,4)]
    r <- do.call(rbind, lapply(c(1,0), function(g){
      x <- a[a$iih==g, ]; ci <- stats::binom.test(sum(x[[oc]]), nrow(x))$conf.int
      data.frame(k=sum(x[[oc]]), n=nrow(x), pct=100*mean(x[[oc]]),
                 lo=100*ci[1], hi=100*ci[2], rate=1000*sum(x[[oc]])/sum(x$t_y)) }))
    rows[[length(rows)+1]] <- data.frame(
      outcome=c(epi="Epilepsy (recurrent/established)", sgl="Single seizure only")[oc],
      cohort=if (eng) "Engagement-restricted" else "Full",
      iih=sprintf("%d/%d (%.2f%%)", r$k[1], r$n[1], r$pct[1]),
      control=sprintf("%d/%d (%.2f%%)", r$k[2], r$n[2], r$pct[2]),
      iih_rate_1000py=round(r$rate[1],1), control_rate_1000py=round(r$rate[2],1),
      HR=hr[1], lo=hr[2], hi=hr[3],
      estimate=if (is.na(hr[1])) "not estimable (see header)" else fmt_est(hr[1], hr[2], hr[3]))
  }
}
out <- do.call(rbind, rows)
write_tab(out, "J_T10_epilepsy_as_outcome")
print(out[, c("outcome","cohort","iih","control","estimate")], row.names=FALSE)
log_msg("J5 complete")
