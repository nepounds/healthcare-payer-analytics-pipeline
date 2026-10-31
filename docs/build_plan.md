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

Implemented Phase 3 objects include:

- `ref.measure_definition`;
- `ref.measure_value_set`;
- `measure.fuh_index_event_detail`;
- `measure.fuh_followup_event_detail`;
- `measure.fuh_measure_result`;
- `measure.fuh_measure_summary`;
- `measure.fuh_report_payer_monthly`;
- `measure.fuh_report_demographic`;
- `measure.fuh_report_followup_timing`;
- `measure.fuh_open_gap_detail`.

Controlled acceptance benchmark:

```text
denominator = 40
7-day numerator = 18
30-day numerator = 32
7-day rate = 45.00%
30-day rate = 80.00%
```

The current implementation does not claim official NCQA HEDIS compliance, licensed value sets, principal-diagnosis-based readmission/transfer exclusion logic, pharmacy/physical-health integration, disability/cultural-factor analysis, or regulatory submission capability.

## Phase 4 — Excel analytics, reconciliation, and SQL practice sandbox

**Status: complete and validated.**

### Implemented SQL analysis layer

Phase 4 adds the `analysis` schema and four compact Excel-facing views:

- `analysis.excel_encounter_activity`;
- `analysis.excel_member_data`;
- `analysis.excel_fuh_data`;
- `analysis.excel_payer_lookup`.

The encounter view is aggregated at payer × month × encounter type. Claims are aggregated to one row per encounter before joining so the one-to-many relationship cannot multiply encounter rows. A `LEFT JOIN` to payer preserves unattributed encounters for full encounter reconciliation. The FUH view uses the authoritative Phase 3 measure result rather than rebuilding measure logic in Excel.

Executable Phase 4 SQL QA: `T-XL-001` through `T-XL-012`.

Validated SQL totals:

```text
members = 5,671
encounters = 313,094
claims = 573,681
FUH denominator = 40
FUH 7-day numerator = 18
FUH 30-day numerator = 32
payers = 10
```

### Implemented Excel workbook

Committed artifact:

`excel/healthcare_payer_analysis.xlsx`

Workbook sheets:

- `README`;
- `Encounter_Data`;
- `Member_Data`;
- `FUH_Data`;
- `Payer_Lookup`;
- `Formula_Practice`;
- `Pivot_Analysis`;
- `Charts`;
- `SQL_Reconciliation`.

SQL-backed tables are loaded through Power Query and can be refreshed with **Data -> Refresh All**.

Implemented formula evidence:

- VLOOKUP — payer ID to payer name;
- XLOOKUP — payer ID to payer type;
- IFERROR — lookup error handling;
- SUMIFS — all-time encounters by payer and 2025 encounters by payer;
- COUNTIFS — FUH 7-day/30-day numerator and gap checks;
- IF — reconciliation/PASS-FAIL checks.

Implemented PivotTables:

1. encounter volume by payer and month using `SUM(encounter_count)`;
2. encounter mix by encounter type and payer;
3. FUH follow-up timing distribution with gender as an available filter.

Implemented charts:

1. 2025 monthly encounter-volume line chart;
2. stacked payer-mix-by-encounter-type chart;
3. FUH follow-up timing distribution bar chart.

### Excel reconciliation

The workbook independently recalculates six authoritative SQL totals.

| Metric | SQL | Excel | Difference | Status |
|---|---:|---:|---:|---|
| Members | 5,671 | 5,671 | 0 | PASS |
| Encounters | 313,094 | 313,094 | 0 | PASS |
| Claims | 573,681 | 573,681 | 0 | PASS |
| FUH denominator | 40 | 40 | 0 | PASS |
| FUH 7-day numerator | 18 | 18 | 0 | PASS |
| FUH 30-day numerator | 32 | 32 | 0 | PASS |

Member reconciliation uses the one-row-per-member `Member_Data` source rather than summing grouped distinct-member counts from the encounter aggregation.

### Privacy, size, and refresh closeout

- no names, SSNs, driver's-license values, street addresses, phone numbers, emails, or other unnecessary personal-looking fields are exported;
- Excel document properties/personal information were removed with Document Inspector;
- workbook reopened successfully after metadata removal;
- Power Query refresh remained successful;
- PivotTables/charts remained functional;
- all reconciliation controls remained PASS;
- final workbook size: approximately 12.8 KB.

### Reusability

The SQL Server database remains the large-data query sandbox. New SQL exercises can use the existing core/measure objects without expanding the workbook. The Excel workbook remains a compact formula/PivotTable/chart/reconciliation sandbox and can refresh from the four `analysis` views.

## Phase 5 — Power BI reporting

**Status: next.**

Planned deliverables:

- Power BI model using SQL-defined business logic;
- denominator/numerator KPI cards;
- trend view;
- timing/gap view;
- useful subgroup filters;
- presentation-oriented DAX where appropriate.

Power BI should consume SQL-defined measure results rather than recreate eligibility and numerator logic independently.

## Later — Expanded payer analytics platform

The longer-term roadmap remains under `docs/roadmap/v0.2-expanded-payer-platform/`.

Expanded payer domains should begin only after the SQL + Excel + Power BI analyst workflow is complete. The project should not add pharmacy, physical-health, disability, cultural-factor, or other domains merely to satisfy keywords.
