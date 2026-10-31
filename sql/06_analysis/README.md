# 06_analysis

Phase 4 Excel-facing analysis layer.

## Build order

Run against `HealthcarePayerAnalytics` after Phase 3 is complete:

```text
001_create_excel_analysis_views.sql
../05_tests/008_validate_phase4_excel_analysis.sql
```

## Objects

`001_create_excel_analysis_views.sql` creates the `analysis` schema if needed and defines:

- `analysis.excel_encounter_activity` — payer × month × encounter-type aggregation;
- `analysis.excel_member_data` — one non-identifying analytical row per member;
- `analysis.excel_fuh_data` — FUH event detail derived from authoritative Phase 3 results;
- `analysis.excel_payer_lookup` — one-row-per-payer lookup/reference data.

The encounter view aggregates claims to encounter grain before joining so claim multiplicity cannot inflate encounter counts. `member_count` is distinct within each group and is not additive across groups.

## Validation

`008_validate_phase4_excel_analysis.sql` runs `T-XL-001` through `T-XL-012` and fails with `THROW` on any broken invariant.

Validated benchmarks:

```text
encounters = 313,094
claims = 573,681
members = 5,671
FUH denominator = 40
FUH 7-day numerator = 18
FUH 30-day numerator = 32
payers = 10
```

These views are the supported SQL sources for `excel/healthcare_payer_analysis.xlsx`.
