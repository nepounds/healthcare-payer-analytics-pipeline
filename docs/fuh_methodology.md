# v0.1 FUH-Style Measure Methodology

## Important limitation

This project does **not** implement or reproduce the licensed HEDIS FUH technical specification.

It implements a transparent educational approximation using:

- publicly available NCQA measure descriptions;
- public source documentation;
- synthetic data;
- explicitly documented project assumptions.

NCQA's public FUH description states that the measure concerns discharges for persons age 6 and older who were hospitalized with a principal diagnosis of mental illness or any diagnosis of intentional self-harm and reports follow-up within 30 days and within 7 days.

Public reference:
https://www.ncqa.org/report-cards/health-plans/state-of-health-care-quality-report/follow-up-after-hospitalization-for-mental-illness-fuh/

## Analytical grain

FUH is modeled at the **candidate discharge episode** level for auditability.

`measure.fuh_episode_detail` keeps one row for every candidate discharge identified by the project logic, including candidates later found ineligible or excluded. `denominator_flag = 1` identifies the episodes used in the reported rate.

A member may contribute more than one eligible denominator episode when the documented rules permit it.

The authoritative field list and grain definition live in [`data_dictionary.md`](data_dictionary.md#measurefuh_episode_detail).

## Proposed SQL structure

The implementation should remain readable enough to walk through during an interview.

Recommended shape:

```sql
WITH candidate_discharges AS (
    -- Identify possible inpatient behavioral-health discharges
),
age_eligible AS (
    -- Apply project age rule
),
enrollment_eligible AS (
    -- Apply documented enrollment assumption
),
excluded_episodes AS (
    -- Apply project exclusions
),
denominator AS (
    -- Final eligible denominator episodes
),
candidate_followups AS (
    -- Find possible post-discharge follow-up services
),
ranked_followups AS (
    -- ROW_NUMBER() to select the first qualifying follow-up
),
episode_results AS (
    -- Calculate days-to-follow-up and numerator flags
)
SELECT ...
```

A giant monolithic query is specifically discouraged.

## v0.1 rule authority

The implemented v0.1 boundary and eligibility rules are maintained in [`assumptions_register.md`](assumptions_register.md).

Important locked rules include:

- A-009 — continuous medical and behavioral-health enrollment from discharge through day 30, with no gap;
- A-010 — explicit readmission/direct-transfer handling;
- A-015 — follow-up on the discharge date does not count;
- A-017 — candidate discharges occur January 1 through December 1 of the measurement year, with special handling when a readmission/transfer moves the last discharge past December 1.

Do not restate or independently “choose” these rules in this methodology file. If a rule changes, update the assumptions register first.

## Episode audit output

`measure.fuh_episode_detail` is the project’s auditable candidate-episode table.

Its **only canonical column definition** is in [`data_dictionary.md`](data_dictionary.md#measurefuh_episode_detail).

The reported denominator is the subset where `denominator_flag = 1`. Excluded and ineligible candidates remain in the audit table with their flags/reasons populated.

## Validation requirements

The stable test catalog is [`../sql/05_tests/TEST_CASES.md`](../sql/05_tests/TEST_CASES.md).

Do not maintain a separate numbered validation list here. The test catalog is the source of truth for boundary cases and is linked directly from the assumptions register.
