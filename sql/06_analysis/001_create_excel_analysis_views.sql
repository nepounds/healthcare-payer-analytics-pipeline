/*
Healthcare Payer Analytics Pipeline
Phase 4 - Excel-facing analysis layer

Purpose:
- expose compact, analysis-ready SQL views for hands-on Excel practice;
- keep large/detail healthcare tables in SQL Server;
- preserve authoritative Phase 2/3 business logic rather than rebuilding it in Excel;
- demonstrate practical INNER JOIN, LEFT JOIN, one-to-many aggregation, and distinct counting.

Objects:
- analysis.excel_encounter_activity
- analysis.excel_member_data
- analysis.excel_fuh_data
- analysis.excel_payer_lookup

Public-workbook design:
- no member names, SSNs, driver's-license values, addresses, phone numbers, or emails;
- encounter detail remains in SQL; the Excel encounter source is aggregated;
- claim transactions remain in SQL and are not required by this layer.
*/

USE HealthcarePayerAnalytics;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'analysis'
)
    EXEC('CREATE SCHEMA analysis');
GO

/*
Grain: one row per encounter payer x encounter month x encounter type.

Join notes:
- LEFT JOIN core.payer preserves encounters whose payer is missing instead of silently
  dropping them from the 313,094-encounter reconciliation.
- core.claim is one-to-many from encounter, so claims are aggregated to one row per
  encounter before being joined. Joining raw claim rows first would multiply encounter
  rows and inflate encounter counts.
- member_count is a distinct count within each group. It is not additive across groups.
*/
CREATE OR ALTER VIEW analysis.excel_encounter_activity
AS
WITH claim_by_encounter AS (
    SELECT
        c.encounter_id,
        COUNT_BIG(*) AS claim_count
    FROM core.claim AS c
    GROUP BY c.encounter_id
)
SELECT
    e.payer_id,
    COALESCE(p.payer_name, 'UNATTRIBUTED') AS payer_name,
    COALESCE(p.ownership, 'UNKNOWN') AS payer_type,
    DATEFROMPARTS(
        YEAR(e.encounter_start_datetime),
        MONTH(e.encounter_start_datetime),
        1
    ) AS encounter_month,
    YEAR(e.encounter_start_datetime) AS encounter_year,
    MONTH(e.encounter_start_datetime) AS encounter_month_number,
    e.encounter_type,
    COUNT_BIG(*) AS encounter_count,
    COUNT_BIG(DISTINCT e.member_id) AS member_count,
    SUM(COALESCE(cbe.claim_count, CONVERT(BIGINT, 0))) AS claim_count
FROM core.encounter AS e
LEFT JOIN core.payer AS p
    ON p.payer_id = e.payer_id
LEFT JOIN claim_by_encounter AS cbe
    ON cbe.encounter_id = e.encounter_id
GROUP BY
    e.payer_id,
    COALESCE(p.payer_name, 'UNATTRIBUTED'),
    COALESCE(p.ownership, 'UNKNOWN'),
    DATEFROMPARTS(
        YEAR(e.encounter_start_datetime),
        MONTH(e.encounter_start_datetime),
        1
    ),
    YEAR(e.encounter_start_datetime),
    MONTH(e.encounter_start_datetime),
    e.encounter_type;
GO

/*
Grain: one row per member.

The fixed analysis date comes from the validated Phase 3 measure configuration so the
age calculation is reproducible instead of drifting with GETDATE(). The export retains
only non-identifying analytical fields.
*/
CREATE OR ALTER VIEW analysis.excel_member_data
AS
WITH config AS (
    SELECT
        analysis_date
    FROM ref.measure_definition
    WHERE measure_id = 'FUH_STYLE_MY2025'
      AND active_flag = 1
),
aged AS (
    SELECT
        m.member_id,
        cfg.analysis_date,
        m.sex,
        m.county_code,
        CAST(CASE WHEN m.deceased_date IS NOT NULL AND m.deceased_date <= cfg.analysis_date THEN 1 ELSE 0 END AS BIT) AS deceased_flag,
        DATEDIFF(YEAR, m.birth_date, cfg.analysis_date)
            - CASE
                WHEN DATEADD(YEAR, DATEDIFF(YEAR, m.birth_date, cfg.analysis_date), m.birth_date) > cfg.analysis_date
                    THEN 1
                ELSE 0
              END AS age_as_of_analysis_date,
        m.synthetic_fixture_flag
    FROM core.member AS m
    CROSS JOIN config AS cfg
)
SELECT
    member_id,
    analysis_date,
    age_as_of_analysis_date,
    CASE
        WHEN age_as_of_analysis_date BETWEEN 0 AND 17 THEN '00-17'
        WHEN age_as_of_analysis_date BETWEEN 18 AND 34 THEN '18-34'
        WHEN age_as_of_analysis_date BETWEEN 35 AND 44 THEN '35-44'
        WHEN age_as_of_analysis_date BETWEEN 45 AND 54 THEN '45-54'
        WHEN age_as_of_analysis_date BETWEEN 55 AND 64 THEN '55-64'
        WHEN age_as_of_analysis_date >= 65 THEN '65+'
        ELSE 'UNKNOWN'
    END AS age_band,
    COALESCE(NULLIF(LTRIM(RTRIM(sex)), ''), 'UNKNOWN') AS sex,
    county_code,
    deceased_flag,
    synthetic_fixture_flag
FROM aged;
GO

/*
Grain: one row per final FUH-style denominator event.

INNER JOIN is appropriate here because an eligible FUH denominator event is required to
have a valid payer relationship. The QA script separately reconciles row counts so an
unexpected missing payer cannot disappear silently.

The numerator flags remain authoritative from measure.fuh_measure_result. This view only
adds Excel-friendly classifications and payer category.
*/
CREATE OR ALTER VIEW analysis.excel_fuh_data
AS
SELECT
    r.member_id,
    r.index_event_id,
    r.index_encounter_id,
    r.payer_id,
    r.payer_name,
    p.ownership AS payer_type,
    r.index_discharge_date AS index_date,
    r.age_at_discharge,
    CASE
        WHEN r.age_at_discharge BETWEEN 6 AND 17 THEN '06-17'
        WHEN r.age_at_discharge BETWEEN 18 AND 34 THEN '18-34'
        WHEN r.age_at_discharge BETWEEN 35 AND 44 THEN '35-44'
        WHEN r.age_at_discharge BETWEEN 45 AND 54 THEN '45-54'
        WHEN r.age_at_discharge BETWEEN 55 AND 64 THEN '55-64'
        WHEN r.age_at_discharge >= 65 THEN '65+'
        ELSE 'UNKNOWN'
    END AS age_band,
    COALESCE(NULLIF(LTRIM(RTRIM(r.sex)), ''), 'UNKNOWN') AS sex,
    r.county_code,
    r.denominator_flag,
    r.numerator_7d_flag,
    r.numerator_30d_flag,
    r.days_to_7d_followup,
    r.days_to_30d_followup,
    r.days_to_first_qualifying_followup,
    CASE
        WHEN r.numerator_7d_flag = 1 THEN '01_DAY_1_7'
        WHEN r.numerator_30d_flag = 1
         AND r.days_to_first_qualifying_followup BETWEEN 8 AND 14 THEN '02_DAY_8_14'
        WHEN r.numerator_30d_flag = 1
         AND r.days_to_first_qualifying_followup BETWEEN 15 AND 30 THEN '03_DAY_15_30'
        ELSE '04_NO_30D_FOLLOWUP'
    END AS followup_timing_band,
    CASE
        WHEN r.numerator_7d_flag = 1 THEN 'MET_7D'
        WHEN r.numerator_30d_flag = 1 THEN 'MISSED_7D_MET_30D'
        ELSE 'MISSED_30D'
    END AS gap_status,
    r.synthetic_fixture_flag
FROM measure.fuh_measure_result AS r
INNER JOIN core.payer AS p
    ON p.payer_id = r.payer_id;
GO

/*
Grain: one row per payer.

This is intentionally small and stable so Excel can use payer_id as a genuine lookup key
for both VLOOKUP and XLOOKUP practice.
*/
CREATE OR ALTER VIEW analysis.excel_payer_lookup
AS
SELECT
    p.payer_id,
    p.source_payer_id,
    p.payer_name,
    p.ownership AS payer_type
FROM core.payer AS p;
GO

/*
Preview / reconciliation outputs for the person running the script in SSMS.
These SELECTs do not create additional persistent objects.
*/
SELECT
    COUNT_BIG(*) AS encounter_activity_rows,
    SUM(encounter_count) AS reconciled_encounters,
    SUM(claim_count) AS reconciled_claims
FROM analysis.excel_encounter_activity;
GO

SELECT
    COUNT_BIG(*) AS member_rows
FROM analysis.excel_member_data;
GO

SELECT
    COUNT_BIG(*) AS fuh_denominator,
    SUM(CASE WHEN numerator_7d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS fuh_7d_numerator,
    SUM(CASE WHEN numerator_30d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS fuh_30d_numerator
FROM analysis.excel_fuh_data;
GO

SELECT
    payer_id,
    payer_name,
    payer_type
FROM analysis.excel_payer_lookup
ORDER BY payer_name, payer_id;
GO
