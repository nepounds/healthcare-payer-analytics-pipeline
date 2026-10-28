/*
Healthcare Payer Analytics Pipeline
Phase 2 - core.enrollment_span

Grain:
- One row per continuous enrollment span for a member,
  payer, and benefit configuration.

Design:
- Normalize adjacent or overlapping source coverage rows.
- Use internal member and payer surrogate keys.
- Retain derived medical and behavioral-health benefit flags.
- Preserve fixture and pipeline lineage.
- Record how many raw coverage rows were merged into each span.
*/

USE HealthcarePayerAnalytics;
GO

IF OBJECT_ID('core.enrollment_span', 'U') IS NULL
BEGIN
    CREATE TABLE core.enrollment_span (
        enrollment_span_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_core_enrollment_span PRIMARY KEY,

        member_id BIGINT NOT NULL,
        payer_id BIGINT NOT NULL,

        enrollment_start_date DATE NOT NULL,
        enrollment_end_date DATE NOT NULL,

        medical_benefit_flag BIT NOT NULL,
        behavioral_health_benefit_flag BIT NOT NULL,

        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,

        source_rows_merged INT NOT NULL,

        created_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_core_enrollment_span_created_at_utc
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT FK_core_enrollment_span_member
            FOREIGN KEY (member_id)
            REFERENCES core.member(member_id),

        CONSTRAINT FK_core_enrollment_span_payer
            FOREIGN KEY (payer_id)
            REFERENCES core.payer(payer_id),

        CONSTRAINT CK_core_enrollment_span_dates
            CHECK (enrollment_end_date >= enrollment_start_date),

        CONSTRAINT CK_core_enrollment_span_source_rows
            CHECK (source_rows_merged >= 1)
    );
END;
GO