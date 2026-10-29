# Healthcare Payer Analytics Pipeline Build Plan

## Project objective

Build a portfolio-ready healthcare payer analytics project that demonstrates SQL Server, relational healthcare data, quality-measure logic, validation, Excel analysis, and reporting while remaining useful as a reusable practice sandbox.

## Phase 0 — Environment/setup

**Status: complete.**

Local SQL Server Developer Edition, SSMS, Python environment, repository structure, and database schemas are established.

## Phase 1 — Source generation and raw ingestion

**Status: complete.**

Deliverables include reproducible Synthea generation, controlled FUH fixtures, source-shaped `raw` tables, load metadata, and source profiling.

## Phase 2 — Typed core relational model

**Status: complete and validated.**

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

**Status: complete and validated.**

The final closeout suite `007_validate_phase3_closeout.sql` passed `T-FUH-095` through `T-FUH-110`.

### Implemented measure configuration

- `ref.measure_definition`;
- `ref.measure_value_set`;
- fixed measurement-year/analysis-date configuration;
- project-owned diagnosis and encounter-type reference rules;
- explicit flags preventing the portfolio measure from being represented as official HEDIS.

### Implemented FUH-style measure pipeline

1. `measure.fuh_index_event_detail`
   - candidate inpatient behavioral-health discharges;
   - typed diagnosis evidence from `core.condition`;
   - age and measurement-window logic;
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
   - ALL, FIXTURE, and NON_FIXTURE scopes;
   - denominator, 7-day numerator, 30-day numerator;
   - safe decimal rates with `NULL` for a zero denominator.

### Implemented analytical reporting

- `measure.fuh_report_payer_monthly`;
- `measure.fuh_report_demographic`;
- `measure.fuh_report_followup_timing`;
- `measure.fuh_open_gap_detail`.

### Controlled acceptance benchmark

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
- pharmacy or physical-health integration;
- disability/cultural-factor analysis;
- regulatory submission capability.

## Phase 4 — Excel analytics, reconciliation, and SQL practice sandbox

**Status: next.**

### Objective

Turn the existing SQL Server database into a reusable SQL + Excel practice environment while creating concrete portfolio evidence for Excel analysis skills.

Phase 4 is intentionally not just a polished one-time workbook. The SQL database should remain useful for writing new joins and analysis queries, exporting results, testing formulas, building PivotTables, and reconciling Excel outputs back to SQL.

### SQL deliverables

Create a small Excel-facing analysis/export layer using the existing core and measure tables. Prefer a few useful queries/views over a large reporting mart.

Expected outputs include:

- member/encounter analysis detail built from relational joins;
- payer/month summary data;
- FUH-style event-level detail for Excel validation;
- small lookup/reference extracts used by Excel formulas.

The SQL work should provide additional practice with:

- inner and outer joins;
- one-to-many relationships;
- aggregation;
- date logic;
- missing-value handling;
- reconciliation queries;
- filtering and grouping across a large healthcare dataset.

### Excel workbook deliverables

Create one committed workbook under `excel/` with clearly labeled tabs for:

- workbook instructions/source notes;
- imported analysis data;
- FUH-style measure data;
- lookup/reference data;
- formula practice;
- PivotTable analysis;
- charts;
- SQL-to-Excel reconciliation.

The workbook should demonstrate legitimate use of:

- `VLOOKUP`;
- `XLOOKUP`;
- `SUMIFS`;
- `COUNTIFS`;
- `IF` / `IFERROR` where useful;
- Excel Tables and structured references;
- PivotTables;
- PivotCharts or standard charts;
- filtering/sorting;
- basic conditional formatting;
- reconciliation controls.

### Required PivotTables

At least three useful PivotTables, such as:

1. encounter volume by payer and month;
2. encounter volume by encounter/service type;
3. FUH-style follow-up timing or demographic summary.

Do not invent fake payer variation in the controlled FUH fixtures merely to create a more interesting pivot.

### Required charts

At least three charts driven by the analysis, such as:

- monthly encounter-volume trend;
- payer or encounter-setting volume comparison;
- FUH-style follow-up timing distribution.

### Reconciliation requirement

Create an Excel reconciliation sheet that compares authoritative SQL totals with Excel-derived totals and displays the difference.

At minimum reconcile:

- members;
- encounters;
- FUH denominator;
- 7-day numerator;
- 30-day numerator.

Expected clean differences are zero.

### Sandbox requirement

Phase 4 must preserve the project as a reusable practice environment. The documentation should explain how to:

1. write or modify a SQL analysis query;
2. export or refresh the result;
3. practice formulas/lookups against the exported data;
4. build or modify PivotTables/charts;
5. reconcile key totals back to SQL.

The goal is to make continued SQL and Excel practice easy after the formal Phase 4 deliverables are complete.

### Phase 4 definition of done

Phase 4 is complete only when:

1. Excel-facing SQL analysis/export queries exist and use meaningful relational joins.
2. One documented Excel workbook is committed under `excel/`.
3. `VLOOKUP` is used correctly in the workbook.
4. `XLOOKUP` is used correctly in the workbook.
5. `SUMIFS` and/or `COUNTIFS` are used correctly.
6. At least three useful PivotTables exist.
7. At least three useful charts exist.
8. SQL-to-Excel reconciliation exists and clean totals reconcile to zero difference.
9. Formula and reporting tabs use actual project data rather than made-up examples.
10. The workbook is usable as an ongoing Excel practice sandbox.
11. SQL export/reconciliation queries are documented and reproducible.
12. README and skills documentation are updated from "planned" to "implemented" only after the workbook is validated.

See `docs/phase4_excel_plan.md` for the working implementation plan.

## Phase 5 — Power BI reporting

**Status: planned after Phase 4.**

Planned deliverables:

- Power BI model using SQL-defined business logic;
- denominator/numerator KPI cards;
- trend view;
- timing/gap view;
- useful subgroup filters;
- presentation-oriented DAX where appropriate.

Power BI should consume SQL-defined measure results rather than recreate eligibility and numerator logic independently.

## Phase 6 — Portfolio release polish

Planned deliverables:

- refreshed public README;
- screenshots of Excel and Power BI outputs;
- simple run/refresh instructions;
- final limitations;
- clean Git history and public-repository check.

## Later — Expanded payer analytics platform

The longer-term roadmap remains under `docs/roadmap/v0.2-expanded-payer-platform/`.

Expanded payer domains should begin only after the SQL + Excel + Power BI analyst workflow is complete. The project should not add pharmacy, physical-health, disability, cultural-factor, or other domains merely to satisfy keywords.
