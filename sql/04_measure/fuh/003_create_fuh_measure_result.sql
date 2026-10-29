/*
Healthcare Payer Analytics Pipeline
Phase 3 - FUH-style final event-level measure result

Object:
- measure.fuh_measure_result (view)

Grain:
- One row per final denominator event.

Design:
- denominator = eligible rows from measure.fuh_index_event_detail;
- 7-day and 30-day numerator credit is selected from
  measure.fuh_followup_event_detail;
- multiple qualifying services cannot inflate the numerator because TOP (1) selects
  the earliest qualifying event in each window using a deterministic tie-breaker;
- same-day services cannot be selected because their numerator flags are zero.
*/

USE HealthcarePayerAnalytics;
GO

CREATE OR ALTER VIEW measure.fuh_measure_result
AS
SELECT
    idx.measure_id,
    idx.methodology_version,
    idx.measurement_year,
    idx.analysis_date,

    idx.index_event_id,
    idx.member_id,
    idx.source_member_id,
    idx.index_encounter_id,
    idx.source_index_encounter_id,
    idx.index_claim_id,
    idx.source_index_claim_id,
    idx.index_admission_datetime,
    idx.index_discharge_datetime,
    idx.index_discharge_date,

    idx.encounter_payer_id AS payer_id,
    idx.encounter_payer_name AS payer_name,
    idx.enrollment_span_id,
    idx.organization_id AS index_organization_id,
    idx.provider_id AS index_provider_id,
    idx.sex,
    idx.county_code,
    idx.age_at_discharge,

    CAST(1 AS BIT) AS denominator_flag,

    f7.followup_event_id AS first_7d_followup_event_id,
    f7.source_followup_encounter_id AS first_7d_source_followup_encounter_id,
    f7.followup_claim_id AS first_7d_followup_claim_id,
    f7.source_followup_claim_id AS first_7d_source_followup_claim_id,
    f7.followup_start_datetime AS first_7d_followup_start_datetime,
    f7.followup_date AS first_7d_followup_date,
    f7.days_from_index AS days_to_7d_followup,
    CAST(CASE WHEN f7.followup_event_id IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS numerator_7d_flag,

    f30.followup_event_id AS first_30d_followup_event_id,
    f30.source_followup_encounter_id AS first_30d_source_followup_encounter_id,
    f30.followup_claim_id AS first_30d_followup_claim_id,
    f30.source_followup_claim_id AS first_30d_source_followup_claim_id,
    f30.followup_start_datetime AS first_30d_followup_start_datetime,
    f30.followup_date AS first_30d_followup_date,
    f30.days_from_index AS days_to_30d_followup,
    f30.days_from_index AS days_to_first_qualifying_followup,
    CAST(CASE WHEN f30.followup_event_id IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS numerator_30d_flag,

    idx.synthetic_fixture_flag,
    idx.index_source_name,
    idx.index_source_file,
    idx.index_pipeline_run_id
FROM measure.fuh_index_event_detail AS idx
OUTER APPLY (
    SELECT TOP (1)
        fu.followup_event_id,
        fu.source_followup_encounter_id,
        fu.followup_claim_id,
        fu.source_followup_claim_id,
        fu.followup_date,
        fu.followup_start_datetime,
        fu.days_from_index
    FROM measure.fuh_followup_event_detail AS fu
    WHERE fu.index_event_id = idx.index_event_id
      AND fu.member_id = idx.member_id
      AND fu.qualifies_7d_flag = 1
    ORDER BY
        fu.followup_date,
        fu.followup_start_datetime,
        fu.followup_event_id
) AS f7
OUTER APPLY (
    SELECT TOP (1)
        fu.followup_event_id,
        fu.source_followup_encounter_id,
        fu.followup_claim_id,
        fu.source_followup_claim_id,
        fu.followup_date,
        fu.followup_start_datetime,
        fu.days_from_index
    FROM measure.fuh_followup_event_detail AS fu
    WHERE fu.index_event_id = idx.index_event_id
      AND fu.member_id = idx.member_id
      AND fu.qualifies_30d_flag = 1
    ORDER BY
        fu.followup_date,
        fu.followup_start_datetime,
        fu.followup_event_id
) AS f30
WHERE idx.eligibility_flag = 1;
GO

SELECT
    CASE
        WHEN synthetic_fixture_flag = 1 THEN 'FIXTURE'
        ELSE 'NON_FIXTURE'
    END AS population_scope,
    COUNT_BIG(*) AS denominator,
    SUM(CASE WHEN numerator_7d_flag = 1 THEN 1 ELSE 0 END) AS numerator_7d,
    SUM(CASE WHEN numerator_30d_flag = 1 THEN 1 ELSE 0 END) AS numerator_30d
FROM measure.fuh_measure_result
GROUP BY synthetic_fixture_flag
ORDER BY population_scope;
GO
