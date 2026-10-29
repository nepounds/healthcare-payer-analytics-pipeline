# 05_tests

Executable structural, reconciliation, measure, and reporting QA lives here. Scripts fail loudly with `THROW` when an invariant is violated.

See [`TEST_CASES.md`](TEST_CASES.md) for the human-readable catalog.

## Implemented core validation

```text
000_validate_core_foundation.sql  # T-CORE-001 through T-CORE-006
001_validate_core_network.sql     # T-CORE-007 through T-CORE-010
002_validate_core_clinical.sql    # T-CORE-011 through T-CORE-015
003_validate_core_claims.sql      # T-CORE-016 through T-CORE-022
```

## Implemented Phase 3 validation

```text
004_validate_fuh_index.sql        # T-FUH-023 through T-FUH-044
005_validate_fuh_measure.sql      # T-FUH-045 through T-FUH-075
006_validate_fuh_reporting.sql    # T-FUH-076 through T-FUH-094
007_validate_phase3_closeout.sql  # T-FUH-095 through T-FUH-110
```

The Phase 3 suite covers generic invariants plus deterministic fixture acceptance. Fixture benchmarks are not the only QA: grain uniqueness, required fields, relationships, date logic, same-day handling, deterministic first follow-up, aggregate reconciliation, reporting reconciliation, lineage, and scope/rate validity are tested independently.
