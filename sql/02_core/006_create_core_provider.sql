/*
Healthcare Payer Analytics Pipeline
Phase 2 - core.provider

Grain:
- One row per source clinician/provider.

Design:
- Use an internal surrogate key for downstream joins.
- Preserve the source provider identifier.
- Link each provider to the source organization exported by Synthea.
- Retain provider identity/specialty needed for attribution without duplicating
  organization-level address fields in a separate provider-location table.
- Preserve source and fixture lineage.
*/

USE HealthcarePayerAnalytics;
GO

IF OBJECT_ID('core.provider', 'U') IS NULL
BEGIN
    CREATE TABLE core.provider (
        provider_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_core_provider PRIMARY KEY,

        source_provider_id VARCHAR(64) NOT NULL,
        organization_id BIGINT NOT NULL,

        provider_name VARCHAR(512) NOT NULL,
        sex CHAR(1) NULL,
        specialty VARCHAR(255) NULL,
        npi VARCHAR(20) NULL,

        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(255) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,

        created_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_core_provider_created_at_utc
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT UQ_core_provider_source_provider_id
            UNIQUE (source_provider_id),

        CONSTRAINT FK_core_provider_organization
            FOREIGN KEY (organization_id)
            REFERENCES core.organization(organization_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('core.provider')
      AND name = 'IX_core_provider_organization'
)
BEGIN
    CREATE INDEX IX_core_provider_organization
        ON core.provider (organization_id)
        INCLUDE (specialty, source_provider_id);
END;
GO
