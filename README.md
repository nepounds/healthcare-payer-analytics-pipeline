# Healthcare Payer Analytics Pipeline

A portfolio project that uses synthetic healthcare data to build a payer analytics workflow in SQL Server.

The project loads raw healthcare data, cleans it into a relational model, calculates a behavioral-health quality measure, and produces reporting outputs that could be used for quality analysis.

## What the project does

The current version includes:

- raw data ingestion into SQL Server;
- a cleaned relational model for members, payers, enrollment, encounters, conditions, claims, providers, and organizations;
- a FUH-style behavioral-health follow-up measure for measurement year 2025;
- member eligibility and enrollment checks;
- 7-day and 30-day follow-up calculations;
- payer, monthly, demographic, follow-up timing, and open-gap reporting;
- automated SQL tests for data quality and measure logic.

Excel reconciliation and Power BI reporting are planned for the next phase.

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

## Tools

- Python
- Microsoft SQL Server Developer Edition
- SQL Server Management Studio
- Git / GitHub
- Excel / Power Query — planned
- Power BI Desktop — planned

## Database structure

The project uses four main SQL schemas:

- `raw` — source data loaded with minimal changes;
- `core` — cleaned and typed relational tables;
- `ref` — measure definitions and reference values;
- `measure` — quality-measure logic and reporting outputs.

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
```

Breaking the measure into separate steps makes it easier to check how a member entered the denominator, whether they were eligible, and which follow-up visit counted.

More detail is available in:

- [`sql/04_measure/fuh/README.md`](sql/04_measure/fuh/README.md)
- [`docs/fuh_methodology.md`](docs/fuh_methodology.md)
- [`docs/assumptions_register.md`](docs/assumptions_register.md)

## Reporting outputs

The current measure layer includes:

- performance by payer and month;
- performance by age group and sex;
- follow-up timing distributions;
- member-level follow-up gaps.

These outputs are meant to support quality analysis, such as finding groups with lower follow-up rates or members who missed the 7-day or 30-day target.

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
- source lineage.

The final Phase 3 closeout test passed `T-FUH-095` through `T-FUH-110`.

The controlled fixture results also matched the expected:

- 40 denominator events;
- 18 seven-day follow-ups;
- 32 thirty-day follow-ups;
- 45% seven-day rate;
- 80% thirty-day rate.

## How to run

1. Follow [`sql/02_core/README.md`](sql/02_core/README.md) to build the core SQL tables after raw data has been loaded.
2. Follow [`sql/04_measure/fuh/README.md`](sql/04_measure/fuh/README.md) to build the reference and FUH-style measure layer.
3. Run `sql/05_tests/004_validate_fuh_index.sql` through `sql/05_tests/007_validate_phase3_closeout.sql`.

Local setup notes are available in [`docs/setup.md`](docs/setup.md).

## Project status

- **Phase 0 — Setup:** complete
- **Phase 1 — Raw ingestion:** complete
- **Phase 2 — Core relational model:** complete and validated
- **Phase 3 — Quality measure and reporting:** complete and validated
- **Next:** Excel reconciliation and Power BI reporting

## Current limitations

This is a portfolio project built with synthetic data.

The current version doesn't include:

- official NCQA HEDIS specifications or licensed value sets;
- principal-diagnosis-based readmission or transfer exclusions;
- pharmacy integration;
- physical-health integration;
- disability or cultural-factor analysis;
- regulatory submission workflows.

Those areas aren't claimed unless they're actually implemented.

Future expansion ideas are documented in [`docs/roadmap/v0.2-expanded-payer-platform/`](docs/roadmap/v0.2-expanded-payer-platform/).
