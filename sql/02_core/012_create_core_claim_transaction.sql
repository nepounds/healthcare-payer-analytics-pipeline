/*
Healthcare Payer Analytics Pipeline
Phase 2 - core.claim_transaction

Grain:
- One row per source claim-transaction record.

Design:
- This is a transaction/event table, not a fabricated claim-line table.
- Preserve the unique source transaction ID and the source CHARGEID as an opaque related identifier;
  CHARGEID is not treated as a stable service-line number.
- Keep direct member/encounter/provider relationships from the transaction source so
  transaction-level analysis remains practical and can be checked against the parent claim.
- Preserve PATIENTINSURANCEID as source_patient_insurance_id rather than a payer FK. In normal
  Synthea output this field is an insurance-member identifier that resolves to payer_transition.MEMBERID;
  controlled fixtures currently carry a payer UUID in the same source column, so the combined field
  has mixed semantics and must remain opaque in core.
- Preserve PLACEOFSERVICE as source_place_value because the combined source package has mixed
  semantics: normal Synthea rows use organization resource IDs while controlled fixtures use POS-style
  values such as 11 and 21. place_organization_id is populated only when the raw value resolves to a
  known core organization.
- Financial values remain transaction-level facts; no claim-level billed/allowed/paid totals are invented.
- service_to_date is nullable because the source contains two invalid end-date patterns: a Unix-epoch
  sentinel (1970-01-01) and a small set of end dates that precede the service start. Both normalize
  to NULL; source_transaction_id preserves raw-layer traceability to the original value.
- Preserve source and fixture lineage.
*/

USE HealthcarePayerAnalytics;
GO

IF OBJECT_ID('core.claim_transaction', 'U') IS NULL
BEGIN
    CREATE TABLE core.claim_transaction (
        claim_transaction_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_core_claim_transaction PRIMARY KEY,

        source_transaction_id VARCHAR(64) NOT NULL,
        source_charge_id VARCHAR(64) NULL,

        claim_id BIGINT NOT NULL,
        member_id BIGINT NOT NULL,
        encounter_id BIGINT NULL,
        provider_id BIGINT NULL,
        supervising_provider_id BIGINT NULL,
        source_patient_insurance_id VARCHAR(64) NULL,
        place_organization_id BIGINT NULL,

        transaction_type VARCHAR(128) NOT NULL,
        amount DECIMAL(19,2) NULL,
        method VARCHAR(128) NULL,

        service_from_date DATE NOT NULL,
        service_to_date DATE NULL,

        source_place_value VARCHAR(128) NULL,
        procedure_code VARCHAR(255) NULL,
        modifier_1 VARCHAR(128) NULL,
        modifier_2 VARCHAR(128) NULL,

        diagnosis_reference_1 TINYINT NULL,
        diagnosis_reference_2 TINYINT NULL,
        diagnosis_reference_3 TINYINT NULL,
        diagnosis_reference_4 TINYINT NULL,

        units INT NULL,
        department_id VARCHAR(64) NULL,
        notes VARCHAR(2000) NULL,
        unit_amount DECIMAL(19,2) NULL,

        transfer_out_id VARCHAR(64) NULL,
        transfer_type VARCHAR(128) NULL,
        payments DECIMAL(19,2) NULL,
        adjustments DECIMAL(19,2) NULL,
        transfers DECIMAL(19,2) NULL,
        outstanding DECIMAL(19,2) NULL,

        line_note VARCHAR(2000) NULL,
        fee_schedule_id VARCHAR(64) NULL,

        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(255) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,

        created_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_core_claim_transaction_created_at_utc
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT UQ_core_claim_transaction_source_transaction_id
            UNIQUE (source_transaction_id),

        CONSTRAINT FK_core_claim_transaction_claim
            FOREIGN KEY (claim_id)
            REFERENCES core.claim(claim_id),

        CONSTRAINT FK_core_claim_transaction_member
            FOREIGN KEY (member_id)
            REFERENCES core.member(member_id),

        CONSTRAINT FK_core_claim_transaction_encounter
            FOREIGN KEY (encounter_id)
            REFERENCES core.encounter(encounter_id),

        CONSTRAINT FK_core_claim_transaction_provider
            FOREIGN KEY (provider_id)
            REFERENCES core.provider(provider_id),

        CONSTRAINT FK_core_claim_transaction_supervising_provider
            FOREIGN KEY (supervising_provider_id)
            REFERENCES core.provider(provider_id),

        CONSTRAINT FK_core_claim_transaction_place_organization
            FOREIGN KEY (place_organization_id)
            REFERENCES core.organization(organization_id),

        CONSTRAINT CK_core_claim_transaction_diagnosis_refs
            CHECK (
                (diagnosis_reference_1 IS NULL OR diagnosis_reference_1 BETWEEN 1 AND 8)
                AND (diagnosis_reference_2 IS NULL OR diagnosis_reference_2 BETWEEN 1 AND 8)
                AND (diagnosis_reference_3 IS NULL OR diagnosis_reference_3 BETWEEN 1 AND 8)
                AND (diagnosis_reference_4 IS NULL OR diagnosis_reference_4 BETWEEN 1 AND 8)
            )
    );
END;
GO

/*
Upgrade path for an already-created Batch 3 table.
The first Batch 3 draft incorrectly interpreted raw.claim_transaction.PATIENTINSURANCEID
as a payer ID. Synthea uses that column as an insurance-member identifier, and the
controlled fixtures currently use the same source column differently. Preserve the raw
value as opaque lineage instead of enforcing a false payer relationship.
*/
IF EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE parent_object_id = OBJECT_ID('core.claim_transaction')
      AND name = 'FK_core_claim_transaction_payer'
)
BEGIN
    ALTER TABLE core.claim_transaction
        DROP CONSTRAINT FK_core_claim_transaction_payer;
END;
GO

IF COL_LENGTH('core.claim_transaction', 'payer_id') IS NOT NULL
BEGIN
    ALTER TABLE core.claim_transaction
        DROP COLUMN payer_id;
END;
GO

IF COL_LENGTH('core.claim_transaction', 'source_patient_insurance_id') IS NULL
BEGIN
    ALTER TABLE core.claim_transaction
        ADD source_patient_insurance_id VARCHAR(64) NULL;
END;
GO

/*
Upgrade path for an already-created Batch 3 table.
The first Batch 3 draft required service_to_date, but source profiling found two
documented invalid-end-date patterns. Core normalizes those end dates to NULL.
*/
IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('core.claim_transaction')
      AND name = 'service_to_date'
      AND is_nullable = 0
)
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.check_constraints
        WHERE parent_object_id = OBJECT_ID('core.claim_transaction')
          AND name = 'CK_core_claim_transaction_dates'
    )
    BEGIN
        ALTER TABLE core.claim_transaction
            DROP CONSTRAINT CK_core_claim_transaction_dates;
    END;

    ALTER TABLE core.claim_transaction
        ALTER COLUMN service_to_date DATE NULL;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID('core.claim_transaction')
      AND name = 'CK_core_claim_transaction_dates'
)
BEGIN
    ALTER TABLE core.claim_transaction
        ADD CONSTRAINT CK_core_claim_transaction_dates
        CHECK (service_to_date IS NULL OR service_to_date >= service_from_date);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('core.claim_transaction')
      AND name = 'IX_core_claim_transaction_claim'
)
BEGIN
    CREATE INDEX IX_core_claim_transaction_claim
        ON core.claim_transaction (claim_id)
        INCLUDE (
            member_id,
            encounter_id,
            transaction_type,
            service_from_date,
            service_to_date,
            procedure_code,
            amount,
            payments,
            adjustments
        );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('core.claim_transaction')
      AND name = 'IX_core_claim_transaction_member_service'
)
BEGIN
    CREATE INDEX IX_core_claim_transaction_member_service
        ON core.claim_transaction (member_id, service_from_date)
        INCLUDE (
            claim_id,
            encounter_id,
            transaction_type,
            procedure_code,
            source_place_value,
            synthetic_fixture_flag
        );
END;
GO
