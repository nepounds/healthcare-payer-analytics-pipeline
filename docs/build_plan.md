# Quality Performance Milestone Build Plan

## Milestone objective

Build a business-facing Healthcare Payer Analytics Pipeline that demonstrates reproducible payer quality measurement, auditable business rules, analytical reporting, and validation in Microsoft SQL Server.

## Phase 0 — Environment/setup

**Status: complete.**

Local SQL Server Developer Edition, SSMS, Python environment, repository structure, and database schemas are established.

## Phase 1 — Source generation and raw ingestion

**Status: complete.**

Deliverables include reproducible Synthea generation, controlled FUH fixtures, source-shaped `raw` tables, load metadata, and source profiling.

## Phase 2 — Typed core relational model

**Status: complete.**

Implemented entities:

- `core.member`;
- `core.payer`;
- `core.enrollment_span`;
- `core.organization`;
- `core.provider`;
- `core.encounter`;
- `core.condition`;
- `core.claim`;
- `core.claim_diagnosis`;
- `core.claim_transaction`.

The source is transaction/event-grained, so Phase 2 deliberately does not fabricate a claim-line entity. Claim diagnosis positions are preserved without inferring principal-diagnosis semantics or an unsupported coding system.

Executable QA: `T-CORE-001` through `T-CORE-022`.

## Phase 3 — Performance measures and quality analytics

**Status: implemented; closeout is complete when `007_validate_phase3_closeout.sql` passes.**

### Measure configuration

Implemented:

- `ref.measure_definition`;
- `ref.measure_value_set`;
- fixed measurement-year/analysis-date configuration;
- project-owned diagnosis and encounter-type reference rules;
- explicit flags preventing the portfolio measure from being represented as official HEDIS.

### FUH-style measure pipeline

Implemented:

1. `measure.fuh_index_event_detail`
   - candidate inpatient behavioral-health discharges;
   - typed diagnosis evidence from `core.condition`;
   - age and January 1–December 1 measurement-window logic;
   - payer-specific continuous enrollment through day 30;
   - medical and behavioral-health benefit requirements;
   - explicit ineligibility reason;
   - source/fixture lineage.

2. `measure.fuh_followup_event_detail`
   - qualifying ambulatory/outpatient follow-up events;
   - typed behavioral-health diagnosis evidence;
   - day-from-index calculation;
   - same-day visibility with no numerator credit;
   - 7-day and 30-day qualification flags;
   - source/fixture lineage.

3. `measure.fuh_measure_result`
   - one row per final denominator event;
   - deterministic earliest 7-day and 30-day qualifying follow-up;
   - denominator and numerator flags;
   - payer/demographic/source lineage.

4. `measure.fuh_measure_summary`
   - ALL, FIXTURE, and NON_FIXTURE population scopes;
   - denominator, 7-day numerator, 30-day numerator;
   - safe decimal rates with `NULL` for a zero denominator.

### Analytical reporting

Implemented:

- `measure.fuh_report_payer_monthly` — payer/month volume, rates, average follow-up timing;
- `measure.fuh_report_demographic` — age-band/sex summaries;
- `measure.fuh_report_followup_timing` — timing distribution and percentages;
- `measure.fuh_open_gap_detail` — episode-level missed-7-day/missed-30-day gap output.

These outputs demonstrate analytical reporting and quality-improvement support without claiming that the project implemented an intervention or improved outcomes.

### Phase 3 validation

Executable suites:

```text
004_validate_fuh_index.sql        # T-FUH-023 through T-FUH-044
005_validate_fuh_measure.sql      # T-FUH-045 through T-FUH-075
006_validate_fuh_reporting.sql    # T-FUH-076 through T-FUH-094
007_validate_phase3_closeout.sql  # T-FUH-095 through T-FUH-110
```

Controlled acceptance benchmark:

```text
denominator = 40
7-day numerator = 18
30-day numerator = 32
7-day rate = 45.00%
30-day rate = 80.00%
```

### Explicit Phase 3 limitations

The current implementation does not claim:

- official NCQA HEDIS compliance or licensed value sets;
- principal-diagnosis semantics from `core.claim_diagnosis` or encounter reason fields;
- a readmission/transfer exclusion that requires trustworthy principal-diagnosis semantics;
- a separate intentional-self-harm value set;
- pharmacy or physical-health integration;
- disability/cultural-factor analysis;
- regulatory submission capability.

These are documented limitations, not silently invented features.

## Phase 4 — Excel reconciliation

Planned deliverables:

- Power Query connection/import;
- authoritative SQL episode/result extract;
- source-level validation extract;
- reconciliation/exception logic;
- pivot summaries and slicers;
- deliberate discrepancy test.

Exit condition: clean data reconcile to authoritative SQL outputs and a deliberate discrepancy is surfaced clearly.

## Phase 5 — Power BI Quality report

Planned deliverables:

- clean relationships/date model as needed;
- denominator/numerator cards;
- trend view;
- timing/gap view;
- useful subgroup filters;
- presentation-oriented DAX only.

Power BI must consume the SQL-defined measure; it must not recreate eligibility logic.

## Phase 6 — Quality Performance milestone release

Deliverables:

- polished public README;
- screenshots;
- run instructions;
- final limitations;
- Excel/Power BI evidence;
- clean Git history.

## Later expansion

Additional payer domains may be added after the current milestone when source data and business rules support them. The project should not add pharmacy, physical-health, disability, cultural-factor, or other domains merely to satisfy keywords.
