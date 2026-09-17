# Negative-control outcomes — extraction specification

Hand this to whoever runs the extracts. One file per outcome group, or one file
with a group label, either is fine.

## Extraction rules — these matter more than the codes

1. **Both arms.** All 2,618 IIH patients and all 9,122 comparators. A pull
   restricted to one arm is unusable, and a pull restricted to patients who have
   the code is unusable for the same reason the seizure extract was.
2. **All dates, unfiltered.** Every occurrence, before and after index. Baseline
   prevalence is the whole point — an outcome that is already commoner in the
   IIH arm before index is disqualified, and that can only be seen with the
   pre-index rows present.
3. **Same layout as before:** `Clinic Number, Diagnosis Code System, Diagnosis
   Code, Diagnosis Description, Diagnosis Date`.
4. **CSV, zipped.** Not .xlsb — that is what truncated the encounter files at
   1,048,575 rows.
5. Both coding systems. Index dates run 2002 to 2025, so ICD-9 is needed for the
   earlier years.

## Group 1 — Fractures, excluding skull and face  ★ best candidate

Broadens limb fracture, the only outcome that balanced at baseline. Skull and
facial fractures (S02, ICD-9 800–804) are **excluded deliberately**: head injury
causes seizures and traumatic brain injury is already a cohort exclusion.

| System | Codes |
|---|---|
| ICD-10 | S12, S22, S32, S42, S52, S62, S72, S82, S92 (all subcodes) |
| ICD-9 | 805–829 |

## Group 2 — Acute upper respiratory infection and influenza  ★ best candidate

Common, acutely symptomatic, no obesity or IIH link.

| System | Codes |
|---|---|
| ICD-10 | J00, J01, J02, J03, J04, J05, J06, J09, J10, J11, J20, J21 |
| ICD-9 | 460–466, 487, 488 |

## Group 3 — Sprains and strains

Very common and symptom-forced. Not in the earlier panel; worth adding.

| System | Codes |
|---|---|
| ICD-10 | S13, S23, S33, S43, S53, S63, S73, S83, S93 |
| ICD-9 | 840–848 |

## Group 4 — Otitis media and externa

| System | Codes |
|---|---|
| ICD-10 | H60, H65, H66, H67 |
| ICD-9 | 380.1, 381, 382 |

## Group 5 — Laceration and open wound of the limbs

Head and neck wounds (S01, ICD-9 870–873) are **excluded**, again to avoid head
trauma.

| System | Codes |
|---|---|
| ICD-10 | S41, S51, S61, S71, S81, S91 |
| ICD-9 | 880–884, 890–894 |

## Group 6 — Contact dermatitis

Clean, common, no plausible route to IIH.

| System | Codes |
|---|---|
| ICD-10 | L23, L24, L25 |
| ICD-9 | 692 |

## Group 7 — Inguinal hernia

Included for completeness, but this cohort is 88% female and inguinal hernia is
strongly male-predominant, so power will be poor. Pull it only if the others are
cheap to run alongside.

| System | Codes |
|---|---|
| ICD-10 | K40 |
| ICD-9 | 550 |

---

## Deliberately not requested

**Acute conjunctivitis** (H10, ICD-9 372.0), despite being common and acute.
Patients with IIH attend ophthalmology far more often than comparators, so
differential detection is guaranteed. It would fail for the same reason carpal
tunnel did.

Anything linked to obesity, to acetazolamide or topiramate, or to healthcare
contact intensity. That ruled out all five of the failed controls: renal stone
and gallstones (obesity and IIH drugs), carpal tunnel (obesity), herpes zoster
and appendicitis (both baseline-imbalanced in these data).

---

## What happens when the data arrive

For each group, in this order, and the order matters:

1. Compute baseline prevalence in each arm on the inherited index dates, and
   test balance. **Any group failing balance is discarded at this point, before
   its hazard ratio is computed or looked at.** This is what turns the panel
   from a post-hoc rationalisation into a pre-specified screen.
2. For the survivors, estimate the post-index hazard ratio on exactly the clock,
   washout and matched sets used for the primary outcome.
3. Report every group pulled, including the discarded ones and the reason, so
   the screen is visible rather than implied.

A group needs roughly **25 or more events per arm** for its interval to be worth
plotting. Limb fracture gave 2 and 7, which is why it could not be used.

If two or three groups survive step 1 with adequate events, the panel is
rebuilt and can carry a specificity argument. If none survive, that is itself
the finding, and the manuscript says no valid negative control was available.
