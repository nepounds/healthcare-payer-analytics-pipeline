# v0.1 Architecture

## Design principle

v0.1 uses the smallest architecture that still demonstrates professional separation of concerns.

The database contains four schemas:

```text
raw
core
ref
measure
```

Additional schemas are added later only when there is enough complexity to justify them.

## End-to-end flow

```text
Synthetic source data
        |
        v
Python generation/import
        |
        v
raw schema
        |
        v
SQL standardization and relational modeling
        |
        v
core + ref schemas
        |
        v
FUH-style measure logic
        |
        v
measure.fuh_episode_detail
        |
        +----------------------+
        |                      |
        v                      v
Excel reconciliation      Power BI Quality page
```

## Schema responsibilities

### `raw`

Purpose: preserve source-shaped records with minimal modification.

Typical tables:

- `raw.patient`
- `raw.encounter`
- `raw.claim`
- `raw.claim_line`
- `raw.condition`
- `raw.provider`
- `raw.organization`
- `raw.payer_transition` or equivalent enrollment source

Rules:

- retain source identifiers;
- preserve source dates and categories;
- avoid measure-specific logic;
- add load metadata where useful;
- make reruns repeatable.

### `core`

Purpose: provide cleaned, payer-oriented relational entities.

Initial tables:

- `core.member`
- `core.enrollment_span`
- `core.encounter`
- `core.claim`
- `core.claim_line`
- `core.claim_diagnosis`
- `core.provider`
- `core.provider_location`

Rules:

- stable keys;
- explicit grain;
- consistent data types;
- normalized dates;
- referential-integrity checks;
- no FUH numerator/denominator flags.

### `ref`

Purpose: centralize reusable definitions and lookup data.

Initial tables:

- `ref.date`
- `ref.county`
- `ref.diagnosis_group`
- `ref.service_type`
- `ref.measure_definition`
- `ref.measure_value_set`

The project should prefer reference-driven logic over long hardcoded code lists inside measure queries.

### `measure`

Purpose: hold measure-specific analytical results.

Initial objects:

- `measure.fuh_episode_detail`
- `measure.fuh_summary`
- `measure.fuh_open_gap`

## Business-logic ownership

| Logic | Owner |
|---|---|
| source ingestion | Python |
| source cleanup and typing | SQL |
| member/enrollment/claim modeling | SQL |
| FUH business rules | SQL |
| independent reconciliation | Excel |
| visual aggregation and interaction | Power BI |
| documentation of assumptions | Markdown |

Power BI may contain display-oriented DAX measures, but it should not recreate the FUH eligibility logic.

## Why an episode table matters

The primary analytical output is not a single percentage.

`measure.fuh_episode_detail` is an **audit table at candidate-discharge grain**. It retains eligible, excluded, and otherwise non-denominator candidates so a reviewer can trace exactly why each episode was retained or dropped.

The FUH denominator is derived from rows where `denominator_flag = 1`; numerator flags are then evaluated only for those denominator episodes.

The **single canonical column list** for this table lives in [`data_dictionary.md`](data_dictionary.md#measurefuh_episode_detail). Do not maintain a second field definition here.

This table is the bridge between computation, validation, and operational reporting.

## Development scale

Build and debug against approximately **5,000 members**.

Do not scale to 50,000 until:

1. the load succeeds repeatably;
2. row counts reconcile;
3. FUH test cases pass;
4. Excel reconciliation is stable;
5. the Power BI page refreshes correctly.

At that point, scaling becomes a performance exercise rather than a logic-debugging exercise.
