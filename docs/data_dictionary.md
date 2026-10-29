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

`raw.claim_transaction.PATIENTINSURANCEID` is retained as source lineage rather than promoted to a payer or enrollment foreign key. Synthea v4.0.0 writes a plan-record/member-like source identifier in this field, but the authoritative combined source does not support a universal relational FK and controlled fixtures use the field differently. The payer relationships used by current analytics therefore come from `core.claim` and `core.enrollment_span`.

Source transaction end dates equal to `1970-01-01` or earlier than the corresponding service start date are normalized to `NULL`; unparseable dates still fail the load. The raw record remains available through `source_transaction_id` for audit.

## `ref.measure_definition`

**Status:** implemented.

**Grain:** one row per configured measure/methodology definition.

| Column | Purpose |
|---|---|
| `measure_id` | stable measure identifier; current value `FUH_STYLE_MY2025` |
| `measure_name` | descriptive portfolio measure name |
| `measurement_year` | configured measurement year |
| `analysis_date` | fixed reproducibility/as-of date |
| `methodology_version` | documented rules version |
| `hedis_oriented_flag` | 1 for the current HEDIS-oriented portfolio measure |
| `official_hedis_flag` | constrained to 0 |
| `active_flag` | active configuration indicator |
| `source_note` | limitation/source note |
| `created_at_utc`, `updated_at_utc` | configuration audit timestamps |

## `ref.measure_value_set`

**Status:** implemented.

**Grain:** one row per project-defined measure/reference rule.

| Column | Purpose |
|---|---|
| `measure_value_set_id` | surrogate rule key |
| `measure_id` | FK to `ref.measure_definition` |
| `value_set_name` | rule group such as index type, follow-up type, BH diagnosis |
| `code_system` | source semantic/coding-system label |
| `code_value` | project-owned match value |
| `match_type` | `EXACT` or `PREFIX` |
| `effective_start_date`, `effective_end_date` | optional rule-effective dates |
| `source_note` | project rule/source explanation |
| `licensed_spec_flag` | constrained to 0 |
| `active_flag` | active-rule indicator |

Current seeded rules: inpatient index encounter, project-owned ICD-10-CM behavioral-health prefixes `F0` and `F2`–`F9` (excluding `F10`–`F19`), and ambulatory/outpatient follow-up encounter types.

These rows are not official NCQA value sets.

## `measure.fuh_index_event_detail`

**Status:** implemented view.

**Grain:** one row per candidate inpatient behavioral-health index encounter/discharge.

Key fields include:

- measure/methodology/year/analysis-date configuration;
- index event/member/encounter/optional claim identifiers;
- admission/discharge dates and 7-/30-day deadlines;
- typed diagnosis evidence from `core.condition`;
- encounter payer and matched enrollment span;
- medical/BH benefit flags;
- organization/provider/member demographic context;
- `candidate_flag`, age/window/enrollment eligibility flags, final `eligibility_flag`;
- `ineligibility_reason`;
- fixture and source/pipeline lineage.

Eligibility requires age 6+, discharge January 1–December 1, and a payer-matched continuous enrollment span covering discharge through day 30 with both benefit flags = 1.

## `measure.fuh_followup_event_detail`

**Status:** implemented view.

**Grain:** one row per eligible index event / qualifying follow-up encounter pair in day 0 through day 30.

Key fields include:

- index/member identifiers and deadlines;
- follow-up encounter and optional claim identifiers;
- follow-up date/time/type;
- typed diagnosis evidence;
- qualification source;
- `days_from_index`;
- `same_day_followup_flag`;
- `qualifies_7d_flag`;
- `qualifies_30d_flag`;
- index/follow-up payer/provider/organization context;
- fixture/source/pipeline lineage.

Day 0 remains visible for audit but cannot receive numerator credit.

## `measure.fuh_measure_result`

**Status:** implemented view.

**Grain:** one row per final denominator event.

Key fields include:

- index/member/claim/encounter identifiers;
- index discharge date;
- payer/enrollment/provider/organization/demographic dimensions;
- `denominator_flag`;
- first deterministic 7-day qualifying follow-up identifiers/date and `days_to_7d_followup`;
- `numerator_7d_flag`;
- first deterministic 30-day qualifying follow-up identifiers/date and `days_to_30d_followup`;
- `days_to_first_qualifying_followup`;
- `numerator_30d_flag`;
- fixture/source/pipeline lineage.

Only `fuh_index_event_detail` rows with `eligibility_flag = 1` enter this view.

## `measure.fuh_measure_summary`

**Status:** implemented view.

**Grain:** one row per population scope: `ALL`, `FIXTURE`, `NON_FIXTURE`.

Columns:

- measure/methodology/year/analysis date;
- population scope;
- denominator;
- 7-day numerator;
- 30-day numerator;
- 7-day percentage rate;
- 30-day percentage rate.

A zero denominator returns `NULL` for rates.

Controlled fixture expectation: 40 denominator, 18 seven-day numerator, 32 thirty-day numerator, 45.00% and 80.00%.

## `measure.fuh_report_payer_monthly`

**Status:** implemented view.

**Grain:** one row per measurement year / discharge month / payer / fixture scope.

Outputs denominator/numerators, rates, and average days to qualifying 30-day follow-up.

## `measure.fuh_report_demographic`

**Status:** implemented view.

**Grain:** one row per measurement year / age band / sex group / fixture scope.

Outputs denominator/numerators and rates.

## `measure.fuh_report_followup_timing`

**Status:** implemented view.

**Grain:** one row per measurement year / timing band / fixture scope.

Timing bands:

- `01_DAY_1_7`;
- `02_DAY_8_14`;
- `03_DAY_15_30`;
- `04_NO_30D_FOLLOWUP`.

Outputs episode count, percent of denominator, and average follow-up timing where applicable.

## `measure.fuh_open_gap_detail`

**Status:** implemented view.

**Grain:** one row per denominator event that missed the 7-day numerator.

`gap_status` is:

- `MISSED_7D_MET_30D`; or
- `MISSED_30D`.

The view retains member/index/payer/demographic/source lineage for audit and quality-improvement-oriented follow-up analysis.

## Measure-layer limitation

The measure layer does not implement principal-diagnosis-dependent readmission exclusions, official licensed value sets, pharmacy integration, physical-health integration, disability/cultural-factor analysis, or regulatory submission logic. Those capabilities are not supported by the current v0.1 source/specification package and are not manufactured in this portfolio layer.
