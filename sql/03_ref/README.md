# 03_ref

Reference/configuration objects used by measure logic.

Implemented Phase 3 file:

```text
001_create_measure_reference.sql
```

It creates and seeds:

- `ref.measure_definition`;
- `ref.measure_value_set`.

The current `FUH_STYLE_MY2025` definition is explicitly HEDIS-oriented/FUH-style and explicitly **not** official HEDIS. The reference rows are project-owned portfolio rules, not licensed NCQA value sets.


Current seeded rules: one inpatient index-encounter rule, nine project-owned ICD-10-CM behavioral-health prefixes (`F0`, `F2`–`F9`) that exclude `F10`–`F19`, and two ambulatory/outpatient follow-up encounter rules.

These rows are not official NCQA value sets.
