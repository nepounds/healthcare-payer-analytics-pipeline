# Healthcare Payer Analytics Pipeline

A portfolio project modeling a synthetic North Carolina Medicaid managed-care analytics workflow from source ingestion through payer reporting.

## Current milestone — Quality Performance

Development is intentionally sequenced so the first complete business-facing milestone demonstrates a realistic quality-data workflow:

**synthetic source data → SQL Server raw/core model → FUH-style performance measure → quality analysis → Excel reconciliation → Power BI**

The Quality Performance milestone centers on an educational approximation of Follow-Up After Hospitalization for Mental Illness (FUH) using publicly available measure descriptions and explicitly documented assumptions. It also adds trend analysis, population stratification, gap reporting, physical-health context, and a small pharmacy integration so the result behaves like an analyst workflow rather than a single measure query.

The project does not reproduce licensed HEDIS specifications and does not claim certified HEDIS results.

## Full project direction

The Quality Performance milestone is **not the end of the project**. After it is stable, development continues into the expanded payer platform under `docs/roadmap/v0.2bigdaddy/`, including:

- IET-style quality measurement;
- claims operations analytics;
- finance and utilization analytics;
- network analytics;
- larger-scale performance testing;
- governance/audit enhancements;
- orchestration and automation.

The roadmap is being reordered, not reduced.

## Initial development scale

Start with approximately **5,000 synthetic members**.

Scale only after the end-to-end quality logic is correct and validated.

## Stack

- Python
- Microsoft SQL Server Developer Edition
- SQL Server Management Studio
- Excel / Power Query
- Power BI Desktop
- Git / GitHub

## Active Quality milestone schemas

- `raw`
- `core`
- `ref`
- `measure`

Additional `stg`, `mart`, and `audit` schemas are introduced later when the expanded platform justifies them.

## Repository status

Keep the repository private during initial construction.

The Quality Performance milestone is ready for a public portfolio release when it is:

1. working end to end;
2. tested and reproducible;
3. reconciled in Excel;
4. reportable in Power BI;
5. documented and screenshot-ready;
6. understandable to a hiring manager in roughly two minutes.

See `docs/build_plan.md` and `docs/assumptions_register.md`.

The expanded platform plan remains under `docs/roadmap/v0.2bigdaddy/`.
