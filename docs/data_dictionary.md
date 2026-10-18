# v0.1 Data Dictionary

This document defines the minimum logical data model required for the FUH release. Physical column names may evolve during implementation, but the grain of each table should remain explicit.

## `core.member`

**Grain:** one row per synthetic member.

Suggested columns:

| Column | Purpose |
|---|---|
| `member_id` | stable internal member identifier |
| `source_patient_id` | source-system identifier |
| `birth_date` | date of birth |
| `sex` | source demographic field |
| `county_code` | member geography |
| `state_code` | expected to be NC for modeled population |
| `deceased_date` | optional synthetic source field |
| `created_at` | pipeline metadata |

Do not place FUH flags on this table. FUH is episode-based, not member-based.

## `core.enrollment_span`

**Grain:** one row per uninterrupted enrollment span per member for a consistent benefit package.

Suggested columns:

| Column | Purpose |
|---|---|
| `enrollment_span_id` | surrogate key |
| `member_id` | member foreign key |
| `coverage_start_date` | first covered date |
| `coverage_end_date` | last covered date |
| `product_line` | Medicaid in v0.1 |
| `plan_id` | fictional plan identifier |
| `medical_benefit_flag` | member has medical coverage during the span |
| `behavioral_health_benefit_flag` | member has mental/behavioral-health coverage during the span |

For v0.1 FUH eligibility, the member must have uninterrupted enrollment with both required benefit flags equal to 1 from the discharge date through 30 days after discharge, with no allowable gap.

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
