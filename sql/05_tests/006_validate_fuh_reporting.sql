/*
Healthcare Payer Analytics Pipeline
Phase 3 QA - FUH-style analytical reporting layer

Validates that reporting views reconcile to the authoritative event-level measure,
retain valid rates/grains, and expose deterministic fixture timing/gap patterns.
*/

USE HealthcarePayerAnalytics;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID('measure.fuh_report_payer_monthly', 'V') IS NULL
    THROW 52201, 'T-FUH-076 failed: measure.fuh_report_payer_monthly does not exist.', 1;

IF OBJECT_ID('measure.fuh_report_demographic', 'V') IS NULL
    THROW 52202, 'T-FUH-077 failed: measure.fuh_report_demographic does not exist.', 1;

IF OBJECT_ID('measure.fuh_report_followup_timing', 'V') IS NULL
    THROW 52203, 'T-FUH-078 failed: measure.fuh_report_followup_timing does not exist.', 1;

IF OBJECT_ID('measure.fuh_open_gap_detail', 'V') IS NULL
    THROW 52204, 'T-FUH-079 failed: measure.fuh_open_gap_detail does not exist.', 1;

IF EXISTS (
    SELECT
        measure_id,
        methodology_version,
        measurement_year,
        discharge_month,
        payer_id,
        synthetic_fixture_flag
    FROM measure.fuh_report_payer_monthly
    GROUP BY
        measure_id,
        methodology_version,
        measurement_year,
        discharge_month,
        payer_id,
        synthetic_fixture_flag
    HAVING COUNT_BIG(*) > 1
)
    THROW 52205, 'T-FUH-080 failed: payer/month reporting grain is not unique.', 1;

IF EXISTS (
    SELECT
        measure_id,
        methodology_version,
        measurement_year,
        age_band,
        sex_group,
        synthetic_fixture_flag
    FROM measure.fuh_report_demographic
    GROUP BY
        measure_id,
        methodology_version,
        measurement_year,
        age_band,
        sex_group,
        synthetic_fixture_flag
    HAVING COUNT_BIG(*) > 1
)
    THROW 52206, 'T-FUH-081 failed: demographic reporting grain is not unique.', 1;

IF EXISTS (
    SELECT
        measure_id,
        methodology_version,
        measurement_year,
        timing_band,
        synthetic_fixture_flag
    FROM measure.fuh_report_followup_timing
    GROUP BY
        measure_id,
        methodology_version,
        measurement_year,
        timing_band,
        synthetic_fixture_flag
    HAVING COUNT_BIG(*) > 1
)
    THROW 52207, 'T-FUH-082 failed: follow-up timing reporting grain is not unique.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_report_payer_monthly
    WHERE denominator <= 0
       OR numerator_7d < 0
       OR numerator_30d < 0
       OR numerator_7d > numerator_30d
       OR numerator_30d > denominator
       OR rate_7d_pct < 0 OR rate_7d_pct > 100
       OR rate_30d_pct < 0 OR rate_30d_pct > 100
)
    THROW 52208, 'T-FUH-083 failed: payer/month report contains invalid numerator, denominator, or rate values.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_report_demographic
    WHERE denominator <= 0
       OR numerator_7d < 0
       OR numerator_30d < 0
       OR numerator_7d > numerator_30d
       OR numerator_30d > denominator
       OR rate_7d_pct < 0 OR rate_7d_pct > 100
       OR rate_30d_pct < 0 OR rate_30d_pct > 100
)
    THROW 52209, 'T-FUH-084 failed: demographic report contains invalid numerator, denominator, or rate values.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_report_followup_timing
    WHERE episode_count <= 0
       OR pct_of_denominator < 0
       OR pct_of_denominator > 100
       OR timing_band NOT IN ('01_DAY_1_7', '02_DAY_8_14', '03_DAY_15_30', '04_NO_30D_FOLLOWUP')
)
    THROW 52210, 'T-FUH-085 failed: follow-up timing report contains invalid bands or statistics.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_open_gap_detail
    WHERE numerator_7d_flag <> 0
       OR gap_status IS NULL
       OR gap_status NOT IN ('MISSED_7D_MET_30D', 'MISSED_30D')
       OR (gap_status = 'MISSED_7D_MET_30D' AND numerator_30d_flag <> 1)
       OR (gap_status = 'MISSED_30D' AND numerator_30d_flag <> 0)
)
    THROW 52211, 'T-FUH-086 failed: open-gap detail contains a row inconsistent with event-level numerator flags.', 1;

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
    THROW 52212, 'T-FUH-087 failed: payer/month totals do not reconcile to event-level results.', 1;

IF EXISTS (
    SELECT d.synthetic_fixture_flag
    FROM measure.fuh_report_demographic AS d
    GROUP BY d.synthetic_fixture_flag
    HAVING SUM(d.denominator) <> (
               SELECT COUNT_BIG(*)
               FROM measure.fuh_measure_result AS r
               WHERE r.synthetic_fixture_flag = d.synthetic_fixture_flag
           )
        OR SUM(d.numerator_7d) <> (
               SELECT SUM(CASE WHEN r.numerator_7d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END)
               FROM measure.fuh_measure_result AS r
               WHERE r.synthetic_fixture_flag = d.synthetic_fixture_flag
           )
        OR SUM(d.numerator_30d) <> (
               SELECT SUM(CASE WHEN r.numerator_30d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END)
               FROM measure.fuh_measure_result AS r
               WHERE r.synthetic_fixture_flag = d.synthetic_fixture_flag
           )
)
    THROW 52213, 'T-FUH-088 failed: demographic totals do not reconcile to event-level results.', 1;

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
    THROW 52214, 'T-FUH-089 failed: timing-band totals do not reconcile to the denominator.', 1;

IF EXISTS (
    SELECT 1
    FROM measure.fuh_open_gap_detail AS g
    LEFT JOIN measure.fuh_measure_result AS r
        ON r.index_event_id = g.index_event_id
       AND r.member_id = g.member_id
    WHERE r.index_event_id IS NULL
       OR r.numerator_7d_flag <> 0
       OR r.synthetic_fixture_flag <> g.synthetic_fixture_flag
)
    THROW 52215, 'T-FUH-090 failed: open-gap lineage does not resolve to the event-level measure result.', 1;

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

IF @fixture_denominator <> 40 OR @fixture_7d <> 18 OR @fixture_30d <> 32
    THROW 52216, 'T-FUH-091 failed: fixture event-level benchmark changed before reporting validation.', 1;

IF (
    SELECT SUM(denominator)
    FROM measure.fuh_report_payer_monthly
    WHERE synthetic_fixture_flag = 1
) <> 40
OR (
    SELECT SUM(numerator_7d)
    FROM measure.fuh_report_payer_monthly
    WHERE synthetic_fixture_flag = 1
) <> 18
OR (
    SELECT SUM(numerator_30d)
    FROM measure.fuh_report_payer_monthly
    WHERE synthetic_fixture_flag = 1
) <> 32
    THROW 52217, 'T-FUH-092 failed: fixture payer/month report does not reconcile to 40 / 18 / 32.', 1;

IF (
    SELECT SUM(episode_count)
    FROM measure.fuh_report_followup_timing
    WHERE synthetic_fixture_flag = 1
      AND timing_band = '01_DAY_1_7'
) <> 18
OR (
    SELECT SUM(episode_count)
    FROM measure.fuh_report_followup_timing
    WHERE synthetic_fixture_flag = 1
      AND timing_band = '02_DAY_8_14'
) <> 8
OR (
    SELECT SUM(episode_count)
    FROM measure.fuh_report_followup_timing
    WHERE synthetic_fixture_flag = 1
      AND timing_band = '03_DAY_15_30'
) <> 6
OR (
    SELECT SUM(episode_count)
    FROM measure.fuh_report_followup_timing
    WHERE synthetic_fixture_flag = 1
      AND timing_band = '04_NO_30D_FOLLOWUP'
) <> 8
    THROW 52218, 'T-FUH-093 failed: fixture timing distribution does not equal 18 / 8 / 6 / 8.', 1;

IF (
    SELECT COUNT_BIG(*)
    FROM measure.fuh_open_gap_detail
    WHERE synthetic_fixture_flag = 1
) <> 22
OR (
    SELECT COUNT_BIG(*)
    FROM measure.fuh_open_gap_detail
    WHERE synthetic_fixture_flag = 1
      AND gap_status = 'MISSED_7D_MET_30D'
) <> 14
OR (
    SELECT COUNT_BIG(*)
    FROM measure.fuh_open_gap_detail
    WHERE synthetic_fixture_flag = 1
      AND gap_status = 'MISSED_30D'
) <> 8
    THROW 52219, 'T-FUH-094 failed: fixture open-gap distribution does not equal 22 total / 14 missed-7d / 8 missed-30d.', 1;

PRINT 'FUH analytical-reporting validation passed: T-FUH-076 through T-FUH-094.';

SELECT
    SUM(denominator) AS fixture_denominator,
    SUM(numerator_7d) AS fixture_numerator_7d,
    SUM(numerator_30d) AS fixture_numerator_30d
FROM measure.fuh_report_payer_monthly
WHERE synthetic_fixture_flag = 1;

SELECT
    timing_band,
    episode_count,
    pct_of_denominator,
    avg_days_to_followup
FROM measure.fuh_report_followup_timing
WHERE synthetic_fixture_flag = 1
ORDER BY timing_band;

SELECT
    gap_status,
    COUNT_BIG(*) AS fixture_gap_episodes
FROM measure.fuh_open_gap_detail
WHERE synthetic_fixture_flag = 1
GROUP BY gap_status
ORDER BY gap_status;
GO
