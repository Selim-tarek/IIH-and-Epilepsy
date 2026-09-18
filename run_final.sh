#!/usr/bin/env bash
# Final from-scratch run. Halts on the first failure; every step logs to outputs/logs.
set -euo pipefail
cd "$(dirname "$0")"
LOG=outputs/logs/final_run_$(date +%Y%m%d_%H%M%S).log
export RUN_START="$(date "+%Y-%m-%d %H:%M:%S")"
mkdir -p outputs/logs

step () {  # step <label> <command...>
  echo "──────── $1" | tee -a "$LOG"
  if ! "${@:2}" >>"$LOG" 2>&1; then
    echo "FAILED at: $1  (see $LOG)" | tee -a "$LOG"; exit 1
  fi
}

step "Z0 provenance gate"            Rscript R/Z0_provenance.R
step "F1 import from master workbook" Rscript R/F1_import_audit_final.R
step "G1 build master dataset"        Rscript R/G1_build_master.R
step "K15 primary, ENC_MODE=visits"   env ENC_MODE=visits Rscript R/K15_final_analysis.R
step "K15 primary, ENC_MODE=all"      env ENC_MODE=all    Rscript R/K15_final_analysis.R
step "K17 negative controls, panel 1" Rscript R/K17_negative_controls.R
step "K19 negative controls, panel 2" Rscript R/K19_negative_controls_v2.R
step "K20 healthcare contact"         Rscript R/K20_healthcare_contact.R
step "K22 contact robustness"         Rscript R/K22_contact_robustness.R
step "K23 post-index collider"        Rscript R/K23_post_index_collider.R
step "K24 SAP completion"             Rscript R/K24_sap_completion.R
step "K25 controls over time"         Rscript R/K25_nc_over_time.R
step "K26 post-index surveillance"    Rscript R/K26_post_index_surveillance.R
step "K27 E-values"                   Rscript R/K27_evalue.R
step "K16 primary figures"            Rscript R/K16_final_figures.R
step "K18 additional figures"         Rscript R/K18_more_figures.R
step "K21 contact figure"             Rscript R/K21_contact_figure.R
step "Z2 consolidated final output"   Rscript R/Z2_final_output.R

echo "ALL STEPS COMPLETE — $LOG" | tee -a "$LOG"
