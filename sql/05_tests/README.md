# 05_tests

Boundary cases, data-quality checks, row-count checks, duplicate/orphan checks, and measure QA live here.

Start with [`TEST_CASES.md`](TEST_CASES.md). Its stable `T-*` identifiers are referenced directly from the assumptions register.

Implemented Phase 2 core validation:

```text
000_validate_core_foundation.sql  # T-CORE-001 through T-CORE-006
001_validate_core_network.sql     # T-CORE-007 through T-CORE-010
002_validate_core_clinical.sql    # T-CORE-011 through T-CORE-015
003_validate_core_claims.sql      # T-CORE-016 through T-CORE-022
```

Each executable validation script uses `THROW` to fail loudly when a structural or reconciliation invariant is violated. FUH boundary tests will be added here during Phase 3.
