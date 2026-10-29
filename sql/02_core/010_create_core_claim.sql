/*
Healthcare Payer Analytics Pipeline
Phase 2 - core.claim

Grain:
- One row per source claim.

Design:
- Use an internal surrogate key for downstream joins while preserving the unique source claim ID.
- Resolve the member and encounter relationships directly from the source claim.
- Preserve explicit rendering/referring/supervising provider roles and primary/secondary payer roles.
- Keep source claim status, outstanding balance, billing-date, and claim-type fields without inventing
  a single adjudication status or derived claim total that the source does not provide.
- Claim diagnosis codes are normalized separately in core.claim_diagnosis.
- Preserve source and fixture lineage.
*/

USE HealthcarePayerAnalytics;
GO

IF OBJECT_ID('core.claim', 'U') IS NULL
BEGIN
    CREATE TABLE core.claim (
        claim_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_core_claim PRIMARY KEY,

        source_claim_id VARCHAR(64) NOT NULL,
        member_id BIGINT NOT NULL,
        encounter_id BIGINT NOT NULL,

        rendering_provider_id BIGINT NULL,
        referring_provider_id BIGINT NULL,
        supervising_provider_id BIGINT NULL,
        primary_payer_id BIGINT NULL,
        secondary_payer_id BIGINT NULL,

        service_date DATE NOT NULL,
        current_illness_date DATE NULL,

        department_id VARCHAR(64) NULL,
        patient_department_id VARCHAR(64) NULL,

        primary_status VARCHAR(128) NULL,
        secondary_status VARCHAR(128) NULL,
        patient_status VARCHAR(128) NULL,

        primary_outstanding_amount DECIMAL(19,2) NULL,
        secondary_outstanding_amount DECIMAL(19,2) NULL,
        patient_outstanding_amount DECIMAL(19,2) NULL,

        primary_last_billed_date DATE NULL,
        secondary_last_billed_date DATE NULL,
        patient_last_billed_date DATE NULL,

        primary_healthcare_claim_type_id VARCHAR(64) NULL,
        secondary_healthcare_claim_type_id VARCHAR(64) NULL,

        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(255) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,

        created_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_core_claim_created_at_utc
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT UQ_core_claim_source_claim_id
            UNIQUE (source_claim_id),

        CONSTRAINT FK_core_claim_member
            FOREIGN KEY (member_id)
            REFERENCES core.member(member_id),

        CONSTRAINT FK_core_claim_encounter
            FOREIGN KEY (encounter_id)
            REFERENCES core.encounter(encounter_id),

        CONSTRAINT FK_core_claim_rendering_provider
            FOREIGN KEY (rendering_provider_id)
            REFERENCES core.provider(provider_id),

        CONSTRAINT FK_core_claim_referring_provider
            FOREIGN KEY (referring_provider_id)
            REFERENCES core.provider(provider_id),

        CONSTRAINT FK_core_claim_supervising_provider
            FOREIGN KEY (supervising_provider_id)
            REFERENCES core.provider(provider_id),

        CONSTRAINT FK_core_claim_primary_payer
            FOREIGN KEY (primary_payer_id)
            REFERENCES core.payer(payer_id),

        CONSTRAINT FK_core_claim_secondary_payer
            FOREIGN KEY (secondary_payer_id)
            REFERENCES core.payer(payer_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('core.claim')
      AND name = 'IX_core_claim_member_service_date'
)
BEGIN
    CREATE INDEX IX_core_claim_member_service_date
        ON core.claim (member_id, service_date)
        INCLUDE (
            encounter_id,
            rendering_provider_id,
            primary_payer_id,
            source_claim_id,
            synthetic_fixture_flag
        );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('core.claim')
      AND name = 'IX_core_claim_encounter'
)
BEGIN
    CREATE INDEX IX_core_claim_encounter
        ON core.claim (encounter_id)
        INCLUDE (member_id, service_date, source_claim_id, synthetic_fixture_flag);
END;
GO
