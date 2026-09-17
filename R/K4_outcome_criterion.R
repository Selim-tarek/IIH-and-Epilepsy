## K4_outcome_criterion.R -----------------------------------------------------
## The derivation record was in the original master file all along, in a column
## named outcome_criterion. This script reads it.
##
## WHAT IT SHOWS
##   Comparators: every one of the 83 events carries a recorded criterion --
##     57 by criterion 1 (two epilepsy-specific codes >= 30 days apart)
##     26 by criterion 2 (one epilepsy-specific code plus an antiseizure drug)
##   IIH cases:   all 102 events carry a BLANK criterion. Not 88 ("not
##     assessable"), which the file uses elsewhere -- empty.
##
## The companion column seizure_ever is populated only for IIH cases (213) and
## is blank for all 9,742 comparators. The two arms were processed by different
## routes, and only the comparator route recorded which protocol rule was met.
##
## MY ERROR. R/05_outcome_algorithm.R line 22 reads this outcome straight from
## the supplied column, under a comment asserting it was "applied identically
## in both cohorts upstream". That was an assumption I recorded and never
## tested, and this column was the place to test it. Every downstream estimate
## inherits it.
##
## Read with the code evidence (K_T05), the picture is consistent: comparators
## were scored by protocol section 4.1, which requires an epilepsy-specific
## G40/345 code; 70 of the 102 IIH events carry only a non-specific R56.9
## convulsion code, which section 4.1 says does not satisfy the outcome.

source("R/00_setup.R")
log_msg("=== K4 outcome_criterion ===")
r <- utils::read.csv(file.path("data-raw","IIH_MASTER_cases_and_controls_2.csv"), colClasses="character")
ev <- r[r$seizure_incident %in% c("1","1.0"), ]
tab <- as.data.frame.matrix(table(arm=ev$group_label, criterion=ev$outcome_criterion))
names(tab) <- c("criterion BLANK","criterion 1 (two codes)","criterion 2 (code + drug)")[
  match(names(tab), c("","1.0","2.0"))]
tab <- cbind(arm=rownames(tab), tab)
write_tab(tab, "K_T08_outcome_criterion"); print(tab, row.names=FALSE)

cov <- data.frame(
  column = c("outcome_criterion", "outcome_criterion", "seizure_ever", "seizure_ever"),
  arm    = c("IIH case","Matched control","IIH case","Matched control"),
  populated = c(sum(r$outcome_criterion != "" & r$group_label=="IIH case"),
                sum(r$outcome_criterion != "" & r$group_label=="Matched control"),
                sum(r$seizure_ever != "" & r$group_label=="IIH case"),
                sum(r$seizure_ever != "" & r$group_label=="Matched control")),
  total  = c(sum(r$group_label=="IIH case"), sum(r$group_label=="Matched control"),
             sum(r$group_label=="IIH case"), sum(r$group_label=="Matched control")))
write_tab(cov, "K_T09_criterion_coverage"); print(cov, row.names=FALSE)
log_msg("K4 complete")
