# Phase 4 — Excel Analytics, Reconciliation, and SQL Practice Sandbox

## Purpose

Phase 4 turns the existing Healthcare Payer Analytics Pipeline into a reusable SQL + Excel practice environment and creates concrete evidence for common analyst Excel skills.

The project already provides a large relational healthcare dataset and a validated quality-measure layer. Phase 4 should use that foundation rather than creating artificial spreadsheet exercises.

## Main goals

1. Practice SQL joins and analysis against a large healthcare dataset.
2. Export or refresh useful SQL results into Excel.
3. Practice common Excel formulas on real project data.
4. Build PivotTables and charts from meaningful healthcare analysis.
5. Reconcile Excel results back to authoritative SQL totals.
6. Leave behind a workbook and workflow that can continue to be used for practice.

## Proposed Phase 4 structure

```text
SQL Server core + measure tables
            |
            v
Excel-facing SQL queries/views
            |
            v
Excel data / lookup tabs
            |
      +-----+-----+
      |           |
      v           v
formula work    PivotTables
      |           |
      +-----+-----+
            |
            v
        charts
            |
            v
SQL-to-Excel reconciliation
```

## Batch 1 — SQL analysis/export layer

Create a small set of reusable SQL outputs intended for Excel analysis.

Target outputs:

### 1. Member/encounter detail

Purpose: large-detail dataset for joins, filtering, formulas, pivots, and charts.

Useful fields may include:

- member identifier;
- payer identifier/name;
- member age or age band;
- sex;
- county where reliably available;
- encounter identifier;
- encounter date/month;
- encounter class/type;
- organization;
- provider;
- source/fixture flag where useful.

### 2. Payer/month summary

Purpose: grouped SQL output for Excel reconciliation and comparison with PivotTable-derived totals.

Useful fields may include:

- payer;
- month;
- distinct members;
- encounters;
- claims or other supported counts.

### 3. FUH-style Excel detail

Purpose: quality-measure formula practice and reconciliation.

Include the existing event-level results needed to identify:

- denominator events;
- 7-day numerator;
- 30-day numerator;
- first follow-up dates;
- days to follow-up;
- gap status;
- payer/demographic dimensions;
- fixture lineage.

### 4. Lookup/reference data

Purpose: legitimate VLOOKUP/XLOOKUP practice.

Use real project identifiers and descriptions, such as payer or other stable reference values already present in the model.

## Batch 2 — Excel workbook foundation

Create:

`excel/healthcare_payer_analysis.xlsx`

Recommended tabs:

1. `README`
2. `Encounter_Data`
3. `FUH_Data`
4. `Payer_Lookup`
5. `Formula_Practice`
6. `Pivot_Analysis`
7. `Charts`
8. `SQL_Reconciliation`

The workbook should clearly state which tabs are imported/source data and which are analysis outputs.

## Batch 3 — Formula practice

Use actual project data to demonstrate:

### Required

- `VLOOKUP`;
- `XLOOKUP`;
- `SUMIFS`;
- `COUNTIFS`.

### Useful additions

- `IF`;
- `IFERROR`;
- date formulas;
- text cleanup formulas where a genuine use exists;
- Excel Tables and structured references.

Do not add formulas only for keyword coverage. Each formula should answer a reasonable analysis or reconciliation question.

## Batch 4 — PivotTables

Create at least three useful PivotTables.

Recommended:

1. **Encounter volume by payer and month**
   - rows: month;
   - columns/filter: payer;
   - values: encounter count.

2. **Encounter volume by encounter type**
   - rows: encounter type;
   - values: encounter count;
   - optional payer or month filter.

3. **FUH-style follow-up analysis**
   - timing band, sex, age band, or other genuinely supported dimension;
   - denominator/numerator or event counts.

Because the controlled FUH denominator is fixture-only and has limited payer variation, do not present artificial fixture differences as real population findings.

## Batch 5 — Charts

Create at least three charts based on the workbook analysis.

Recommended:

1. line chart — monthly encounter volume;
2. bar chart — encounter volume by payer or setting;
3. bar/column chart — FUH-style follow-up timing distribution.

Charts should be readable and tied to the underlying PivotTables or analysis ranges.

## Batch 6 — SQL-to-Excel reconciliation

Create a control sheet that compares SQL-authoritative totals with Excel-derived totals.

Minimum checks:

| Metric | Authoritative SQL |
|---|---:|
| Members | 5,671 |
| Encounters | 313,094 |
| FUH denominator | 40 |
| FUH 7-day numerator | 18 |
| FUH 30-day numerator | 32 |

The Excel sheet should calculate its own results and a `Difference` column.

Clean expected result:

```text
Difference = 0
```

for every reconciled metric.

A deliberate discrepancy test may also be used to confirm that the control actually detects a mismatch.

## Batch 7 — Sandbox documentation

Document a repeatable practice workflow:

1. choose a SQL question;
2. write or modify the join/query;
3. validate the SQL result;
4. export or refresh it into Excel;
5. practice formulas and/or PivotTables;
6. create or modify a chart;
7. reconcile important totals back to SQL.

This workflow is part of the Phase 4 deliverable. The project should remain useful for future practice rather than becoming a fixed workbook that is never changed again.

## Resume claims unlocked after Phase 4

After the workbook and reconciliation are validated, the project can directly support skills such as:

- Excel PivotTables;
- VLOOKUP;
- XLOOKUP;
- SUMIFS / COUNTIFS;
- charts and graphs;
- data reconciliation;
- large-dataset analysis;
- SQL joins;
- SQL-to-Excel reporting workflow.

Until then, Excel capabilities remain documented as planned.

## Definition of done

Phase 4 is complete only when all of the following are true:

1. At least two meaningful Excel-facing SQL queries/views use relational joins.
2. A reusable detail dataset exists for Excel practice.
3. A committed Excel workbook exists under `excel/`.
4. `VLOOKUP` is used correctly on actual project data.
5. `XLOOKUP` is used correctly on actual project data.
6. `SUMIFS` and/or `COUNTIFS` are used correctly.
7. At least three meaningful PivotTables exist.
8. At least three meaningful charts exist.
9. SQL-vs-Excel reconciliation exists for core and FUH-style totals.
10. Clean reconciliation differences equal zero.
11. Workbook sources and refresh/export steps are documented.
12. The workbook remains usable as a general Excel practice sandbox.
13. README and `docs/skills_coverage.md` are updated only after the Excel evidence exists.
14. Power BI remains a separate Phase 5 rather than being mixed into the Excel milestone.
