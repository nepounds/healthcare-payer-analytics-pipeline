# Quality Performance Milestone Architecture

## Design principle

Use the smallest architecture that demonstrates professional separation of concerns, relational modeling, reproducibility, traceable business rules, payer quality analytics, and independent Excel reconciliation.

Active database schemas:

```text
raw
core
ref
measure
analysis
```

## End-to-end flow

```text
Synthetic Synthea source + deterministic FUH fixtures
                         |
                         v
                    raw schema
                         |
                         v
              typed relational core
                         |
              +----------+----------+
              |                     |
              v                     v
 core clinical/claims data      ref measure rules
              |                     |
              +----------+----------+
                         v
          measure.fuh_index_event_detail
                         |
                         v
        measure.fuh_followup_event_detail
                         |
                         v
             measure.fuh_measure_result
                 /        |         \
                v         v          v
          aggregate   reporting   open gaps
           summary      views
                 \        |        /
                  +-------+-------+
                          |
                          v
                     analysis views
                          |
                          v
                    Power Query
                          |
                          v
               Excel formulas/pivots/charts
                          |
                          v
                    reconciliation
                          |
                          v
                    Power BI (Phase 5)
```

## Schema responsibilities

### `raw`

Preserves source-shaped records with minimal transformation, source identifiers, fixture indicators, and load lineage.

### `core`

Provides typed relational entities at trustworthy source-supported grains:

- `core.member`;
- `core.payer`;
- `core.enrollment_span`;
- `core.organization`;
- `core.provider`;
- `core.encounter`;
- `core.condition`;
- `core.claim`;
- `core.claim_diagnosis`;
- `core.claim_transaction`.

Important semantic protections:

- claim diagnosis position 1 is not treated as principal diagnosis;
- claim diagnosis coding system is not invented;
- `PATIENTINSURANCEID` is retained as opaque source lineage rather than forced into a payer/enrollment FK;
- transaction place values are normalized only when a real organization relationship exists.

### `ref`

Stores reusable measure metadata and project-owned rule/value-set configuration:

- `ref.measure_definition`;
- `ref.measure_value_set`.

The implemented FUH-style configuration is explicitly HEDIS-oriented but not official HEDIS.

### `measure`

Owns FUH-style business logic and report-ready analytical outputs.

Implemented objects include index-event detail, follow-up detail, final event results, aggregate summary, payer/month reporting, demographic reporting, timing distributions, and open-gap detail.

### `analysis`

Owns compact downstream analytical views designed for Excel and later reporting tools without duplicating large detail tables.

- `analysis.excel_encounter_activity` — payer × month × encounter-type aggregation; claims are pre-aggregated to encounter grain before joining;
- `analysis.excel_member_data` — one row per member with non-identifying analytical dimensions;
- `analysis.excel_fuh_data` — one row per authoritative FUH denominator event with Excel-friendly timing/gap classifications;
- `analysis.excel_payer_lookup` — one row per payer for lookup/reference use.

The `analysis` layer does not own FUH eligibility or numerator logic. It reuses `measure.fuh_measure_result` so business rules remain centralized.

## Business-logic ownership

| Logic | Owner |
|---|---|
| source generation/import | Python |
| source cleanup/typing | SQL raw/core |
| relational healthcare model | SQL core |
| measure configuration | SQL ref |
| FUH-style eligibility/numerator logic | SQL measure |
| compact downstream analytical shaping | SQL analysis |
| formulas, pivots, charts, independent reconciliation | Excel |
| visualization/interactions | Power BI (Phase 5) |
| assumptions/lineage/limitations | Markdown + SQL lineage fields |

## Reproducibility and lineage

A workbook result can be traced through:

```text
Excel result
  -> Power Query source
  -> analysis view
  -> measure/core entity
  -> raw source
  -> synthetic Synthea row or controlled fixture
```

FUH results additionally trace through the measure index/follow-up layers and fixed measure configuration.

## Performance design

Large detail tables stay in SQL Server. The Phase 4 encounter source is aggregated before reaching Excel, and `core.claim_transaction` remains in SQL because 5.2M+ transaction rows are not appropriate for a committed workbook.

The encounter activity view avoids row multiplication by aggregating `core.claim` to encounter grain before joining to `core.encounter`.

## Known architectural limits

The current source cannot support a trustworthy production-grade principal-diagnosis/readmission implementation. The project therefore does not infer one from claim position 1 or encounter reason fields. Pharmacy, physical-health integration, disability/cultural-factor analysis, official HEDIS/regulatory functionality, and Power BI reporting remain outside the implemented Phase 4 scope.
