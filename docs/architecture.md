# Quality Performance Milestone Architecture

## Design principle

Use the smallest architecture that demonstrates professional separation of concerns, relational modeling, reproducibility, traceable business rules, and payer quality analytics.

Active database schemas:

```text
raw
core
ref
measure
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
                \         |          /
                 +--------+---------+
                          |
                   Excel / Power BI
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

Owns measure business logic and report-ready analytical outputs.

#### `measure.fuh_index_event_detail`

Grain: one row per candidate inpatient behavioral-health index encounter/discharge.

Responsibilities:

- candidate identification;
- typed behavioral-health diagnosis evidence;
- age logic;
- measurement-window logic;
- payer-specific enrollment/benefit eligibility;
- ineligibility reason;
- source and fixture lineage.

#### `measure.fuh_followup_event_detail`

Grain: one row per eligible index event / qualifying follow-up encounter pair within day 0 through day 30.

Responsibilities:

- qualifying follow-up source/type/diagnosis evidence;
- days from index;
- same-day flag;
- 7-day/30-day qualification flags;
- source and fixture lineage.

#### `measure.fuh_measure_result`

Grain: one row per final denominator event.

Responsibilities:

- denominator flag;
- deterministic earliest 7-day follow-up;
- deterministic earliest 30-day follow-up;
- numerator flags;
- payer/demographic/source lineage.

#### `measure.fuh_measure_summary`

Grain: one row per population scope (`ALL`, `FIXTURE`, `NON_FIXTURE`).

Responsibilities: denominator/numerators and safe decimal rates.

#### Reporting views

- `measure.fuh_report_payer_monthly`;
- `measure.fuh_report_demographic`;
- `measure.fuh_report_followup_timing`;
- `measure.fuh_open_gap_detail`.

These expose report-ready counts, rates, timing distributions, subgroup structures, and quality-gap detail while keeping authoritative numerator/denominator logic upstream.

## Business-logic ownership

| Logic | Owner |
|---|---|
| source generation/import | Python |
| source cleanup/typing | SQL raw/core |
| relational healthcare model | SQL core |
| measure configuration | SQL ref |
| FUH-style eligibility/numerator logic | SQL measure |
| analytical reporting | SQL measure |
| independent reconciliation | Excel |
| visualization/interactions | Power BI |
| assumptions/lineage/limitations | Markdown + SQL lineage fields |

## Reproducibility and lineage

A report result can be traced through:

```text
report output
  -> measure reporting view
  -> measure.fuh_measure_result
  -> index/follow-up detail
  -> core entity
  -> raw source
  -> synthetic Synthea row or controlled fixture
```

The measure configuration retains a fixed analysis date and methodology version. Measure views retain source IDs, source files, pipeline run IDs, and fixture flags where materially useful.

## Performance design

The Phase 3 logic uses `core.encounter`, `core.condition`, `core.enrollment_span`, and optional `core.claim` lineage. It does not scan `core.claim_transaction` because transaction-level detail is unnecessary for the implemented FUH-style qualification rule.

## Known architectural limits

The current source cannot support a trustworthy production-grade principal-diagnosis/readmission implementation. The project therefore does not infer one from claim position 1 or encounter reason fields. Pharmacy, physical-health integration, disability/cultural-factor analysis, and official HEDIS/regulatory functionality remain outside the implemented Phase 3 scope.
