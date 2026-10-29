# 02_core

The `core` layer converts source-shaped raw healthcare data into typed, payer-oriented relational entities with explicit grain, stable keys, reproducible raw-to-core transformations, and documented lineage.

## Phase 2 status

Phase 2 is complete for the current pinned Synthea + deterministic FUH fixture package. Implemented objects:

1. `core.member`
2. `core.payer`
3. `core.enrollment_span`
4. `core.organization`
5. `core.provider`
6. `core.encounter`
7. `core.condition`
8. `core.claim`
9. `core.claim_diagnosis`
10. `core.claim_transaction`

The implementation intentionally does **not** create `core.claim_line` or `core.provider_location`. The current source supports transaction/event grain rather than a trustworthy stable claim-line grain, while provider location is already represented through `core.provider -> core.organization`.

## Rebuild order

For a fresh database with Phase 1 raw load already complete, run the Phase 2 scripts in this order:

```text
sql/02_core/001_create_core_member.sql
sql/02_core/002_create_core_payer.sql
sql/02_core/003_create_core_enrollment_span.sql
sql/02_core/004_load_core_foundation.sql
sql/05_tests/000_validate_core_foundation.sql

sql/02_core/005_create_core_organization.sql
sql/02_core/006_create_core_provider.sql
sql/02_core/008_create_core_encounter.sql
sql/02_core/009_create_core_condition.sql
sql/02_core/007_load_core_remaining.sql
sql/05_tests/001_validate_core_network.sql
sql/05_tests/002_validate_core_clinical.sql

sql/02_core/010_create_core_claim.sql
sql/02_core/011_create_core_claim_diagnosis.sql
sql/02_core/012_create_core_claim_transaction.sql
sql/02_core/013_load_core_claims.sql
sql/05_tests/003_validate_core_claims.sql
```

The load scripts validate source shape and relationships before destructive refresh work, use explicit transactions around refreshes, and roll back on failure. `007_load_core_remaining.sql` rebuilds organization/provider/encounter/condition in dependency order. `013_load_core_claims.sql` rebuilds claim/claim-diagnosis/claim-transaction in dependency order.

## Important source-modeling decisions

- `core.enrollment_span` merges overlapping and directly adjacent payer-transition rows with a running-maximum gaps-and-islands method.
- `core.condition` uses a surrogate key because the raw condition source has no source condition identifier.
- Encounter `REASONCODE` is preserved as `reason_code`; it is not relabeled as principal diagnosis.
- Claim diagnoses preserve source position 1-8 but do not infer principal-diagnosis status or a coding system.
- `core.claim_transaction` is one row per source financial transaction. `CHARGEID` is retained as an opaque source value, not a line number.
- Transaction `PLACEOFSERVICE` has mixed source semantics, so `source_place_value` preserves the raw value and `place_organization_id` is populated only when the value resolves to a known organization.
- Transaction `PATIENTINSURANCEID` is preserved as `source_patient_insurance_id` without a payer/enrollment FK. Current payer relationships are carried by `core.claim`.
- Source transaction end dates equal to `1970-01-01` or earlier than the corresponding start date normalize to `NULL`; unparseable dates still fail the load.

These decisions are documented in `docs/data_dictionary.md` and assumptions A-019 through A-023 in `docs/assumptions_register.md`.

## Current pinned-source benchmark

Observed validated row counts:

| Core object | Rows | Notes |
|---|---:|---|
| `core.member` | 5,671 | 1:1 with `raw.patient` |
| `core.payer` | 10 | 1:1 with `raw.payer` |
| `core.enrollment_span` | 36,632 | normalized from 204,896 payer-transition rows |
| `core.organization` | 1,662 | 1:1 with `raw.organization` |
| `core.provider` | 1,662 | 1:1 with `raw.provider` |
| `core.encounter` | 313,094 | includes 76 controlled fixture encounters |
| `core.condition` | 194,647 | includes 76 controlled fixture conditions |
| `core.claim` | 573,681 | includes 76 controlled fixture claims |
| `core.claim_diagnosis` | 825,929 | one row per populated claim diagnosis position; 76 fixture rows |
| `core.claim_transaction` | 5,220,492 | includes 76 controlled fixture transactions |

Additional validated benchmark details:

- 5,654 members have enrollment; 17 do not.
- all 204,896 raw payer-transition rows reconcile through `source_rows_merged`.
- 0 core conditions lack their source encounter in the current pinned source.
- 5,220,416 transaction place values resolve to `core.organization`; 76 fixture transactions preserve POS-style values `11` or `21`.
- 4,987,846 transactions preserve a nonblank `source_patient_insurance_id`.
- 371,166 source transaction end dates equal the epoch sentinel and 822 additional source end dates precede their start; all 371,988 normalize to `NULL` in core.

These counts are regression benchmarks, not hard-coded correctness rules. Executable QA primarily checks source-to-core reconciliation and structural invariants so deliberate future source expansion can still pass without rewriting tests.

## Executable QA

```text
sql/05_tests/000_validate_core_foundation.sql  # T-CORE-001 through T-CORE-006
sql/05_tests/001_validate_core_network.sql     # T-CORE-007 through T-CORE-010
sql/05_tests/002_validate_core_clinical.sql    # T-CORE-011 through T-CORE-015
sql/05_tests/003_validate_core_claims.sql      # T-CORE-016 through T-CORE-022
```

All four validation scripts fail loudly with `THROW` when an invariant is violated.

Phase 3 can now build the FUH-style measure layer on this core model without adding FUH numerator/denominator flags to core.
