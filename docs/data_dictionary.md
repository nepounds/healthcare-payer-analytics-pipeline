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

## `core.organization`

**Status:** implemented.

**Grain:** one row per source organization/facility.

| Column | Type | Purpose |
|---|---|---|
| `organization_id` | `BIGINT` identity | internal surrogate organization key |
| `source_organization_id` | `VARCHAR(64)` | source organization identifier; unique in core |
| `organization_name` | `VARCHAR(512)` | source organization/facility name |
| `npi` | `VARCHAR(20)`, nullable | source NPI where present |
| `address_line` | `VARCHAR(512)`, nullable | source street address |
| `city` | `VARCHAR(255)`, nullable | source city |
| `state_code` | `CHAR(2)`, nullable | normalized source state code |
| `zip_code` | `VARCHAR(20)`, nullable | source ZIP/postal value |
| `latitude` | `DECIMAL(9,6)`, nullable | source latitude with range constraint |
| `longitude` | `DECIMAL(9,6)`, nullable | source longitude with range constraint |
| `synthetic_fixture_flag` | `BIT` | controlled-fixture lineage flag |
| `source_name` | `VARCHAR(50)` | source family |
| `source_file` | `VARCHAR(255)` | source filename |
| `pipeline_run_id` | `UNIQUEIDENTIFIER` | raw-load execution identifier |
| `created_at_utc` | `DATETIME2(0)` | UTC core-row creation timestamp |

Source organization utilization and revenue aggregates remain in `raw.organization`; they are not duplicated into the relational network entity.

## `core.provider`

**Status:** implemented.

**Grain:** one row per source clinician/provider.

| Column | Type | Purpose |
|---|---|---|
| `provider_id` | `BIGINT` identity | internal surrogate provider key |
| `source_provider_id` | `VARCHAR(64)` | source provider identifier; unique in core |
| `organization_id` | `BIGINT` | foreign key to `core.organization` |
| `provider_name` | `VARCHAR(512)` | source provider name |
| `sex` | `CHAR(1)`, nullable | source F/M value where present |
| `specialty` | `VARCHAR(255)`, nullable | source provider specialty |
| `npi` | `VARCHAR(20)`, nullable | source NPI where present |
| `synthetic_fixture_flag` | `BIT` | controlled-fixture lineage flag |
| `source_name` | `VARCHAR(50)` | source family |
| `source_file` | `VARCHAR(255)` | source filename |
| `pipeline_run_id` | `UNIQUEIDENTIFIER` | raw-load execution identifier |
| `created_at_utc` | `DATETIME2(0)` | UTC core-row creation timestamp |

A separate `core.provider_location` table is not implemented in Phase 2. The current source exposes a provider-to-organization relationship, and organization carries the location attributes needed by the Quality Performance milestone.

## `core.encounter`

**Status:** implemented.

**Grain:** one row per source encounter.

| Column | Type | Purpose |
|---|---|---|
| `encounter_id` | `BIGINT` identity | internal surrogate encounter key |
| `source_encounter_id` | `VARCHAR(64)` | source encounter identifier; unique in core |
| `member_id` | `BIGINT` | required foreign key to `core.member` |
| `organization_id` | `BIGINT`, nullable | facility/organization foreign key where supplied |
| `provider_id` | `BIGINT`, nullable | rendering clinician/provider foreign key where supplied |
| `payer_id` | `BIGINT`, nullable | encounter payer foreign key where supplied |
| `encounter_start_datetime` | `DATETIME2(0)` | normalized encounter start timestamp |
| `encounter_end_datetime` | `DATETIME2(0)` | normalized encounter end timestamp |
| `encounter_type` | `VARCHAR(128)` | source encounter class such as inpatient, ambulatory, or emergency |
| `encounter_code` | `VARCHAR(255)`, nullable | source encounter code |
| `encounter_description` | `VARCHAR(2000)`, nullable | source encounter description |
| `reason_code` | `VARCHAR(255)`, nullable | source reason code; not relabeled as principal diagnosis |
| `reason_description` | `VARCHAR(2000)`, nullable | source reason description |
| `base_encounter_cost` | `DECIMAL(19,2)`, nullable | typed source base encounter cost |
| `total_claim_cost` | `DECIMAL(19,2)`, nullable | typed source total claim cost |
| `payer_coverage` | `DECIMAL(19,2)`, nullable | typed source payer coverage |
| `synthetic_fixture_flag` | `BIT` | controlled-fixture lineage flag |
| `source_name` | `VARCHAR(50)` | source family |
| `source_file` | `VARCHAR(255)` | source filename |
| `pipeline_run_id` | `UNIQUEIDENTIFIER` | raw-load execution identifier |
| `created_at_utc` | `DATETIME2(0)` | UTC core-row creation timestamp |

`REASONCODE` is preserved as a source reason code because the source does not establish principal-diagnosis semantics. Encounter chronology is constrained so end cannot precede start.

## `core.condition`

**Status:** implemented.

**Grain:** one row per source clinical condition/diagnosis record.

| Column | Type | Purpose |
|---|---|---|
| `condition_id` | `BIGINT` identity | internal surrogate condition key |
| `member_id` | `BIGINT` | required foreign key to `core.member` |
| `encounter_id` | `BIGINT`, nullable | foreign key to `core.encounter` where the source supplies an encounter |
| `code_system` | `VARCHAR(255)` | diagnosis coding system |
| `diagnosis_code` | `VARCHAR(255)` | diagnosis code within the stated system |
| `diagnosis_description` | `VARCHAR(2000)`, nullable | source diagnosis description |
| `condition_start_date` | `DATE` | source condition start/onset date |
| `condition_end_date` | `DATE`, nullable | source condition end/resolution date where present |
| `synthetic_fixture_flag` | `BIT` | controlled-fixture lineage flag |
| `source_name` | `VARCHAR(50)` | source family |
| `source_file` | `VARCHAR(255)` | source filename |
| `pipeline_run_id` | `UNIQUEIDENTIFIER` | raw-load execution identifier |
| `created_at_utc` | `DATETIME2(0)` | UTC core-row creation timestamp |

The raw condition export does not contain a condition identifier, so `condition_id` is a core surrogate rather than a wrapper around a nonexistent source key. Duplicate source condition rows are preserved. A diagnosis code must not be interpreted independently of `code_system`; ordinary Synthea conditions are SNOMED-CT in the current source while controlled FUH fixtures are ICD-10-CM.

## `core.claim`

**Status:** implemented.

**Grain:** one row per source claim.

| Column | Type | Purpose |
|---|---|---|
| `claim_id` | `BIGINT` identity | internal surrogate claim key |
| `source_claim_id` | `VARCHAR(64)` | source claim identifier; unique in core |
| `member_id` | `BIGINT` | required foreign key to `core.member` |
| `encounter_id` | `BIGINT` | required foreign key to `core.encounter` |
| `rendering_provider_id` | `BIGINT`, nullable | rendering provider relationship where supplied |
| `referring_provider_id` | `BIGINT`, nullable | referring provider relationship where supplied |
| `supervising_provider_id` | `BIGINT`, nullable | supervising provider relationship where supplied |
| `primary_payer_id` | `BIGINT`, nullable | primary payer relationship where supplied |
| `secondary_payer_id` | `BIGINT`, nullable | secondary payer relationship where supplied |
| `service_date` | `DATE` | source claim service date |
| `current_illness_date` | `DATE`, nullable | typed source current-illness date |
| `department_id` | `VARCHAR(64)`, nullable | source department identifier |
| `patient_department_id` | `VARCHAR(64)`, nullable | source patient-department identifier |
| `primary_status` | `VARCHAR(128)`, nullable | source primary-claim status |
| `secondary_status` | `VARCHAR(128)`, nullable | source secondary-claim status |
| `patient_status` | `VARCHAR(128)`, nullable | source patient-responsibility status |
| `primary_outstanding_amount` | `DECIMAL(19,2)`, nullable | source primary outstanding amount |
| `secondary_outstanding_amount` | `DECIMAL(19,2)`, nullable | source secondary outstanding amount |
| `patient_outstanding_amount` | `DECIMAL(19,2)`, nullable | source patient outstanding amount |
| `primary_last_billed_date` | `DATE`, nullable | source primary last-billed date |
| `secondary_last_billed_date` | `DATE`, nullable | source secondary last-billed date |
| `patient_last_billed_date` | `DATE`, nullable | source patient last-billed date |
| `primary_healthcare_claim_type_id` | `VARCHAR(64)`, nullable | source primary claim-type identifier |
| `secondary_healthcare_claim_type_id` | `VARCHAR(64)`, nullable | source secondary claim-type identifier |
| `synthetic_fixture_flag` | `BIT` | controlled-fixture lineage flag |
| `source_name` | `VARCHAR(50)` | source family |
| `source_file` | `VARCHAR(255)` | source filename |
| `pipeline_run_id` | `UNIQUEIDENTIFIER` | raw-load execution identifier |
| `created_at_utc` | `DATETIME2(0)` | UTC core-row creation timestamp |

Phase 2 does not invent claim-level billed, allowed, or paid totals. The source exposes those financial events at transaction grain, so the claim header preserves only fields actually supported by the claim export.

## `core.claim_diagnosis`

**Status:** implemented.

**Grain:** one row per populated diagnosis position on a source claim.

| Column | Type | Purpose |
|---|---|---|
| `claim_diagnosis_id` | `BIGINT` identity | internal surrogate claim-diagnosis key |
| `claim_id` | `BIGINT` | required foreign key to `core.claim` |
| `diagnosis_sequence` | `TINYINT` | source diagnosis position 1 through 8 |
| `diagnosis_code` | `VARCHAR(255)` | source diagnosis code |
| `synthetic_fixture_flag` | `BIT` | controlled-fixture lineage inherited from the claim |
| `source_name` | `VARCHAR(50)` | source family |
| `source_file` | `VARCHAR(255)` | source filename |
| `pipeline_run_id` | `UNIQUEIDENTIFIER` | raw-load execution identifier |
| `created_at_utc` | `DATETIME2(0)` | UTC core-row creation timestamp |

The claim export does not identify the diagnosis coding system, so Phase 2 does not assign one. Position 1 is not labeled as principal diagnosis. Sequence is retained because transaction diagnosis-reference fields point to claim diagnosis positions.

## `core.claim_transaction`

**Status:** implemented.

**Grain:** one row per source claim-transaction record.

| Column | Type | Purpose |
|---|---|---|
| `claim_transaction_id` | `BIGINT` identity | internal surrogate transaction key |
| `source_transaction_id` | `VARCHAR(64)` | source transaction identifier; unique in core |
| `source_charge_id` | `VARCHAR(64)`, nullable | source CHARGEID preserved as an opaque related identifier, not a line number |
| `claim_id` | `BIGINT` | required foreign key to `core.claim` |
| `member_id` | `BIGINT` | required foreign key to `core.member` |
| `encounter_id` | `BIGINT`, nullable | transaction encounter relationship where supplied |
| `provider_id` | `BIGINT`, nullable | transaction provider relationship where supplied |
| `supervising_provider_id` | `BIGINT`, nullable | supervising-provider relationship where supplied |
| `source_patient_insurance_id` | `VARCHAR(64)`, nullable | raw `PATIENTINSURANCEID` preserved without a payer/enrollment FK |
| `place_organization_id` | `BIGINT`, nullable | organization FK only when `source_place_value` resolves to a known organization |
| `transaction_type` | `VARCHAR(128)` | source financial event type |
| `amount` | `DECIMAL(19,2)`, nullable | source transaction amount |
| `method` | `VARCHAR(128)`, nullable | source payment/adjustment method |
| `service_from_date` | `DATE` | typed source service start date |
| `service_to_date` | `DATE`, nullable | typed valid service end date; documented invalid end dates normalize to `NULL` |
| `source_place_value` | `VARCHAR(128)`, nullable | raw `PLACEOFSERVICE` value preserved because source semantics are mixed |
| `procedure_code` | `VARCHAR(255)`, nullable | source procedure/service code |
| `modifier_1` | `VARCHAR(128)`, nullable | source first modifier |
| `modifier_2` | `VARCHAR(128)`, nullable | source second modifier |
| `diagnosis_reference_1` | `TINYINT`, nullable | ordinal reference to claim diagnosis position 1-8 |
| `diagnosis_reference_2` | `TINYINT`, nullable | ordinal reference to claim diagnosis position 1-8 |
| `diagnosis_reference_3` | `TINYINT`, nullable | ordinal reference to claim diagnosis position 1-8 |
| `diagnosis_reference_4` | `TINYINT`, nullable | ordinal reference to claim diagnosis position 1-8 |
| `units` | `INT`, nullable | source units |
| `department_id` | `VARCHAR(64)`, nullable | source department identifier |
| `notes` | `VARCHAR(2000)`, nullable | source transaction notes/description |
| `unit_amount` | `DECIMAL(19,2)`, nullable | source unit amount |
| `transfer_out_id` | `VARCHAR(64)`, nullable | source transfer-out reference |
| `transfer_type` | `VARCHAR(128)`, nullable | source transfer category |
| `payments` | `DECIMAL(19,2)`, nullable | source payment amount |
| `adjustments` | `DECIMAL(19,2)`, nullable | source adjustment amount |
| `transfers` | `DECIMAL(19,2)`, nullable | source transfer amount |
| `outstanding` | `DECIMAL(19,2)`, nullable | source outstanding amount |
| `line_note` | `VARCHAR(2000)`, nullable | source line note |
| `fee_schedule_id` | `VARCHAR(64)`, nullable | source fee-schedule identifier |
| `synthetic_fixture_flag` | `BIT` | controlled-fixture lineage flag |
| `source_name` | `VARCHAR(50)` | source family |
| `source_file` | `VARCHAR(255)` | source filename |
| `pipeline_run_id` | `UNIQUEIDENTIFIER` | raw-load execution identifier |
| `created_at_utc` | `DATETIME2(0)` | UTC core-row creation timestamp |

There is no separate Phase 2 `core.claim_line`. The source is transaction/event-grained, and `CHARGEID` is not treated as a stable service-line sequence. This keeps claim-level analysis practical without fabricating a line grain.

`raw.claim_transaction.PLACEOFSERVICE` has mixed semantics in the combined source package. Ordinary Synthea rows use organization resource identifiers, while controlled FUH fixture transactions use POS-style values such as `11` and `21`. Core therefore preserves the raw value in `source_place_value` and populates `place_organization_id` only when the value resolves to `core.organization`.

`raw.claim_transaction.PATIENTINSURANCEID` is also retained as source lineage rather than promoted to a payer or enrollment foreign key. The actual payer relationships used by the current core model live on `core.claim`.

Source transaction end dates equal to `1970-01-01` or earlier than the corresponding service start date are normalized to `NULL`; unparseable dates still fail the load. The raw record remains available through `source_transaction_id` for audit.

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
