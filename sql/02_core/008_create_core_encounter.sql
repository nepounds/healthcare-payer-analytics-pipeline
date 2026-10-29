/*
Healthcare Payer Analytics Pipeline
Phase 2 - core.encounter

Grain:
- One row per source encounter.

Design:
- Use an internal surrogate key for downstream joins.
- Preserve the source encounter identifier.
- Resolve member as required; resolve organization, provider, and payer when present.
- Normalize source ISO-8601 timestamps to UTC DATETIME2(0).
- Preserve encounter classification, source service/reason coding, and source-level costs.
- Do not relabel REASONCODE as a principal diagnosis: the source does not establish that semantic.
- Preserve source and fixture lineage.
*/

USE HealthcarePayerAnalytics;
GO

IF OBJECT_ID('core.encounter', 'U') IS NULL
BEGIN
    CREATE TABLE core.encounter (
        encounter_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_core_encounter PRIMARY KEY,

        source_encounter_id VARCHAR(64) NOT NULL,
        member_id BIGINT NOT NULL,
        organization_id BIGINT NULL,
        provider_id BIGINT NULL,
        payer_id BIGINT NULL,

        encounter_start_datetime DATETIME2(0) NOT NULL,
        encounter_end_datetime DATETIME2(0) NOT NULL,
        encounter_type VARCHAR(128) NOT NULL,

        encounter_code VARCHAR(255) NULL,
        encounter_description VARCHAR(2000) NULL,
        reason_code VARCHAR(255) NULL,
        reason_description VARCHAR(2000) NULL,

        base_encounter_cost DECIMAL(19,2) NULL,
        total_claim_cost DECIMAL(19,2) NULL,
        payer_coverage DECIMAL(19,2) NULL,

        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(255) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,

        created_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_core_encounter_created_at_utc
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT UQ_core_encounter_source_encounter_id
            UNIQUE (source_encounter_id),

        CONSTRAINT FK_core_encounter_member
            FOREIGN KEY (member_id)
            REFERENCES core.member(member_id),

        CONSTRAINT FK_core_encounter_organization
            FOREIGN KEY (organization_id)
            REFERENCES core.organization(organization_id),

        CONSTRAINT FK_core_encounter_provider
            FOREIGN KEY (provider_id)
            REFERENCES core.provider(provider_id),

        CONSTRAINT FK_core_encounter_payer
            FOREIGN KEY (payer_id)
            REFERENCES core.payer(payer_id),

        CONSTRAINT CK_core_encounter_dates
            CHECK (encounter_end_datetime >= encounter_start_datetime),

        CONSTRAINT CK_core_encounter_costs
            CHECK (
                (base_encounter_cost IS NULL OR base_encounter_cost >= 0)
                AND (total_claim_cost IS NULL OR total_claim_cost >= 0)
                AND (payer_coverage IS NULL OR payer_coverage >= 0)
            )
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('core.encounter')
      AND name = 'IX_core_encounter_member_dates'
)
BEGIN
    CREATE INDEX IX_core_encounter_member_dates
        ON core.encounter (member_id, encounter_start_datetime, encounter_end_datetime)
        INCLUDE (
            encounter_type,
            organization_id,
            provider_id,
            payer_id,
            reason_code,
            source_encounter_id,
            synthetic_fixture_flag
        );
END;
GO
