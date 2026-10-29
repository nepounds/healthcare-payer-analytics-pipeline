/*
Healthcare Payer Analytics Pipeline
Phase 2 - load remaining core entities

Current implemented scope in this script:
- core.organization
- core.provider
- core.encounter
- core.condition

This file is the canonical Phase 2 loader for the remaining core model. Later
Phase 2 batches extend this same script so the final repository has one
transactional, dependency-aware rebuild path rather than isolated SSMS-only
transforms.

Important:
- raw tables contain only the current landing contents; raw.load_run retains run history.
- This script refreshes the currently implemented remaining-core tables in
  dependency order inside one transaction.
- Run the corresponding core DDL scripts before this loader.
*/

USE HealthcarePayerAnalytics;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID('core.member', 'U') IS NULL
    THROW 51200, 'core.member does not exist. Build the Phase 2 foundation first.', 1;
IF OBJECT_ID('core.payer', 'U') IS NULL
    THROW 51200, 'core.payer does not exist. Build the Phase 2 foundation first.', 1;
IF OBJECT_ID('core.organization', 'U') IS NULL
    THROW 51200, 'core.organization does not exist. Run 005_create_core_organization.sql first.', 1;
IF OBJECT_ID('core.provider', 'U') IS NULL
    THROW 51200, 'core.provider does not exist. Run 006_create_core_provider.sql first.', 1;
IF OBJECT_ID('core.encounter', 'U') IS NULL
    THROW 51200, 'core.encounter does not exist. Run 008_create_core_encounter.sql first.', 1;
IF OBJECT_ID('core.condition', 'U') IS NULL
    THROW 51200, 'core.condition does not exist. Run 009_create_core_condition.sql first.', 1;
GO

DECLARE @pipeline_run_id UNIQUEIDENTIFIER;
DECLARE @raw_organization_rows BIGINT;
DECLARE @raw_provider_rows BIGINT;
DECLARE @raw_encounter_rows BIGINT;
DECLARE @raw_condition_rows BIGINT;

SELECT TOP (1) @pipeline_run_id = pipeline_run_id
FROM core.member;

SELECT @raw_organization_rows = COUNT_BIG(*) FROM raw.organization;
SELECT @raw_provider_rows = COUNT_BIG(*) FROM raw.provider;
SELECT @raw_encounter_rows = COUNT_BIG(*) FROM raw.encounter;
SELECT @raw_condition_rows = COUNT_BIG(*) FROM raw.condition;

IF @pipeline_run_id IS NULL
    THROW 51201, 'core.member is empty. Run the Phase 2 foundation load first.', 1;
IF @raw_organization_rows = 0
    THROW 51202, 'raw.organization is empty. Run the Phase 1 raw loader first.', 1;
IF @raw_provider_rows = 0
    THROW 51203, 'raw.provider is empty. Run the Phase 1 raw loader first.', 1;
IF @raw_encounter_rows = 0
    THROW 51204, 'raw.encounter is empty. Run the Phase 1 raw loader first.', 1;
IF @raw_condition_rows = 0
    THROW 51205, 'raw.condition is empty. Run the Phase 1 raw loader first.', 1;

IF (SELECT COUNT(DISTINCT pipeline_run_id) FROM core.member) <> 1
    THROW 51206, 'core.member contains more than one pipeline_run_id.', 1;
IF EXISTS (SELECT 1 FROM core.payer WHERE pipeline_run_id <> @pipeline_run_id)
    THROW 51207, 'core.payer does not match the current core.member pipeline_run_id.', 1;
IF EXISTS (SELECT 1 FROM raw.organization WHERE pipeline_run_id <> @pipeline_run_id)
    THROW 51208, 'raw.organization does not match the current core.member pipeline_run_id.', 1;
IF EXISTS (SELECT 1 FROM raw.provider WHERE pipeline_run_id <> @pipeline_run_id)
    THROW 51209, 'raw.provider does not match the current core.member pipeline_run_id.', 1;
IF EXISTS (SELECT 1 FROM raw.encounter WHERE pipeline_run_id <> @pipeline_run_id)
    THROW 51210, 'raw.encounter does not match the current core.member pipeline_run_id.', 1;
IF EXISTS (SELECT 1 FROM raw.condition WHERE pipeline_run_id <> @pipeline_run_id)
    THROW 51211, 'raw.condition does not match the current core.member pipeline_run_id.', 1;

IF NOT EXISTS (
    SELECT 1
    FROM raw.load_run
    WHERE pipeline_run_id = @pipeline_run_id
      AND status = 'SUCCESS'
)
    THROW 51212, 'Current pipeline_run_id is not recorded as SUCCESS in raw.load_run.', 1;

/* ---------- source-quality checks: organization ---------- */
IF EXISTS (
    SELECT 1
    FROM raw.organization
    WHERE NULLIF(LTRIM(RTRIM([Id])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([NAME])), '') IS NULL
)
    THROW 51220, 'raw.organization contains a blank Id or NAME.', 1;

IF EXISTS (
    SELECT [Id]
    FROM raw.organization
    GROUP BY [Id]
    HAVING COUNT_BIG(*) > 1
)
    THROW 51221, 'raw.organization contains duplicate Id values.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.organization
    WHERE LEN(LTRIM(RTRIM([NAME]))) > 512
       OR LEN(NULLIF(LTRIM(RTRIM([NPI])), '')) > 20
       OR LEN(NULLIF(LTRIM(RTRIM([ZIP])), '')) > 20
       OR LEN(source_file) > 255
)
    THROW 51222, 'raw.organization contains a value longer than the current core.organization target column.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.organization
    WHERE NULLIF(LTRIM(RTRIM([STATE])), '') IS NOT NULL
      AND UPPER(LTRIM(RTRIM([STATE]))) <> 'NORTH CAROLINA'
      AND LEN(LTRIM(RTRIM([STATE]))) <> 2
)
    THROW 51223, 'raw.organization contains a nonblank STATE that cannot be normalized to a 2-character code.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.organization
    WHERE NULLIF(LTRIM(RTRIM([LAT])), '') IS NOT NULL
      AND (
            TRY_CONVERT(DECIMAL(12,8), LTRIM(RTRIM([LAT]))) IS NULL
            OR TRY_CONVERT(DECIMAL(12,8), LTRIM(RTRIM([LAT]))) NOT BETWEEN -90 AND 90
          )
)
    THROW 51224, 'raw.organization contains an invalid LAT value.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.organization
    WHERE NULLIF(LTRIM(RTRIM([LON])), '') IS NOT NULL
      AND (
            TRY_CONVERT(DECIMAL(12,8), LTRIM(RTRIM([LON]))) IS NULL
            OR TRY_CONVERT(DECIMAL(12,8), LTRIM(RTRIM([LON]))) NOT BETWEEN -180 AND 180
          )
)
    THROW 51225, 'raw.organization contains an invalid LON value.', 1;

/* ---------- source-quality checks: provider ---------- */
IF EXISTS (
    SELECT 1
    FROM raw.provider
    WHERE NULLIF(LTRIM(RTRIM([Id])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([ORGANIZATION])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([NAME])), '') IS NULL
)
    THROW 51230, 'raw.provider contains a blank Id, ORGANIZATION, or NAME.', 1;

IF EXISTS (
    SELECT [Id]
    FROM raw.provider
    GROUP BY [Id]
    HAVING COUNT_BIG(*) > 1
)
    THROW 51231, 'raw.provider contains duplicate Id values.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.provider
    WHERE NULLIF(LTRIM(RTRIM([GENDER])), '') IS NOT NULL
      AND UPPER(LTRIM(RTRIM([GENDER]))) NOT IN ('F', 'M')
)
    THROW 51232, 'raw.provider contains a nonblank GENDER outside F/M.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.provider
    WHERE LEN(LTRIM(RTRIM([NAME]))) > 512
       OR LEN(NULLIF(LTRIM(RTRIM([SPECIALITY])), '')) > 255
       OR LEN(NULLIF(LTRIM(RTRIM([NPI])), '')) > 20
       OR LEN(source_file) > 255
)
    THROW 51233, 'raw.provider contains a value longer than the current core.provider target column.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.provider p
    LEFT JOIN raw.organization o
        ON LTRIM(RTRIM(o.[Id])) = LTRIM(RTRIM(p.[ORGANIZATION]))
    WHERE o.[Id] IS NULL
)
    THROW 51234, 'raw.provider contains ORGANIZATION values not found in raw.organization.', 1;

/* ---------- source-quality checks: encounter ---------- */
IF EXISTS (
    SELECT 1
    FROM raw.encounter
    WHERE NULLIF(LTRIM(RTRIM([Id])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([PATIENT])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([START])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([STOP])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([ENCOUNTERCLASS])), '') IS NULL
)
    THROW 51240, 'raw.encounter contains a blank Id, PATIENT, START, STOP, or ENCOUNTERCLASS.', 1;

IF EXISTS (
    SELECT [Id]
    FROM raw.encounter
    GROUP BY [Id]
    HAVING COUNT_BIG(*) > 1
)
    THROW 51241, 'raw.encounter contains duplicate Id values.', 1;

/*
Materialize a normalized encounter lookup once for downstream raw.condition
integrity checks. raw.* is intentionally landing-oriented and unindexed; joining
raw.condition to raw.encounter with trimming expressions on both sides causes an
expensive repeated scan. The temp-table PK keeps the validation deterministic
without changing the raw landing schema.
*/
IF OBJECT_ID('tempdb..#raw_encounter_lookup') IS NOT NULL
    DROP TABLE #raw_encounter_lookup;

CREATE TABLE #raw_encounter_lookup (
    source_encounter_id VARCHAR(64) NOT NULL
        CONSTRAINT PK_raw_encounter_lookup PRIMARY KEY,
    source_patient_id VARCHAR(64) NOT NULL
);

INSERT INTO #raw_encounter_lookup (source_encounter_id, source_patient_id)
SELECT
    LTRIM(RTRIM([Id])) AS source_encounter_id,
    LTRIM(RTRIM([PATIENT])) AS source_patient_id
FROM raw.encounter;

IF EXISTS (
    SELECT 1
    FROM raw.encounter
    WHERE TRY_CONVERT(DATETIMEOFFSET(0), NULLIF(LTRIM(RTRIM([START])), ''), 127) IS NULL
       OR TRY_CONVERT(DATETIMEOFFSET(0), NULLIF(LTRIM(RTRIM([STOP])), ''), 127) IS NULL
)
    THROW 51242, 'raw.encounter contains an invalid START or STOP timestamp.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.encounter
    WHERE TRY_CONVERT(DATETIMEOFFSET(0), LTRIM(RTRIM([STOP])), 127)
        < TRY_CONVERT(DATETIMEOFFSET(0), LTRIM(RTRIM([START])), 127)
)
    THROW 51243, 'raw.encounter contains STOP before START.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.encounter
    WHERE (NULLIF(LTRIM(RTRIM([BASE_ENCOUNTER_COST])), '') IS NOT NULL
           AND TRY_CONVERT(DECIMAL(19,2), LTRIM(RTRIM([BASE_ENCOUNTER_COST]))) IS NULL)
       OR (NULLIF(LTRIM(RTRIM([TOTAL_CLAIM_COST])), '') IS NOT NULL
           AND TRY_CONVERT(DECIMAL(19,2), LTRIM(RTRIM([TOTAL_CLAIM_COST]))) IS NULL)
       OR (NULLIF(LTRIM(RTRIM([PAYER_COVERAGE])), '') IS NOT NULL
           AND TRY_CONVERT(DECIMAL(19,2), LTRIM(RTRIM([PAYER_COVERAGE]))) IS NULL)
)
    THROW 51244, 'raw.encounter contains a nonnumeric source cost value.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.encounter
    WHERE TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM([BASE_ENCOUNTER_COST])), '')) < 0
       OR TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM([TOTAL_CLAIM_COST])), '')) < 0
       OR TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM([PAYER_COVERAGE])), '')) < 0
)
    THROW 51245, 'raw.encounter contains a negative source cost value.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.encounter
    WHERE LEN(LTRIM(RTRIM([ENCOUNTERCLASS]))) > 128
       OR LEN(NULLIF(LTRIM(RTRIM([CODE])), '')) > 255
       OR LEN(NULLIF(LTRIM(RTRIM([REASONCODE])), '')) > 255
       OR LEN(source_file) > 255
)
    THROW 51246, 'raw.encounter contains a value longer than the current core.encounter target column.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.encounter e
    LEFT JOIN core.member m
        ON m.source_patient_id = LTRIM(RTRIM(e.[PATIENT]))
    WHERE m.member_id IS NULL
)
    THROW 51247, 'raw.encounter contains PATIENT values not found in core.member.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.encounter e
    LEFT JOIN core.organization o
        ON o.source_organization_id = NULLIF(LTRIM(RTRIM(e.[ORGANIZATION])), '')
    WHERE NULLIF(LTRIM(RTRIM(e.[ORGANIZATION])), '') IS NOT NULL
      AND o.organization_id IS NULL
)
    THROW 51248, 'raw.encounter contains nonblank ORGANIZATION values not found in core.organization.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.encounter e
    LEFT JOIN core.provider p
        ON p.source_provider_id = NULLIF(LTRIM(RTRIM(e.[PROVIDER])), '')
    WHERE NULLIF(LTRIM(RTRIM(e.[PROVIDER])), '') IS NOT NULL
      AND p.provider_id IS NULL
)
    THROW 51249, 'raw.encounter contains nonblank PROVIDER values not found in core.provider.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.encounter e
    LEFT JOIN core.payer p
        ON p.source_payer_id = NULLIF(LTRIM(RTRIM(e.[PAYER])), '')
    WHERE NULLIF(LTRIM(RTRIM(e.[PAYER])), '') IS NOT NULL
      AND p.payer_id IS NULL
)
    THROW 51250, 'raw.encounter contains nonblank PAYER values not found in core.payer.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.encounter e
    INNER JOIN core.provider p
        ON p.source_provider_id = NULLIF(LTRIM(RTRIM(e.[PROVIDER])), '')
    INNER JOIN core.organization o
        ON o.source_organization_id = NULLIF(LTRIM(RTRIM(e.[ORGANIZATION])), '')
    WHERE p.organization_id <> o.organization_id
)
    THROW 51251, 'raw.encounter PROVIDER and ORGANIZATION resolve to different provider-network organizations.', 1;

/* ---------- source-quality checks: condition ---------- */
IF EXISTS (
    SELECT 1
    FROM raw.condition
    WHERE NULLIF(LTRIM(RTRIM([PATIENT])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([START])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([SYSTEM])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([CODE])), '') IS NULL
)
    THROW 51260, 'raw.condition contains a blank PATIENT, START, SYSTEM, or CODE.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.condition
    WHERE TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM([START])), ''), 23) IS NULL
       OR (
            NULLIF(LTRIM(RTRIM([STOP])), '') IS NOT NULL
            AND TRY_CONVERT(DATE, LTRIM(RTRIM([STOP])), 23) IS NULL
          )
)
    THROW 51261, 'raw.condition contains an invalid START or nonblank STOP date.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.condition
    WHERE TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM([STOP])), ''), 23)
        < TRY_CONVERT(DATE, LTRIM(RTRIM([START])), 23)
)
    THROW 51262, 'raw.condition contains STOP before START.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.condition
    WHERE LEN(LTRIM(RTRIM([SYSTEM]))) > 255
       OR LEN(LTRIM(RTRIM([CODE]))) > 255
       OR LEN(source_file) > 255
)
    THROW 51263, 'raw.condition contains a value longer than the current core.condition target column.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.condition c
    LEFT JOIN core.member m
        ON m.source_patient_id = LTRIM(RTRIM(c.[PATIENT]))
    WHERE m.member_id IS NULL
)
    THROW 51264, 'raw.condition contains PATIENT values not found in core.member.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.condition c
    LEFT JOIN #raw_encounter_lookup e
        ON e.source_encounter_id = NULLIF(LTRIM(RTRIM(c.[ENCOUNTER])), '')
    WHERE NULLIF(LTRIM(RTRIM(c.[ENCOUNTER])), '') IS NOT NULL
      AND e.source_encounter_id IS NULL
)
    THROW 51265, 'raw.condition contains nonblank ENCOUNTER values not found in raw.encounter.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.condition c
    INNER JOIN #raw_encounter_lookup e
        ON e.source_encounter_id = NULLIF(LTRIM(RTRIM(c.[ENCOUNTER])), '')
    WHERE LTRIM(RTRIM(c.[PATIENT])) <> e.source_patient_id
)
    THROW 51266, 'raw.condition PATIENT disagrees with the referenced raw.encounter PATIENT.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    /* Refresh in dependency order. This loader is extended as Phase 2 grows. */
    DELETE FROM core.condition;
    DELETE FROM core.encounter;
    DELETE FROM core.provider;
    DELETE FROM core.organization;

    DBCC CHECKIDENT ('core.condition', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('core.encounter', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('core.provider', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('core.organization', RESEED, 0) WITH NO_INFOMSGS;

    /* ---------- core.organization ---------- */
    INSERT INTO core.organization (
        source_organization_id,
        organization_name,
        npi,
        address_line,
        city,
        state_code,
        zip_code,
        latitude,
        longitude,
        synthetic_fixture_flag,
        source_name,
        source_file,
        pipeline_run_id
    )
    SELECT
        LTRIM(RTRIM([Id])) AS source_organization_id,
        LTRIM(RTRIM([NAME])) AS organization_name,
        NULLIF(LTRIM(RTRIM([NPI])), '') AS npi,
        NULLIF(LTRIM(RTRIM([ADDRESS])), '') AS address_line,
        NULLIF(LTRIM(RTRIM([CITY])), '') AS city,
        CAST(
            CASE
                WHEN NULLIF(LTRIM(RTRIM([STATE])), '') IS NULL THEN NULL
                WHEN UPPER(LTRIM(RTRIM([STATE]))) = 'NORTH CAROLINA' THEN 'NC'
                ELSE UPPER(LTRIM(RTRIM([STATE])))
            END
            AS CHAR(2)
        ) AS state_code,
        NULLIF(LTRIM(RTRIM([ZIP])), '') AS zip_code,
        TRY_CONVERT(DECIMAL(9,6), NULLIF(LTRIM(RTRIM([LAT])), '')) AS latitude,
        TRY_CONVERT(DECIMAL(9,6), NULLIF(LTRIM(RTRIM([LON])), '')) AS longitude,
        synthetic_fixture_flag,
        source_name,
        source_file,
        pipeline_run_id
    FROM raw.organization;

    /* ---------- core.provider ---------- */
    INSERT INTO core.provider (
        source_provider_id,
        organization_id,
        provider_name,
        sex,
        specialty,
        npi,
        synthetic_fixture_flag,
        source_name,
        source_file,
        pipeline_run_id
    )
    SELECT
        LTRIM(RTRIM(p.[Id])) AS source_provider_id,
        o.organization_id,
        LTRIM(RTRIM(p.[NAME])) AS provider_name,
        CAST(NULLIF(UPPER(LTRIM(RTRIM(p.[GENDER]))), '') AS CHAR(1)) AS sex,
        NULLIF(LTRIM(RTRIM(p.[SPECIALITY])), '') AS specialty,
        NULLIF(LTRIM(RTRIM(p.[NPI])), '') AS npi,
        p.synthetic_fixture_flag,
        p.source_name,
        p.source_file,
        p.pipeline_run_id
    FROM raw.provider p
    INNER JOIN core.organization o
        ON o.source_organization_id = LTRIM(RTRIM(p.[ORGANIZATION]));

    /* ---------- core.encounter ---------- */
    INSERT INTO core.encounter (
        source_encounter_id,
        member_id,
        organization_id,
        provider_id,
        payer_id,
        encounter_start_datetime,
        encounter_end_datetime,
        encounter_type,
        encounter_code,
        encounter_description,
        reason_code,
        reason_description,
        base_encounter_cost,
        total_claim_cost,
        payer_coverage,
        synthetic_fixture_flag,
        source_name,
        source_file,
        pipeline_run_id
    )
    SELECT
        LTRIM(RTRIM(e.[Id])) AS source_encounter_id,
        m.member_id,
        o.organization_id,
        pr.provider_id,
        py.payer_id,
        CAST(SWITCHOFFSET(CONVERT(DATETIMEOFFSET(0), LTRIM(RTRIM(e.[START])), 127), '+00:00') AS DATETIME2(0)) AS encounter_start_datetime,
        CAST(SWITCHOFFSET(CONVERT(DATETIMEOFFSET(0), LTRIM(RTRIM(e.[STOP])), 127), '+00:00') AS DATETIME2(0)) AS encounter_end_datetime,
        LTRIM(RTRIM(e.[ENCOUNTERCLASS])) AS encounter_type,
        NULLIF(LTRIM(RTRIM(e.[CODE])), '') AS encounter_code,
        NULLIF(LTRIM(RTRIM(e.[DESCRIPTION])), '') AS encounter_description,
        NULLIF(LTRIM(RTRIM(e.[REASONCODE])), '') AS reason_code,
        NULLIF(LTRIM(RTRIM(e.[REASONDESCRIPTION])), '') AS reason_description,
        TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM(e.[BASE_ENCOUNTER_COST])), '')) AS base_encounter_cost,
        TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM(e.[TOTAL_CLAIM_COST])), '')) AS total_claim_cost,
        TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM(e.[PAYER_COVERAGE])), '')) AS payer_coverage,
        e.synthetic_fixture_flag,
        e.source_name,
        e.source_file,
        e.pipeline_run_id
    FROM raw.encounter e
    INNER JOIN core.member m
        ON m.source_patient_id = LTRIM(RTRIM(e.[PATIENT]))
    LEFT JOIN core.organization o
        ON o.source_organization_id = NULLIF(LTRIM(RTRIM(e.[ORGANIZATION])), '')
    LEFT JOIN core.provider pr
        ON pr.source_provider_id = NULLIF(LTRIM(RTRIM(e.[PROVIDER])), '')
    LEFT JOIN core.payer py
        ON py.source_payer_id = NULLIF(LTRIM(RTRIM(e.[PAYER])), '');

    /* ---------- core.condition ---------- */
    INSERT INTO core.condition (
        member_id,
        encounter_id,
        code_system,
        diagnosis_code,
        diagnosis_description,
        condition_start_date,
        condition_end_date,
        synthetic_fixture_flag,
        source_name,
        source_file,
        pipeline_run_id
    )
    SELECT
        m.member_id,
        e.encounter_id,
        LTRIM(RTRIM(c.[SYSTEM])) AS code_system,
        LTRIM(RTRIM(c.[CODE])) AS diagnosis_code,
        NULLIF(LTRIM(RTRIM(c.[DESCRIPTION])), '') AS diagnosis_description,
        CONVERT(DATE, LTRIM(RTRIM(c.[START])), 23) AS condition_start_date,
        TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(c.[STOP])), ''), 23) AS condition_end_date,
        c.synthetic_fixture_flag,
        c.source_name,
        c.source_file,
        c.pipeline_run_id
    FROM raw.condition c
    INNER JOIN core.member m
        ON m.source_patient_id = LTRIM(RTRIM(c.[PATIENT]))
    LEFT JOIN core.encounter e
        ON e.source_encounter_id = NULLIF(LTRIM(RTRIM(c.[ENCOUNTER])), '');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;

IF OBJECT_ID('tempdb..#raw_encounter_lookup') IS NOT NULL
    DROP TABLE #raw_encounter_lookup;

SELECT
    @pipeline_run_id AS pipeline_run_id,
    @raw_organization_rows AS raw_organization_rows,
    (SELECT COUNT_BIG(*) FROM core.organization) AS core_organization_rows,
    @raw_provider_rows AS raw_provider_rows,
    (SELECT COUNT_BIG(*) FROM core.provider) AS core_provider_rows,
    @raw_encounter_rows AS raw_encounter_rows,
    (SELECT COUNT_BIG(*) FROM core.encounter) AS core_encounter_rows,
    @raw_condition_rows AS raw_condition_rows,
    (SELECT COUNT_BIG(*) FROM core.condition) AS core_condition_rows,
    (SELECT COUNT_BIG(*) FROM core.encounter WHERE synthetic_fixture_flag = 1) AS fixture_encounter_rows,
    (SELECT COUNT_BIG(*) FROM core.condition WHERE synthetic_fixture_flag = 1) AS fixture_condition_rows;
GO
