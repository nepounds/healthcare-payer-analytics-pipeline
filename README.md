# Healthcare Payer Analytics Pipeline

A portfolio project modeling a synthetic North Carolina Medicaid managed-care analytics workflow.

## v0.1

The first release is intentionally narrow:

**synthetic source data → SQL Server → FUH-style episode logic → Excel reconciliation → Power BI**

v0.1 focuses on an educational approximation of Follow-Up After Hospitalization for Mental Illness (FUH) using publicly available measure descriptions and explicitly documented assumptions. It does not reproduce licensed HEDIS specifications and does not claim certified HEDIS results.

## Initial development scale

Start with approximately **5,000 synthetic members**.

Scale only after the end-to-end logic is correct.

## Stack

- Python
- Microsoft SQL Server Developer Edition
- SQL Server Management Studio
- Excel / Power Query
- Power BI Desktop
- Git / GitHub

## Active v0.1 schemas

- `raw`
- `core`
- `ref`
- `measure`

Additional schemas are deferred until actual project complexity justifies them.

## Repository status

Keep the repository private during initial construction.

Make it public when v0.1 is:

1. working end to end;
2. documented;
3. screenshot-ready;
4. understandable to a hiring manager in roughly two minutes.

See `docs/build_plan.md` and `docs/assumptions_register.md`.

The expanded v0.2 plan is parked under `docs/roadmap/v0.2bigdaddy/`.
