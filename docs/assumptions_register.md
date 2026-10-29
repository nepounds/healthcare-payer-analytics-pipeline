# v0.1 Assumptions Register

This register records material judgment calls where the portfolio implementation makes a choice that would normally be governed by an authoritative specification, organizational policy, contractual requirement, or production data definition.

**A documented assumption is preferable to an invisible guess.**

## Register

| ID | Business rule / issue | v0.1 implementation | Basis | Limitation / risk | Executable evidence | Status |
|---|---|---|---|---|---|---|
| A-001 | Population | Fictional North Carolina Medicaid managed-care analytics population | Project scope | Not representative of any real plan or population | Phase 1/2 source profiling | Locked |
| A-002 | Data privacy | Synthetic data only | Project scope | Does not demonstrate operation with real PHI | repository/source design | Locked |
| A-003 | FUH naming | Describe result as FUH-style / HEDIS-oriented portfolio demonstration | NCQA licensing boundary | Not a certified HEDIS result | `T-FUH-027`, `T-FUH-096` | Locked |
| A-004 | FUH age | Age 6+ at candidate discharge | Public FUH description + project rule | Full licensed eligibility criteria are not implemented | `T-FUH-036` | Locked |
| A-005 | FUH windows | Day 1–7 qualifies for both numerators; day 8–30 qualifies only for 30-day; day 31+ is outside the window | Public FUH description + project rule | Full licensed numerator detail is not reproduced | `T-FUH-051`, `T-FUH-059`, `T-FUH-064`, `T-FUH-065`, `T-FUH-074` | Locked |
| A-006 | Behavioral-health diagnosis qualification | Use project-owned ICD-10-CM `F*` prefix as a broad behavioral-health proxy in `ref.measure_value_set` | Portfolio-safe project rule using typed `core.condition` coding-system evidence | Broad proxy; not a proprietary NCQA value set and not equivalent to official FUH diagnosis logic | `T-FUH-029`, `T-FUH-034`, `T-FUH-053`, `T-FUH-097` | Locked |
| A-007 | Intentional self-harm | No separate intentional-self-harm value set is implemented in v0.1 | Current source/fixture scope | Official/public FUH descriptions may include self-harm pathways; this portfolio version does not claim to reproduce them | documented limitation in methodology/test catalog | Deferred |
| A-008 | Qualifying follow-up services | Accept source encounter types `ambulatory` and `outpatient` when accompanied by qualifying typed behavioral-health diagnosis evidence | Project-owned transparent service rule | May differ from licensed specification and does not use proprietary value sets | `T-FUH-048`, `T-FUH-052`, `T-FUH-053`, `T-FUH-097` | Locked |
| A-009 | Continuous enrollment and benefits | Require one `core.enrollment_span` for the index payer covering discharge through day 30, with `medical_benefit_flag = 1` and `behavioral_health_benefit_flag = 1`; no allowable gap within the required span | Public FUH guidance + project modeling | Synthetic coverage simplifies real benefit administration | `T-FUH-038`, `T-FUH-039`, `T-FUH-061`, `T-FUH-100` | Locked |
| A-010 | Readmissions / transfers | **Not implemented in v0.1.** The project does not infer principal diagnosis from claim position 1 or encounter reason fields, so it does not apply a principal-diagnosis-dependent readmission/transfer exclusion | Phase 2 source-semantics findings | This is a material limitation versus a production/official FUH implementation | documented in methodology/test catalog | Deferred |
| A-011 | As-of date | Store fixed analysis date `2026-10-18` in `ref.measure_definition` rather than relying on system date | Reproducibility | Historical portfolio timing differs from production operations | `T-FUH-026`, `T-FUH-096` | Locked |
| A-012 | Provider attribution | Preserve available provider/organization lineage but do not create a separate quality-attribution rule in Phase 3 | Source availability | Not a production attribution model | relationship QA in Phase 2; lineage in measure outputs | Deferred |
| A-013 | Excel reconciliation | Reconcile authoritative event-level SQL output rather than every raw transaction | Practical validation design | Does not independently rebuild the entire warehouse | future Excel phase | Locked |
| A-014 | Power BI logic | Power BI will consume SQL-defined measure results; eligibility remains in SQL | Auditability | Display-oriented DAX may still be used | future Power BI phase | Locked |
| A-015 | Same-day follow-up | A qualifying follow-up on the discharge date remains visible for audit but does not satisfy either numerator; day 1 is the day after discharge | Public FUH guidance + project rule | Portfolio approximation still depends on project-owned service definitions | `T-FUH-058`, `T-FUH-101` | Locked |
| A-016 | Sparse FUH episodes in generated data | Use a separate deterministic 2025 fixture package with 40 eligible psychiatric discharges and expected 18/40 7-day, 32/40 30-day results | Observed Synthea profiling + test-data design | Fixtures validate logic and are not prevalence-representative | `T-FUH-040`–`T-FUH-044`, `T-FUH-067`–`T-FUH-074`, `T-FUH-103` | Locked |
| A-017 | Measurement-year discharge cutoff | Candidate discharges must occur January 1 through December 1 of measurement year 2025 | Public FUH guidance + project rule | No v0.1 readmission sequence logic moves a last discharge across the cutoff | `T-FUH-037` | Locked |
| A-018 | Benefit coverage derivation | Medicaid enrollment is treated as having medical and behavioral-health benefit flags = 1/1; other primary payer spans are 0/0 | Source-data limitation + project modeling decision | Real payer benefit carve-outs may differ | `T-CORE-006`, `T-FUH-038` | Locked |
| A-019 | Claim-transaction service end dates | Normalize `TODATE` to `NULL` when it is `1970-01-01` or precedes `FROMDATE`; unparseable dates fail load | Observed pinned-source behavior | Null means source end date was not analytically trustworthy | `T-CORE-021` | Locked |
| A-020 | Claim-transaction place value | Preserve raw `PLACEOFSERVICE`; populate organization FK only when the value resolves to a known organization | Observed mixed source semantics | One combined field cannot honestly be modeled as only POS code or only organization ID | `T-CORE-021`, `T-CORE-022` | Locked |
| A-021 | Claim-transaction patient-insurance value | Preserve `PATIENTINSURANCEID` as opaque `source_patient_insurance_id`; do not enforce a payer/enrollment FK | Synthea v4.0.0 source behavior + controlled fixture design | Synthea writes a plan-record/member-like source identifier, but the authoritative combined source does not support a universal FK and fixtures use the field differently | `T-CORE-020` | Locked |
| A-022 | Claim diagnosis semantics | Preserve positions 1–8 without assigning a coding system or treating position 1 as principal diagnosis | Raw claim structure + transaction diagnosis-reference behavior | Claim diagnosis rows cannot support typed principal-diagnosis logic without additional source semantics | `T-CORE-018`, `T-CORE-021` | Locked |
| A-023 | Claim-line representation | Model `claims_transactions.csv` as `core.claim_transaction` at one row per source transaction; keep `CHARGEID` opaque | Source grain + exporter behavior | No separate stable claim-line entity exists in current source | `T-CORE-019`, `T-CORE-020` | Locked |
| A-024 | Deterministic numerator selection | When multiple follow-up services qualify, select the earliest event by date/time and encounter ID for each window | Auditability / duplicate-credit prevention | Ties are resolved deterministically rather than producing multiple numerator credits | `T-FUH-064`, `T-FUH-065`, `T-FUH-109` | Locked |
| A-025 | Reporting interpretation | Current controlled fixtures may be summarized by payer/month/demographic/timing dimensions, but fixture subgroup differences are not interpreted as real-world disparities | Fixture design | One payer, one county, narrow adult ages, and controlled timing limit substantive subgroup interpretation | `T-FUH-087`–`T-FUH-094`, `T-FUH-105`–`T-FUH-107` | Locked |

## FUH-style implementation notes

The implemented v0.1 logic is intentionally narrower than an official specification. In particular:

- `core.condition` is used for diagnosis qualification because it retains a trustworthy coding-system field;
- `core.claim_diagnosis` position 1 is not treated as principal diagnosis;
- encounter reason fields are not treated as principal diagnosis;
- no readmission/transfer exclusion is manufactured from unsupported semantics;
- `core.claim_transaction` is not required by Phase 3 measure logic;
- the fixed fixture benchmark is a test oracle, not an epidemiological finding.

## Change discipline

When a rule changes:

1. update this register;
2. update `sql/05_tests/TEST_CASES.md`;
3. update the SQL/reference configuration;
4. run the affected executable tests;
5. refresh downstream Excel/Power BI work if applicable;
6. record the change in Git history.
