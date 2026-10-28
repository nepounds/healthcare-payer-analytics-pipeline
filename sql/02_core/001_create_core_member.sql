/*
Healthcare Payer Analytics Pipeline
Phase 2 - core.member

Grain:
- One row per synthetic member.

Design:
- Use an internal surrogate key for downstream joins.
- Preserve the Synthea/FUH source patient identifier.
- Convert source-shaped text dates into SQL DATE values.
- Normalize North Carolina to NC.
- Store FIPS as a character code, not a numeric measure.
- Preserve enough source lineage to trace the member back to raw.
*/

USE HealthcarePayerAnalytics;
GO

IF OBJECT_ID('core.member', 'U') IS NULL
BEGIN
    CREATE TABLE core.member (
        member_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_core_member PRIMARY KEY,

        source_patient_id VARCHAR(64) NOT NULL,

        birth_date DATE NOT NULL,
        deceased_date DATE NULL,

        sex CHAR(1) NULL,
        county_code CHAR(5) NULL,
        state_code CHAR(2) NULL,

        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,

        created_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_core_member_created_at_utc
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT UQ_core_member_source_patient_id
            UNIQUE (source_patient_id)
    );
END;
GO