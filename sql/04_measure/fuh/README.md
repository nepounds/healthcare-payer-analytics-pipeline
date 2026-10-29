# FUH-style behavioral-health performance measure

This directory implements an FUH-style/HEDIS-oriented portfolio measure. It is not an official NCQA HEDIS implementation.

## Execution order

```text
001_create_fuh_index_event_detail.sql
002_create_fuh_followup_event_detail.sql
003_create_fuh_measure_result.sql
004_create_fuh_measure_summary.sql
005_create_fuh_reporting_views.sql
```

Run `sql/03_ref/001_create_measure_reference.sql` first.

## Objects and grains

| Object | Grain |
|---|---|
| `measure.fuh_index_event_detail` | one row per candidate inpatient behavioral-health index encounter/discharge |
| `measure.fuh_followup_event_detail` | one row per eligible index-event / qualifying follow-up encounter pair in day 0–30 |
| `measure.fuh_measure_result` | one row per final denominator event |
| `measure.fuh_measure_summary` | one row per ALL/FIXTURE/NON_FIXTURE scope |
| `measure.fuh_report_payer_monthly` | one row per month/payer/fixture scope |
| `measure.fuh_report_demographic` | one row per age-band/sex/fixture scope |
| `measure.fuh_report_followup_timing` | one row per timing-band/fixture scope |
| `measure.fuh_open_gap_detail` | one row per denominator event missing 7-day follow-up |

## Controlled acceptance result

```text
denominator = 40
7-day numerator = 18
30-day numerator = 32
7-day rate = 45.00%
30-day rate = 80.00%
```

## Main source tables

- `core.member`;
- `core.payer`;
- `core.enrollment_span`;
- `core.encounter`;
- `core.condition`;
- optional claim lineage from `core.claim`.

`core.claim_transaction` is not scanned for the implemented measure rule.

## Important limitations

The implementation uses project-owned encounter/diagnosis rules. It does not infer principal diagnosis, does not implement unsupported readmission logic, and does not claim licensed value sets or official HEDIS compliance.
