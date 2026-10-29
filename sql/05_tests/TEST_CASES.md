# Quality Performance Milestone Test Case Catalog

This file is the human-readable test catalog for executable SQL QA and documented methodology boundary scenarios.

## Core relational-model tests

Implemented files:

```text
000_validate_core_foundation.sql  # T-CORE-001 through T-CORE-006
001_validate_core_network.sql     # T-CORE-007 through T-CORE-010
002_validate_core_clinical.sql    # T-CORE-011 through T-CORE-015
003_validate_core_claims.sql      # T-CORE-016 through T-CORE-022
```

These validate source/core reconciliation, uniqueness, required fields, relationship integrity, source semantics, dates, fixture lineage, enrollment normalization, and claim/transaction modeling.

## Historical FUH boundary-scenario catalog

The original design catalog used `T-FUH-001` through `T-FUH-022` for scenario planning. Those IDs remain useful documentation, but not every scenario has a dedicated injected edge-case fixture in v0.1.

| Scenario IDs | Design intent | Current implementation status |
|---|---|---|
| `T-FUH-001`–`T-FUH-006` | same-day and 1/7/8/30/31-day follow-up boundaries | implemented through generic window/same-day invariants and fixture timing coverage; executable evidence includes `T-FUH-051`, `T-FUH-058`, `T-FUH-059`, `T-FUH-064`, `T-FUH-065`, `T-FUH-074` |
| `T-FUH-007`, `T-FUH-018` | continuous enrollment / gap handling | implemented through covering-span eligibility checks; executable evidence includes `T-FUH-038`, `T-FUH-039`, `T-FUH-061` |
| `T-FUH-008`–`T-FUH-011` | readmission/direct-transfer exclusions | **deferred in v0.1** because the current core source does not support trustworthy principal-diagnosis semantics needed for an honest implementation |
| `T-FUH-012` | earliest qualifying follow-up | implemented by deterministic `TOP (1)` selection; executable evidence `T-FUH-064`, `T-FUH-065` |
| `T-FUH-013`, `T-FUH-014` | age boundary | implemented as generic age-rule validation; executable evidence `T-FUH-036` |
| `T-FUH-015` | project-defined BH diagnosis qualification | implemented with typed `core.condition` evidence; executable evidence `T-FUH-029`, `T-FUH-034`, `T-FUH-053` |
| `T-FUH-016` | distinct intentional-self-harm rule | **not separately implemented in v0.1**; current project-owned proxy is the documented ICD-10-CM `F*` behavioral-health rule |
| `T-FUH-017` | qualifying follow-up service rule | implemented; executable evidence `T-FUH-048`, `T-FUH-052`, `T-FUH-053` |
| `T-FUH-019` | fixture lineage | implemented; executable evidence `T-FUH-040`–`T-FUH-044`, `T-FUH-067`–`T-FUH-074` |
| `T-FUH-020` | multiple eligible episodes | supported by event-grain design and uniqueness rules; no dedicated multi-episode fixture is currently required for acceptance |
| `T-FUH-021`, `T-FUH-022` | January 1–December 1 measurement-window rule | implemented as generic window validation; executable evidence `T-FUH-037` |

The deferred scenarios above are documented limitations. They are not silently treated as passing tests.

## Executable Phase 3 tests

### `004_validate_fuh_index.sql` — T-FUH-023 through T-FUH-044

Validates:

- reference/config objects exist;
- exactly one active `FUH_STYLE_MY2025` definition;
- official-HEDIS flag is false;
- required index/BH reference rules exist;
- index-event grain uniqueness;
- required fields;
- member/encounter/diagnosis/optional-claim integrity;
- age rule;
- measurement-window rule;
- enrollment/benefit auditability;
- final eligibility flag;
- fixture lineage and fixture-manifest reconciliation;
- controlled fixture index count = 40 and eligible count = 40.

### `005_validate_fuh_measure.sql` — T-FUH-045 through T-FUH-075

Validates:

- follow-up/result/summary objects exist;
- follow-up reference set exists;
- follow-up grain uniqueness;
- required follow-up fields;
- day 0–30 date range;
- encounter-type and diagnosis qualification;
- same-member/index integrity;
- encounter/diagnosis/optional-claim lineage;
- same-day events receive no numerator credit;
- 7-day qualification implies 30-day qualification;
- final denominator grain uniqueness;
- denominator reconciliation to eligible index events;
- event-level numerator/denominator consistency;
- earliest deterministic 7-day/30-day selection;
- no duplicate numerator credit;
- fixture lineage;
- fixture denominator = 40;
- fixture 7-day numerator = 18;
- fixture 30-day numerator = 32;
- fixture rates = 45.00% / 80.00%;
- day-31 fixture events do not enter the day 0–30 detail layer;
- aggregate totals reconcile to event-level results.

### `006_validate_fuh_reporting.sql` — T-FUH-076 through T-FUH-094

Validates:

- all four analytical reporting views exist;
- report grains are unique;
- numerator/denominator/rate ranges are valid;
- open-gap classifications match event-level flags;
- payer/month, demographic, and timing totals reconcile to event-level results;
- open-gap lineage resolves to authoritative event-level results;
- fixture benchmark remains 40 / 18 / 32;
- fixture timing distribution = 18 / 8 / 6 / 8;
- fixture open-gap distribution = 22 total, including 14 missed-7-day/met-30-day and 8 missed-30-day.

### `007_validate_phase3_closeout.sql` — T-FUH-095 through T-FUH-110

Final smoke validation covering:

- complete Phase 3 object inventory;
- configuration/reference integrity;
- no Phase 3 measure dependency on `core.claim_transaction`;
- denominator/source reconciliation;
- relationship and lineage integrity;
- same-day and 7-day/30-day invariants;
- fixture acceptance benchmark;
- reporting reconciliation;
- timing/gap reconciliation;
- reporting scopes and rate ranges;
- primary-grain uniqueness;
- required source lineage.

## Controlled acceptance benchmark

The deterministic fixture package must produce:

```text
denominator = 40
7-day numerator = 18
30-day numerator = 32
7-day rate = 45.00%
30-day rate = 80.00%
```

These expected values may be hard-coded in fixture acceptance tests because the fixture package exists specifically to provide a deterministic acceptance target. The measure calculations themselves do not hard-code them.
