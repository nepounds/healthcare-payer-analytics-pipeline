# v0.2bigdaddy Quality Measure Methodology

## General design

Quality logic follows a reusable episode pattern:

```text
candidate event
→ eligibility
→ exclusions
→ denominator
→ candidate numerator events
→ first/required qualifying event(s)
→ episode result
→ summary
→ open gap
```

Project-defined reference tables hold distributable code groupings and metadata.

## FUH-style approximation

Carry forward the validated v0.1 methodology.

Public NCQA description:
- people age 6+;
- qualifying hospitalization context;
- 7-day follow-up rate;
- 30-day follow-up rate.

Reference:
https://www.ncqa.org/report-cards/health-plans/state-of-health-care-quality-report/follow-up-after-hospitalization-for-mental-illness-fuh/

The project must continue to label the implementation as an approximation and maintain its assumptions register.

## IET-style approximation

NCQA's public description defines two rates for new substance-use-disorder episodes:

- **Initiation:** treatment initiation within 14 days;
- **Engagement:** evidence of treatment engagement within 34 days after initiation.

Reference:
https://www.ncqa.org/report-cards/health-plans/state-of-health-care-quality-report/initiation-and-engagement-of-substance-use-disorder-treatment-iet/

### Proposed episode shape

```text
iet_episode_id
member_id
index_episode_date
sud_category
eligible_flag
exclusion_flag
first_initiation_date
days_to_initiation
initiation_flag
engagement_event_count
engagement_complete_date
engagement_flag
gap_status
```

### SQL skills exercised

IET naturally adds:

- episode de-duplication;
- `LAG` or window logic for identifying new episodes/gaps;
- multiple-event requirements;
- `ROW_NUMBER`;
- date-window logic;
- grouped event counting.

## Cross-measure conventions

All measures should share:

- a fixed analysis/as-of date;
- consistent member/date/provider keys;
- explicit assumption IDs;
- reproducible logic;
- episode-level auditability;
- source references;
- QA test cases.

## What not to do

Do not create a generic “HEDIS engine” in this portfolio project.

That would dramatically expand scope, invite licensing problems, and distract from the analyst skills the project is meant to demonstrate.
