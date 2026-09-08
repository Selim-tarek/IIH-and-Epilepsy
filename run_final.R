## run_final.R ----------------------------------------------------------------
## FINAL pipeline on IIH_MASTER_FINAL.xlsx:  Rscript run_final.R
for (s in c("R/F1_import_audit_final.R", "R/F2_analysis_final.R",
            "R/F3_medications_final.R", "R/F5_cox_regression_final.R",
            "R/F6_additional_analyses_final.R",
            "R/F7_additional_figures_final.R",
            "R/F8_dual_channel_final.R",
            "R/F9_carpal_rebuild_final.R",
            "R/F10_smoking_final.R",
            "R/F4_figures_report_final.R")) {
  cat("\n========== ", s, " ==========\n", sep = ""); source(s, echo = FALSE)
}
cat("\nDone. See report/final_analysis_report.md and outputs/.\n")
writeLines(utils::capture.output(utils::sessionInfo()),
           file.path("outputs", "logs", "sessionInfo_final.txt"))

## Rebuilt (G-series) pipeline: ingests every supplied source.
for (s2 in c("R/G1_build_master.R","R/G2_analysis.R","R/G3_figures_report.R")) {
  cat("\n========== ", s2, " ==========\n", sep=""); source(s2, echo=FALSE)
}
