# Quality Performance Milestone Data Dictionary

This document defines the logical and physical data model used by the first Quality Performance milestone.

For objects already implemented in SQL, the columns below reflect the committed physical schema. Objects not yet implemented remain proposed and may evolve before their DDL is committed. The grain of every object must remain explicit.

## `core.member`

**Status:** implemented.

**Grain:** one row per synthetic member.

| Column | Type | Purpose |
|---|---|---|
| `member_id` | `BIGINT` identity | internal surrogate member key |
| `source_patient_id` | `VARCHAR(64)` | Synthea/FUH-fixture patient identifier; unique in core |
| `birth_date` | `DATE` | typed date of birth |
| `deceased_date` | `DATE`, nullable | typed death date when present |
| `sex` | `CHAR(1)`, nullable | source F/M demographic value |
| `county_code` | `CHAR(5)`, nullable | five-character county FIPS code |
| `state_code` | `CHAR(2)`, nullable | normalized state code; `NC` for the modeled population |
| `synthetic_fixture_flag` | `BIT` | distinguishes controlled FUH fixture members from Synthea source members |
| `source_name` | `VARCHAR(50)` | source family such as `SYNTHEA` or `FUH_FIXTURE` |
| `pipeline_run_id` | `UNIQUEIDENTIFIER` | raw-load execution identifier used for lineage |
| `created_at_utc` | `DATETIME2(0)` | UTC core-row creation timestamp |

`source_patient_id` is unique. FUH flags do not belong on this table because FUH is episode-based, not member-based.

## `core.payer`

**Status:** implemented.

**Grain:** one row per source payer.

| Column | Type | Purpose |
|---|---|---|
| `payer_id` | `BIGINT` identity | internal surrogate payer key |
| `source_payer_id` | `VARCHAR(64)` | source payer identifier; unique in core |
| `payer_name` | `VARCHAR(100)` | source payer name |
| `ownership` | `VARCHAR(50)`, nullable | source ownership category |
| `source_name` | `VARCHAR(50)` | source family |
| `source_file` | `VARCHAR(255)` | source filename for direct payer lineage |
| `pipeline_run_id` | `UNIQUEIDENTIFIER` | raw-load execution identifier |
| `created_at_utc` | `DATETIME2(0)` | UTC core-row creation timestamp |

The payer table intentionally keeps only descriptive fields required by the current core model. Source financial/utilization aggregates remain in `raw.payer` until a later analytical domain needs them.

## `core.enrollment_span`

**Status:** implemented.

**Grain:** one row per continuous enrollment span for a member, payer, benefit configuration, and retained source-lineage partition.

| Column | Type | Purpose |
|---|---|---|
| `enrollment_span_id` | `BIGINT` identity | surrogate enrollment-span key |
| `member_id` | `BIGINT` | foreign key to `core.member` |
| `payer_id` | `BIGINT` | foreign key to `core.payer` |
| `enrollment_start_date` | `DATE` | first covered date in the normalized span |
| `enrollment_end_date` | `DATE` | last covered date in the normalized span |
| `medical_benefit_flag` | `BIT` | whether medical benefit coverage is modeled for the span |
| `behavioral_health_benefit_flag` | `BIT` | whether behavioral-health benefit coverage is modeled for the span |
| `synthetic_fixture_flag` | `BIT` | identifies controlled fixture-derived coverage |
| `source_name` | `VARCHAR(50)` | source family retained for lineage |
| `pipeline_run_id` | `UNIQUEIDENTIFIER` | raw-load execution identifier |
| `source_rows_merged` | `INT` | number of raw payer-transition rows represented by the normalized span |
| `created_at_utc` | `DATETIME2(0)` | UTC core-row creation timestamp |

The Phase 2 load uses `raw.payer_transition.PAYER` as the primary payer relationship. `SECONDARY_PAYER` is not yet promoted into the core enrollment model.

Overlapping and directly adjacent source coverage rows are merged with a gaps-and-islands algorithm using the **running maximum prior end date**. This handles nested overlaps correctly and allows `SUM(source_rows_merged)` to reconcile back to the raw payer-transition row count.

For the current Quality Performance milestone, assumption A-018 derives both benefit flags as `1` for Medicaid spans and `0` for other primary payer spans. This is an educational modeling approximation, not a representation of real benefit administration.

For FUH eligibility, the member must have uninterrupted enrollment with both required benefit flags equal to `1` from the discharge date through 30 days after discharge, with no allowable gap.

## `core.encounter`

**Grain:** one row per encounter.

Suggested columns:

| Column | Purpose |
|---|---|
| `encounter_id` | internal encounter key |
| `member_id` | member |
| `provider_id` | rendering/facility provider where available |
| `encounter_start_datetime` | encounter start |
| `encounter_end_datetime` | encounter end |
| `encounter_type` | inpatient, outpatient, ED, etc. |
| `place_of_service` | normalized setting |
| `principal_diagnosis_code` | convenient principal diagnosis field if source supports it |
| `source_encounter_id` | source identifier |

## `core.condition`

**Grain:** one row per source clinical condition/diagnosis record.

Suggested columns:

| Column | Purpose |
|---|---|
| `condition_id` | internal condition key |
| `member_id` | member foreign key |
| `encounter_id` | related encounter where available |
| `code_system` | diagnosis coding system, such as SNOMED-CT or ICD-10-CM |
| `diagnosis_code` | diagnosis code within the stated code system |
| `diagnosis_description` | source diagnosis description |
| `condition_start_date` | condition onset/start date where available |
| `condition_end_date` | condition resolution/end date where available |
| `source_condition_id` | source identifier where available |
| `synthetic_fixture_flag` | identifies controlled fixture records |
| `pipeline_run_id` | source pipeline execution identifier |

A diagnosis code must not be interpreted independently of `code_system`. Synthea clinical conditions primarily use SNOMED-CT, while the controlled FUH fixtures use ICD-10-CM.

## `core.claim`

**Grain:** one row per claim.

Suggested columns:

| Column | Purpose |
|---|---|
| `claim_id` | internal claim key |
| `member_id` | member |
| `provider_id` | billing/rendering/facility provider as modeled |
| `service_from_date` | earliest service date |
| `service_to_date` | latest service date |
| `adjudication_date` | optional for future expansion |
| `claim_status` | paid/denied/etc. if available |
| `total_billed_amount` | claim total |
| `total_allowed_amount` | allowed total |
| `total_paid_amount` | paid total |

v0.1 may use only a subset of these fields, but claim grain should be established correctly for later releases.

## `core.claim_line`

**Grain:** one row per service line within a claim.

Suggested columns:

| Column | Purpose |
|---|---|
| `claim_line_id` | internal line key |
| `claim_id` | parent claim |
| `line_number` | source line sequence |
| `service_date` | line service date |
| `procedure_code` | service/procedure code |
| `place_of_service` | line-level setting if available |
| `billed_amount` | line billed amount |
| `allowed_amount` | line allowed amount |
| `paid_amount` | line paid amount |
| `denial_reason_code` | optional future field |

## `core.claim_diagnosis`

**Grain:** one row per claim/diagnosis association.

Suggested columns:

| Column | Purpose |
|---|---|
| `claim_id` | parent claim |
| `diagnosis_sequence` | diagnosis order |
| `code_system` | coding system associated with the diagnosis code |
| `diagnosis_code` | diagnosis |
| `principal_flag` | whether principal diagnosis |
| `diagnosis_group_id` | optional normalized grouping |

## `core.provider`

**Grain:** one row per provider entity.

Suggested columns:

| Column | Purpose |
|---|---|
| `provider_id` | internal provider key |
| `source_provider_id` | source identifier |
| `provider_name` | synthetic provider name |
| `provider_type` | practitioner/facility/etc. |
| `specialty` | normalized specialty where available |
| `organization_id` | optional parent organization |

## `core.provider_location`

**Grain:** one row per provider-location combination.

Suggested columns:

| Column | Purpose |
|---|---|
| `provider_location_id` | key |
| `provider_id` | provider |
| `county_code` | NC county |
| `state_code` | state |
| `zip_code` | synthetic ZIP if retained |
| `active_start_date` | optional |
| `active_end_date` | optional |

## `ref.date`

**Grain:** one row per calendar date.

Suggested fields include date, month, quarter, year, month start/end, week, and other reporting attributes needed by Power BI.

## `ref.measure_value_set`

**Grain:** one row per project-defined measure/value-set/code relationship.

Suggested columns:

| Column | Purpose |
|---|---|
| `measure_id` | e.g. `FUH_APPROX` |
| `value_set_name` | project-defined grouping |
| `code_system` | ICD-10-CM, CPT, HCPCS, POS, etc. |
| `code` | code used by project |
| `effective_start_date` | optional |
| `effective_end_date` | optional |
| `source_note` | where the approximation came from |
| `licensed_spec_flag` | expected false for public project |

Do not represent this table as an official NCQA value set.

## `measure.fuh_episode_detail`

**Grain:** one row per **candidate FUH discharge episode**, before final denominator filtering.

This is the canonical column definition for the FUH audit table. Other project documents should link here instead of maintaining duplicate field lists.

The table retains candidate episodes that are later found ineligible or excluded so a reviewer can see **why an episode did or did not enter the denominator**.

| Column | Purpose |
|---|---|
| `episode_id` | stable identifier for the candidate discharge episode |
| `member_id` | member foreign key |
| `index_admission_date` | admission date for the candidate hospitalization |
| `index_discharge_date` | discharge date for the candidate hospitalization |
| `measurement_year` | reporting year assigned to the candidate discharge |
| `age_at_discharge` | member age on the discharge date |
| `diagnosis_group` | project-defined qualifying diagnosis grouping |
| `candidate_flag` | candidate discharge met the initial event-identification rule |
| `age_eligible_flag` | passed age requirement |
| `enrollment_eligible_flag` | passed continuous medical + behavioral-health coverage rule |
| `measurement_window_eligible_flag` | discharge falls within January 1–December 1 candidate window |
| `eligible_flag` | passed project eligibility requirements before exclusions |
| `exclusion_flag` | episode is excluded by a project-defined exclusion |
| `exclusion_reason` | human-readable reason/code for exclusion |
| `denominator_flag` | 1 only when the candidate is eligible and not excluded |
| `first_qualifying_followup_date` | earliest qualifying follow-up after discharge |
| `days_to_followup` | days from discharge to first qualifying follow-up |
| `fuh_7d_flag` | denominator episode met 7-day numerator |
| `fuh_30d_flag` | denominator episode met 30-day numerator |
| `seven_day_deadline` | discharge date + 7 days |
| `thirty_day_deadline` | discharge date + 30 days |
| `seven_day_gap_status` | complete/open/missed/not-applicable status |
| `thirty_day_gap_status` | complete/open/missed/not-applicable status |
| `days_remaining_7d` | days remaining in 7-day window as of configured analysis date |
| `days_remaining_30d` | days remaining in 30-day window as of configured analysis date |
| `assigned_provider_id` | provider attribution used for operational reporting when available |
| `member_county` | member county used for stratification |
| `synthetic_fixture_flag` | 1 when the episode was deliberately injected for controlled synthetic coverage/testing |
| `assumption_version` | version/tag tying the output to the documented rule set |
| `pipeline_run_id` | pipeline execution identifier for reproducibility |

### Rate calculation

FUH rates use only rows where:

```text
denominator_flag = 1
```

Excluded and otherwise ineligible candidate rows remain in this audit table but do not contribute to the denominator.

## `measure.fuh_summary`

**Grain:** one row per reporting period/stratification combination used by the report.

Possible dimensions:

- measurement year;
- month or quarter;
- county;
- age band;
- provider/facility where appropriate.

## `measure.fuh_open_gap`

**Grain:** one row per currently actionable follow-up gap.

This object may be a view over `fuh_episode_detail` rather than a physical table.
