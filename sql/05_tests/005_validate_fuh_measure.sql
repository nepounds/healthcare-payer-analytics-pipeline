/*
Healthcare Payer Analytics Pipeline
Phase 3 QA - FUH-style follow-up and final measure layers

Validates generic structural/semantic invariants plus deterministic controlled-fixture
acceptance. The fixture benchmark is hard-coded only in QA, never in measure logic.
*/

USE HealthcarePayerAnalytics;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID('measure.fuh_followup_event_detail', 'V') IS NULL
    THROW 52101, 'T-FUH-045 failed: measure.fuh_followup_event_detail does not exist.', 1;

IF OBJECT_ID('measure.fuh_measure_result', 'V') IS NULL
    THROW 52102, 'T-FUH-046 failed: measure.fuh_measure_result does not exist.', 1;

IF OBJECT_ID('measure.fuh_measure_summary', 'V') IS NULL
    THROW 52103, 'T-FUH-047 failed: measure.fuh_measure_summary does not exist.', 1;

IF NOT EXISTS (
    SELECT 1
    FROM ref.measure_value_set
    WHERE measure_id = 'FUH_STYLE_MY2025'
      AND value_set_name = 'FOLLOWUP_ENCOUNTER_TYPE'
      AND active_flag = 1
)
    THROW 52104, 'T-FUH-048 failed: follow-up encounter reference set is missing.', 1;

IF EXISTS (
    SELECT index_event_id, followup_event_id
    FROM measure.fuh_followup_event_detail
    GROUP BY index_event_id, followup_event_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 52105, 'T-FUH-049 failed: follow-up event grain is not unique within index event.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_followup_event_detail
    WHERE index_event_id IS NULL
       OR member_id IS NULL
       OR followup_event_id IS NULL
       OR source_followup_encounter_id IS NULL
       OR followup_date IS NULL
       OR followup_diagnosis_condition_id IS NULL
       OR followup_diagnosis_code_system IS NULL
       OR followup_diagnosis_code IS NULL
       OR days_from_index IS NULL
)
    THROW 52106, 'T-FUH-050 failed: required follow-up detail fields are null.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_followup_event_detail
    WHERE days_from_index < 0
       OR days_from_index > 30
)
    THROW 52107, 'T-FUH-051 failed: follow-up detail contains an event outside day 0 through day 30.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_followup_event_detail AS f
    WHERE NOT EXISTS (
        SELECT 1
        FROM ref.measure_value_set AS vs
        WHERE vs.measure_id = f.measure_id
          AND vs.value_set_name = 'FOLLOWUP_ENCOUNTER_TYPE'
          AND vs.active_flag = 1
          AND vs.code_system = 'SOURCE_ENCOUNTER_TYPE'
          AND vs.match_type = 'EXACT'
          AND LOWER(f.followup_encounter_type) = LOWER(vs.code_value)
          AND (vs.effective_start_date IS NULL OR f.followup_date >= vs.effective_start_date)
          AND (vs.effective_end_date IS NULL OR f.followup_date <= vs.effective_end_date)
    )
)
    THROW 52108, 'T-FUH-052 failed: a follow-up event is outside the documented encounter-type rule.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_followup_event_detail AS f
    WHERE NOT EXISTS (
        SELECT 1
        FROM ref.measure_value_set AS vs
        WHERE vs.measure_id = f.measure_id
          AND vs.value_set_name = 'BEHAVIORAL_HEALTH_DIAGNOSIS'
          AND vs.active_flag = 1
          AND UPPER(vs.code_system) = UPPER(f.followup_diagnosis_code_system)
          AND (
              (vs.match_type = 'EXACT' AND UPPER(f.followup_diagnosis_code) = UPPER(vs.code_value))
              OR
              (vs.match_type = 'PREFIX' AND UPPER(f.followup_diagnosis_code) LIKE UPPER(vs.code_value) + '%')
          )
          AND (vs.effective_start_date IS NULL OR f.followup_date >= vs.effective_start_date)
          AND (vs.effective_end_date IS NULL OR f.followup_date <= vs.effective_end_date)
    )
)
    THROW 52109, 'T-FUH-053 failed: follow-up diagnosis evidence is outside the documented rule.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_followup_event_detail AS f
    LEFT JOIN measure.fuh_index_event_detail AS i
        ON i.index_event_id = f.index_event_id
    WHERE i.index_event_id IS NULL
       OR i.eligibility_flag <> 1
       OR i.member_id <> f.member_id
       OR i.index_encounter_id <> f.index_encounter_id
)
    THROW 52110, 'T-FUH-054 failed: follow-up event does not resolve to the same eligible index member/event.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_followup_event_detail AS f
    LEFT JOIN core.encounter AS e
        ON e.encounter_id = f.followup_encounter_id
    WHERE e.encounter_id IS NULL
       OR e.member_id <> f.member_id
       OR e.source_encounter_id <> f.source_followup_encounter_id
)
    THROW 52111, 'T-FUH-055 failed: follow-up encounter lineage mismatch.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_followup_event_detail AS f
    LEFT JOIN core.condition AS c
        ON c.condition_id = f.followup_diagnosis_condition_id
    WHERE c.condition_id IS NULL
       OR c.member_id <> f.member_id
       OR c.encounter_id <> f.followup_encounter_id
       OR c.code_system <> f.followup_diagnosis_code_system
       OR c.diagnosis_code <> f.followup_diagnosis_code
)
    THROW 52112, 'T-FUH-056 failed: follow-up diagnosis lineage mismatch.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_followup_event_detail AS f
    LEFT JOIN core.claim AS cl
        ON cl.claim_id = f.followup_claim_id
    WHERE f.followup_claim_id IS NOT NULL
      AND (
          cl.claim_id IS NULL
          OR cl.member_id <> f.member_id
          OR cl.encounter_id <> f.followup_encounter_id
      )
)
    THROW 52113, 'T-FUH-057 failed: optional follow-up claim lineage mismatch.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_followup_event_detail
    WHERE same_day_followup_flag = 1
      AND (qualifies_7d_flag <> 0 OR qualifies_30d_flag <> 0)
)
    THROW 52114, 'T-FUH-058 failed: same-day follow-up received numerator credit contrary to A-015.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_followup_event_detail
    WHERE qualifies_7d_flag = 1
      AND qualifies_30d_flag <> 1
)
    THROW 52115, 'T-FUH-059 failed: 7-day follow-up does not imply 30-day qualification.', 1;

IF EXISTS (
    SELECT index_event_id
    FROM measure.fuh_measure_result
    GROUP BY index_event_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 52116, 'T-FUH-060 failed: final denominator-event grain is not unique.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_index_event_detail AS i
    LEFT JOIN measure.fuh_measure_result AS r
        ON r.index_event_id = i.index_event_id
    WHERE i.eligibility_flag = 1
      AND r.index_event_id IS NULL
)
OR EXISTS (
    SELECT 1
    FROM measure.fuh_measure_result AS r
    LEFT JOIN measure.fuh_index_event_detail AS i
        ON i.index_event_id = r.index_event_id
    WHERE i.index_event_id IS NULL
       OR i.eligibility_flag <> 1
       OR i.member_id <> r.member_id
)
    THROW 52117, 'T-FUH-061 failed: final denominator does not reconcile exactly to eligible index events.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_measure_result
    WHERE denominator_flag <> 1
       OR (numerator_7d_flag = 1 AND first_7d_followup_event_id IS NULL)
       OR (numerator_7d_flag = 0 AND first_7d_followup_event_id IS NOT NULL)
       OR (numerator_30d_flag = 1 AND first_30d_followup_event_id IS NULL)
       OR (numerator_30d_flag = 0 AND first_30d_followup_event_id IS NOT NULL)
)
    THROW 52118, 'T-FUH-062 failed: event-level denominator/numerator flags are internally inconsistent.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_measure_result
    WHERE numerator_7d_flag = 1
      AND numerator_30d_flag <> 1
)
    THROW 52119, 'T-FUH-063 failed: event-level 7-day numerator does not imply 30-day numerator.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_measure_result AS r
    WHERE r.numerator_7d_flag = 1
      AND EXISTS (
          SELECT 1
          FROM measure.fuh_followup_event_detail AS f
          WHERE f.index_event_id = r.index_event_id
            AND f.qualifies_7d_flag = 1
            AND (
                f.followup_date < r.first_7d_followup_date
                OR (
                    f.followup_date = r.first_7d_followup_date
                    AND f.followup_start_datetime < r.first_7d_followup_start_datetime
                )
                OR (
                    f.followup_date = r.first_7d_followup_date
                    AND f.followup_start_datetime = r.first_7d_followup_start_datetime
                    AND f.followup_event_id < r.first_7d_followup_event_id
                )
            )
      )
)
    THROW 52120, 'T-FUH-064 failed: selected 7-day follow-up is not the earliest deterministic qualifying event.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_measure_result AS r
    WHERE r.numerator_30d_flag = 1
      AND EXISTS (
          SELECT 1
          FROM measure.fuh_followup_event_detail AS f
          WHERE f.index_event_id = r.index_event_id
            AND f.qualifies_30d_flag = 1
            AND (
                f.followup_date < r.first_30d_followup_date
                OR (
                    f.followup_date = r.first_30d_followup_date
                    AND f.followup_start_datetime < r.first_30d_followup_start_datetime
                )
                OR (
                    f.followup_date = r.first_30d_followup_date
                    AND f.followup_start_datetime = r.first_30d_followup_start_datetime
                    AND f.followup_event_id < r.first_30d_followup_event_id
                )
            )
      )
)
    THROW 52121, 'T-FUH-065 failed: selected 30-day follow-up is not the earliest deterministic qualifying event.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_measure_result AS r
    LEFT JOIN measure.fuh_followup_event_detail AS f7
        ON f7.index_event_id = r.index_event_id
       AND f7.followup_event_id = r.first_7d_followup_event_id
    LEFT JOIN measure.fuh_followup_event_detail AS f30
        ON f30.index_event_id = r.index_event_id
       AND f30.followup_event_id = r.first_30d_followup_event_id
    WHERE (r.numerator_7d_flag = 1 AND (f7.followup_event_id IS NULL OR f7.member_id <> r.member_id OR f7.qualifies_7d_flag <> 1))
       OR (r.numerator_30d_flag = 1 AND (f30.followup_event_id IS NULL OR f30.member_id <> r.member_id OR f30.qualifies_30d_flag <> 1))
)
    THROW 52122, 'T-FUH-066 failed: selected numerator service does not resolve to the same member/index event.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_measure_result
    WHERE synthetic_fixture_flag = 1
      AND index_source_name <> 'FUH_FIXTURE'
)
    THROW 52123, 'T-FUH-067 failed: fixture lineage did not survive to final measure results.', 1;

IF (SELECT COUNT_BIG(*) FROM measure.fuh_followup_event_detail WHERE synthetic_fixture_flag = 1) <> 32
    THROW 52124, 'T-FUH-068 failed: expected 32 controlled fixture follow-up events inside day 0 through day 30.', 1;

IF (SELECT COUNT_BIG(*) FROM measure.fuh_measure_result WHERE synthetic_fixture_flag = 1) <> 40
    THROW 52125, 'T-FUH-069 failed: expected fixture denominator = 40.', 1;

IF (SELECT COUNT_BIG(*) FROM measure.fuh_measure_result WHERE synthetic_fixture_flag = 1 AND numerator_7d_flag = 1) <> 18
    THROW 52126, 'T-FUH-070 failed: expected fixture 7-day numerator = 18.', 1;

IF (SELECT COUNT_BIG(*) FROM measure.fuh_measure_result WHERE synthetic_fixture_flag = 1 AND numerator_30d_flag = 1) <> 32
    THROW 52127, 'T-FUH-071 failed: expected fixture 30-day numerator = 32.', 1;

IF NOT EXISTS (
    SELECT 1
    FROM measure.fuh_measure_summary
    WHERE population_scope = 'FIXTURE'
      AND denominator = 40
      AND numerator_7d = 18
      AND numerator_30d = 32
      AND rate_7d_pct = CAST(45.00 AS DECIMAL(9,2))
      AND rate_30d_pct = CAST(80.00 AS DECIMAL(9,2))
)
    THROW 52128, 'T-FUH-072 failed: fixture summary must equal 40 / 18 / 32 and 45.00% / 80.00%.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.fuh_fixture_manifest AS fm
    INNER JOIN measure.fuh_measure_result AS r
        ON r.source_index_encounter_id = fm.index_encounter_id
       AND r.synthetic_fixture_flag = 1
    WHERE r.denominator_flag <> fm.expected_denominator_flag
       OR r.numerator_7d_flag <> fm.expected_fuh_7d_flag
       OR r.numerator_30d_flag <> fm.expected_fuh_30d_flag
)
OR EXISTS (
    SELECT 1
    FROM raw.fuh_fixture_manifest AS fm
    LEFT JOIN measure.fuh_measure_result AS r
        ON r.source_index_encounter_id = fm.index_encounter_id
       AND r.synthetic_fixture_flag = 1
    WHERE fm.expected_denominator_flag = 1
      AND r.index_event_id IS NULL
)
    THROW 52129, 'T-FUH-073 failed: fixture result flags do not reconcile row-by-row to the fixture manifest.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.fuh_fixture_manifest AS fm
    INNER JOIN measure.fuh_followup_event_detail AS f
        ON f.source_followup_encounter_id = fm.followup_encounter_id
       AND f.synthetic_fixture_flag = 1
    WHERE TRY_CONVERT(INT, NULLIF(fm.followup_day, '')) >= 31
)
    THROW 52130, 'T-FUH-074 failed: day-31-or-later fixture follow-up entered the day 0 through day 30 detail window.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_measure_summary AS s
    WHERE s.population_scope = 'ALL'
      AND (
          s.denominator <> (SELECT COUNT_BIG(*) FROM measure.fuh_measure_result)
          OR s.numerator_7d <> (SELECT COUNT_BIG(*) FROM measure.fuh_measure_result WHERE numerator_7d_flag = 1)
          OR s.numerator_30d <> (SELECT COUNT_BIG(*) FROM measure.fuh_measure_result WHERE numerator_30d_flag = 1)
      )
)
OR EXISTS (
    SELECT 1
    FROM measure.fuh_measure_summary AS s
    WHERE s.population_scope = 'FIXTURE'
      AND (
          s.denominator <> (SELECT COUNT_BIG(*) FROM measure.fuh_measure_result WHERE synthetic_fixture_flag = 1)
          OR s.numerator_7d <> (SELECT COUNT_BIG(*) FROM measure.fuh_measure_result WHERE synthetic_fixture_flag = 1 AND numerator_7d_flag = 1)
          OR s.numerator_30d <> (SELECT COUNT_BIG(*) FROM measure.fuh_measure_result WHERE synthetic_fixture_flag = 1 AND numerator_30d_flag = 1)
      )
)
    THROW 52131, 'T-FUH-075 failed: aggregate summary does not reconcile to event-level results.', 1;

PRINT 'FUH follow-up/final-measure validation passed: T-FUH-045 through T-FUH-075.';

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
    END,
    population_scope;
GO
