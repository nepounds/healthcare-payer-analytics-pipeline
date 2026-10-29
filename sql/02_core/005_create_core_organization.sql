/*
Healthcare Payer Analytics Pipeline
Phase 2 - core.organization

Grain:
- One row per source organization/facility.

Design:
- Use an internal surrogate key for downstream joins.
- Preserve the source organization identifier.
- Retain organization identity and basic location attributes useful for
  encounter/provider attribution.
- Leave source utilization/revenue aggregates in raw.organization.
- Preserve source and fixture lineage.
*/

USE HealthcarePayerAnalytics;
GO

IF OBJECT_ID('core.organization', 'U') IS NULL
BEGIN
    CREATE TABLE core.organization (
        organization_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_core_organization PRIMARY KEY,

        source_organization_id VARCHAR(64) NOT NULL,
        organization_name VARCHAR(512) NOT NULL,
        npi VARCHAR(20) NULL,

        address_line VARCHAR(512) NULL,
        city VARCHAR(255) NULL,
        state_code CHAR(2) NULL,
        zip_code VARCHAR(20) NULL,
        latitude DECIMAL(9,6) NULL,
        longitude DECIMAL(9,6) NULL,

        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(255) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,

        created_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_core_organization_created_at_utc
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT UQ_core_organization_source_organization_id
            UNIQUE (source_organization_id),

        CONSTRAINT CK_core_organization_latitude
            CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),

        CONSTRAINT CK_core_organization_longitude
            CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180)
    );
END;
GO
