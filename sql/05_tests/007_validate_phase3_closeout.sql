/*
Healthcare Payer Analytics Pipeline
Phase 3 closeout smoke validation

Purpose:
- prove the implemented Phase 3 object inventory is complete;
- reconcile event-level and aggregate outputs;
- preserve fixture acceptance benchmarks;
- confirm source lineage and relationship integrity;
- confirm the measure layer does not depend on core.claim_transaction.
*/

USE HealthcarePayerAnalytics;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- T-FUH-095: complete Phase 3 object inventory.
IF OBJECT_ID('ref.measure_definition', 'U') IS NULL
   OR OBJECT_ID('ref.measure_value_set', 'U') IS NULL
   OR OBJECT_ID('measure.fuh_index_event_detail', 'V') IS NULL
   OR OBJECT_ID('measure.fuh_followup_event_detail', 'V') IS NULL
   OR OBJECT_ID('measure.fuh_measure_result', 'V') IS NULL
   OR OBJECT_ID('measure.fuh_measure_summary', 'V') IS NULL
   OR OBJECT_ID('measure.fuh_report_payer_monthly', 'V') IS NULL
   OR OBJECT_ID('measure.fuh_report_demographic', 'V') IS NULL
   OR OBJECT_ID('measure.fuh_report_followup_timing', 'V') IS NULL
   OR OBJECT_ID('measure.fuh_open_gap_detail', 'V') IS NULL
    THROW 52301, 'T-FUH-095 failed: one or more required Phase 3 objects are missing.', 1;

-- T-FUH-096: configuration is active and explicitly non-official.
IF (
    SELECT COUNT_BIG(*)
    FROM ref.measure_definition
    WHERE measure_id = 'FUH_STYLE_MY2025'
      AND active_flag = 1
      AND hedis_oriented_flag = 1
      AND official_hedis_flag = 0
      AND measurement_year = 2025
      AND analysis_date = CONVERT(DATE, '2026-10-18')
      AND methodology_version = 'v0.1'
) <> 1
    THROW 52302, 'T-FUH-096 failed: FUH_STYLE_MY2025 configuration is missing or inconsistent.', 1;

-- T-FUH-097: expected project-owned reference rules exist.
IF (
    SELECT COUNT_BIG(*)
    FROM ref.measure_value_set
    WHERE measure_id = 'FUH_STYLE_MY2025'
      AND active_flag = 1
      AND licensed_spec_flag = 0
) <> 12
OR (
    SELECT COUNT_BIG(*)
    FROM ref.measure_value_set
    WHERE measure_id = 'FUH_STYLE_MY2025'
      AND value_set_name = 'INDEX_ENCOUNTER_TYPE'
      AND active_flag = 1
) <> 1
OR (
    SELECT COUNT_BIG(*)
    FROM ref.measure_value_set
    WHERE measure_id = 'FUH_STYLE_MY2025'
      AND value_set_name = 'BEHAVIORAL_HEALTH_DIAGNOSIS'
      AND active_flag = 1
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
OR (
    SELECT COUNT_BIG(*)
    FROM ref.measure_value_set
    WHERE measure_id = 'FUH_STYLE_MY2025'
      AND value_set_name = 'FOLLOWUP_ENCOUNTER_TYPE'
      AND active_flag = 1
) <> 2
    THROW 52303, 'T-FUH-097 failed: expected 1 index rule, 9 non-substance BH prefixes, and 2 follow-up encounter rules.', 1;

-- T-FUH-098: measure/reporting views must not depend on the 5.2M-row transaction table.
IF EXISTS (
    SELECT 1
    FROM sys.sql_expression_dependencies AS d
    WHERE d.referenced_id = OBJECT_ID('core.claim_transaction')
      AND d.referencing_id IN (
            OBJECT_ID('measure.fuh_index_event_detail'),
            OBJECT_ID('measure.fuh_followup_event_detail'),
            OBJECT_ID('measure.fuh_measure_result'),
            OBJECT_ID('measure.fuh_measure_summary'),
            OBJECT_ID('measure.fuh_report_payer_monthly'),
            OBJECT_ID('measure.fuh_report_demographic'),
            OBJECT_ID('measure.fuh_report_followup_timing'),
            OBJECT_ID('measure.fuh_open_gap_detail')
      )
)
    THROW 52304, 'T-FUH-098 failed: a Phase 3 measure/reporting view unexpectedly depends on core.claim_transaction.', 1;

-- T-FUH-099: final denominator reconciles exactly to eligible index events.
IF (
    SELECT COUNT_BIG(*)
    FROM measure.fuh_measure_result
) <> (
    SELECT COUNT_BIG(*)
    FROM measure.fuh_index_event_detail
    WHERE eligibility_flag = 1
)
    THROW 52305, 'T-FUH-099 failed: final denominator does not reconcile to eligible index events.', 1;

-- T-FUH-100: final results resolve to member, encounter, and enrollment relationships.
IF EXISTS (
    SELECT 1
    FROM measure.fuh_measure_result AS r
    LEFT JOIN core.member AS m
        ON m.member_id = r.member_id
    LEFT JOIN core.encounter AS e
        ON e.encounter_id = r.index_encounter_id
       AND e.member_id = r.member_id
    LEFT JOIN core.enrollment_span AS es
        ON es.enrollment_span_id = r.enrollment_span_id
       AND es.member_id = r.member_id
       AND es.payer_id = r.payer_id
    WHERE m.member_id IS NULL
       OR e.encounter_id IS NULL
       OR es.enrollment_span_id IS NULL
)
    THROW 52306, 'T-FUH-100 failed: final result relationship integrity failed.', 1;

-- T-FUH-101: same-day follow-up never gets numerator credit.
IF EXISTS (
    SELECT 1
    FROM measure.fuh_followup_event_detail
    WHERE same_day_followup_flag = 1
      AND (qualifies_7d_flag = 1 OR qualifies_30d_flag = 1)
)
    THROW 52307, 'T-FUH-101 failed: same-day follow-up received numerator qualification.', 1;

-- T-FUH-102: 7-day numerator always implies 30-day numerator.
IF EXISTS (
    SELECT 1
    FROM measure.fuh_measure_result
    WHERE numerator_7d_flag = 1
      AND numerator_30d_flag <> 1
)
    THROW 52308, 'T-FUH-102 failed: 7-day numerator does not imply 30-day numerator.', 1;

-- T-FUH-103: deterministic fixture acceptance benchmark.
DECLARE @fixture_denominator BIGINT = (
    SELECT COUNT_BIG(*)
    FROM measure.fuh_measure_result
    WHERE synthetic_fixture_flag = 1
);
DECLARE @fixture_7d BIGINT = (
    SELECT SUM(CASE WHEN numerator_7d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END)
    FROM measure.fuh_measure_result
    WHERE synthetic_fixture_flag = 1
);
DECLARE @fixture_30d BIGINT = (
    SELECT SUM(CASE WHEN numerator_30d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END)
    FROM measure.fuh_measure_result
    WHERE synthetic_fixture_flag = 1
);
DECLARE @fixture_rate_7d DECIMAL(9,2) = (
    SELECT rate_7d_pct
    FROM measure.fuh_measure_summary
    WHERE population_scope = 'FIXTURE'
);
DECLARE @fixture_rate_30d DECIMAL(9,2) = (
    SELECT rate_30d_pct
    FROM measure.fuh_measure_summary
    WHERE population_scope = 'FIXTURE'
);

IF @fixture_denominator <> 40
   OR @fixture_7d <> 18
   OR @fixture_30d <> 32
   OR @fixture_rate_7d <> CAST(45.00 AS DECIMAL(9,2))
   OR @fixture_rate_30d <> CAST(80.00 AS DECIMAL(9,2))
    THROW 52309, 'T-FUH-103 failed: fixture benchmark is not 40 / 18 / 32 and 45.00% / 80.00%.', 1;

-- T-FUH-104: ALL summary reconciles to event-level results.
IF EXISTS (
    SELECT 1
    FROM measure.fuh_measure_summary AS s
    WHERE s.population_scope = 'ALL'
      AND (
            s.denominator <> (SELECT COUNT_BIG(*) FROM measure.fuh_measure_result)
         OR s.numerator_7d <> (
                SELECT SUM(CASE WHEN numerator_7d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END)
                FROM measure.fuh_measure_result
            )
         OR s.numerator_30d <> (
                SELECT SUM(CASE WHEN numerator_30d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END)
                FROM measure.fuh_measure_result
            )
      )
)
    THROW 52310, 'T-FUH-104 failed: ALL summary does not reconcile to event-level results.', 1;

-- T-FUH-105: payer/month reporting reconciles to event-level totals by fixture scope.
IF EXISTS (
    SELECT pm.synthetic_fixture_flag
    FROM measure.fuh_report_payer_monthly AS pm
    GROUP BY pm.synthetic_fixture_flag
    HAVING SUM(pm.denominator) <> (
               SELECT COUNT_BIG(*)
               FROM measure.fuh_measure_result AS r
               WHERE r.synthetic_fixture_flag = pm.synthetic_fixture_flag
           )
        OR SUM(pm.numerator_7d) <> (
               SELECT SUM(CASE WHEN r.numerator_7d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END)
               FROM measure.fuh_measure_result AS r
               WHERE r.synthetic_fixture_flag = pm.synthetic_fixture_flag
           )
        OR SUM(pm.numerator_30d) <> (
               SELECT SUM(CASE WHEN r.numerator_30d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END)
               FROM measure.fuh_measure_result AS r
               WHERE r.synthetic_fixture_flag = pm.synthetic_fixture_flag
           )
)
    THROW 52311, 'T-FUH-105 failed: payer/month reporting does not reconcile to event-level totals.', 1;

-- T-FUH-106: timing bands cover every denominator event exactly once.
IF EXISTS (
    SELECT t.synthetic_fixture_flag
    FROM measure.fuh_report_followup_timing AS t
    GROUP BY t.synthetic_fixture_flag
    HAVING SUM(t.episode_count) <> (
        SELECT COUNT_BIG(*)
        FROM measure.fuh_measure_result AS r
        WHERE r.synthetic_fixture_flag = t.synthetic_fixture_flag
    )
)
    THROW 52312, 'T-FUH-106 failed: timing bands do not reconcile to denominator events.', 1;

-- T-FUH-107: open-gap detail equals all events missing 7-day follow-up.
IF (
    SELECT COUNT_BIG(*)
    FROM measure.fuh_open_gap_detail
) <> (
    SELECT COUNT_BIG(*)
    FROM measure.fuh_measure_result
    WHERE numerator_7d_flag = 0
)
    THROW 52313, 'T-FUH-107 failed: open-gap detail does not equal all 7-day misses.', 1;

-- T-FUH-108: summary contains exactly the documented scopes and valid rate behavior.
IF (
    SELECT COUNT_BIG(*)
    FROM measure.fuh_measure_summary
    WHERE population_scope IN ('ALL', 'FIXTURE', 'NON_FIXTURE')
) <> 3
OR EXISTS (
    SELECT 1
    FROM measure.fuh_measure_summary
    WHERE denominator < 0
       OR numerator_7d < 0
       OR numerator_30d < 0
       OR numerator_7d > numerator_30d
       OR numerator_30d > denominator
       OR (denominator = 0 AND (rate_7d_pct IS NOT NULL OR rate_30d_pct IS NOT NULL))
       OR (denominator > 0 AND (rate_7d_pct NOT BETWEEN 0 AND 100 OR rate_30d_pct NOT BETWEEN 0 AND 100))
)
    THROW 52314, 'T-FUH-108 failed: summary scopes or rate behavior are invalid.', 1;

-- T-FUH-109: primary grains remain unique.
IF EXISTS (
    SELECT index_event_id
    FROM measure.fuh_index_event_detail
    GROUP BY index_event_id
    HAVING COUNT_BIG(*) > 1
)
OR EXISTS (
    SELECT index_event_id, followup_event_id
    FROM measure.fuh_followup_event_detail
    GROUP BY index_event_id, followup_event_id
    HAVING COUNT_BIG(*) > 1
)
OR EXISTS (
    SELECT index_event_id
    FROM measure.fuh_measure_result
    GROUP BY index_event_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 52315, 'T-FUH-109 failed: a primary Phase 3 grain is duplicated.', 1;

-- T-FUH-110: required source lineage survives to index and final-result layers.
IF EXISTS (
    SELECT 1
    FROM measure.fuh_index_event_detail
    WHERE source_member_id IS NULL
       OR source_index_encounter_id IS NULL
       OR index_source_name IS NULL
       OR index_source_file IS NULL
       OR index_pipeline_run_id IS NULL
       OR diagnosis_source_file IS NULL
       OR diagnosis_pipeline_run_id IS NULL
)
OR EXISTS (
    SELECT 1
    FROM measure.fuh_measure_result
    WHERE source_member_id IS NULL
       OR source_index_encounter_id IS NULL
       OR index_source_name IS NULL
       OR index_source_file IS NULL
       OR index_pipeline_run_id IS NULL
)
    THROW 52316, 'T-FUH-110 failed: required Phase 3 source lineage is missing.', 1;

PRINT 'Phase 3 closeout validation passed: T-FUH-095 through T-FUH-110.';

SELECT
    population_scope,
    denominator,
    numerator_7d,
    numerator_30d,
    rate_7d_pct,
    rate_30d_pct
FROM measure.fuh_measure_summary
ORDER BY
    CASE population_scope
        WHEN 'ALL' THEN 1
        WHEN 'FIXTURE' THEN 2
        WHEN 'NON_FIXTURE' THEN 3
        ELSE 4
    END;

SELECT
    COUNT_BIG(*) AS index_candidate_events,
    SUM(CASE WHEN eligibility_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS eligible_index_events
FROM measure.fuh_index_event_detail;

SELECT
    COUNT_BIG(*) AS followup_events_day_0_to_30,
    SUM(CASE WHEN qualifies_7d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS qualifying_7d_events,
    SUM(CASE WHEN qualifies_30d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS qualifying_30d_events
FROM measure.fuh_followup_event_detail;
GO
