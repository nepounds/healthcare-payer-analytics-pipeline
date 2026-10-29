/*
Healthcare Payer Analytics Pipeline
Phase 3 - FUH-style index-event detail

Object:
- measure.fuh_index_event_detail (view)

Grain:
- One row per candidate inpatient behavioral-health index encounter/discharge.

Qualification:
- source encounter type must match the project-defined INDEX_ENCOUNTER_TYPE set;
- at least one linked core.condition must match the project-defined behavioral-health diagnosis set;
- core.condition is used because it retains a reliable code_system;
- claim diagnosis position 1 and encounter REASONCODE are not treated as principal diagnoses.

Eligibility:
- age 6+ at discharge;
- discharge from January 1 through December 1 of the configured measurement year;
- one continuous core.enrollment_span for the encounter payer covers discharge through day 30;
- that span has both medical and behavioral-health benefit flags = 1.

No readmission/principal-diagnosis exclusion is applied in this v0.1 layer because the
implemented core model intentionally does not infer principal-diagnosis semantics.
*/

USE HealthcarePayerAnalytics;
GO

CREATE OR ALTER VIEW measure.fuh_index_event_detail
AS
WITH config AS (
    SELECT
        measure_id,
        measurement_year,
        analysis_date,
        methodology_version,
        DATEFROMPARTS(measurement_year, 1, 1) AS measurement_start_date,
        DATEFROMPARTS(measurement_year, 12, 1) AS measurement_last_index_date
    FROM ref.measure_definition
    WHERE measure_id = 'FUH_STYLE_MY2025'
      AND active_flag = 1
),
candidate AS (
    SELECT
        cfg.measure_id,
        cfg.measurement_year,
        cfg.analysis_date,
        cfg.methodology_version,
        cfg.measurement_start_date,
        cfg.measurement_last_index_date,

        e.encounter_id AS index_event_id,
        e.member_id,
        m.source_patient_id AS source_member_id,

        e.encounter_id AS index_encounter_id,
        e.source_encounter_id AS source_index_encounter_id,
        e.encounter_start_datetime AS index_admission_datetime,
        e.encounter_end_datetime AS index_discharge_datetime,
        CONVERT(DATE, e.encounter_start_datetime) AS index_admission_date,
        CONVERT(DATE, e.encounter_end_datetime) AS index_discharge_date,
        e.encounter_type,

        dx.condition_id AS diagnosis_condition_id,
        dx.code_system AS diagnosis_code_system,
        dx.diagnosis_code,
        dx.diagnosis_description,
        CAST('core.condition' AS VARCHAR(50)) AS diagnosis_source,

        e.payer_id AS encounter_payer_id,
        p_enc.payer_name AS encounter_payer_name,
        e.organization_id,
        e.provider_id,

        m.birth_date,
        m.sex,
        m.county_code,

        e.synthetic_fixture_flag,
        e.source_name AS index_source_name,
        e.source_file AS index_source_file,
        e.pipeline_run_id AS index_pipeline_run_id,
        dx.source_file AS diagnosis_source_file,
        dx.pipeline_run_id AS diagnosis_pipeline_run_id
    FROM core.encounter AS e
    CROSS JOIN config AS cfg
    INNER JOIN core.member AS m
        ON m.member_id = e.member_id
    LEFT JOIN core.payer AS p_enc
        ON p_enc.payer_id = e.payer_id
    CROSS APPLY (
        SELECT TOP (1)
            c.condition_id,
            c.code_system,
            c.diagnosis_code,
            c.diagnosis_description,
            c.source_file,
            c.pipeline_run_id
        FROM core.condition AS c
        WHERE c.encounter_id = e.encounter_id
          AND c.member_id = e.member_id
          AND EXISTS (
              SELECT 1
              FROM ref.measure_value_set AS vs
              WHERE vs.measure_id = cfg.measure_id
                AND vs.value_set_name = 'BEHAVIORAL_HEALTH_DIAGNOSIS'
                AND vs.active_flag = 1
                AND UPPER(vs.code_system) = UPPER(c.code_system)
                AND (
                    (vs.match_type = 'EXACT' AND UPPER(c.diagnosis_code) = UPPER(vs.code_value))
                    OR
                    (vs.match_type = 'PREFIX' AND UPPER(c.diagnosis_code) LIKE UPPER(vs.code_value) + '%')
                )
                AND (vs.effective_start_date IS NULL OR CONVERT(DATE, e.encounter_end_datetime) >= vs.effective_start_date)
                AND (vs.effective_end_date IS NULL OR CONVERT(DATE, e.encounter_end_datetime) <= vs.effective_end_date)
          )
        ORDER BY c.condition_id
    ) AS dx
    WHERE EXISTS (
        SELECT 1
        FROM ref.measure_value_set AS vs
        WHERE vs.measure_id = cfg.measure_id
          AND vs.value_set_name = 'INDEX_ENCOUNTER_TYPE'
          AND vs.active_flag = 1
          AND vs.code_system = 'SOURCE_ENCOUNTER_TYPE'
          AND vs.match_type = 'EXACT'
          AND LOWER(e.encounter_type) = LOWER(vs.code_value)
          AND (vs.effective_start_date IS NULL OR CONVERT(DATE, e.encounter_end_datetime) >= vs.effective_start_date)
          AND (vs.effective_end_date IS NULL OR CONVERT(DATE, e.encounter_end_datetime) <= vs.effective_end_date)
    )
),
derived AS (
    SELECT
        c.*,
        DATEDIFF(YEAR, c.birth_date, c.index_discharge_date)
            - CASE
                WHEN DATEADD(YEAR, DATEDIFF(YEAR, c.birth_date, c.index_discharge_date), c.birth_date) > c.index_discharge_date
                    THEN 1
                ELSE 0
              END AS age_at_discharge,
        DATEADD(DAY, 7, c.index_discharge_date) AS seven_day_deadline,
        DATEADD(DAY, 30, c.index_discharge_date) AS thirty_day_deadline
    FROM candidate AS c
)
SELECT
    d.measure_id,
    d.methodology_version,
    d.measurement_year,
    d.analysis_date,

    d.index_event_id,
    d.member_id,
    d.source_member_id,

    d.index_encounter_id,
    d.source_index_encounter_id,
    claim_pick.claim_id AS index_claim_id,
    claim_pick.source_claim_id AS source_index_claim_id,

    d.index_admission_datetime,
    d.index_discharge_datetime,
    d.index_admission_date,
    d.index_discharge_date,
    d.seven_day_deadline,
    d.thirty_day_deadline,
    d.encounter_type,

    d.diagnosis_condition_id,
    d.diagnosis_code_system,
    d.diagnosis_code,
    d.diagnosis_description,
    d.diagnosis_source,

    d.encounter_payer_id,
    d.encounter_payer_name,
    enrollment.enrollment_span_id,
    enrollment.payer_id AS enrollment_payer_id,
    enrollment.enrollment_start_date,
    enrollment.enrollment_end_date,
    enrollment.medical_benefit_flag,
    enrollment.behavioral_health_benefit_flag,

    d.organization_id,
    d.provider_id,
    d.sex,
    d.county_code,
    d.age_at_discharge,

    CAST(1 AS BIT) AS candidate_flag,
    CAST(CASE WHEN d.age_at_discharge >= 6 THEN 1 ELSE 0 END AS BIT) AS age_eligible_flag,
    CAST(
        CASE
            WHEN d.index_discharge_date BETWEEN d.measurement_start_date AND d.measurement_last_index_date
                THEN 1
            ELSE 0
        END
        AS BIT
    ) AS measurement_window_eligible_flag,
    CAST(CASE WHEN enrollment.enrollment_span_id IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS enrollment_eligible_flag,
    CAST(
        CASE
            WHEN d.age_at_discharge >= 6
             AND d.index_discharge_date BETWEEN d.measurement_start_date AND d.measurement_last_index_date
             AND enrollment.enrollment_span_id IS NOT NULL
                THEN 1
            ELSE 0
        END
        AS BIT
    ) AS eligibility_flag,
    CASE
        WHEN d.age_at_discharge < 6 THEN 'AGE_UNDER_6'
        WHEN d.index_discharge_date < d.measurement_start_date THEN 'BEFORE_MEASUREMENT_YEAR'
        WHEN d.index_discharge_date > d.measurement_last_index_date THEN 'AFTER_DECEMBER_1_CUTOFF'
        WHEN d.encounter_payer_id IS NULL THEN 'INDEX_PAYER_MISSING'
        WHEN enrollment.enrollment_span_id IS NULL THEN 'NO_CONTINUOUS_30_DAY_MEDICAL_BH_ENROLLMENT_FOR_INDEX_PAYER'
        ELSE NULL
    END AS ineligibility_reason,

    d.synthetic_fixture_flag,
    d.index_source_name,
    d.index_source_file,
    d.index_pipeline_run_id,
    d.diagnosis_source_file,
    d.diagnosis_pipeline_run_id
FROM derived AS d
OUTER APPLY (
    SELECT TOP (1)
        cl.claim_id,
        cl.source_claim_id
    FROM core.claim AS cl
    WHERE cl.encounter_id = d.index_encounter_id
      AND cl.member_id = d.member_id
    ORDER BY cl.service_date, cl.claim_id
) AS claim_pick
OUTER APPLY (
    SELECT TOP (1)
        es.enrollment_span_id,
        es.payer_id,
        es.enrollment_start_date,
        es.enrollment_end_date,
        es.medical_benefit_flag,
        es.behavioral_health_benefit_flag
    FROM core.enrollment_span AS es
    WHERE es.member_id = d.member_id
      AND es.payer_id = d.encounter_payer_id
      AND es.medical_benefit_flag = 1
      AND es.behavioral_health_benefit_flag = 1
      AND es.enrollment_start_date <= d.index_discharge_date
      AND es.enrollment_end_date >= d.thirty_day_deadline
    ORDER BY es.enrollment_start_date, es.enrollment_span_id
) AS enrollment;
GO

SELECT
    CASE
        WHEN synthetic_fixture_flag = 1 THEN 'FIXTURE'
        ELSE 'NON_FIXTURE'
    END AS population_scope,
    COUNT_BIG(*) AS candidate_index_events,
    SUM(CASE WHEN eligibility_flag = 1 THEN 1 ELSE 0 END) AS eligible_index_events,
    SUM(CASE WHEN eligibility_flag = 0 THEN 1 ELSE 0 END) AS ineligible_index_events
FROM measure.fuh_index_event_detail
GROUP BY synthetic_fixture_flag
ORDER BY population_scope;

SELECT
    ineligibility_reason,
    COUNT_BIG(*) AS candidate_events
FROM measure.fuh_index_event_detail
WHERE eligibility_flag = 0
GROUP BY ineligibility_reason
ORDER BY candidate_events DESC, ineligibility_reason;
GO
