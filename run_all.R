## run_all.R ------------------------------------------------------------------
## Reruns the entire analysis from a clean session:  Rscript run_all.R
unlink(file.path("outputs", "logs", "pipeline.log"))
scripts <- c(
  "R/01_import_and_dictionary.R",
  "R/02_data_audit.R",
  "R/03_eligibility_and_cohort_flow.R",
  "R/04_matching_and_balance.R",
  "R/05_outcome_algorithm.R",
  "R/06_primary_survival_analysis.R",
  "R/07_secondary_analyses.R",
  "R/08_sensitivity_analyses.R",
  "R/09_subgroups_and_alternative_models.R",
  "R/13_radiology_text_extraction.R",
  "R/14_missing_data.R",
  "R/10_figures.R",
  "R/11_tables.R",
  "R/12_report_generation.R")
for (s in scripts) {
  cat("\n========== ", s, " ==========\n", sep = "")
  source(s, echo = FALSE)
}
cat("\nPipeline complete. See report/analysis_report.md and outputs/.\n")
writeLines(utils::capture.output(utils::sessionInfo()),
           file.path("outputs", "logs", "sessionInfo.txt"))
