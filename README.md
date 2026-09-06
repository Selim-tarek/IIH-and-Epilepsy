# IIH and Epilepsy

Retrospective matched cohort study of incident seizures/epilepsy after
idiopathic intracranial hypertension (Mayo Clinic EHR, 2002–2025).

## Status

Stage 1 (data inventory and audit) is complete. **No inferential model has
been fitted**, pending answers to `docs/CRITICAL_QUESTIONS.md`.

- `docs/DATA_AUDIT.md` — file inventory, cohort structure, realized matching,
  person-time reconstruction, protocol conformance, missing-data codes.
- `docs/ANALYTIC_DATA_MODEL.md` — proposed tables and the estimands the
  delivered data can and cannot support.
- `docs/CRITICAL_QUESTIONS.md` — 11 blocking questions.

## Data

Patient-level files are **not** committed (`data-raw/` is gitignored). Place
locally:

```
data-raw/IIH_MASTER_cases_and_controls.xlsx
data-raw/IIH_FINAL_analysis_dataset.csv
data-raw/IIH_Epilepsy_FINAL.xlsx
```

## Running

```
python3 tools/audit.py     # regenerates the audit (needs pandas, openpyxl)
Rscript R/01_import_and_dictionary.R
```

`R/` holds the analysis pipeline. R is not installed in the authoring
container, so those scripts are **untested**; the numbers in the audit come
from `tools/audit.py`.
