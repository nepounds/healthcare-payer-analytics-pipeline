# Phase 4 — Excel Analytics, Reconciliation & SQL Practice Sandbox

**Status: complete and validated.**

This document records the implemented Phase 4 design and closeout evidence. It replaces earlier planning language that proposed large Excel detail exports.

## Objective

Use the existing SQL Server database as the authoritative large-data platform while creating a compact, refreshable Excel workbook that demonstrates practical analyst skills without duplicating hundreds of thousands or millions of detail rows into Git.

## Implemented architecture

```text
SQL Server core + measure tables
             |
             v
     analysis.* views
             |
             v
     Power Query refresh
             |
             v
 Excel source tables
     |       |       |
     v       v       v
 formulas  pivots  charts
       \      |      /
        \     |     /
         reconciliation
```

SQL owns relational joins, source selection, large-data aggregation, and authoritative measure logic. Excel owns lookup/formula practice, exploratory summaries, PivotTables, charts, and independent reconciliation.

## SQL analysis/export layer

Implemented file:

`sql/06_analysis/001_create_excel_analysis_views.sql`

Implemented views:

### `analysis.excel_encounter_activity`

**Grain:** payer × encounter month × encounter type.

Key fields include payer ID/name/type, month/year, encounter type, encounter count, grouped distinct member count, and claim count.

The view uses a `LEFT JOIN` to payer so missing payer references do not disappear from encounter reconciliation. Because claims are one-to-many from encounters, claims are aggregated to one row per encounter before the encounter-level join. This prevents row multiplication.

`member_count` is distinct only within each grouped row and is not additive across groups.

### `analysis.excel_member_data`

**Grain:** one row per member.

Contains non-identifying analytical fields such as member ID, fixed analysis date, age, age band, sex, county code, deceased flag, and fixture flag. It does not expose member names, birth date, SSN-shaped values, driver's-license values, street addresses, phones, or email addresses.

### `analysis.excel_fuh_data`

**Grain:** one row per final FUH-style denominator event.

Reuses authoritative Phase 3 numerator/denominator results and adds Excel-friendly payer category, age band, follow-up timing band, and gap status. No FUH eligibility or numerator logic is reimplemented in Excel.

### `analysis.excel_payer_lookup`

**Grain:** one row per payer.

Provides payer ID, source payer ID, payer name, and payer type for genuine lookup practice.

## SQL QA

Implemented file:

`sql/05_tests/008_validate_phase4_excel_analysis.sql`

Tests `T-XL-001` through `T-XL-012` validate:

- required analysis objects;
- encounter-view grain uniqueness;
- encounter reconciliation to `core.encounter`;
- claim reconciliation to `core.claim` without row multiplication;
- valid encounter summary values;
- one-row-per-member reconciliation;
- member analytical field validity;
- one-row-per-FUH-event reconciliation;
- FUH classification consistency;
- controlled 40 / 18 / 32 FUH benchmark;
- one-row-per-payer lookup integrity;
- exclusion of common personal-looking fields from Excel-facing views.

All tests passed.

## Workbook

Committed artifact:

`excel/healthcare_payer_analysis.xlsx`

Final size: approximately **12.8 KB**.

Sheets:

- `README`;
- `Encounter_Data`;
- `Member_Data`;
- `FUH_Data`;
- `Payer_Lookup`;
- `Formula_Practice`;
- `Pivot_Analysis`;
- `Charts`;
- `SQL_Reconciliation`.

Power Query loads the four `analysis.*` views into Excel Tables:

- `tblEncounter`;
- `tblMember`;
- `tblFUH`;
- `tblPayer`.

## Formula evidence

The `Formula_Practice` sheet contains actual project-data examples of:

- `VLOOKUP` — payer ID to payer name;
- `XLOOKUP` — payer ID to payer type;
- `IFERROR` — lookup error handling;
- `SUMIFS` — all-time encounters by payer;
- `SUMIFS` — 2025 encounters by payer;
- `COUNTIFS` — 7-day FUH numerator = 18;
- `COUNTIFS` — 30-day FUH numerator = 32;
- `COUNTIFS` — missed 30-day = 8;
- `COUNTIFS` — missed 7-day but met 30-day = 14;
- `IF` — PASS/FAIL checks.

The FUH SQL `BIT` flags arrive through Power Query as Excel logical `TRUE`/`FALSE`, so the workbook's COUNTIFS criteria use logical values rather than numeric 1/0.

## PivotTables

Three PivotTables were built manually:

1. **Encounter volume by payer and month** — `SUM(encounter_count)` rather than row count.
2. **Encounter mix by encounter type and payer** — supports month filtering and preserves aggregated encounter counts.
3. **FUH follow-up timing distribution** — counts event IDs by timing band; gender is available as a useful filter because the controlled FUH fixtures only contain Medicaid payer events.

## Charts

Three charts were built from the project data:

1. **2025 Monthly Encounter Volume** — line chart filtered to 2025 so the long synthetic history does not compress the trend into an unreadable axis.
2. **Payer Mix by Encounter Type** — stacked chart for encounter-setting composition across payers.
3. **FUH Follow-Up Timing Distribution** — bar chart across the four follow-up timing categories.

## SQL-to-Excel reconciliation

The `SQL_Reconciliation` sheet independently recalculates SQL totals with formulas rather than manually entered Excel answers.

| Metric | SQL Expected | Excel Calculated | Difference | Status |
|---|---:|---:|---:|---|
| Members | 5,671 | 5,671 | 0 | PASS |
| Encounters | 313,094 | 313,094 | 0 | PASS |
| Claims | 573,681 | 573,681 | 0 | PASS |
| FUH denominator | 40 | 40 | 0 | PASS |
| FUH 7-day numerator | 18 | 18 | 0 | PASS |
| FUH 30-day numerator | 32 | 32 | 0 | PASS |

Member reconciliation uses `Member_Data`. It does not sum grouped distinct-member counts from `Encounter_Data`.

## Refresh workflow

1. Start SQL Server and confirm `HealthcarePayerAnalytics` is available.
2. Open `excel/healthcare_payer_analysis.xlsx`.
3. Use **Data -> Refresh All**.
4. Allow all four Power Query connections to finish.
5. Confirm `SQL_Reconciliation` remains zero-difference / PASS.
6. Refresh PivotTables/PivotCharts if Excel does not refresh them automatically.

This workflow was successfully re-tested during Phase 4 closeout.

## Privacy and metadata closeout

The workbook contains no unnecessary names, SSNs, driver's-license values, street addresses, phone numbers, email addresses, or other personal-looking synthetic fields.

Excel Document Inspector was used to remove document properties/personal information. The workbook was then closed, reopened, refreshed, and revalidated successfully.

## Reusable practice sandbox

Future SQL exercises can be added against the existing database without changing Phase 4 artifacts. Suitable exercises include INNER vs LEFT JOIN, CTEs, window functions, GROUP BY/HAVING, CASE, date logic, subqueries, optimization, and reconciliation.

Future Excel exercises can be added to the workbook or a copy without changing the validated evidence above. Suitable exercises include INDEX/MATCH, dynamic arrays, text/date functions, conditional formatting, additional PivotTables/charts, Power Query transformations, and reconciliation.

## Definition of done

Phase 4 is closed. The implemented repository now supports defensible claims for:

**Excel: PivotTables, VLOOKUP/XLOOKUP, SUMIFS/COUNTIFS, IF/IFERROR, charts, Power Query, data reconciliation.**

Power BI remains Phase 5 and is not claimed as implemented.
