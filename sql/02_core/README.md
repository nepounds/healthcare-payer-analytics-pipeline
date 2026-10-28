# 02_core

The `core` layer converts source-shaped raw healthcare data into typed, payer-oriented relational entities with explicit grain, stable keys, and documented lineage.

## Current Phase 2 foundation

Implemented objects:

1. `001_create_core_member.sql` — creates `core.member` at one row per synthetic member.
2. `002_create_core_payer.sql` — creates `core.payer` at one row per source payer.
3. `003_create_core_enrollment_span.sql` — creates `core.enrollment_span` at one row per continuous member/payer/benefit span.
4. `004_load_core_foundation.sql` — reproducibly rebuilds all three objects from the current raw landing run, including enrollment gaps-and-islands normalization.

Run the DDL scripts first, then `004_load_core_foundation.sql`.

Executable QA for the foundation lives in:

```text
sql/05_tests/000_validate_core_foundation.sql
```

The validation script checks source-to-core row reconciliation, grain uniqueness, normalized enrollment separation, relationship integrity, and the documented Medicaid benefit approximation.

## Enrollment normalization

`core.enrollment_span` merges overlapping and directly adjacent raw payer-transition rows within the same member, payer, benefit configuration, and source lineage partition.

The implementation uses a running maximum prior end date rather than a simple `LAG(end_date)`. This avoids false gaps when one coverage row is nested inside a longer overlapping row.

For the current Quality Performance milestone, assumption A-018 maps Medicaid coverage to both medical and behavioral-health benefits. Other primary payer spans retain both benefit flags as false until a broader benefit model is implemented.

## Current pinned-source benchmark

The current synthetic source/fixture package has produced the following observed Phase 2 benchmark:

- 5,671 members;
- 10 payers;
- 204,896 raw payer-transition rows;
- 36,632 normalized enrollment spans;
- 5,654 members with enrollment;
- 17 members without enrollment;
- all 204,896 payer-transition rows reconciled through `source_rows_merged`.

These numbers are useful regression benchmarks for the pinned source generation. The executable tests primarily validate structural invariants so deliberate future source expansion does not require rewriting the test logic.

## Next core entities

Phase 2 continues with encounter, condition, claim, claim-line/transaction, provider, and organization modeling before the FUH measure layer is built.
