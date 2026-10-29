/*
Healthcare Payer Analytics Pipeline
Phase 3 QA - FUH-style index-event layer

Validates actual-data structural invariants plus deterministic fixture acceptance
for the index/eligibility stage. Fails loudly with THROW.
*/

USE HealthcarePayerAnalytics;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID('ref.measure_definition', 'U') IS NULL
    THROW 52001, 'T-FUH-023 failed: ref.measure_definition does not exist.', 1;

IF OBJECT_ID('ref.measure_value_set', 'U') IS NULL
    THROW 52002, 'T-FUH-024 failed: ref.measure_value_set does not exist.', 1;

IF OBJECT_ID('measure.fuh_index_event_detail', 'V') IS NULL
    THROW 52003, 'T-FUH-025 failed: measure.fuh_index_event_detail does not exist.', 1;

IF (SELECT COUNT(*) FROM ref.measure_definition WHERE measure_id = 'FUH_STYLE_MY2025' AND active_flag = 1) <> 1
    THROW 52004, 'T-FUH-026 failed: expected exactly one active FUH_STYLE_MY2025 definition.', 1;

IF EXISTS (
    SELECT 1
    FROM ref.measure_definition
    WHERE measure_id = 'FUH_STYLE_MY2025'
      AND official_hedis_flag <> 0
)
    THROW 52005, 'T-FUH-027 failed: portfolio measure must not be marked official HEDIS.', 1;

IF NOT EXISTS (
    SELECT 1
    FROM ref.measure_value_set
    WHERE measure_id = 'FUH_STYLE_MY2025'
      AND value_set_name = 'INDEX_ENCOUNTER_TYPE'
      AND active_flag = 1
)
    THROW 52006, 'T-FUH-028 failed: index encounter reference set is missing.', 1;

IF (
    SELECT COUNT_BIG(*)
    FROM ref.measure_value_set
    WHERE measure_id = 'FUH_STYLE_MY2025'
      AND value_set_name = 'BEHAVIORAL_HEALTH_DIAGNOSIS'
      AND active_flag = 1
      AND licensed_spec_flag = 0
      AND UPPER(code_system) = 'ICD-10-CM'
      AND match_type = 'PREFIX'
      AND UPPER(code_value) IN ('F0', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9')
) <> 9
OR EXISTS (
    SELECT 1
    FROM ref.measure_value_set
    WHERE measure_id = 'FUH_STYLE_MY2025'
      AND value_set_name = 'BEHAVIORAL_HEALTH_DIAGNOSIS'
      AND active_flag = 1
      AND UPPER(code_value) NOT IN ('F0', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9')
)
    THROW 52007, 'T-FUH-029 failed: expected the nine project-owned non-substance BH prefixes F0 and F2-F9.', 1;

IF EXISTS (
    SELECT index_event_id
    FROM measure.fuh_index_event_detail
    GROUP BY index_event_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 52008, 'T-FUH-030 failed: index-event grain is not unique.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_index_event_detail
    WHERE member_id IS NULL
       OR source_member_id IS NULL
       OR index_encounter_id IS NULL
       OR source_index_encounter_id IS NULL
       OR index_discharge_date IS NULL
       OR diagnosis_condition_id IS NULL
       OR diagnosis_code_system IS NULL
       OR diagnosis_code IS NULL
       OR candidate_flag <> 1
)
    THROW 52009, 'T-FUH-031 failed: required index-event fields are null or invalid.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_index_event_detail AS f
    LEFT JOIN core.member AS m
        ON m.member_id = f.member_id
    WHERE m.member_id IS NULL
)
    THROW 52010, 'T-FUH-032 failed: index event has an orphan member.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_index_event_detail AS f
    LEFT JOIN core.encounter AS e
        ON e.encounter_id = f.index_encounter_id
    WHERE e.encounter_id IS NULL
       OR e.member_id <> f.member_id
)
    THROW 52011, 'T-FUH-033 failed: index encounter integrity mismatch.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_index_event_detail AS f
    LEFT JOIN core.condition AS c
        ON c.condition_id = f.diagnosis_condition_id
    WHERE c.condition_id IS NULL
       OR c.member_id <> f.member_id
       OR c.encounter_id <> f.index_encounter_id
       OR c.code_system <> f.diagnosis_code_system
       OR c.diagnosis_code <> f.diagnosis_code
)
    THROW 52012, 'T-FUH-034 failed: diagnosis qualification lineage mismatch.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_index_event_detail AS f
    LEFT JOIN core.claim AS cl
        ON cl.claim_id = f.index_claim_id
    WHERE f.index_claim_id IS NOT NULL
      AND (
          cl.claim_id IS NULL
          OR cl.member_id <> f.member_id
          OR cl.encounter_id <> f.index_encounter_id
      )
)
    THROW 52013, 'T-FUH-035 failed: optional index claim lineage mismatch.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_index_event_detail
    WHERE age_eligible_flag <> CASE WHEN age_at_discharge >= 6 THEN 1 ELSE 0 END
)
    THROW 52014, 'T-FUH-036 failed: age eligibility flag is inconsistent.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_index_event_detail
    WHERE measurement_window_eligible_flag <>
        CASE
            WHEN index_discharge_date BETWEEN DATEFROMPARTS(measurement_year, 1, 1)
                                         AND DATEFROMPARTS(measurement_year, 12, 1)
                THEN 1
            ELSE 0
        END
)
    THROW 52015, 'T-FUH-037 failed: measurement-window eligibility flag is inconsistent.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_index_event_detail
    WHERE enrollment_eligible_flag = 1
      AND (
          enrollment_span_id IS NULL
          OR enrollment_payer_id <> encounter_payer_id
          OR medical_benefit_flag <> 1
          OR behavioral_health_benefit_flag <> 1
          OR enrollment_start_date > index_discharge_date
          OR enrollment_end_date < thirty_day_deadline
      )
)
    THROW 52016, 'T-FUH-038 failed: enrollment eligibility is not auditable to a covering benefit span.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_index_event_detail
    WHERE eligibility_flag <>
        CASE
            WHEN age_eligible_flag = 1
             AND measurement_window_eligible_flag = 1
             AND enrollment_eligible_flag = 1
                THEN 1
            ELSE 0
        END
)
    THROW 52017, 'T-FUH-039 failed: final eligibility flag is inconsistent.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_index_event_detail
    WHERE synthetic_fixture_flag = 1
      AND index_source_name <> 'FUH_FIXTURE'
)
    THROW 52018, 'T-FUH-040 failed: fixture lineage is not preserved on index events.', 1;

IF (SELECT COUNT_BIG(*) FROM measure.fuh_index_event_detail WHERE synthetic_fixture_flag = 1) <> 40
    THROW 52019, 'T-FUH-041 failed: expected exactly 40 controlled fixture index events.', 1;

IF (SELECT COUNT_BIG(*) FROM measure.fuh_index_event_detail WHERE synthetic_fixture_flag = 1 AND eligibility_flag = 1) <> 40
    THROW 52020, 'T-FUH-042 failed: expected all 40 controlled fixture index events to pass current eligibility rules.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.fuh_fixture_manifest AS fm
    LEFT JOIN measure.fuh_index_event_detail AS f
        ON f.source_index_encounter_id = fm.index_encounter_id
       AND f.synthetic_fixture_flag = 1
    WHERE f.index_event_id IS NULL
)
    THROW 52021, 'T-FUH-043 failed: a fixture-manifest index encounter is missing from the measure index layer.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_index_event_detail AS f
    WHERE f.synthetic_fixture_flag = 1
      AND NOT EXISTS (
          SELECT 1
          FROM raw.fuh_fixture_manifest AS fm
          WHERE fm.index_encounter_id = f.source_index_encounter_id
      )
)
    THROW 52022, 'T-FUH-044 failed: fixture index layer contains an event absent from the fixture manifest.', 1;

PRINT 'FUH index-event validation passed: T-FUH-023 through T-FUH-044.';

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
    COUNT_BIG(*) AS fixture_manifest_rows,
    SUM(CASE WHEN expected_denominator_flag = 1 THEN 1 ELSE 0 END) AS fixture_expected_denominator
FROM raw.fuh_fixture_manifest;
GO
