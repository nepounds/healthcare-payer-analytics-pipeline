# v0.2bigdaddy Data Model

## Shared core entities

### Member and enrollment

- `core.member` — one row per member
- `core.enrollment_span` — one row per uninterrupted coverage span
- `core.member_provider_assignment` — one row per member/provider attribution span if implemented

### Claims and encounters

- `core.claim` — one row per claim
- `core.claim_line` — one row per claim line
- `core.claim_diagnosis` — one row per claim/diagnosis
- `core.encounter` — one row per clinical encounter
- `core.authorization` — optional, only if source data support a useful use case

### Providers and geography

- `core.provider` — one row per provider
- `core.provider_location` — one row per provider/location
- `core.organization` — one row per facility/organization where useful

### Finance

- `core.member_month` — one row per member per covered month
- `core.budget` — one row per budget period/category combination
- service-category mappings in `ref`

`core.member_month` becomes particularly important for PMPM and rate denominators.

## Shared reference entities

Recommended:

- `ref.date`
- `ref.county`
- `ref.service_category`
- `ref.place_of_service`
- `ref.denial_reason`
- `ref.diagnosis_group`
- `ref.procedure_group`
- `ref.measure_definition`
- `ref.measure_value_set`
- `ref.metric_definition`

## Quality outputs

- `measure.fuh_episode_detail`
- `measure.fuh_summary`
- `measure.fuh_open_gap`
- `measure.iet_episode_detail`
- `measure.iet_summary`
- `measure.iet_open_gap` where meaningful

## Report marts

### `mart.fact_quality_episode`

**Grain:** one quality-measure episode.

Related dimensions:

- `mart.dim_member`
- `mart.dim_date`
- `mart.dim_measure`
- `mart.dim_provider`
- `mart.dim_county`

### `mart.fact_claim`

**Grain:** one claim or one claim line depending on report design. If both are needed, use separate fact tables rather than mixing grains.

Metrics may include:

- billed;
- allowed;
- paid;
- denied;
- adjudication days;
- clean-claim indicators.

### `mart.fact_member_month`

**Grain:** one enrolled member-month.

Supports:

- PMPM;
- member-month denominators;
- rate normalization;
- finance trends.

### `mart.fact_utilization`

**Grain:** one service-category/time/geography aggregation or a clearly defined event-level fact.

Supports utilization per thousand and service mix.

### `mart.fact_network_access`

**Grain:** define explicitly before implementation. Candidate design is county/specialty/month with provider supply and covered-member demand.

Do not combine provider-level and county-level grains in one table without a clear reason.

## Grain rule

Every table in the repository must state its grain in its documentation.

If a developer cannot answer “what does one row represent?” the object is not ready for use.
