# v0.1 Assumptions Register

This register records every material judgment call where the educational implementation makes a choice that would normally be governed by an authoritative specification, organizational policy, contractual requirement, or production data definition.

**A documented assumption is preferable to an invisible guess.**

## Register

| ID | Business rule / issue | v0.1 implementation | Basis | Limitation / risk | Test case | Status |
|---|---|---|---|---|---|---|
| A-001 | Population | Fictional North Carolina Medicaid managed care organization | Project scope | Not representative of any real plan or population | `T-DATA-001` | Locked |
| A-002 | Data privacy | Synthetic data only | Project scope | Does not demonstrate operation with real PHI | `T-SEC-001` | Locked |
| A-003 | FUH naming | Describe result as FUH-style / educational approximation | NCQA licensing boundary | Not a certified HEDIS result | `T-DOC-001` | Locked |
| A-004 | FUH age | Age 6+ at qualifying discharge | Public FUH description | Full licensed eligibility criteria are not implemented | `T-FUH-013`, `T-FUH-014` | Locked |
| A-005 | FUH windows | Report follow-up within 7 days and within 30 days after discharge | Public FUH description | Full licensed numerator detail is not reproduced | `T-FUH-002`–`T-FUH-006` | Locked |
| A-006 | Mental-health diagnoses | Use project-defined, distributable code grouping | Public/legal source to be documented | Not the proprietary NCQA value set | `T-FUH-015` | Open |
| A-007 | Intentional self-harm | Include using a distributable project-defined code grouping | Public FUH description + public code source to be documented | Approximation; not NCQA's licensed value set | `T-FUH-016` | Proposed |
| A-008 | Qualifying follow-up services | Define a transparent project service set from distributable public sources | Public sources + project judgment | May differ from licensed specification | `T-FUH-017` | Open |
| A-009 | Continuous enrollment and benefits | Require uninterrupted enrollment from the discharge date through 30 days after discharge, with both `medical_benefit_flag = 1` and `behavioral_health_benefit_flag = 1`; no allowable gap | [Johns Hopkins Health Plans, *2026 Quality Measures HEDIS® Toolkit — FUH: Follow-Up After Hospitalization for Mental Illness*](https://www.hopkinsmedicine.org/-/media/johns-hopkins-health-plans/documents/all_plans/2026-hedis-quality-measures-tip-sheet.pdf) | Synthetic coverage data simplify real benefit administration | `T-FUH-007`, `T-FUH-018` | Locked |
| A-010 | Readmissions / transfers | During the 30-day follow-up period: (1) acute mental-health or intentional-self-harm readmission/direct transfer → count only the last qualifying discharge; (2) acute readmission/direct transfer for another principal diagnosis → exclude the affected discharge episode(s); (3) nonacute readmission/direct transfer → exclude the affected discharge, **except psychiatric residential treatment** | [Johns Hopkins Health Plans, *2026 Quality Measures HEDIS® Toolkit — FUH: Follow-Up After Hospitalization for Mental Illness*, printed p. 195, Denominator Exclusions](https://www.hopkinsmedicine.org/-/media/johns-hopkins-health-plans/documents/all_plans/2026-hedis-quality-measures-tip-sheet.pdf); [Anthem, *HEDIS Coding Booklet 2025*, p. 41, FUH Exclusions](https://providers.anthem.com/docs/gpp/WI_CAID_HedisCoding25.pdf?v=202411151629); [NCQA, *Follow-Up After Hospitalization for Mental Illness (FUH) — HEDIS MY 2025 Draft for Public Comment*, Summary of Changes](https://www.ncqa.org/wp-content/uploads/09.-FUH.pdf) | The current Hopkins 2026 toolkit and Anthem 2025 booklet both explicitly state the psychiatric-residential-treatment exception. The NCQA MY2025 public-comment summary says residential treatment was added to the numerator and removed from denominator-removal criteria, although the detailed nonacute paragraph in that obsolete draft does not display the exception. Exact production implementation remains governed by licensed specifications. | `T-FUH-008`–`T-FUH-011` | Locked |
| A-011 | As-of date | Store a fixed analysis date in configuration rather than relying on current system date | Reproducibility | Synthetic historical timing differs from production operations | `T-PIPE-001` | Proposed |
| A-012 | Provider attribution | Use available synthetic rendering/facility relationship | Source availability | May not model real payer attribution rules | `T-DATA-002` | Proposed |
| A-013 | Excel reconciliation | Reconcile episode-level output, not every raw claim row | Practical validation design | Does not independently rebuild the entire warehouse | `T-VAL-001` | Locked |
| A-014 | Power BI logic | Power BI consumes SQL-defined episode results; measure eligibility logic remains in SQL | Auditability | Display-only DAX remains in Power BI | `T-BI-001` | Locked |
| A-015 | Same-day follow-up | A qualifying follow-up service on the discharge date does **not** satisfy either FUH follow-up rate. Day 1 is the day after discharge. | [Johns Hopkins Health Plans, *2026 Quality Measures HEDIS® Toolkit — FUH: Follow-Up After Hospitalization for Mental Illness*](https://www.hopkinsmedicine.org/-/media/johns-hopkins-health-plans/documents/all_plans/2026-hedis-quality-measures-tip-sheet.pdf) | Educational approximation; source logic must still be translated correctly into project service definitions | `T-FUH-001` | Locked |
| A-016 | Sparse FUH episodes in generated data | The 5,000-member Synthea population was profiled and produced no inpatient mental-health encounters suitable for the FUH denominator. The Quality Performance milestone therefore adds a separate deterministic 2025 FUH fixture package containing 40 eligible psychiatric discharge episodes. Fixtures are generated separately from immutable Synthea source data and carry `synthetic_fixture_flag = 1`. The fixture manifest defines expected results of 18/40 (45.0%) for 7-day follow-up and 32/40 (80.0%) for 30-day follow-up. | Observed Synthea profiling + portfolio/test-data design | Augmented fixtures are intentionally not prevalence-representative and exist to exercise and validate measure logic; they must not be presented as population epidemiology | `T-DATA-003`, `T-FUH-019` | Locked |
| A-017 | Measurement-year discharge cutoff | Candidate FUH discharges must occur from January 1 through December 1 of the measurement year. Discharges after December 1 are not denominator candidates. If a qualifying acute readmission/direct transfer causes the last discharge to occur after December 1, exclude the affected discharge sequence from the measurement-year denominator. | [Johns Hopkins Health Plans, *2026 Quality Measures HEDIS® Toolkit — FUH: Follow-Up After Hospitalization for Mental Illness*](https://www.hopkinsmedicine.org/-/media/johns-hopkins-health-plans/documents/all_plans/2026-hedis-quality-measures-tip-sheet.pdf); [NCQA, *Follow-Up After Hospitalization for Mental Illness (FUH) — HEDIS MY 2025 Draft for Public Comment*](https://wpcdn.ncqa.org/www-prod/wp-content/uploads/09.-FUH.pdf) | Project follows the public boundary rule but does not claim full licensed HEDIS implementation | `T-FUH-021`, `T-FUH-022` | Locked |
| A-018 | Benefit coverage derivation | For the Quality Performance milestone, Medicaid enrollment is treated as providing both medical and behavioral-health benefits: `medical_benefit_flag = 1` and `behavioral_health_benefit_flag = 1`; other primary payer spans are assigned `0/0`. These flags are an educational derivation because Synthea does not independently model the benefit carve-outs needed by the FUH rule. Controlled edge-case fixtures may explicitly override this derivation when benefit-eligibility testing is added. | Source-data limitation + project modeling decision | Real payer benefit administration may include carve-outs, partial benefits, or separately administered behavioral-health coverage that this approximation does not represent | `T-CORE-006` | Locked |

## Source verification for locked FUH rules

The four most consequential locked boundary rules are tied to named public sources in the Basis column.

- **A-009:** The Johns Hopkins 2026 toolkit states continuous enrollment is from the discharge date through 30 days after discharge, with no allowable gap, and requires medical and mental-health benefits.
- **A-010:** Verified directly in the Johns Hopkins 2026 toolkit, printed page 195 under **Denominator Exclusions**: the nonacute readmission/direct-transfer exclusion contains an explicit psychiatric-residential-treatment exception. Anthem's 2025 HEDIS coding booklet independently states the same exception. The NCQA MY2025 public-comment summary says residential treatment was added to the numerator and removed from denominator-removal criteria; its later detailed nonacute paragraph does not show the exception, so the project does not cite that paragraph as proof of the exception.
- **A-015:** The Johns Hopkins 2026 toolkit explicitly states that follow-up visits on the discharge date do not count.
- **A-017:** The Johns Hopkins 2026 toolkit limits denominator discharges to January 1 through December 1. The NCQA MY2025 public-comment draft explicitly states that if the last discharge in an acute readmission/direct-transfer sequence occurs after December 1, the affected discharges are excluded.

The NCQA document is a public-comment draft and is labeled obsolete after March 13, 2024. It is used here only as a public source for the detailed rule language that is not reproduced in the general NCQA public measure page. The project does not represent this draft as the licensed final specification.

## How to use this file

When a rule changes:

1. update the assumption here;
2. update the linked test case in `sql/05_tests/TEST_CASES.md`;
3. update the SQL;
4. run the affected SQL tests;
5. refresh the Excel reconciliation;
6. refresh Power BI if the change affects reporting;
7. record the change in Git history.

## Interview use

This file is intentionally part of the portfolio. It should make it possible to answer questions such as:

- Why did you define the denominator this way?
- Which parts of the logic are approximations?
- What would have to change if licensed specifications were available?
- How did you make the measure auditable?
- How did you handle readmissions, enrollment continuity and boundary dates?
- How did you prevent the dashboard from becoming the only place business logic exists?

A documented assumption is preferable to an invisible guess.
