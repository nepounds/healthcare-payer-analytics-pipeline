/*
Healthcare Payer Analytics Pipeline
Phase 2 - core.claim_diagnosis

Grain:
- One row per populated diagnosis position on a source claim.

Design:
- Preserve source diagnosis position 1-8 because claim transactions reference diagnosis positions.
- Do not infer a principal-diagnosis flag from position 1.
- Do not assign a diagnosis code system: the source claims export does not identify one, and the
  current landing combines normal Synthea claim diagnoses with controlled ICD-10-CM fixtures.
- Preserve source and fixture lineage inherited from the parent claim row.
*/

USE HealthcarePayerAnalytics;
GO

IF OBJECT_ID('core.claim_diagnosis', 'U') IS NULL
BEGIN
    CREATE TABLE core.claim_diagnosis (
        claim_diagnosis_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_core_claim_diagnosis PRIMARY KEY,

        claim_id BIGINT NOT NULL,
        diagnosis_sequence TINYINT NOT NULL,
        diagnosis_code VARCHAR(255) NOT NULL,

        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(255) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,

        created_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_core_claim_diagnosis_created_at_utc
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT UQ_core_claim_diagnosis_claim_sequence
            UNIQUE (claim_id, diagnosis_sequence),

        CONSTRAINT FK_core_claim_diagnosis_claim
            FOREIGN KEY (claim_id)
            REFERENCES core.claim(claim_id),

        CONSTRAINT CK_core_claim_diagnosis_sequence
            CHECK (diagnosis_sequence BETWEEN 1 AND 8)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('core.claim_diagnosis')
      AND name = 'IX_core_claim_diagnosis_code'
)
BEGIN
    CREATE INDEX IX_core_claim_diagnosis_code
        ON core.claim_diagnosis (diagnosis_code, claim_id)
        INCLUDE (diagnosis_sequence, synthetic_fixture_flag);
END;
GO
