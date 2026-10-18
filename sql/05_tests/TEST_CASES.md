# v0.1 Test Case Catalog

This file is the human-readable test catalog. Matching executable T-SQL tests will be added in this directory as measure logic is built.

Test IDs are referenced directly from `docs/assumptions_register.md`.

## Data / pipeline tests

| Test ID | Rule | Expected result |
|---|---|---|
| `T-DATA-001` | Synthetic population is the intended fictional NC Medicaid population | Population/profile checks pass |
| `T-DATA-002` | Provider relationships used for attribution are present and valid | No unexpected orphan attribution keys |
| `T-DATA-003` | FUH episode sufficiency check after initial load | At least 30 usable FUH denominator episodes per measurement year, or controlled fixture augmentation is triggered |
| `T-PIPE-001` | Fixed analysis date controls open-window calculations | Same source + same config produces same result across reruns |
| `T-SEC-001` | Repository contains synthetic data only and no committed secrets | Repository scan/check passes |
| `T-DOC-001` | Public documentation labels FUH as an educational approximation | Required disclaimer is present |
| `T-VAL-001` | Excel episode reconciliation agrees with SQL for controlled sample | No unexplained variance |
| `T-BI-001` | Power BI consumes SQL episode results rather than rebuilding eligibility | Semantic model contains presentation logic only |

## FUH denominator and numerator boundary tests

| Test ID | Scenario | Expected result |
|---|---|---|
| `T-FUH-001` | Qualifying follow-up occurs on the discharge date | Does **not** count for 7-day or 30-day numerator |
| `T-FUH-002` | First qualifying follow-up occurs 1 day after discharge | Counts for 7-day and 30-day numerator |
| `T-FUH-003` | First qualifying follow-up occurs 7 days after discharge | Counts for 7-day and 30-day numerator |
| `T-FUH-004` | First qualifying follow-up occurs 8 days after discharge | Fails 7-day; counts for 30-day |
| `T-FUH-005` | First qualifying follow-up occurs 30 days after discharge | Fails 7-day; counts for 30-day |
| `T-FUH-006` | First qualifying follow-up occurs 31 days after discharge | Fails both rates |
| `T-FUH-007` | Enrollment is continuous from discharge date through day 30 | Episode remains eligible |
| `T-FUH-008` | Acute readmission/direct transfer within 30 days for qualifying mental-health / self-harm diagnosis | Count only the last qualifying discharge |
| `T-FUH-009` | Acute readmission/direct transfer within 30 days for another principal diagnosis | Exclude the affected denominator episode(s) per project rule |
| `T-FUH-010` | Nonacute readmission/direct transfer within 30 days | Exclude affected discharge |
| `T-FUH-011` | Psychiatric residential treatment within 30-day window | Do not apply the nonacute exclusion solely because of psychiatric residential treatment |
| `T-FUH-012` | Multiple qualifying follow-up visits exist | Select the earliest qualifying post-discharge visit |
| `T-FUH-013` | Member is exactly age 6 on discharge date | Age-eligible |
| `T-FUH-014` | Member is under age 6 on discharge date | Not age-eligible |
| `T-FUH-015` | Discharge diagnosis is inside vs. outside project-defined mental-health code grouping | Only in-group qualifying diagnosis enters candidate denominator |
| `T-FUH-016` | Intentional self-harm diagnosis meets project-defined position/code rule | Candidate denominator treatment matches documented project rule |
| `T-FUH-017` | Follow-up service is inside vs. outside project-defined qualifying service set | Only qualifying service can close the gap |
| `T-FUH-018` | Member has a one-day enrollment gap between discharge and day 30 | Episode fails continuous-enrollment requirement |
| `T-FUH-019` | Controlled fixture rows are injected | All injected records are tagged `synthetic_fixture_flag = 1` and are reproducible |
| `T-FUH-020` | Same member has multiple independently eligible discharges in the measurement year | Each qualifying candidate discharge is retained as its own episode; each denominator-eligible discharge can contribute separately |
| `T-FUH-021` | Candidate discharge occurs on December 1 | Episode remains eligible for denominator evaluation, subject to all other rules |
| `T-FUH-022` | Candidate discharge occurs after December 1, or qualifying readmission moves the last discharge after December 1 | Episode/affected discharge sequence is excluded from the measurement-year denominator |

## Planned executable SQL files

```text
001_test_same_day_followup.sql
002_test_followup_windows.sql
003_test_continuous_enrollment.sql
004_test_readmissions_transfers.sql
005_test_age_boundary.sql
006_test_first_followup.sql
007_test_episode_sufficiency.sql
008_test_multiple_episodes.sql
009_test_measurement_year_cutoff.sql
```

The filenames may evolve. The stable identifiers are the `T-*` IDs above.
