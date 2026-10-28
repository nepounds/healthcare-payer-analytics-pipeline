/*
Healthcare Payer Analytics Pipeline
Phase 2 - core.payer

Grain:
- One row per source payer.

Design:
- Use an internal surrogate key for downstream joins.
- Preserve the source payer identifier.
- Retain only descriptive payer attributes needed by the core model.
- Preserve source lineage.
*/

USE HealthcarePayerAnalytics;
GO

IF OBJECT_ID('core.payer', 'U') IS NULL
BEGIN
    CREATE TABLE core.payer (
        payer_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_core_payer PRIMARY KEY,

        source_payer_id VARCHAR(64) NOT NULL,
        payer_name VARCHAR(100) NOT NULL,
        ownership VARCHAR(50) NULL,

        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(255) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,

        created_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_core_payer_created_at_utc
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT UQ_core_payer_source_payer_id
            UNIQUE (source_payer_id)
    );
END;
GO