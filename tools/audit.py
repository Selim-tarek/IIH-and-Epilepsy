#!/usr/bin/env python3
"""Data audit for the IIH -> epilepsy matched cohort.

R is not installed in this container, so this script produced the numbers in
docs/DATA_AUDIT.md and outputs/diagnostics/data_dictionary.csv. The analytic
pipeline itself is written in R (R/). This file is an audit utility, not part
of the inferential workflow. It never writes to data-raw/.
"""
import sys, pathlib
import pandas as pd, numpy as np

RAW = pathlib.Path("data-raw")
OUT = pathlib.Path("outputs/diagnostics"); OUT.mkdir(parents=True, exist_ok=True)
MASTER = RAW / "IIH_MASTER_cases_and_controls.xlsx"
FINAL  = RAW / "IIH_Epilepsy_FINAL.xlsx"
CSV    = RAW / "IIH_FINAL_analysis_dataset.csv"

MISS_CODES = {88, 99}   # 88 = not applicable / no event; 99 = unknown after searching

def load_master(sheet="Master_Data"):
    """Header sits on the 5th spreadsheet row; rows 1-3 are free-text banners."""
    df = pd.read_excel(MASTER, sheet_name=sheet, header=4).dropna(how="all")
    return df

def data_dictionary(df, matched):
    rows = []
    ca = matched[matched.group == 1]; co = matched[matched.group == 0]
    for v in df.columns:
        s = df[v]
        uniq = s.dropna().unique()
        rows.append(dict(
            variable=v,
            dtype=str(s.dtype),
            n_nonmissing=int(s.notna().sum()),
            pct_missing_overall=round(100 * s.isna().mean(), 1),
            pct_missing_cases_matched=round(100 * ca[v].isna().mean(), 1),
            pct_missing_controls_matched=round(100 * co[v].isna().mean(), 1),
            n_distinct=int(len(uniq)),
            uses_88=bool(np.isin(88, uniq)) if s.dtype != object else ("88" in set(map(str, uniq))),
            uses_99=bool(np.isin(99, uniq)) if s.dtype != object else ("99" in set(map(str, uniq))),
            example_values="; ".join(map(str, uniq[:6])),
        ))
    return pd.DataFrame(rows)

def main():
    m = load_master()
    matched = m[m.in_matched_analysis == 1].copy()
    ca, co = matched[matched.group == 1], matched[matched.group == 0]

    dd = data_dictionary(m, matched)
    dd.to_csv(OUT / "data_dictionary.csv", index=False)

    rep = []
    P = rep.append
    P(f"rows={len(m)}  unique record_id={m.record_id.nunique()}  duplicated={m.record_id.duplicated().sum()}")
    P(f"cases={int((m.group==1).sum())}  controls={int((m.group==0).sum())}")
    P(f"in_matched_analysis=1: {len(matched)}  (cases {len(ca)}, controls {len(co)})")
    P(f"cases excluded from matched analysis: {int((m.in_matched_analysis==0).sum())}")

    # --- realized matching ratio -------------------------------------------
    setsize = co.groupby("match_set").size()
    P("controls per matched set: " + str(setsize.value_counts().sort_index().to_dict()))
    P(f"mean controls per set = {setsize.mean():.2f}; sets = {setsize.size}; "
      f"control ids reused = {len(co) - co.record_id.nunique()}")
    P("match_tier by sex (controls):")
    P(pd.crosstab(co.match_tier, co.sex).to_string())

    # --- dates --------------------------------------------------------------
    today = pd.Timestamp("2026-09-06")
    for c in ["index_date", "dob", "seizure_date", "last_encounter_date", "death_date"]:
        d = pd.to_datetime(matched[c], errors="coerce")
        P(f"{c}: nonmissing={d.notna().sum()} (cases {pd.to_datetime(ca[c],errors='coerce').notna().sum()}, "
          f"controls {pd.to_datetime(co[c],errors='coerce').notna().sum()}) range {str(d.min())[:10]}..{str(d.max())[:10]} "
          f"future={int((d>today).sum())}")

    # --- person-time reconstruction ----------------------------------------
    le = pd.to_datetime(co.last_encounter_date, errors="coerce")
    ix = pd.to_datetime(co.index_date, errors="coerce")
    sd = pd.to_datetime(co.seizure_date, errors="coerce")
    dd_ = pd.to_datetime(co.death_date, errors="coerce")
    end = pd.concat([le, sd, dd_], axis=1).min(axis=1)
    fu = (end - ix).dt.days / 365.25
    P(f"control follow-up reproduced from dates within 0.01 y: {int((abs(fu-co.followup_years)<0.01).sum())}/{len(co)}")
    P(f"controls censored at a FUTURE last_encounter_date: {int(((le>today) & (end==le)).sum())}")
    P("case follow-up CANNOT be reconstructed: last_encounter_date/death_date absent for all cases")
    P(f"implied max case end date = {(pd.to_datetime(ca.index_date)+pd.to_timedelta(ca.followup_years*365.25,unit='D')).max()}")

    # --- protocol eligibility checks ---------------------------------------
    P(f"age_index < 16: {int((matched.age_index<16).sum())} (protocol requires >=16)")
    P(f"follow-up < 1 year: {int((matched.followup_years<1).sum())} "
      f"(cases {int((ca.followup_years<1).sum())}, controls {int((co.followup_years<1).sum())})")
    P(f"opening pressure recorded in {int(ca.op_cmh2o.notna().sum())}/{len(ca)} cases; "
      f"<25 cmH2O in {int((ca.op_cmh2o<25).sum())} (violates Friedman)")
    P(f"presenting_seizure=1 among matched cases: {int((ca.presenting_seizure==1).sum())} "
      f"— all coded seizure_incident=0 and retained in the risk set")

    # --- outcomes -----------------------------------------------------------
    P("seizure_incident: " + str(matched.groupby("group").seizure_incident.sum().to_dict()))
    P("status (0=censored,1=seizure,2=death): " + str(pd.crosstab(matched.status, matched.group).to_dict()))
    P(f"deaths during follow-up: cases {int((ca.died_fu==1).sum())}, controls {int((co.died_fu==1).sum())}")
    P(f"carpal_incident missing: cases {int(ca.carpal_incident.isna().sum())}, "
      f"controls {int(co.carpal_incident.isna().sum())} (male controls not extracted)")

    # --- mediator availability ---------------------------------------------
    ei = ca.enceph_index
    P(f"enceph_index among matched cases: assessed(0/1)={int(ei.isin([0,1]).sum())} "
      f"positive={int((ei==1).sum())} coded 88={int((ei==88).sum())}")
    for v in ["empty_sella", "sinus_sten", "globe_flat", "onsd_distend", "skullbase_thin", "eeg_done", "eeg_epileptiform"]:
        s = ca[v]
        P(f"{v}: informative={int((~s.isin(MISS_CODES) & s.notna()).sum())}/{len(ca)} unknown(99)={int((s==99).sum())}")

    # --- cross-file consistency --------------------------------------------
    csv = pd.read_csv(CSV)
    fin = pd.read_excel(FINAL, sheet_name="Analysis_Dataset", header=4)
    P(f"CSV rows={len(csv)}; FINAL Analysis_Dataset rows={len(fin)}; matched master rows={len(matched)}")
    P(f"identical record_id sets: csv=={{master}} -> "
      f"{set(csv.record_id.astype(str))==set(matched.record_id.astype(str))}; "
      f"final=={{master}} -> {set(fin.record_id.astype(str))==set(matched.record_id.astype(str))}")
    P(f"CSV events by group: {csv.groupby('group').seizure_incident.sum().to_dict()}")

    txt = "\n".join(map(str, rep))
    (OUT / "audit_console.txt").write_text(txt + "\n")
    print(txt)

if __name__ == "__main__":
    main()
