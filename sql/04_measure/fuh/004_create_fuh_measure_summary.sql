/*
Healthcare Payer Analytics Pipeline
Phase 3 - FUH-style aggregate performance result

Object:
- measure.fuh_measure_summary (view)

Grain:
- One row per reporting population scope: ALL, FIXTURE, NON_FIXTURE.

Rates:
- Returned as percentage values (for example, 45.00 means 45%).
- A zero denominator returns NULL for the rate rather than dividing by zero.

Implementation note:
- Denominator uses SUM(CASE...) instead of COUNT(nullable_column) so the intentional
  outer-join row for an empty reporting scope does not emit SQL Server's
  "Null value is eliminated by an aggregate" warning.
*/

USE HealthcarePayerAnalytics;
GO

CREATE OR ALTER VIEW measure.fuh_measure_summary
AS
WITH config AS (
    SELECT
        measure_id,
        methodology_version,
        measurement_year,
        analysis_date
    FROM ref.measure_definition
    WHERE measure_id = 'FUH_STYLE_MY2025'
      AND active_flag = 1
),
scopes AS (
    SELECT CAST('ALL' AS VARCHAR(20)) AS population_scope
    UNION ALL
    SELECT CAST('FIXTURE' AS VARCHAR(20))
    UNION ALL
    SELECT CAST('NON_FIXTURE' AS VARCHAR(20))
),
aggregated AS (
    SELECT
        cfg.measure_id,
        cfg.methodology_version,
        cfg.measurement_year,
        cfg.analysis_date,
        s.population_scope,
        SUM(CASE WHEN r.index_event_id IS NOT NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS denominator,
        SUM(CASE WHEN r.numerator_7d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS numerator_7d,
        SUM(CASE WHEN r.numerator_30d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS numerator_30d
    FROM config AS cfg
    CROSS JOIN scopes AS s
    LEFT JOIN measure.fuh_measure_result AS r
        ON r.measure_id = cfg.measure_id
       AND (
           s.population_scope = 'ALL'
           OR (s.population_scope = 'FIXTURE' AND r.synthetic_fixture_flag = 1)
           OR (s.population_scope = 'NON_FIXTURE' AND r.synthetic_fixture_flag = 0)
       )
    GROUP BY
        cfg.measure_id,
        cfg.methodology_version,
        cfg.measurement_year,
        cfg.analysis_date,
        s.population_scope
)
SELECT
    measure_id,
    methodology_version,
    measurement_year,
    analysis_date,
    population_scope,
    denominator,
    numerator_7d,
    numerator_30d,
    CAST(
        CASE
            WHEN denominator = 0 THEN NULL
            ELSE 100.0 * numerator_7d / denominator
        END
        AS DECIMAL(9,2)
    ) AS rate_7d_pct,
    CAST(
        CASE
            WHEN denominator = 0 THEN NULL
            ELSE 100.0 * numerator_30d / denominator
        END
        AS DECIMAL(9,2)
    ) AS rate_30d_pct
FROM aggregated;
GO

SELECT
    measure_id,
    methodology_version,
    measurement_year,
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
