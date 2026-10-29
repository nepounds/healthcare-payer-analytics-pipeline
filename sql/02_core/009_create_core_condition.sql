/*
Healthcare Payer Analytics Pipeline
Phase 2 - core.condition

Grain:
- One row per source clinical condition/diagnosis record.

Design:
- Use an internal surrogate key because the source condition export has no condition ID.
- Preserve the member relationship and encounter relationship where supplied.
- Keep code_system beside diagnosis_code; codes must not be interpreted without their system.
- Store the source START/STOP values as DATE because the condition export is date-grained.
- Preserve duplicate source records rather than inventing a business-key deduplication rule.
- Preserve source and fixture lineage.
*/

USE HealthcarePayerAnalytics;
GO

IF OBJECT_ID('core.condition', 'U') IS NULL
BEGIN
    CREATE TABLE core.condition (
        condition_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_core_condition PRIMARY KEY,

        member_id BIGINT NOT NULL,
        encounter_id BIGINT NULL,

        code_system VARCHAR(255) NOT NULL,
        diagnosis_code VARCHAR(255) NOT NULL,
        diagnosis_description VARCHAR(2000) NULL,

        condition_start_date DATE NOT NULL,
        condition_end_date DATE NULL,

        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(255) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,

        created_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_core_condition_created_at_utc
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT FK_core_condition_member
            FOREIGN KEY (member_id)
            REFERENCES core.member(member_id),

        CONSTRAINT FK_core_condition_encounter
            FOREIGN KEY (encounter_id)
            REFERENCES core.encounter(encounter_id),

        CONSTRAINT CK_core_condition_dates
            CHECK (condition_end_date IS NULL OR condition_end_date >= condition_start_date)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('core.condition')
      AND name = 'IX_core_condition_encounter_code'
)
BEGIN
    CREATE INDEX IX_core_condition_encounter_code
        ON core.condition (encounter_id, code_system, diagnosis_code)
        INCLUDE (member_id, condition_start_date, condition_end_date, synthetic_fixture_flag);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('core.condition')
      AND name = 'IX_core_condition_member_dates'
)
BEGIN
    CREATE INDEX IX_core_condition_member_dates
        ON core.condition (member_id, condition_start_date, condition_end_date)
        INCLUDE (encounter_id, code_system, diagnosis_code, synthetic_fixture_flag);
END;
GO
