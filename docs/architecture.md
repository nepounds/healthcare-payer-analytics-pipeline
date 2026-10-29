# Quality Performance Milestone Architecture

## Design principle

The Quality Performance milestone uses the smallest architecture that still demonstrates professional separation of concerns, reproducibility, and a realistic payer-analytics workflow.

The database contains four active schemas:

```text
raw
core
ref
measure
```

The expanded payer platform later introduces additional schemas such as `stg`, `mart`, and `audit` when their complexity is justified.

## End-to-end flow

```text
Synthetic source data + deterministic FUH fixtures
                    |
                    v
          Python generation/import
                    |
                    v
                raw schema
                    |
                    v
     SQL typing + relational modeling
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
          +---------+----------+
          |                    |
          v                    v
 Quality analysis views    Open-gap output
 trends / populations      actionable misses
          |                    |
          +---------+----------+
                    |
          +---------+----------+
          |                    |
          v                    v
 Excel reconciliation   Power BI Quality report
```

A focused medication/pharmacy source is added during the Quality analysis phase and linked to the same member-centered core model. Physical-health context is derived from the condition data already carried through the relational layer.

## Schema responsibilities

### `raw`

Purpose: preserve source-shaped records with minimal modification.

Typical/current source tables include:

- `raw.patient`
- `raw.encounter`
- `raw.condition`
- `raw.claim`
- `raw.claim_transaction`
- `raw.provider`
- `raw.organization`
- `raw.payer`
- `raw.payer_transition`

Quality-milestone extension:

- a Synthea medication source promoted into `raw` when the pharmacy analysis is implemented.

Rules:

- retain source identifiers;
- preserve source dates and categories;
- avoid measure-specific logic;
- add load metadata where useful;
- make reruns repeatable.

### `core`

Purpose: provide cleaned, payer-oriented relational entities with explicit grain and stable relationships.

Quality-milestone Phase 2 entities are:

- `core.member`
- `core.payer`
- `core.enrollment_span`
- `core.organization`
- `core.provider`
- `core.encounter`
- `core.condition`
- `core.claim`
- `core.claim_diagnosis`
- `core.claim_transaction`

The source is transaction/event-grained, so Phase 2 deliberately does not fabricate a separate claim-line table. Provider location is represented through the provider-to-organization relationship rather than a duplicate provider-location entity. Medication/pharmacy representation remains a Phase 4 extension.

Rules:

- stable keys;
- explicit grain;
- consistent data types;
- normalized dates;
- referential-integrity checks;
- source-to-core reconciliation;
- no FUH numerator/denominator flags.

Phase 2 also preserves source semantics when the landing data cannot support a clean normalized relationship. In particular, claim-transaction `PLACEOFSERVICE` is preserved as a raw source value and only resolves to an organization when the value is actually an organization identifier; `PATIENTINSURANCEID` is retained as source lineage rather than forced into a payer FK; and invalid/sentinel transaction end dates normalize to `NULL` while remaining traceable in raw.

### `ref`

Purpose: centralize reusable definitions and lookup data.

Initial tables may include:

- `ref.date`
- `ref.county`
- `ref.diagnosis_group`
- `ref.service_type`
- `ref.measure_definition`
- `ref.measure_value_set`

The project should prefer reference-driven logic over long hardcoded code lists inside measure queries.

### `measure`

Purpose: hold measure-specific and report-ready quality analytical results.

Core FUH objects:

- `measure.fuh_episode_detail`
- `measure.fuh_summary`
- `measure.fuh_open_gap`

Additional Quality analysis objects may expose:

- monthly/quarterly trends;
- population stratifications;
- physical-health/comorbidity summaries;
- focused pharmacy context.

These may be tables or views depending on the need for persistence, auditability, and refresh behavior.

## Business-logic ownership

| Logic | Owner |
|---|---|
| source ingestion | Python |
| source cleanup and typing | SQL |
| member/enrollment/claim/clinical modeling | SQL |
| FUH business rules | SQL |
| quality trend/population/gap analysis | SQL |
| physical-health/pharmacy integration | SQL |
| independent reconciliation | Excel |
| visual aggregation and interaction | Power BI |
| documentation of assumptions/lineage | Markdown |

Power BI may contain display-oriented DAX measures, but it should not recreate FUH eligibility logic.

## Why an episode table matters

The primary analytical output is not a single percentage.

`measure.fuh_episode_detail` is an **audit table at candidate-discharge grain**. It retains eligible, excluded, and otherwise non-denominator candidates so a reviewer can trace exactly why each episode was retained or dropped.

The FUH denominator is derived from rows where `denominator_flag = 1`; numerator flags are then evaluated only for those denominator episodes.

The **single canonical column list** for this table lives in [`data_dictionary.md`](data_dictionary.md#measurefuh_episode_detail). Do not maintain a second field definition here.

This table is the bridge between computation, validation, quality-gap analysis, and operational reporting.

## Reproducibility and report lineage

Report-ready outputs should be traceable back through:

```text
report visual / workbook result
        -> measure/reporting object
        -> core relational entity
        -> raw source table
        -> documented synthetic source or fixture
```

Assumptions, configured analysis dates, fixture flags, and pipeline/load identifiers should be retained wherever they materially affect reproducibility.

## Development scale

Build and debug against approximately **5,000 members**.

Do not scale to 50,000 until:

1. the load succeeds repeatably;
2. row counts reconcile;
3. core relationships are tested;
4. FUH test cases pass;
5. Quality analysis outputs are reproducible;
6. Excel reconciliation is stable;
7. the Power BI report refreshes correctly.

At that point, scaling becomes a performance exercise rather than a logic-debugging exercise, and development continues into the expanded payer platform.
