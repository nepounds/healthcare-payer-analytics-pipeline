/*
Healthcare Payer Analytics Pipeline
Phase 3 - FUH-style analytical reporting views

Purpose:
- expose a small, reproducible set of quality-improvement-oriented reporting outputs;
- keep numerator/denominator business logic in the authoritative measure layer;
- provide report-ready summaries without manufacturing unsupported dimensions.

Objects:
- measure.fuh_report_payer_monthly
- measure.fuh_report_demographic
- measure.fuh_report_followup_timing
- measure.fuh_open_gap_detail

Important limitation:
The current deterministic FUH fixture package is designed to validate measure logic,
not to simulate population epidemiology. Current fixture members use one payer, one
county, a narrow adult age range, and controlled follow-up timing. These views are
therefore interpretation-ready structures, but current fixture subgroup differences
must not be presented as real-world disparities or payer performance.
*/

USE HealthcarePayerAnalytics;
GO

CREATE OR ALTER VIEW measure.fuh_report_payer_monthly
AS
SELECT
    r.measure_id,
    r.methodology_version,
    r.measurement_year,
    DATEFROMPARTS(YEAR(r.index_discharge_date), MONTH(r.index_discharge_date), 1) AS discharge_month,
    r.payer_id,
    COALESCE(r.payer_name, 'UNKNOWN') AS payer_name,
    r.synthetic_fixture_flag,
    COUNT_BIG(*) AS denominator,
    SUM(CASE WHEN r.numerator_7d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS numerator_7d,
    SUM(CASE WHEN r.numerator_30d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS numerator_30d,
    CAST(
        100.0 * SUM(CASE WHEN r.numerator_7d_flag = 1 THEN 1.0 ELSE 0.0 END) / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(9,2)
    ) AS rate_7d_pct,
    CAST(
        100.0 * SUM(CASE WHEN r.numerator_30d_flag = 1 THEN 1.0 ELSE 0.0 END) / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(9,2)
    ) AS rate_30d_pct,
    CAST(
        SUM(CASE
                WHEN r.numerator_30d_flag = 1
                    THEN CONVERT(DECIMAL(18,2), r.days_to_first_qualifying_followup)
                ELSE CONVERT(DECIMAL(18,2), 0)
            END)
        / NULLIF(SUM(CASE WHEN r.numerator_30d_flag = 1 THEN 1 ELSE 0 END), 0)
        AS DECIMAL(9,2)
    ) AS avg_days_to_qualifying_followup
FROM measure.fuh_measure_result AS r
GROUP BY
    r.measure_id,
    r.methodology_version,
    r.measurement_year,
    DATEFROMPARTS(YEAR(r.index_discharge_date), MONTH(r.index_discharge_date), 1),
    r.payer_id,
    COALESCE(r.payer_name, 'UNKNOWN'),
    r.synthetic_fixture_flag;
GO

CREATE OR ALTER VIEW measure.fuh_report_demographic
AS
WITH banded AS (
    SELECT
        r.*,
        CASE
            WHEN r.age_at_discharge BETWEEN 6 AND 17 THEN '06-17'
            WHEN r.age_at_discharge BETWEEN 18 AND 34 THEN '18-34'
            WHEN r.age_at_discharge BETWEEN 35 AND 44 THEN '35-44'
            WHEN r.age_at_discharge BETWEEN 45 AND 54 THEN '45-54'
            WHEN r.age_at_discharge BETWEEN 55 AND 64 THEN '55-64'
            WHEN r.age_at_discharge >= 65 THEN '65+'
            ELSE 'UNKNOWN'
        END AS age_band,
        COALESCE(NULLIF(LTRIM(RTRIM(r.sex)), ''), 'UNKNOWN') AS sex_group
    FROM measure.fuh_measure_result AS r
)
SELECT
    measure_id,
    methodology_version,
    measurement_year,
    age_band,
    sex_group,
    synthetic_fixture_flag,
    COUNT_BIG(*) AS denominator,
    SUM(CASE WHEN numerator_7d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS numerator_7d,
    SUM(CASE WHEN numerator_30d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS numerator_30d,
    CAST(
        100.0 * SUM(CASE WHEN numerator_7d_flag = 1 THEN 1.0 ELSE 0.0 END) / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(9,2)
    ) AS rate_7d_pct,
    CAST(
        100.0 * SUM(CASE WHEN numerator_30d_flag = 1 THEN 1.0 ELSE 0.0 END) / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(9,2)
    ) AS rate_30d_pct
FROM banded
GROUP BY
    measure_id,
    methodology_version,
    measurement_year,
    age_band,
    sex_group,
    synthetic_fixture_flag;
GO

CREATE OR ALTER VIEW measure.fuh_report_followup_timing
AS
WITH classified AS (
    SELECT
        r.measure_id,
        r.methodology_version,
        r.measurement_year,
        r.synthetic_fixture_flag,
        CASE
            WHEN r.numerator_7d_flag = 1 THEN '01_DAY_1_7'
            WHEN r.numerator_30d_flag = 1 AND r.days_to_first_qualifying_followup BETWEEN 8 AND 14 THEN '02_DAY_8_14'
            WHEN r.numerator_30d_flag = 1 AND r.days_to_first_qualifying_followup BETWEEN 15 AND 30 THEN '03_DAY_15_30'
            ELSE '04_NO_30D_FOLLOWUP'
        END AS timing_band,
        r.days_to_first_qualifying_followup
    FROM measure.fuh_measure_result AS r
),
aggregated AS (
    SELECT
        measure_id,
        methodology_version,
        measurement_year,
        synthetic_fixture_flag,
        timing_band,
        COUNT_BIG(*) AS episode_count,
        SUM(CASE
                WHEN days_to_first_qualifying_followup IS NOT NULL
                    THEN CONVERT(DECIMAL(18,2), days_to_first_qualifying_followup)
                ELSE CONVERT(DECIMAL(18,2), 0)
            END)
        / NULLIF(SUM(CASE WHEN days_to_first_qualifying_followup IS NOT NULL THEN 1 ELSE 0 END), 0) AS avg_days_to_followup
    FROM classified
    GROUP BY
        measure_id,
        methodology_version,
        measurement_year,
        synthetic_fixture_flag,
        timing_band
)
SELECT
    a.measure_id,
    a.methodology_version,
    a.measurement_year,
    a.synthetic_fixture_flag,
    a.timing_band,
    a.episode_count,
    CAST(
        100.0 * a.episode_count /
        NULLIF(SUM(a.episode_count) OVER (
            PARTITION BY a.measure_id, a.methodology_version, a.measurement_year, a.synthetic_fixture_flag
        ), 0)
        AS DECIMAL(9,2)
    ) AS pct_of_denominator,
    CAST(a.avg_days_to_followup AS DECIMAL(9,2)) AS avg_days_to_followup
FROM aggregated AS a;
GO

CREATE OR ALTER VIEW measure.fuh_open_gap_detail
AS
SELECT
    r.measure_id,
    r.methodology_version,
    r.measurement_year,
    r.analysis_date,
    r.index_event_id,
    r.member_id,
    r.source_member_id,
    r.index_encounter_id,
    r.source_index_encounter_id,
    r.index_discharge_date,
    r.payer_id,
    r.payer_name,
    r.sex,
    r.county_code,
    r.age_at_discharge,
    r.numerator_7d_flag,
    r.numerator_30d_flag,
    r.first_30d_followup_date,
    r.days_to_first_qualifying_followup,
    CASE
        WHEN r.numerator_30d_flag = 0 THEN 'MISSED_30D'
        WHEN r.numerator_7d_flag = 0 AND r.numerator_30d_flag = 1 THEN 'MISSED_7D_MET_30D'
        ELSE NULL
    END AS gap_status,
    r.synthetic_fixture_flag,
    r.index_source_name,
    r.index_source_file,
    r.index_pipeline_run_id
FROM measure.fuh_measure_result AS r
WHERE r.numerator_7d_flag = 0;
GO

SELECT
    discharge_month,
    payer_name,
    CASE WHEN synthetic_fixture_flag = 1 THEN 'FIXTURE' ELSE 'NON_FIXTURE' END AS population_scope,
    denominator,
    numerator_7d,
    numerator_30d,
    rate_7d_pct,
    rate_30d_pct,
    avg_days_to_qualifying_followup
FROM measure.fuh_report_payer_monthly
ORDER BY discharge_month, payer_name, population_scope;
GO

SELECT
    age_band,
    sex_group,
    CASE WHEN synthetic_fixture_flag = 1 THEN 'FIXTURE' ELSE 'NON_FIXTURE' END AS population_scope,
    denominator,
    numerator_7d,
    numerator_30d,
    rate_7d_pct,
    rate_30d_pct
FROM measure.fuh_report_demographic
ORDER BY age_band, sex_group, population_scope;
GO

SELECT
    timing_band,
    CASE WHEN synthetic_fixture_flag = 1 THEN 'FIXTURE' ELSE 'NON_FIXTURE' END AS population_scope,
    episode_count,
    pct_of_denominator,
    avg_days_to_followup
FROM measure.fuh_report_followup_timing
ORDER BY population_scope, timing_band;
GO

SELECT
    gap_status,
    CASE WHEN synthetic_fixture_flag = 1 THEN 'FIXTURE' ELSE 'NON_FIXTURE' END AS population_scope,
    COUNT_BIG(*) AS gap_episodes,
    MIN(index_discharge_date) AS first_index_discharge_date,
    MAX(index_discharge_date) AS last_index_discharge_date
FROM measure.fuh_open_gap_detail
GROUP BY gap_status, synthetic_fixture_flag
ORDER BY population_scope, gap_status;
GO
