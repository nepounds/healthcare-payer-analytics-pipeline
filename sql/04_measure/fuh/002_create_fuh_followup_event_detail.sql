/*
Healthcare Payer Analytics Pipeline
Phase 3 - FUH-style follow-up event detail

Object:
- measure.fuh_followup_event_detail (view)

Grain:
- One row per eligible index event / qualifying follow-up encounter pair occurring
  from the index discharge date through day 30.

Qualification:
- index event must already be denominator-eligible in measure.fuh_index_event_detail;
- follow-up encounter type must match the project-defined FOLLOWUP_ENCOUNTER_TYPE set;
- at least one linked core.condition must match the project-defined behavioral-health
  diagnosis set using its retained code_system;
- core.claim is retained only as optional lineage and is not required to qualify the service.

Window handling:
- day 0 (same calendar date as discharge) remains visible for audit but receives no
  numerator credit under A-015;
- days 1-7 qualify for both the 7-day and 30-day numerators;
- days 8-30 qualify for the 30-day numerator only;
- day 31 and later are outside this view's measure window.

This layer does not scan core.claim_transaction because transaction-level detail is not
needed to establish the project-defined follow-up service rule.
*/

USE HealthcarePayerAnalytics;
GO

CREATE OR ALTER VIEW measure.fuh_followup_event_detail
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
    idx.index_discharge_datetime,
    idx.index_discharge_date,
    idx.seven_day_deadline,
    idx.thirty_day_deadline,

    fu.encounter_id AS followup_event_id,
    fu.encounter_id AS followup_encounter_id,
    fu.source_encounter_id AS source_followup_encounter_id,
    claim_pick.claim_id AS followup_claim_id,
    claim_pick.source_claim_id AS source_followup_claim_id,
    fu.encounter_start_datetime AS followup_start_datetime,
    fu.encounter_end_datetime AS followup_end_datetime,
    CONVERT(DATE, fu.encounter_start_datetime) AS followup_date,
    fu.encounter_type AS followup_encounter_type,

    dx.condition_id AS followup_diagnosis_condition_id,
    dx.code_system AS followup_diagnosis_code_system,
    dx.diagnosis_code AS followup_diagnosis_code,
    dx.diagnosis_description AS followup_diagnosis_description,
    CAST('core.encounter + core.condition' AS VARCHAR(100)) AS qualification_source,

    DATEDIFF(
        DAY,
        idx.index_discharge_date,
        CONVERT(DATE, fu.encounter_start_datetime)
    ) AS days_from_index,

    CAST(
        CASE
            WHEN CONVERT(DATE, fu.encounter_start_datetime) = idx.index_discharge_date
                THEN 1
            ELSE 0
        END
        AS BIT
    ) AS same_day_followup_flag,

    CAST(
        CASE
            WHEN DATEDIFF(DAY, idx.index_discharge_date, CONVERT(DATE, fu.encounter_start_datetime)) BETWEEN 1 AND 7
                THEN 1
            ELSE 0
        END
        AS BIT
    ) AS qualifies_7d_flag,

    CAST(
        CASE
            WHEN DATEDIFF(DAY, idx.index_discharge_date, CONVERT(DATE, fu.encounter_start_datetime)) BETWEEN 1 AND 30
                THEN 1
            ELSE 0
        END
        AS BIT
    ) AS qualifies_30d_flag,

    idx.encounter_payer_id AS index_payer_id,
    idx.encounter_payer_name AS index_payer_name,
    fu.payer_id AS followup_payer_id,
    fu.organization_id AS followup_organization_id,
    fu.provider_id AS followup_provider_id,

    idx.synthetic_fixture_flag AS index_fixture_flag,
    fu.synthetic_fixture_flag AS followup_fixture_flag,
    CAST(
        CASE
            WHEN idx.synthetic_fixture_flag = 1
             AND fu.synthetic_fixture_flag = 1
                THEN 1
            ELSE 0
        END
        AS BIT
    ) AS synthetic_fixture_flag,

    fu.source_name AS followup_source_name,
    fu.source_file AS followup_source_file,
    fu.pipeline_run_id AS followup_pipeline_run_id,
    dx.source_file AS diagnosis_source_file,
    dx.pipeline_run_id AS diagnosis_pipeline_run_id
FROM measure.fuh_index_event_detail AS idx
INNER JOIN core.encounter AS fu
    ON fu.member_id = idx.member_id
   AND fu.encounter_id <> idx.index_encounter_id
   AND CONVERT(DATE, fu.encounter_start_datetime) >= idx.index_discharge_date
   AND CONVERT(DATE, fu.encounter_start_datetime) <= idx.thirty_day_deadline
CROSS APPLY (
    SELECT TOP (1)
        c.condition_id,
        c.code_system,
        c.diagnosis_code,
        c.diagnosis_description,
        c.source_file,
        c.pipeline_run_id
    FROM core.condition AS c
    WHERE c.encounter_id = fu.encounter_id
      AND c.member_id = fu.member_id
      AND EXISTS (
          SELECT 1
          FROM ref.measure_value_set AS vs
          WHERE vs.measure_id = idx.measure_id
            AND vs.value_set_name = 'BEHAVIORAL_HEALTH_DIAGNOSIS'
            AND vs.active_flag = 1
            AND UPPER(vs.code_system) = UPPER(c.code_system)
            AND (
                (vs.match_type = 'EXACT' AND UPPER(c.diagnosis_code) = UPPER(vs.code_value))
                OR
                (vs.match_type = 'PREFIX' AND UPPER(c.diagnosis_code) LIKE UPPER(vs.code_value) + '%')
            )
            AND (vs.effective_start_date IS NULL OR CONVERT(DATE, fu.encounter_start_datetime) >= vs.effective_start_date)
            AND (vs.effective_end_date IS NULL OR CONVERT(DATE, fu.encounter_start_datetime) <= vs.effective_end_date)
      )
    ORDER BY c.condition_id
) AS dx
OUTER APPLY (
    SELECT TOP (1)
        cl.claim_id,
        cl.source_claim_id
    FROM core.claim AS cl
    WHERE cl.encounter_id = fu.encounter_id
      AND cl.member_id = fu.member_id
    ORDER BY cl.service_date, cl.claim_id
) AS claim_pick
WHERE idx.eligibility_flag = 1
  AND EXISTS (
      SELECT 1
      FROM ref.measure_value_set AS vs
      WHERE vs.measure_id = idx.measure_id
        AND vs.value_set_name = 'FOLLOWUP_ENCOUNTER_TYPE'
        AND vs.active_flag = 1
        AND vs.code_system = 'SOURCE_ENCOUNTER_TYPE'
        AND vs.match_type = 'EXACT'
        AND LOWER(fu.encounter_type) = LOWER(vs.code_value)
        AND (vs.effective_start_date IS NULL OR CONVERT(DATE, fu.encounter_start_datetime) >= vs.effective_start_date)
        AND (vs.effective_end_date IS NULL OR CONVERT(DATE, fu.encounter_start_datetime) <= vs.effective_end_date)
  );
GO

SELECT
    CASE
        WHEN synthetic_fixture_flag = 1 THEN 'FIXTURE'
        ELSE 'NON_FIXTURE'
    END AS population_scope,
    COUNT_BIG(*) AS qualifying_followup_events_in_day_0_to_30_window,
    SUM(CASE WHEN same_day_followup_flag = 1 THEN 1 ELSE 0 END) AS same_day_events,
    SUM(CASE WHEN qualifies_7d_flag = 1 THEN 1 ELSE 0 END) AS events_qualifying_7d,
    SUM(CASE WHEN qualifies_30d_flag = 1 THEN 1 ELSE 0 END) AS events_qualifying_30d
FROM measure.fuh_followup_event_detail
GROUP BY synthetic_fixture_flag
ORDER BY population_scope;
GO
