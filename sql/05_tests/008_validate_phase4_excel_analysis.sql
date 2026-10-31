/*
Healthcare Payer Analytics Pipeline
Phase 4 - Excel analysis/export layer validation

Tests:
T-XL-001 through T-XL-012

The script fails loudly with THROW when an invariant is violated.
*/

USE HealthcarePayerAnalytics;
GO

SET NOCOUNT ON;

-- T-XL-001: analysis schema and required Excel-facing views exist.
IF SCHEMA_ID('analysis') IS NULL
OR OBJECT_ID('analysis.excel_encounter_activity', 'V') IS NULL
OR OBJECT_ID('analysis.excel_member_data', 'V') IS NULL
OR OBJECT_ID('analysis.excel_fuh_data', 'V') IS NULL
OR OBJECT_ID('analysis.excel_payer_lookup', 'V') IS NULL
    THROW 52401, 'T-XL-001 failed: one or more Phase 4 analysis objects are missing.', 1;

-- T-XL-002: aggregated encounter output has the documented payer x month x encounter-type grain.
IF EXISTS (
    SELECT
        payer_id,
        encounter_month,
        encounter_type
    FROM analysis.excel_encounter_activity
    GROUP BY
        payer_id,
        encounter_month,
        encounter_type
    HAVING COUNT_BIG(*) > 1
)
    THROW 52402, 'T-XL-002 failed: encounter activity grain is duplicated.', 1;

-- T-XL-003: aggregated encounter counts reconcile exactly to core.encounter.
IF COALESCE((
    SELECT SUM(encounter_count)
    FROM analysis.excel_encounter_activity
), 0) <> (
    SELECT COUNT_BIG(*)
    FROM core.encounter
)
    THROW 52403, 'T-XL-003 failed: aggregated encounter_count does not reconcile to core.encounter.', 1;

-- T-XL-004: claim counts survive the one-to-many join without row multiplication or loss.
IF COALESCE((
    SELECT SUM(claim_count)
    FROM analysis.excel_encounter_activity
), 0) <> (
    SELECT COUNT_BIG(*)
    FROM core.claim
)
    THROW 52404, 'T-XL-004 failed: aggregated claim_count does not reconcile to core.claim.', 1;

-- T-XL-005: encounter output has valid summary values and normalized month starts.
IF EXISTS (
    SELECT 1
    FROM analysis.excel_encounter_activity
    WHERE encounter_month IS NULL
       OR DAY(encounter_month) <> 1
       OR encounter_count <= 0
       OR member_count <= 0
       OR member_count > encounter_count
       OR claim_count < 0
       OR payer_name IS NULL
       OR payer_type IS NULL
       OR encounter_type IS NULL
)
    THROW 52405, 'T-XL-005 failed: encounter activity contains invalid summary values.', 1;

-- T-XL-006: member export is exactly one row per core member.
IF (
    SELECT COUNT_BIG(*)
    FROM analysis.excel_member_data
) <> (
    SELECT COUNT_BIG(*)
    FROM core.member
)
OR EXISTS (
    SELECT member_id
    FROM analysis.excel_member_data
    GROUP BY member_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 52406, 'T-XL-006 failed: member export does not reconcile one-to-one to core.member.', 1;

-- T-XL-007: member analytical fields are valid and use the fixed configured analysis date.
IF EXISTS (
    SELECT 1
    FROM analysis.excel_member_data
    WHERE analysis_date IS NULL
       OR age_as_of_analysis_date < 0
       OR age_band NOT IN ('00-17', '18-34', '35-44', '45-54', '55-64', '65+', 'UNKNOWN')
       OR sex IS NULL
)
OR EXISTS (
    SELECT 1
    FROM analysis.excel_member_data AS x
    CROSS JOIN (
        SELECT analysis_date
        FROM ref.measure_definition
        WHERE measure_id = 'FUH_STYLE_MY2025'
          AND active_flag = 1
    ) AS cfg
    WHERE x.analysis_date <> cfg.analysis_date
)
    THROW 52407, 'T-XL-007 failed: member analytical fields or analysis-date lineage are invalid.', 1;

-- T-XL-008: FUH Excel detail remains one row per authoritative denominator event.
IF (
    SELECT COUNT_BIG(*)
    FROM analysis.excel_fuh_data
) <> (
    SELECT COUNT_BIG(*)
    FROM measure.fuh_measure_result
)
OR EXISTS (
    SELECT index_event_id
    FROM analysis.excel_fuh_data
    GROUP BY index_event_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 52408, 'T-XL-008 failed: FUH Excel detail does not reconcile to measure.fuh_measure_result.', 1;

-- T-XL-009: FUH flags and classifications are internally consistent.
IF EXISTS (
    SELECT 1
    FROM analysis.excel_fuh_data
    WHERE denominator_flag <> 1
       OR numerator_7d_flag NOT IN (0, 1)
       OR numerator_30d_flag NOT IN (0, 1)
       OR numerator_7d_flag > numerator_30d_flag
       OR followup_timing_band NOT IN (
            '01_DAY_1_7',
            '02_DAY_8_14',
            '03_DAY_15_30',
            '04_NO_30D_FOLLOWUP'
       )
       OR gap_status NOT IN ('MET_7D', 'MISSED_7D_MET_30D', 'MISSED_30D')
       OR (numerator_7d_flag = 1 AND (followup_timing_band <> '01_DAY_1_7' OR gap_status <> 'MET_7D'))
       OR (numerator_7d_flag = 0 AND numerator_30d_flag = 1 AND gap_status <> 'MISSED_7D_MET_30D')
       OR (numerator_30d_flag = 0 AND (followup_timing_band <> '04_NO_30D_FOLLOWUP' OR gap_status <> 'MISSED_30D'))
)
    THROW 52409, 'T-XL-009 failed: FUH flags/timing/gap classifications are inconsistent.', 1;

-- T-XL-010: controlled FUH fixture benchmark remains 40 / 18 / 32.
IF (
    SELECT COUNT_BIG(*)
    FROM analysis.excel_fuh_data
    WHERE synthetic_fixture_flag = 1
) <> 40
OR (
    SELECT SUM(CASE WHEN numerator_7d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END)
    FROM analysis.excel_fuh_data
    WHERE synthetic_fixture_flag = 1
) <> 18
OR (
    SELECT SUM(CASE WHEN numerator_30d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END)
    FROM analysis.excel_fuh_data
    WHERE synthetic_fixture_flag = 1
) <> 32
    THROW 52410, 'T-XL-010 failed: FUH fixture benchmark is not 40 / 18 / 32.', 1;

-- T-XL-011: payer lookup is one row per core payer and contains required lookup fields.
IF (
    SELECT COUNT_BIG(*)
    FROM analysis.excel_payer_lookup
) <> (
    SELECT COUNT_BIG(*)
    FROM core.payer
)
OR EXISTS (
    SELECT payer_id
    FROM analysis.excel_payer_lookup
    GROUP BY payer_id
    HAVING COUNT_BIG(*) > 1
)
OR EXISTS (
    SELECT 1
    FROM analysis.excel_payer_lookup
    WHERE payer_id IS NULL
       OR payer_name IS NULL
)
    THROW 52411, 'T-XL-011 failed: payer lookup does not reconcile one-to-one to core.payer.', 1;

-- T-XL-012: public Excel-facing views do not expose common personal-looking fields.
IF EXISTS (
    SELECT 1
    FROM sys.columns AS c
    WHERE c.object_id IN (
        OBJECT_ID('analysis.excel_encounter_activity'),
        OBJECT_ID('analysis.excel_member_data'),
        OBJECT_ID('analysis.excel_fuh_data'),
        OBJECT_ID('analysis.excel_payer_lookup')
    )
      AND LOWER(c.name) IN (
        'first_name',
        'last_name',
        'full_name',
        'name',
        'ssn',
        'drivers_license',
        'driver_license',
        'address',
        'address_line',
        'street_address',
        'phone',
        'phone_number',
        'email',
        'email_address',
        'provider_name',
        'organization_name',
        'birth_date'
      )
)
    THROW 52412, 'T-XL-012 failed: an Excel-facing view exposes a prohibited personal-looking field.', 1;

PRINT 'Phase 4 Excel analysis validation passed: T-XL-001 through T-XL-012.';

SELECT
    COUNT_BIG(*) AS encounter_activity_rows,
    SUM(encounter_count) AS encounter_count,
    SUM(claim_count) AS claim_count
FROM analysis.excel_encounter_activity;

SELECT
    COUNT_BIG(*) AS member_rows
FROM analysis.excel_member_data;

SELECT
    COUNT_BIG(*) AS fuh_denominator,
    SUM(CASE WHEN numerator_7d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS numerator_7d,
    SUM(CASE WHEN numerator_30d_flag = 1 THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS numerator_30d
FROM analysis.excel_fuh_data;

SELECT
    COUNT_BIG(*) AS payer_lookup_rows
FROM analysis.excel_payer_lookup;
GO
