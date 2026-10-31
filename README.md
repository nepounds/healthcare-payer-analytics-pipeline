# Healthcare Payer Analytics Pipeline

A portfolio project that uses synthetic healthcare data to build a payer analytics workflow in SQL Server and Excel.

The project loads raw healthcare data, cleans it into a relational model, calculates a behavioral-health quality measure, exposes compact analysis-ready SQL views, and analyzes those outputs in a refreshable Excel workbook. The SQL Server database is also intentionally retained as a large practice sandbox for joins, aggregation, reconciliation, and reporting.

## What the project does

The current version includes:

- raw data ingestion into SQL Server;
- a cleaned relational model for members, payers, enrollment, encounters, conditions, claims, providers, and organizations;
- a FUH-style behavioral-health follow-up measure for measurement year 2025;
- member eligibility and enrollment checks;
- 7-day and 30-day follow-up calculations;
- payer, monthly, demographic, follow-up timing, and open-gap reporting;
- a compact Excel-facing SQL analysis layer with tested joins and aggregation;
- a refreshable Excel workbook using Power Query, Excel Tables, VLOOKUP/XLOOKUP, SUMIFS/COUNTIFS, IF/IFERROR, PivotTables, charts, and SQL-to-Excel reconciliation;
- automated SQL tests for data quality, measure logic, and Excel-facing output integrity.

Power BI reporting remains planned for Phase 5.

## FUH-style results

The project includes a controlled test population so the measure logic can be checked against known results.

| Result | Value |
|---|---:|
| Denominator | 40 |
| 7-day numerator | 18 |
| 30-day numerator | 32 |
| 7-day rate | 45.00% |
| 30-day rate | 80.00% |

![SSMS result showing the final FUH-style fixture results](docs/assets/fuh_closeout_results.png)

All 40 denominator events shown above are controlled test fixtures.

The non-fixture Synthea population produced **zero eligible FUH-style denominator events** under the current rules. The 45% and 80% rates are therefore test results used to validate the SQL logic, not real-population performance findings.

This project is **FUH-style / HEDIS-oriented** for portfolio purposes. It does not use licensed NCQA specifications or claim official HEDIS compliance.

## Data size

The current SQL Server database contains:

| Table | Rows |
|---|---:|
| Members | 5,671 |
| Payers | 10 |
| Enrollment spans | 36,632 |
| Organizations | 1,662 |
| Providers | 1,662 |
| Encounters | 313,094 |
| Conditions | 194,647 |
| Claims | 573,681 |
| Claim diagnoses | 825,929 |
| Claim transactions | 5,220,492 |

Large detail tables remain in SQL Server. The committed Excel workbook uses compact analysis-ready views rather than duplicating the warehouse in `.xlsx` form.

## Tools

- Python
- Microsoft SQL Server Developer Edition
- SQL Server Management Studio
- Git / GitHub
- Microsoft Excel
- Power Query
- Power BI Desktop — planned for Phase 5

## Database structure

The project uses five active SQL schemas:

- `raw` — source data loaded with minimal changes;
- `core` — cleaned and typed relational tables;
- `ref` — measure definitions and reference values;
- `measure` — quality-measure logic and reporting outputs;
- `analysis` — compact Excel-facing analytical views.

The Phase 4 analysis layer exposes:

- `analysis.excel_encounter_activity` — payer × month × encounter-type aggregation;
- `analysis.excel_member_data` — one non-identifying analytical row per member;
- `analysis.excel_fuh_data` — Excel-friendly FUH event detail using authoritative Phase 3 flags;
- `analysis.excel_payer_lookup` — small payer reference table for lookup practice.

The FUH-style measure is built in several steps:

```text
reference rules
      |
      v
index events
      |
      v
follow-up events
      |
      v
final event results
      |
      +------> summary results
      |
      +------> reporting views
      |
      +------> analysis views -> Excel workbook
```

More detail is available in:

- [`sql/04_measure/fuh/README.md`](sql/04_measure/fuh/README.md)
- [`sql/06_analysis/README.md`](sql/06_analysis/README.md)
- [`docs/fuh_methodology.md`](docs/fuh_methodology.md)
- [`docs/phase4_excel_plan.md`](docs/phase4_excel_plan.md)
- [`docs/assumptions_register.md`](docs/assumptions_register.md)

## Excel analysis

The committed workbook is:

`excel/healthcare_payer_analysis.xlsx`

It contains compact SQL-backed source tables plus separate formula-practice, PivotTable, chart, and reconciliation sheets. Implemented Excel evidence includes:

- VLOOKUP and XLOOKUP against a real payer lookup table;
- IFERROR for lookup handling;
- SUMIFS for payer-level and payer/year encounter totals;
- COUNTIFS for FUH numerator/gap checks;
- IF-based PASS/FAIL controls;
- three manually built PivotTables;
- three charts, including a 2025 monthly encounter trend and FUH timing distribution;
- SQL-to-Excel reconciliation for members, encounters, claims, and FUH results.

Final reconciliation differences are zero for all six controls:

- members = 5,671;
- encounters = 313,094;
- claims = 573,681;
- FUH denominator = 40;
- FUH 7-day numerator = 18;
- FUH 30-day numerator = 32.

The workbook refresh workflow was re-tested after document metadata removal. The committed workbook contains no unnecessary personal-looking synthetic fields.

## Testing

The project includes executable SQL tests for:

- duplicate and grain checks;
- member and encounter relationships;
- enrollment eligibility;
- follow-up date rules;
- same-day handling;
- numerator and denominator reconciliation;
- fixture results;
- reporting totals;
- source lineage;
- Excel-facing analysis-view grain and reconciliation;
- prevention of unintended row multiplication;
- public-workbook field restrictions.

Phase 3 closeout passed `T-FUH-095` through `T-FUH-110`.

Phase 4 SQL analysis validation passed `T-XL-001` through `T-XL-012`.

## How to run

1. Follow [`sql/02_core/README.md`](sql/02_core/README.md) to build the core SQL tables after raw data has been loaded.
2. Follow [`sql/04_measure/fuh/README.md`](sql/04_measure/fuh/README.md) to build the reference and FUH-style measure layer.
3. Run `sql/06_analysis/001_create_excel_analysis_views.sql`.
4. Run `sql/05_tests/008_validate_phase4_excel_analysis.sql`.
5. Open `excel/healthcare_payer_analysis.xlsx` and use **Data -> Refresh All**.
6. Confirm the `SQL_Reconciliation` sheet remains all PASS with zero differences.

Local setup notes are available in [`docs/setup.md`](docs/setup.md).

## Project status

- **Phase 0 — Setup:** complete
- **Phase 1 — Raw ingestion:** complete
- **Phase 2 — Core relational model:** complete and validated
- **Phase 3 — Quality measure and reporting:** complete and validated
- **Phase 4 — Excel analytics, reconciliation, and SQL practice sandbox:** complete and validated
- **Phase 5 — Power BI reporting:** next
- **Later — Expanded payer analytics platform:** planned

See [`docs/phase4_excel_plan.md`](docs/phase4_excel_plan.md) for the implemented Phase 4 design and closeout evidence.

## Current limitations

This is a portfolio project built with synthetic data.

The current version does not include:

- official NCQA HEDIS specifications or licensed value sets;
- principal-diagnosis-based readmission or transfer exclusions;
- pharmacy integration;
- physical-health integration;
- disability or cultural-factor analysis;
- regulatory submission workflows;
- completed Power BI reporting.

Those areas are not claimed unless they are actually implemented.

Future expansion ideas are documented in [`docs/roadmap/v0.2-expanded-payer-platform/`](docs/roadmap/v0.2-expanded-payer-platform/).
