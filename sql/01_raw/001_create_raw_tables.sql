/*
Healthcare Payer Analytics Pipeline
Phase 1 - raw landing tables

Design:
- Preserve selected Synthea CSV fields as source-shaped text.
- Add only ingestion metadata and synthetic_fixture_flag.
- Perform business typing/cleanup later in the core schema.
- No foreign keys in raw; relationship checks belong in validation/core work.
*/

USE HealthcarePayerAnalytics;
GO

/* ---------- load metadata ---------- */
IF OBJECT_ID('raw.load_run', 'U') IS NULL
BEGIN
    CREATE TABLE raw.load_run (
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        started_at_utc DATETIME2(0) NOT NULL,
        completed_at_utc DATETIME2(0) NULL,
        status VARCHAR(20) NOT NULL,
        synthea_source_path VARCHAR(1000) NOT NULL,
        fixture_source_path VARCHAR(1000) NULL,
        error_message VARCHAR(4000) NULL
    );
END;
GO

IF OBJECT_ID('raw.load_file_audit', 'U') IS NULL
BEGIN
    CREATE TABLE raw.load_file_audit (
        load_file_audit_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,
        target_table VARCHAR(128) NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(1000) NOT NULL,
        expected_rows BIGINT NOT NULL,
        loaded_rows BIGINT NOT NULL,
        started_at_utc DATETIME2(0) NOT NULL,
        completed_at_utc DATETIME2(0) NOT NULL,
        status VARCHAR(20) NOT NULL,
        error_message VARCHAR(4000) NULL,
        CONSTRAINT FK_raw_load_file_audit_run
            FOREIGN KEY (pipeline_run_id) REFERENCES raw.load_run(pipeline_run_id)
    );
END;
GO

/* ---------- source-shaped raw tables ---------- */
IF OBJECT_ID('raw.patient', 'U') IS NULL
BEGIN
    CREATE TABLE raw.patient (
        [Id] VARCHAR(64) NULL,
        [BIRTHDATE] VARCHAR(64) NULL,
        [DEATHDATE] VARCHAR(64) NULL,
        [SSN] VARCHAR(64) NULL,
        [DRIVERS] VARCHAR(64) NULL,
        [PASSPORT] VARCHAR(64) NULL,
        [PREFIX] VARCHAR(64) NULL,
        [FIRST] VARCHAR(255) NULL,
        [MIDDLE] VARCHAR(255) NULL,
        [LAST] VARCHAR(255) NULL,
        [SUFFIX] VARCHAR(64) NULL,
        [MAIDEN] VARCHAR(255) NULL,
        [MARITAL] VARCHAR(64) NULL,
        [RACE] VARCHAR(128) NULL,
        [ETHNICITY] VARCHAR(128) NULL,
        [GENDER] VARCHAR(64) NULL,
        [BIRTHPLACE] VARCHAR(512) NULL,
        [ADDRESS] VARCHAR(512) NULL,
        [CITY] VARCHAR(255) NULL,
        [STATE] VARCHAR(255) NULL,
        [COUNTY] VARCHAR(255) NULL,
        [FIPS] VARCHAR(64) NULL,
        [ZIP] VARCHAR(64) NULL,
        [LAT] VARCHAR(64) NULL,
        [LON] VARCHAR(64) NULL,
        [HEALTHCARE_EXPENSES] VARCHAR(64) NULL,
        [HEALTHCARE_COVERAGE] VARCHAR(64) NULL,
        [INCOME] VARCHAR(64) NULL,
        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(1000) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,
        loaded_at_utc DATETIME2(0) NOT NULL
    );
END;
GO

IF OBJECT_ID('raw.encounter', 'U') IS NULL
BEGIN
    CREATE TABLE raw.encounter (
        [Id] VARCHAR(64) NULL,
        [START] VARCHAR(64) NULL,
        [STOP] VARCHAR(64) NULL,
        [PATIENT] VARCHAR(64) NULL,
        [ORGANIZATION] VARCHAR(64) NULL,
        [PROVIDER] VARCHAR(64) NULL,
        [PAYER] VARCHAR(64) NULL,
        [ENCOUNTERCLASS] VARCHAR(128) NULL,
        [CODE] VARCHAR(255) NULL,
        [DESCRIPTION] VARCHAR(2000) NULL,
        [BASE_ENCOUNTER_COST] VARCHAR(64) NULL,
        [TOTAL_CLAIM_COST] VARCHAR(64) NULL,
        [PAYER_COVERAGE] VARCHAR(64) NULL,
        [REASONCODE] VARCHAR(255) NULL,
        [REASONDESCRIPTION] VARCHAR(2000) NULL,
        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(1000) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,
        loaded_at_utc DATETIME2(0) NOT NULL
    );
END;
GO

IF OBJECT_ID('raw.condition', 'U') IS NULL
BEGIN
    CREATE TABLE raw.condition (
        [START] VARCHAR(64) NULL,
        [STOP] VARCHAR(64) NULL,
        [PATIENT] VARCHAR(64) NULL,
        [ENCOUNTER] VARCHAR(64) NULL,
        [SYSTEM] VARCHAR(255) NULL,
        [CODE] VARCHAR(255) NULL,
        [DESCRIPTION] VARCHAR(2000) NULL,
        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(1000) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,
        loaded_at_utc DATETIME2(0) NOT NULL
    );
END;
GO

IF OBJECT_ID('raw.claim', 'U') IS NULL
BEGIN
    CREATE TABLE raw.claim (
        [Id] VARCHAR(64) NULL,
        [PATIENTID] VARCHAR(64) NULL,
        [PROVIDERID] VARCHAR(64) NULL,
        [PRIMARYPATIENTINSURANCEID] VARCHAR(64) NULL,
        [SECONDARYPATIENTINSURANCEID] VARCHAR(64) NULL,
        [DEPARTMENTID] VARCHAR(64) NULL,
        [PATIENTDEPARTMENTID] VARCHAR(64) NULL,
        [DIAGNOSIS1] VARCHAR(255) NULL,
        [DIAGNOSIS2] VARCHAR(255) NULL,
        [DIAGNOSIS3] VARCHAR(255) NULL,
        [DIAGNOSIS4] VARCHAR(255) NULL,
        [DIAGNOSIS5] VARCHAR(255) NULL,
        [DIAGNOSIS6] VARCHAR(255) NULL,
        [DIAGNOSIS7] VARCHAR(255) NULL,
        [DIAGNOSIS8] VARCHAR(255) NULL,
        [REFERRINGPROVIDERID] VARCHAR(64) NULL,
        [APPOINTMENTID] VARCHAR(64) NULL,
        [CURRENTILLNESSDATE] VARCHAR(64) NULL,
        [SERVICEDATE] VARCHAR(64) NULL,
        [SUPERVISINGPROVIDERID] VARCHAR(64) NULL,
        [STATUS1] VARCHAR(128) NULL,
        [STATUS2] VARCHAR(128) NULL,
        [STATUSP] VARCHAR(128) NULL,
        [OUTSTANDING1] VARCHAR(64) NULL,
        [OUTSTANDING2] VARCHAR(64) NULL,
        [OUTSTANDINGP] VARCHAR(64) NULL,
        [LASTBILLEDDATE1] VARCHAR(64) NULL,
        [LASTBILLEDDATE2] VARCHAR(64) NULL,
        [LASTBILLEDDATEP] VARCHAR(64) NULL,
        [HEALTHCARECLAIMTYPEID1] VARCHAR(64) NULL,
        [HEALTHCARECLAIMTYPEID2] VARCHAR(64) NULL,
        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(1000) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,
        loaded_at_utc DATETIME2(0) NOT NULL
    );
END;
GO

IF OBJECT_ID('raw.claim_transaction', 'U') IS NULL
BEGIN
    CREATE TABLE raw.claim_transaction (
        [ID] VARCHAR(64) NULL,
        [CLAIMID] VARCHAR(64) NULL,
        [CHARGEID] VARCHAR(64) NULL,
        [PATIENTID] VARCHAR(64) NULL,
        [TYPE] VARCHAR(128) NULL,
        [AMOUNT] VARCHAR(64) NULL,
        [METHOD] VARCHAR(128) NULL,
        [FROMDATE] VARCHAR(64) NULL,
        [TODATE] VARCHAR(64) NULL,
        [PLACEOFSERVICE] VARCHAR(128) NULL,
        [PROCEDURECODE] VARCHAR(255) NULL,
        [MODIFIER1] VARCHAR(128) NULL,
        [MODIFIER2] VARCHAR(128) NULL,
        [DIAGNOSISREF1] VARCHAR(64) NULL,
        [DIAGNOSISREF2] VARCHAR(64) NULL,
        [DIAGNOSISREF3] VARCHAR(64) NULL,
        [DIAGNOSISREF4] VARCHAR(64) NULL,
        [UNITS] VARCHAR(64) NULL,
        [DEPARTMENTID] VARCHAR(64) NULL,
        [NOTES] VARCHAR(2000) NULL,
        [UNITAMOUNT] VARCHAR(64) NULL,
        [TRANSFEROUTID] VARCHAR(64) NULL,
        [TRANSFERTYPE] VARCHAR(128) NULL,
        [PAYMENTS] VARCHAR(64) NULL,
        [ADJUSTMENTS] VARCHAR(64) NULL,
        [TRANSFERS] VARCHAR(64) NULL,
        [OUTSTANDING] VARCHAR(64) NULL,
        [APPOINTMENTID] VARCHAR(64) NULL,
        [LINENOTE] VARCHAR(2000) NULL,
        [PATIENTINSURANCEID] VARCHAR(64) NULL,
        [FEESCHEDULEID] VARCHAR(64) NULL,
        [PROVIDERID] VARCHAR(64) NULL,
        [SUPERVISINGPROVIDERID] VARCHAR(64) NULL,
        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(1000) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,
        loaded_at_utc DATETIME2(0) NOT NULL
    );
END;
GO

IF OBJECT_ID('raw.payer_transition', 'U') IS NULL
BEGIN
    CREATE TABLE raw.payer_transition (
        [PATIENT] VARCHAR(64) NULL,
        [MEMBERID] VARCHAR(64) NULL,
        [START_DATE] VARCHAR(64) NULL,
        [END_DATE] VARCHAR(64) NULL,
        [PAYER] VARCHAR(64) NULL,
        [SECONDARY_PAYER] VARCHAR(64) NULL,
        [PLAN_OWNERSHIP] VARCHAR(128) NULL,
        [OWNER_NAME] VARCHAR(512) NULL,
        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(1000) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,
        loaded_at_utc DATETIME2(0) NOT NULL
    );
END;
GO

IF OBJECT_ID('raw.provider', 'U') IS NULL
BEGIN
    CREATE TABLE raw.provider (
        [Id] VARCHAR(64) NULL,
        [ORGANIZATION] VARCHAR(64) NULL,
        [NAME] VARCHAR(512) NULL,
        [GENDER] VARCHAR(64) NULL,
        [SPECIALITY] VARCHAR(255) NULL,
        [ADDRESS] VARCHAR(512) NULL,
        [CITY] VARCHAR(255) NULL,
        [STATE] VARCHAR(255) NULL,
        [ZIP] VARCHAR(64) NULL,
        [LAT] VARCHAR(64) NULL,
        [LON] VARCHAR(64) NULL,
        [ENCOUNTERS] VARCHAR(64) NULL,
        [PROCEDURES] VARCHAR(64) NULL,
        [NPI] VARCHAR(64) NULL,
        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(1000) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,
        loaded_at_utc DATETIME2(0) NOT NULL
    );
END;
GO

IF OBJECT_ID('raw.organization', 'U') IS NULL
BEGIN
    CREATE TABLE raw.organization (
        [Id] VARCHAR(64) NULL,
        [NAME] VARCHAR(512) NULL,
        [ADDRESS] VARCHAR(512) NULL,
        [CITY] VARCHAR(255) NULL,
        [STATE] VARCHAR(255) NULL,
        [ZIP] VARCHAR(64) NULL,
        [LAT] VARCHAR(64) NULL,
        [LON] VARCHAR(64) NULL,
        [PHONE] VARCHAR(128) NULL,
        [REVENUE] VARCHAR(64) NULL,
        [UTILIZATION] VARCHAR(64) NULL,
        [NPI] VARCHAR(64) NULL,
        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(1000) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,
        loaded_at_utc DATETIME2(0) NOT NULL
    );
END;
GO

IF OBJECT_ID('raw.payer', 'U') IS NULL
BEGIN
    CREATE TABLE raw.payer (
        [Id] VARCHAR(64) NULL,
        [NAME] VARCHAR(512) NULL,
        [OWNERSHIP] VARCHAR(128) NULL,
        [ADDRESS] VARCHAR(512) NULL,
        [CITY] VARCHAR(255) NULL,
        [STATE_HEADQUARTERED] VARCHAR(255) NULL,
        [ZIP] VARCHAR(64) NULL,
        [PHONE] VARCHAR(128) NULL,
        [AMOUNT_COVERED] VARCHAR(64) NULL,
        [AMOUNT_UNCOVERED] VARCHAR(64) NULL,
        [REVENUE] VARCHAR(64) NULL,
        [COVERED_ENCOUNTERS] VARCHAR(64) NULL,
        [UNCOVERED_ENCOUNTERS] VARCHAR(64) NULL,
        [COVERED_MEDICATIONS] VARCHAR(64) NULL,
        [UNCOVERED_MEDICATIONS] VARCHAR(64) NULL,
        [COVERED_PROCEDURES] VARCHAR(64) NULL,
        [UNCOVERED_PROCEDURES] VARCHAR(64) NULL,
        [COVERED_IMMUNIZATIONS] VARCHAR(64) NULL,
        [UNCOVERED_IMMUNIZATIONS] VARCHAR(64) NULL,
        [UNIQUE_CUSTOMERS] VARCHAR(64) NULL,
        [QOLS_AVG] VARCHAR(64) NULL,
        [MEMBER_MONTHS] VARCHAR(64) NULL,
        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(1000) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,
        loaded_at_utc DATETIME2(0) NOT NULL
    );
END;
GO

IF OBJECT_ID('raw.fuh_fixture_manifest', 'U') IS NULL
BEGIN
    CREATE TABLE raw.fuh_fixture_manifest (
        fixture_key VARCHAR(64) NOT NULL,
        patient_id VARCHAR(64) NOT NULL,
        index_encounter_id VARCHAR(64) NOT NULL,
        followup_encounter_id VARCHAR(64) NULL,
        index_discharge_date VARCHAR(64) NOT NULL,
        followup_date VARCHAR(64) NULL,
        followup_day VARCHAR(64) NULL,
        expected_denominator_flag BIT NOT NULL,
        expected_fuh_7d_flag BIT NOT NULL,
        expected_fuh_30d_flag BIT NOT NULL,
        synthetic_fixture_flag BIT NOT NULL,
        source_name VARCHAR(50) NOT NULL,
        source_file VARCHAR(1000) NOT NULL,
        pipeline_run_id UNIQUEIDENTIFIER NOT NULL,
        loaded_at_utc DATETIME2(0) NOT NULL
    );
END;
GO

PRINT 'Phase 1 raw tables are ready.';
GO
