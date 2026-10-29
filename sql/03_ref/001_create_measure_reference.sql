/*
Healthcare Payer Analytics Pipeline
Phase 3 - measure reference/configuration objects

Purpose:
- Provide reusable, auditable measure configuration instead of burying constants in measure SQL.
- Seed the project-defined FUH-style 2025 configuration and public-portfolio proxy value sets.

Important:
- These are project-defined reference rules for portfolio demonstration.
- They are not licensed NCQA HEDIS value sets and must not be described as such.
*/

USE HealthcarePayerAnalytics;
GO

SET XACT_ABORT ON;
GO

IF OBJECT_ID('ref.measure_definition', 'U') IS NULL
BEGIN
    CREATE TABLE ref.measure_definition (
        measure_id VARCHAR(64) NOT NULL
            CONSTRAINT PK_ref_measure_definition PRIMARY KEY,

        measure_name VARCHAR(255) NOT NULL,
        measurement_year SMALLINT NOT NULL,
        analysis_date DATE NOT NULL,
        methodology_version VARCHAR(32) NOT NULL,

        hedis_oriented_flag BIT NOT NULL,
        official_hedis_flag BIT NOT NULL,
        active_flag BIT NOT NULL,

        source_note VARCHAR(2000) NOT NULL,

        created_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_ref_measure_definition_created_at_utc
            DEFAULT SYSUTCDATETIME(),
        updated_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_ref_measure_definition_updated_at_utc
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT CK_ref_measure_definition_year
            CHECK (measurement_year BETWEEN 2000 AND 2100),
        CONSTRAINT CK_ref_measure_definition_official
            CHECK (official_hedis_flag = 0)
    );
END;
GO

IF OBJECT_ID('ref.measure_value_set', 'U') IS NULL
BEGIN
    CREATE TABLE ref.measure_value_set (
        measure_value_set_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_ref_measure_value_set PRIMARY KEY,

        measure_id VARCHAR(64) NOT NULL,
        value_set_name VARCHAR(100) NOT NULL,
        code_system VARCHAR(100) NOT NULL,
        code_value VARCHAR(255) NOT NULL,
        match_type VARCHAR(20) NOT NULL,

        effective_start_date DATE NULL,
        effective_end_date DATE NULL,
        source_note VARCHAR(2000) NOT NULL,
        licensed_spec_flag BIT NOT NULL,
        active_flag BIT NOT NULL,

        created_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_ref_measure_value_set_created_at_utc
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT FK_ref_measure_value_set_measure
            FOREIGN KEY (measure_id)
            REFERENCES ref.measure_definition(measure_id),

        CONSTRAINT UQ_ref_measure_value_set_rule
            UNIQUE (measure_id, value_set_name, code_system, code_value, match_type),

        CONSTRAINT CK_ref_measure_value_set_match_type
            CHECK (match_type IN ('EXACT', 'PREFIX')),

        CONSTRAINT CK_ref_measure_value_set_dates
            CHECK (
                effective_end_date IS NULL
                OR effective_start_date IS NULL
                OR effective_end_date >= effective_start_date
            ),

        CONSTRAINT CK_ref_measure_value_set_licensed
            CHECK (licensed_spec_flag = 0)
    );
END;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE ref.measure_definition
    SET
        measure_name = 'FUH-style behavioral-health follow-up performance measure',
        measurement_year = 2025,
        analysis_date = CONVERT(DATE, '2026-10-18'),
        methodology_version = 'v0.1',
        hedis_oriented_flag = 1,
        official_hedis_flag = 0,
        active_flag = 1,
        source_note = 'Portfolio demonstration. HEDIS-oriented/FUH-style only; not an official or certified NCQA HEDIS implementation.',
        updated_at_utc = SYSUTCDATETIME()
    WHERE measure_id = 'FUH_STYLE_MY2025';

    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO ref.measure_definition (
            measure_id,
            measure_name,
            measurement_year,
            analysis_date,
            methodology_version,
            hedis_oriented_flag,
            official_hedis_flag,
            active_flag,
            source_note
        )
        VALUES (
            'FUH_STYLE_MY2025',
            'FUH-style behavioral-health follow-up performance measure',
            2025,
            CONVERT(DATE, '2026-10-18'),
            'v0.1',
            1,
            0,
            1,
            'Portfolio demonstration. HEDIS-oriented/FUH-style only; not an official or certified NCQA HEDIS implementation.'
        );
    END;

    DELETE FROM ref.measure_value_set
    WHERE measure_id = 'FUH_STYLE_MY2025';

    INSERT INTO ref.measure_value_set (
        measure_id,
        value_set_name,
        code_system,
        code_value,
        match_type,
        effective_start_date,
        effective_end_date,
        source_note,
        licensed_spec_flag,
        active_flag
    )
    VALUES
        (
            'FUH_STYLE_MY2025',
            'INDEX_ENCOUNTER_TYPE',
            'SOURCE_ENCOUNTER_TYPE',
            'inpatient',
            'EXACT',
            '2025-01-01',
            '2025-12-31',
            'Project-defined inpatient source-encounter classification used to identify candidate hospital discharges.',
            0,
            1
        ),
        (
            'FUH_STYLE_MY2025',
            'BEHAVIORAL_HEALTH_DIAGNOSIS',
            'ICD-10-CM',
            'F',
            'PREFIX',
            '2025-01-01',
            '2026-01-31',
            'Broad project-owned ICD-10-CM F-prefix behavioral-health proxy. It is intentionally not represented as an official NCQA FUH value set.',
            0,
            1
        ),
        (
            'FUH_STYLE_MY2025',
            'FOLLOWUP_ENCOUNTER_TYPE',
            'SOURCE_ENCOUNTER_TYPE',
            'ambulatory',
            'EXACT',
            '2025-01-01',
            '2026-01-31',
            'Project-defined ambulatory source encounter type accepted as follow-up when accompanied by qualifying behavioral-health diagnosis evidence.',
            0,
            1
        ),
        (
            'FUH_STYLE_MY2025',
            'FOLLOWUP_ENCOUNTER_TYPE',
            'SOURCE_ENCOUNTER_TYPE',
            'outpatient',
            'EXACT',
            '2025-01-01',
            '2026-01-31',
            'Project-defined outpatient source encounter type accepted as follow-up when accompanied by qualifying behavioral-health diagnosis evidence.',
            0,
            1
        );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

SELECT
    measure_id,
    measure_name,
    measurement_year,
    analysis_date,
    methodology_version,
    hedis_oriented_flag,
    official_hedis_flag,
    active_flag
FROM ref.measure_definition
WHERE measure_id = 'FUH_STYLE_MY2025';

SELECT
    value_set_name,
    code_system,
    code_value,
    match_type,
    effective_start_date,
    effective_end_date,
    licensed_spec_flag,
    active_flag
FROM ref.measure_value_set
WHERE measure_id = 'FUH_STYLE_MY2025'
ORDER BY value_set_name, code_system, code_value;
GO
