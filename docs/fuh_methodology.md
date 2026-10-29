# v0.1 FUH-Style Measure Methodology

## Important limitation

This project does **not** implement or reproduce the licensed NCQA HEDIS FUH technical specification.

It implements a transparent FUH-style/HEDIS-oriented behavioral-health follow-up performance measure for portfolio demonstration using synthetic data, project-owned rule sets, and explicitly documented assumptions.

Do not describe the output as certified HEDIS, official NCQA FUH, or regulatory-submission ready.

## Implemented measurement configuration

- measure ID: `FUH_STYLE_MY2025`;
- measurement year: 2025;
- fixed analysis date: 2026-10-18;
- methodology version: `v0.1`;
- official HEDIS flag: false.

Configuration lives in `ref.measure_definition` and `ref.measure_value_set`.

## Implemented architecture

The measure is intentionally split into auditable grains:

```text
measure.fuh_index_event_detail
        -> measure.fuh_followup_event_detail
        -> measure.fuh_measure_result
        -> measure.fuh_measure_summary
        -> reporting views / open-gap detail
```

A single giant measure query is intentionally avoided.

## Index-event qualification

`measure.fuh_index_event_detail` has one row per candidate inpatient behavioral-health index encounter/discharge.

A candidate requires:

- source encounter type matching the project-owned inpatient rule;
- at least one linked `core.condition` matching the project-owned behavioral-health diagnosis rule;
- diagnosis evidence from a typed `core.condition.code_system`.

The current public-portfolio diagnosis proxy uses ICD-10-CM prefixes `F0` and `F2`–`F9`. The `F1x` block (`F10`–`F19`) is excluded so substance-use disorders are not swept into this FUH-style proxy. The remaining rule is still deliberately broad and is **not** represented as an official NCQA FUH value set.

The project does not infer principal diagnosis from `core.claim_diagnosis` position 1 or from encounter reason fields.

## Eligibility

A candidate is eligible when:

- age is 6 or older on discharge;
- discharge occurs January 1 through December 1 of measurement year 2025;
- the encounter payer is present;
- one `core.enrollment_span` for that member/payer covers the discharge date through day 30 without a gap;
- medical and behavioral-health benefit flags are both 1.

The index-event view retains auditable eligibility flags, the matched enrollment span, and an ineligibility reason.

## Follow-up qualification

`measure.fuh_followup_event_detail` has one row per eligible index-event / qualifying follow-up encounter pair from day 0 through day 30.

A follow-up requires:

- project-owned encounter type of `ambulatory` or `outpatient`;
- linked behavioral-health diagnosis evidence matching the typed project-owned diagnosis rule;
- same member as the index event.

`core.claim` is retained only as optional lineage. `core.claim_transaction` is not required for qualification.

## Follow-up windows

- day 0: visible for audit, does not count;
- days 1–7: qualifies for both 7-day and 30-day numerator;
- days 8–30: qualifies for 30-day numerator only;
- day 31+: outside the measure window.

This implements documented assumption A-015 for same-day handling.

## Final event-level result

`measure.fuh_measure_result` has one row per eligible denominator event.

For each window, the first qualifying follow-up is selected deterministically by follow-up date/time and encounter ID. Multiple qualifying services therefore cannot inflate the numerator.

## Aggregate result

`measure.fuh_measure_summary` reports:

- denominator;
- 7-day numerator;
- 30-day numerator;
- 7-day rate;
- 30-day rate;

for `ALL`, `FIXTURE`, and `NON_FIXTURE` scopes. A zero denominator returns a `NULL` rate.

Controlled-fixture acceptance result:

```text
denominator = 40
7-day numerator = 18
30-day numerator = 32
7-day rate = 45.00%
30-day rate = 80.00%
```

## Analytical reporting

The measure layer also exposes:

- payer/month performance and volume;
- age-band/sex performance structures;
- follow-up timing distributions;
- open 7-day/30-day gap detail.

These outputs support quality-improvement analysis by identifying timing gaps and lower-performing slices. They do not claim that an intervention was implemented or that patient outcomes improved.

## Current limitations

The v0.1 implementation does not separately implement:

- licensed NCQA value sets;
- official principal-diagnosis semantics;
- readmission/transfer exclusion logic that depends on principal diagnosis;
- a distinct intentional-self-harm value set;
- pharmacy utilization;
- physical-health integration;
- disability/cultural-factor analysis.

The deterministic fixtures exist to exercise measure mechanics, not to represent epidemiology or real payer disparities. Current fixture subgroup/payer differences should not be interpreted as real-world performance findings.

## Validation

Executable Phase 3 QA lives in `sql/05_tests/`:

```text
004_validate_fuh_index.sql
005_validate_fuh_measure.sql
006_validate_fuh_reporting.sql
007_validate_phase3_closeout.sql
```

The human-readable test catalog is `sql/05_tests/TEST_CASES.md`.
