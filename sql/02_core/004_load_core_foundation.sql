/*
Healthcare Payer Analytics Pipeline
Phase 2 - load core foundation

Purpose:
- Rebuild core.member, core.payer, and core.enrollment_span from the current raw landing run.
- Keep typing/normalization in SQL rather than in Python ingestion.
- Make the first Phase 2 transforms reproducible outside an SSMS scratch window.

Important:
- raw tables contain only the current landing contents; raw.load_run retains run history.
- This script intentionally refreshes the three foundation core tables in dependency order.
- Run after 001_create_core_member.sql, 002_create_core_payer.sql, and
  003_create_core_enrollment_span.sql.
*/

USE HealthcarePayerAnalytics;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID('core.member', 'U') IS NULL
    THROW 51000, 'core.member does not exist. Run 001_create_core_member.sql first.', 1;
IF OBJECT_ID('core.payer', 'U') IS NULL
    THROW 51000, 'core.payer does not exist. Run 002_create_core_payer.sql first.', 1;
IF OBJECT_ID('core.enrollment_span', 'U') IS NULL
    THROW 51000, 'core.enrollment_span does not exist. Run 003_create_core_enrollment_span.sql first.', 1;
GO

DECLARE @pipeline_run_id UNIQUEIDENTIFIER;
DECLARE @raw_patient_rows BIGINT;
DECLARE @raw_payer_rows BIGINT;
DECLARE @raw_enrollment_rows BIGINT;

SELECT @raw_patient_rows = COUNT_BIG(*) FROM raw.patient;
SELECT TOP (1) @pipeline_run_id = pipeline_run_id FROM raw.patient;

SELECT @raw_payer_rows = COUNT_BIG(*) FROM raw.payer;
SELECT @raw_enrollment_rows = COUNT_BIG(*) FROM raw.payer_transition;

IF @raw_patient_rows = 0
    THROW 51001, 'raw.patient is empty. Run the Phase 1 raw loader first.', 1;
IF @raw_payer_rows = 0
    THROW 51002, 'raw.payer is empty. Run the Phase 1 raw loader first.', 1;
IF @raw_enrollment_rows = 0
    THROW 51003, 'raw.payer_transition is empty. Run the Phase 1 raw loader first.', 1;

IF (SELECT COUNT(DISTINCT pipeline_run_id) FROM raw.patient) <> 1
    THROW 51004, 'raw.patient contains more than one pipeline_run_id.', 1;
IF EXISTS (SELECT 1 FROM raw.payer WHERE pipeline_run_id <> @pipeline_run_id)
    THROW 51005, 'raw.payer does not match the current raw.patient pipeline_run_id.', 1;
IF EXISTS (SELECT 1 FROM raw.payer_transition WHERE pipeline_run_id <> @pipeline_run_id)
    THROW 51006, 'raw.payer_transition does not match the current raw.patient pipeline_run_id.', 1;

IF NOT EXISTS (
    SELECT 1
    FROM raw.load_run
    WHERE pipeline_run_id = @pipeline_run_id
      AND status = 'SUCCESS'
)
    THROW 51007, 'Current raw pipeline_run_id is not recorded as SUCCESS in raw.load_run.', 1;

/* ---------- source-quality checks: member ---------- */
IF EXISTS (
    SELECT 1
    FROM raw.patient
    WHERE NULLIF(LTRIM(RTRIM([Id])), '') IS NULL
)
    THROW 51010, 'raw.patient contains a blank patient Id.', 1;

IF EXISTS (
    SELECT [Id]
    FROM raw.patient
    GROUP BY [Id]
    HAVING COUNT_BIG(*) > 1
)
    THROW 51011, 'raw.patient contains duplicate patient Id values.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.patient
    WHERE TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM([BIRTHDATE])), ''), 23) IS NULL
)
    THROW 51012, 'raw.patient contains a blank or invalid BIRTHDATE.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.patient
    WHERE NULLIF(LTRIM(RTRIM([DEATHDATE])), '') IS NOT NULL
      AND TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM([DEATHDATE])), ''), 23) IS NULL
)
    THROW 51013, 'raw.patient contains an invalid nonblank DEATHDATE.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.patient
    WHERE NULLIF(LTRIM(RTRIM([GENDER])), '') IS NOT NULL
      AND UPPER(LTRIM(RTRIM([GENDER]))) NOT IN ('F', 'M')
)
    THROW 51014, 'raw.patient contains a nonblank GENDER outside F/M.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.patient
    WHERE NULLIF(LTRIM(RTRIM([STATE])), '') IS NOT NULL
      AND UPPER(LTRIM(RTRIM([STATE]))) NOT IN ('NC', 'NORTH CAROLINA')
)
    THROW 51015, 'raw.patient contains a state outside the modeled North Carolina population.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.patient
    WHERE NULLIF(LTRIM(RTRIM([FIPS])), '') IS NOT NULL
      AND (
            LEN(LTRIM(RTRIM([FIPS]))) > 5
            OR TRY_CONVERT(INT, LTRIM(RTRIM([FIPS]))) IS NULL
          )
)
    THROW 51016, 'raw.patient contains a FIPS value that cannot be normalized to a 5-character code.', 1;

/* ---------- source-quality checks: payer ---------- */
IF EXISTS (
    SELECT 1
    FROM raw.payer
    WHERE NULLIF(LTRIM(RTRIM([Id])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([NAME])), '') IS NULL
)
    THROW 51020, 'raw.payer contains a blank Id or NAME.', 1;

IF EXISTS (
    SELECT [Id]
    FROM raw.payer
    GROUP BY [Id]
    HAVING COUNT_BIG(*) > 1
)
    THROW 51021, 'raw.payer contains duplicate payer Id values.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.payer
    WHERE LEN(LTRIM(RTRIM([NAME]))) > 100
       OR LEN(NULLIF(LTRIM(RTRIM([OWNERSHIP])), '')) > 50
       OR LEN(source_file) > 255
)
    THROW 51022, 'raw.payer contains a value longer than the current core.payer target column.', 1;

/* ---------- source-quality checks: enrollment ---------- */
IF EXISTS (
    SELECT 1
    FROM raw.payer_transition
    WHERE NULLIF(LTRIM(RTRIM([PATIENT])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([PAYER])), '') IS NULL
)
    THROW 51030, 'raw.payer_transition contains a blank PATIENT or PAYER.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.payer_transition
    WHERE TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM([START_DATE])), ''), 23) IS NULL
       OR TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM([END_DATE])), ''), 23) IS NULL
)
    THROW 51031, 'raw.payer_transition contains a blank or invalid START_DATE/END_DATE.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.payer_transition
    WHERE TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM([END_DATE])), ''), 23)
        < TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM([START_DATE])), ''), 23)
)
    THROW 51032, 'raw.payer_transition contains END_DATE before START_DATE.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    /* Refresh in dependency order. */
    DELETE FROM core.enrollment_span;
    DELETE FROM core.member;
    DELETE FROM core.payer;

    DBCC CHECKIDENT ('core.enrollment_span', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('core.member', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('core.payer', RESEED, 0) WITH NO_INFOMSGS;

    /* ---------- core.member ---------- */
    INSERT INTO core.member (
        source_patient_id,
        birth_date,
        deceased_date,
        sex,
        county_code,
        state_code,
        synthetic_fixture_flag,
        source_name,
        pipeline_run_id
    )
    SELECT
        LTRIM(RTRIM([Id])) AS source_patient_id,
        CONVERT(DATE, LTRIM(RTRIM([BIRTHDATE])), 23) AS birth_date,
        TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM([DEATHDATE])), ''), 23) AS deceased_date,
        CAST(NULLIF(UPPER(LTRIM(RTRIM([GENDER]))), '') AS CHAR(1)) AS sex,
        CAST(
            CASE
                WHEN NULLIF(LTRIM(RTRIM([FIPS])), '') IS NULL THEN NULL
                ELSE RIGHT('00000' + LTRIM(RTRIM([FIPS])), 5)
            END
            AS CHAR(5)
        ) AS county_code,
        CAST(
            CASE
                WHEN NULLIF(LTRIM(RTRIM([STATE])), '') IS NULL THEN NULL
                ELSE 'NC'
            END
            AS CHAR(2)
        ) AS state_code,
        synthetic_fixture_flag,
        source_name,
        pipeline_run_id
    FROM raw.patient;

    /* ---------- core.payer ---------- */
    INSERT INTO core.payer (
        source_payer_id,
        payer_name,
        ownership,
        source_name,
        source_file,
        pipeline_run_id
    )
    SELECT
        LTRIM(RTRIM([Id])) AS source_payer_id,
        LTRIM(RTRIM([NAME])) AS payer_name,
        NULLIF(LTRIM(RTRIM([OWNERSHIP])), '') AS ownership,
        source_name,
        source_file,
        pipeline_run_id
    FROM raw.payer;

    IF EXISTS (
        SELECT 1
        FROM raw.payer_transition pt
        LEFT JOIN core.member m
            ON m.source_patient_id = LTRIM(RTRIM(pt.[PATIENT]))
        WHERE m.member_id IS NULL
    )
        THROW 51033, 'raw.payer_transition contains PATIENT values not found in core.member.', 1;

    IF EXISTS (
        SELECT 1
        FROM raw.payer_transition pt
        LEFT JOIN core.payer p
            ON p.source_payer_id = LTRIM(RTRIM(pt.[PAYER]))
        WHERE p.payer_id IS NULL
    )
        THROW 51034, 'raw.payer_transition contains PAYER values not found in core.payer.', 1;

    /*
    ---------- core.enrollment_span ----------

    A-018 educational benefit approximation:
    - Medicaid => medical_benefit_flag = 1 and behavioral_health_benefit_flag = 1
    - all other primary payers => 0 / 0 for the current Quality milestone

    Gaps-and-islands rule:
    - within member/payer/benefit/lineage partitions, overlapping or directly
      adjacent rows belong to the same continuous span;
    - use the running maximum prior end date rather than simple LAG(end_date)
      so nested overlaps cannot create false islands.
    */
    ;WITH typed_enrollment AS (
        SELECT
            m.member_id,
            p.payer_id,
            CONVERT(DATE, LTRIM(RTRIM(pt.[START_DATE])), 23) AS enrollment_start_date,
            CONVERT(DATE, LTRIM(RTRIM(pt.[END_DATE])), 23) AS enrollment_end_date,
            CAST(
                CASE WHEN UPPER(LTRIM(RTRIM(p.payer_name))) = 'MEDICAID' THEN 1 ELSE 0 END
                AS BIT
            ) AS medical_benefit_flag,
            CAST(
                CASE WHEN UPPER(LTRIM(RTRIM(p.payer_name))) = 'MEDICAID' THEN 1 ELSE 0 END
                AS BIT
            ) AS behavioral_health_benefit_flag,
            pt.synthetic_fixture_flag,
            pt.source_name,
            pt.pipeline_run_id
        FROM raw.payer_transition pt
        INNER JOIN core.member m
            ON m.source_patient_id = LTRIM(RTRIM(pt.[PATIENT]))
        INNER JOIN core.payer p
            ON p.source_payer_id = LTRIM(RTRIM(pt.[PAYER]))
    ),
    distinct_intervals AS (
        SELECT
            member_id,
            payer_id,
            enrollment_start_date,
            enrollment_end_date,
            medical_benefit_flag,
            behavioral_health_benefit_flag,
            synthetic_fixture_flag,
            source_name,
            pipeline_run_id,
            COUNT_BIG(*) AS raw_rows_in_interval
        FROM typed_enrollment
        GROUP BY
            member_id,
            payer_id,
            enrollment_start_date,
            enrollment_end_date,
            medical_benefit_flag,
            behavioral_health_benefit_flag,
            synthetic_fixture_flag,
            source_name,
            pipeline_run_id
    ),
    prior_bounds AS (
        SELECT
            di.*,
            MAX(di.enrollment_end_date) OVER (
                PARTITION BY
                    di.member_id,
                    di.payer_id,
                    di.medical_benefit_flag,
                    di.behavioral_health_benefit_flag,
                    di.synthetic_fixture_flag,
                    di.source_name,
                    di.pipeline_run_id
                ORDER BY
                    di.enrollment_start_date,
                    di.enrollment_end_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ) AS prior_max_end_date
        FROM distinct_intervals di
    ),
    island_starts AS (
        SELECT
            pb.*,
            CASE
                WHEN pb.prior_max_end_date IS NULL THEN 1
                WHEN pb.enrollment_start_date > DATEADD(DAY, 1, pb.prior_max_end_date) THEN 1
                ELSE 0
            END AS new_island_flag
        FROM prior_bounds pb
    ),
    numbered_islands AS (
        SELECT
            i.*,
            SUM(i.new_island_flag) OVER (
                PARTITION BY
                    i.member_id,
                    i.payer_id,
                    i.medical_benefit_flag,
                    i.behavioral_health_benefit_flag,
                    i.synthetic_fixture_flag,
                    i.source_name,
                    i.pipeline_run_id
                ORDER BY
                    i.enrollment_start_date,
                    i.enrollment_end_date
                ROWS UNBOUNDED PRECEDING
            ) AS island_id
        FROM island_starts i
    )
    INSERT INTO core.enrollment_span (
        member_id,
        payer_id,
        enrollment_start_date,
        enrollment_end_date,
        medical_benefit_flag,
        behavioral_health_benefit_flag,
        synthetic_fixture_flag,
        source_name,
        pipeline_run_id,
        source_rows_merged
    )
    SELECT
        member_id,
        payer_id,
        MIN(enrollment_start_date) AS enrollment_start_date,
        MAX(enrollment_end_date) AS enrollment_end_date,
        medical_benefit_flag,
        behavioral_health_benefit_flag,
        synthetic_fixture_flag,
        source_name,
        pipeline_run_id,
        CONVERT(INT, SUM(raw_rows_in_interval)) AS source_rows_merged
    FROM numbered_islands
    GROUP BY
        member_id,
        payer_id,
        medical_benefit_flag,
        behavioral_health_benefit_flag,
        synthetic_fixture_flag,
        source_name,
        pipeline_run_id,
        island_id;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;

SELECT
    @pipeline_run_id AS pipeline_run_id,
    @raw_patient_rows AS raw_patient_rows,
    (SELECT COUNT_BIG(*) FROM core.member) AS core_member_rows,
    @raw_payer_rows AS raw_payer_rows,
    (SELECT COUNT_BIG(*) FROM core.payer) AS core_payer_rows,
    @raw_enrollment_rows AS raw_payer_transition_rows,
    (SELECT COUNT_BIG(*) FROM core.enrollment_span) AS core_enrollment_spans,
    (SELECT COUNT(DISTINCT member_id) FROM core.enrollment_span) AS members_with_enrollment,
    (SELECT SUM(CONVERT(BIGINT, source_rows_merged)) FROM core.enrollment_span) AS reconciled_source_rows;
GO
