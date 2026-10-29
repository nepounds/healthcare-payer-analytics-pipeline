/*
Healthcare Payer Analytics Pipeline
Phase 2 - claims-domain core load

Scope:
- core.claim
- core.claim_diagnosis
- core.claim_transaction

Purpose:
- Rebuild the claims-domain portion of Phase 2 without repeatedly reloading the already-validated
  organization/provider/encounter/condition tables while the 5.2M-row transaction model is tested.
- The final Phase 2 execution path will be synchronized after this domain load is validated.

Refresh behavior:
- Destructive refresh of the three claims-domain core tables only.
- DELETE/INSERT work is wrapped in one transaction with XACT_ABORT ON.
- Any failed invariant or insert rolls the claims-domain refresh back.
*/

USE HealthcarePayerAnalytics;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID('core.member', 'U') IS NULL
    THROW 51400, 'core.member does not exist. Build the Phase 2 foundation first.', 1;
IF OBJECT_ID('core.payer', 'U') IS NULL
    THROW 51401, 'core.payer does not exist. Build the Phase 2 foundation first.', 1;
IF OBJECT_ID('core.organization', 'U') IS NULL
    THROW 51402, 'core.organization does not exist. Build the Phase 2 network core first.', 1;
IF OBJECT_ID('core.provider', 'U') IS NULL
    THROW 51403, 'core.provider does not exist. Build the Phase 2 network core first.', 1;
IF OBJECT_ID('core.encounter', 'U') IS NULL
    THROW 51404, 'core.encounter does not exist. Build the Phase 2 clinical core first.', 1;
IF OBJECT_ID('core.claim', 'U') IS NULL
    THROW 51405, 'core.claim does not exist. Run 010_create_core_claim.sql first.', 1;
IF OBJECT_ID('core.claim_diagnosis', 'U') IS NULL
    THROW 51406, 'core.claim_diagnosis does not exist. Run 011_create_core_claim_diagnosis.sql first.', 1;
IF OBJECT_ID('core.claim_transaction', 'U') IS NULL
    THROW 51407, 'core.claim_transaction does not exist. Run 012_create_core_claim_transaction.sql first.', 1;
GO

DECLARE @pipeline_run_id UNIQUEIDENTIFIER;
DECLARE @raw_claim_rows BIGINT;
DECLARE @raw_transaction_rows BIGINT;
DECLARE @expected_claim_diagnosis_rows BIGINT;
DECLARE @inserted_rows BIGINT;

SELECT TOP (1) @pipeline_run_id = pipeline_run_id
FROM core.member;

SELECT @raw_claim_rows = COUNT_BIG(*) FROM raw.claim;
SELECT @raw_transaction_rows = COUNT_BIG(*) FROM raw.claim_transaction;

SELECT @expected_claim_diagnosis_rows = COUNT_BIG(*)
FROM raw.claim c
CROSS APPLY (
    VALUES
        (c.[DIAGNOSIS1]),
        (c.[DIAGNOSIS2]),
        (c.[DIAGNOSIS3]),
        (c.[DIAGNOSIS4]),
        (c.[DIAGNOSIS5]),
        (c.[DIAGNOSIS6]),
        (c.[DIAGNOSIS7]),
        (c.[DIAGNOSIS8])
) d (diagnosis_code)
WHERE NULLIF(LTRIM(RTRIM(d.diagnosis_code)), '') IS NOT NULL;

IF @pipeline_run_id IS NULL
    THROW 51408, 'core.member is empty. Run the Phase 2 foundation load first.', 1;
IF @raw_claim_rows = 0
    THROW 51409, 'raw.claim is empty. Run the Phase 1 raw loader first.', 1;
IF @raw_transaction_rows = 0
    THROW 51410, 'raw.claim_transaction is empty. Run the Phase 1 raw loader first.', 1;

IF (SELECT COUNT(DISTINCT pipeline_run_id) FROM core.member) <> 1
    THROW 51411, 'core.member contains more than one pipeline_run_id.', 1;
IF EXISTS (SELECT 1 FROM raw.claim WHERE pipeline_run_id <> @pipeline_run_id)
    THROW 51412, 'raw.claim does not match the current core.member pipeline_run_id.', 1;
IF EXISTS (SELECT 1 FROM raw.claim_transaction WHERE pipeline_run_id <> @pipeline_run_id)
    THROW 51413, 'raw.claim_transaction does not match the current core.member pipeline_run_id.', 1;

IF NOT EXISTS (
    SELECT 1
    FROM raw.load_run
    WHERE pipeline_run_id = @pipeline_run_id
      AND status = 'SUCCESS'
)
    THROW 51414, 'Current pipeline_run_id is not recorded as SUCCESS in raw.load_run.', 1;

/* ---------- raw.claim quality and relationship checks ---------- */
IF EXISTS (
    SELECT 1
    FROM raw.claim
    WHERE NULLIF(LTRIM(RTRIM([Id])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([PATIENTID])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([APPOINTMENTID])), '') IS NULL
       OR NULLIF(LTRIM(RTRIM([SERVICEDATE])), '') IS NULL
)
    THROW 51415, 'raw.claim contains a blank required claim identifier/member/encounter/service-date field.', 1;

IF EXISTS (
    SELECT LTRIM(RTRIM([Id])) AS source_claim_id
    FROM raw.claim
    GROUP BY LTRIM(RTRIM([Id]))
    HAVING COUNT_BIG(*) > 1
)
    THROW 51416, 'raw.claim contains duplicate source claim IDs.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.claim
    WHERE TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM([SERVICEDATE])), 10), 23) IS NULL
       OR (
            NULLIF(LTRIM(RTRIM([CURRENTILLNESSDATE])), '') IS NOT NULL
            AND TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM([CURRENTILLNESSDATE])), 10), 23) IS NULL
          )
       OR (
            NULLIF(LTRIM(RTRIM([LASTBILLEDDATE1])), '') IS NOT NULL
            AND TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM([LASTBILLEDDATE1])), 10), 23) IS NULL
          )
       OR (
            NULLIF(LTRIM(RTRIM([LASTBILLEDDATE2])), '') IS NOT NULL
            AND TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM([LASTBILLEDDATE2])), 10), 23) IS NULL
          )
       OR (
            NULLIF(LTRIM(RTRIM([LASTBILLEDDATEP])), '') IS NOT NULL
            AND TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM([LASTBILLEDDATEP])), 10), 23) IS NULL
          )
)
    THROW 51417, 'raw.claim contains an invalid source date.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.claim
    WHERE (
            NULLIF(LTRIM(RTRIM([OUTSTANDING1])), '') IS NOT NULL
            AND TRY_CONVERT(DECIMAL(19,2), LTRIM(RTRIM([OUTSTANDING1]))) IS NULL
          )
       OR (
            NULLIF(LTRIM(RTRIM([OUTSTANDING2])), '') IS NOT NULL
            AND TRY_CONVERT(DECIMAL(19,2), LTRIM(RTRIM([OUTSTANDING2]))) IS NULL
          )
       OR (
            NULLIF(LTRIM(RTRIM([OUTSTANDINGP])), '') IS NOT NULL
            AND TRY_CONVERT(DECIMAL(19,2), LTRIM(RTRIM([OUTSTANDINGP]))) IS NULL
          )
)
    THROW 51418, 'raw.claim contains a nonnumeric outstanding amount.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.claim
    WHERE LEN(LTRIM(RTRIM([Id]))) > 64
       OR LEN(LTRIM(RTRIM([PATIENTID]))) > 64
       OR LEN(LTRIM(RTRIM([APPOINTMENTID]))) > 64
       OR LEN(NULLIF(LTRIM(RTRIM([PROVIDERID])), '')) > 64
       OR LEN(NULLIF(LTRIM(RTRIM([REFERRINGPROVIDERID])), '')) > 64
       OR LEN(NULLIF(LTRIM(RTRIM([SUPERVISINGPROVIDERID])), '')) > 64
       OR LEN(NULLIF(LTRIM(RTRIM([PRIMARYPATIENTINSURANCEID])), '')) > 64
       OR LEN(NULLIF(LTRIM(RTRIM([SECONDARYPATIENTINSURANCEID])), '')) > 64
       OR LEN(NULLIF(LTRIM(RTRIM([DEPARTMENTID])), '')) > 64
       OR LEN(NULLIF(LTRIM(RTRIM([PATIENTDEPARTMENTID])), '')) > 64
       OR LEN(NULLIF(LTRIM(RTRIM([STATUS1])), '')) > 128
       OR LEN(NULLIF(LTRIM(RTRIM([STATUS2])), '')) > 128
       OR LEN(NULLIF(LTRIM(RTRIM([STATUSP])), '')) > 128
       OR LEN(NULLIF(LTRIM(RTRIM([HEALTHCARECLAIMTYPEID1])), '')) > 64
       OR LEN(NULLIF(LTRIM(RTRIM([HEALTHCARECLAIMTYPEID2])), '')) > 64
       OR LEN(source_file) > 255
)
    THROW 51419, 'raw.claim contains a value longer than the current core.claim target column.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.claim c
    LEFT JOIN core.member m
        ON m.source_patient_id = LTRIM(RTRIM(c.[PATIENTID]))
    WHERE m.member_id IS NULL
)
    THROW 51420, 'raw.claim contains PATIENTID values not found in core.member.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.claim c
    LEFT JOIN core.encounter e
        ON e.source_encounter_id = LTRIM(RTRIM(c.[APPOINTMENTID]))
    WHERE e.encounter_id IS NULL
)
    THROW 51421, 'raw.claim contains APPOINTMENTID values not found in core.encounter.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.claim c
    LEFT JOIN core.member m
        ON m.source_patient_id = LTRIM(RTRIM(c.[PATIENTID]))
    LEFT JOIN core.encounter e
        ON e.source_encounter_id = LTRIM(RTRIM(c.[APPOINTMENTID]))
    WHERE m.member_id <> e.member_id
)
    THROW 51422, 'raw.claim contains a member/encounter relationship mismatch.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.claim c
    LEFT JOIN core.provider p
        ON p.source_provider_id = NULLIF(LTRIM(RTRIM(c.[PROVIDERID])), '')
    WHERE NULLIF(LTRIM(RTRIM(c.[PROVIDERID])), '') IS NOT NULL
      AND p.provider_id IS NULL
)
    THROW 51423, 'raw.claim contains a nonblank PROVIDERID not found in core.provider.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.claim c
    LEFT JOIN core.provider p
        ON p.source_provider_id = NULLIF(LTRIM(RTRIM(c.[REFERRINGPROVIDERID])), '')
    WHERE NULLIF(LTRIM(RTRIM(c.[REFERRINGPROVIDERID])), '') IS NOT NULL
      AND p.provider_id IS NULL
)
    THROW 51424, 'raw.claim contains a nonblank REFERRINGPROVIDERID not found in core.provider.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.claim c
    LEFT JOIN core.provider p
        ON p.source_provider_id = NULLIF(LTRIM(RTRIM(c.[SUPERVISINGPROVIDERID])), '')
    WHERE NULLIF(LTRIM(RTRIM(c.[SUPERVISINGPROVIDERID])), '') IS NOT NULL
      AND p.provider_id IS NULL
)
    THROW 51425, 'raw.claim contains a nonblank SUPERVISINGPROVIDERID not found in core.provider.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.claim c
    LEFT JOIN core.payer p
        ON p.source_payer_id = NULLIF(LTRIM(RTRIM(c.[PRIMARYPATIENTINSURANCEID])), '')
    WHERE NULLIF(LTRIM(RTRIM(c.[PRIMARYPATIENTINSURANCEID])), '') IS NOT NULL
      AND p.payer_id IS NULL
)
    THROW 51426, 'raw.claim contains a nonblank PRIMARYPATIENTINSURANCEID not found in core.payer.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.claim c
    LEFT JOIN core.payer p
        ON p.source_payer_id = NULLIF(LTRIM(RTRIM(c.[SECONDARYPATIENTINSURANCEID])), '')
    WHERE NULLIF(LTRIM(RTRIM(c.[SECONDARYPATIENTINSURANCEID])), '') IS NOT NULL
      AND p.payer_id IS NULL
)
    THROW 51427, 'raw.claim contains a nonblank SECONDARYPATIENTINSURANCEID not found in core.payer.', 1;

/* ---------- raw.claim_transaction one-pass quality/relationship profile ---------- */
DECLARE @bad_required BIGINT;
DECLARE @bad_dates BIGINT;
DECLARE @epoch_service_to_rows BIGINT;
DECLARE @reversed_non_epoch_service_to_rows BIGINT;
DECLARE @bad_financials BIGINT;
DECLARE @bad_units BIGINT;
DECLARE @bad_diagnosis_refs BIGINT;
DECLARE @bad_lengths BIGINT;
DECLARE @missing_claim BIGINT;
DECLARE @missing_member BIGINT;
DECLARE @missing_encounter BIGINT;
DECLARE @missing_provider BIGINT;
DECLARE @missing_supervising_provider BIGINT;
DECLARE @claim_member_mismatch BIGINT;
DECLARE @claim_encounter_mismatch BIGINT;

SELECT
    @bad_required = SUM(CASE WHEN NULLIF(LTRIM(RTRIM(t.[ID])), '') IS NULL
                                   OR NULLIF(LTRIM(RTRIM(t.[CLAIMID])), '') IS NULL
                                   OR NULLIF(LTRIM(RTRIM(t.[PATIENTID])), '') IS NULL
                                   OR NULLIF(LTRIM(RTRIM(t.[TYPE])), '') IS NULL
                                   OR NULLIF(LTRIM(RTRIM(t.[FROMDATE])), '') IS NULL
                                   OR NULLIF(LTRIM(RTRIM(t.[TODATE])), '') IS NULL
                              THEN 1 ELSE 0 END),
    @bad_dates = SUM(CASE WHEN TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM(t.[FROMDATE])), 10), 23) IS NULL
                                OR TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM(t.[TODATE])), 10), 23) IS NULL
                           THEN 1 ELSE 0 END),
    @epoch_service_to_rows = SUM(CASE WHEN TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM(t.[TODATE])), 10), 23) = CONVERT(DATE, '1970-01-01')
                                      THEN 1 ELSE 0 END),
    @reversed_non_epoch_service_to_rows = SUM(CASE WHEN TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM(t.[TODATE])), 10), 23) <> CONVERT(DATE, '1970-01-01')
                                                        AND TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM(t.[TODATE])), 10), 23)
                                                            < TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM(t.[FROMDATE])), 10), 23)
                                                   THEN 1 ELSE 0 END),
    @bad_financials = SUM(CASE WHEN (NULLIF(LTRIM(RTRIM(t.[AMOUNT])), '') IS NOT NULL
                                      AND TRY_CONVERT(DECIMAL(19,2), LTRIM(RTRIM(t.[AMOUNT]))) IS NULL)
                                   OR (NULLIF(LTRIM(RTRIM(t.[UNITAMOUNT])), '') IS NOT NULL
                                      AND TRY_CONVERT(DECIMAL(19,2), LTRIM(RTRIM(t.[UNITAMOUNT]))) IS NULL)
                                   OR (NULLIF(LTRIM(RTRIM(t.[PAYMENTS])), '') IS NOT NULL
                                      AND TRY_CONVERT(DECIMAL(19,2), LTRIM(RTRIM(t.[PAYMENTS]))) IS NULL)
                                   OR (NULLIF(LTRIM(RTRIM(t.[ADJUSTMENTS])), '') IS NOT NULL
                                      AND TRY_CONVERT(DECIMAL(19,2), LTRIM(RTRIM(t.[ADJUSTMENTS]))) IS NULL)
                                   OR (NULLIF(LTRIM(RTRIM(t.[TRANSFERS])), '') IS NOT NULL
                                      AND TRY_CONVERT(DECIMAL(19,2), LTRIM(RTRIM(t.[TRANSFERS]))) IS NULL)
                                   OR (NULLIF(LTRIM(RTRIM(t.[OUTSTANDING])), '') IS NOT NULL
                                      AND TRY_CONVERT(DECIMAL(19,2), LTRIM(RTRIM(t.[OUTSTANDING]))) IS NULL)
                              THEN 1 ELSE 0 END),
    @bad_units = SUM(CASE WHEN NULLIF(LTRIM(RTRIM(t.[UNITS])), '') IS NOT NULL
                                AND TRY_CONVERT(INT, LTRIM(RTRIM(t.[UNITS]))) IS NULL
                           THEN 1 ELSE 0 END),
    @bad_diagnosis_refs = SUM(CASE WHEN (NULLIF(LTRIM(RTRIM(t.[DIAGNOSISREF1])), '') IS NOT NULL
                                          AND (TRY_CONVERT(TINYINT, LTRIM(RTRIM(t.[DIAGNOSISREF1]))) IS NULL
                                               OR TRY_CONVERT(TINYINT, LTRIM(RTRIM(t.[DIAGNOSISREF1]))) NOT BETWEEN 1 AND 8))
                                       OR (NULLIF(LTRIM(RTRIM(t.[DIAGNOSISREF2])), '') IS NOT NULL
                                          AND (TRY_CONVERT(TINYINT, LTRIM(RTRIM(t.[DIAGNOSISREF2]))) IS NULL
                                               OR TRY_CONVERT(TINYINT, LTRIM(RTRIM(t.[DIAGNOSISREF2]))) NOT BETWEEN 1 AND 8))
                                       OR (NULLIF(LTRIM(RTRIM(t.[DIAGNOSISREF3])), '') IS NOT NULL
                                          AND (TRY_CONVERT(TINYINT, LTRIM(RTRIM(t.[DIAGNOSISREF3]))) IS NULL
                                               OR TRY_CONVERT(TINYINT, LTRIM(RTRIM(t.[DIAGNOSISREF3]))) NOT BETWEEN 1 AND 8))
                                       OR (NULLIF(LTRIM(RTRIM(t.[DIAGNOSISREF4])), '') IS NOT NULL
                                          AND (TRY_CONVERT(TINYINT, LTRIM(RTRIM(t.[DIAGNOSISREF4]))) IS NULL
                                               OR TRY_CONVERT(TINYINT, LTRIM(RTRIM(t.[DIAGNOSISREF4]))) NOT BETWEEN 1 AND 8))
                                  THEN 1 ELSE 0 END),
    @bad_lengths = SUM(CASE WHEN LEN(LTRIM(RTRIM(t.[ID]))) > 64
                                  OR LEN(LTRIM(RTRIM(t.[CLAIMID]))) > 64
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[CHARGEID])), '')) > 64
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[TYPE])), '')) > 128
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[METHOD])), '')) > 128
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[PLACEOFSERVICE])), '')) > 128
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[PROCEDURECODE])), '')) > 255
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[MODIFIER1])), '')) > 128
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[MODIFIER2])), '')) > 128
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[DEPARTMENTID])), '')) > 64
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[NOTES])), '')) > 2000
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[TRANSFEROUTID])), '')) > 64
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[TRANSFERTYPE])), '')) > 128
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[LINENOTE])), '')) > 2000
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[FEESCHEDULEID])), '')) > 64
                                  OR LEN(NULLIF(LTRIM(RTRIM(t.[PATIENTINSURANCEID])), '')) > 64
                                  OR LEN(source_file) > 255
                             THEN 1 ELSE 0 END)
FROM raw.claim_transaction t;

/* Pre-load scan validates transaction shape/types only. Relationship checks run once after core.claim is refreshed. */
IF COALESCE(@bad_required, 0) <> 0
    THROW 51428, 'raw.claim_transaction contains a blank required transaction field.', 1;
IF COALESCE(@bad_dates, 0) <> 0
    THROW 51429, 'raw.claim_transaction contains an unparseable service date.', 1;
IF COALESCE(@bad_financials, 0) <> 0
    THROW 51430, 'raw.claim_transaction contains a nonnumeric financial value.', 1;
IF COALESCE(@bad_units, 0) <> 0
    THROW 51431, 'raw.claim_transaction contains a noninteger UNITS value.', 1;
IF COALESCE(@bad_diagnosis_refs, 0) <> 0
    THROW 51432, 'raw.claim_transaction contains a diagnosis reference outside positions 1-8.', 1;
IF COALESCE(@bad_lengths, 0) <> 0
    THROW 51433, 'raw.claim_transaction contains a value longer than the current core target column.', 1;

/*
PATIENTINSURANCEID is preserved as opaque source lineage.
Synthea v4.0.0 writes a plan-record/member-like identifier here, but the
authoritative generated source does not support a universal FK to the
exported payer-transition rows. Controlled fixtures also use this source
column differently. Payer relationships therefore come from core.claim,
while this transaction field is retained without relational enforcement.
*/
BEGIN TRY
    BEGIN TRANSACTION;

    DELETE FROM core.claim_transaction;
    DELETE FROM core.claim_diagnosis;
    DELETE FROM core.claim;

    INSERT INTO core.claim (
        source_claim_id,
        member_id,
        encounter_id,
        rendering_provider_id,
        referring_provider_id,
        supervising_provider_id,
        primary_payer_id,
        secondary_payer_id,
        service_date,
        current_illness_date,
        department_id,
        patient_department_id,
        primary_status,
        secondary_status,
        patient_status,
        primary_outstanding_amount,
        secondary_outstanding_amount,
        patient_outstanding_amount,
        primary_last_billed_date,
        secondary_last_billed_date,
        patient_last_billed_date,
        primary_healthcare_claim_type_id,
        secondary_healthcare_claim_type_id,
        synthetic_fixture_flag,
        source_name,
        source_file,
        pipeline_run_id
    )
    SELECT
        LTRIM(RTRIM(c.[Id])),
        m.member_id,
        e.encounter_id,
        rp.provider_id,
        refp.provider_id,
        spp.provider_id,
        pp.payer_id,
        spay.payer_id,
        CONVERT(DATE, LEFT(LTRIM(RTRIM(c.[SERVICEDATE])), 10), 23),
        TRY_CONVERT(DATE, LEFT(NULLIF(LTRIM(RTRIM(c.[CURRENTILLNESSDATE])), ''), 10), 23),
        NULLIF(LTRIM(RTRIM(c.[DEPARTMENTID])), ''),
        NULLIF(LTRIM(RTRIM(c.[PATIENTDEPARTMENTID])), ''),
        NULLIF(LTRIM(RTRIM(c.[STATUS1])), ''),
        NULLIF(LTRIM(RTRIM(c.[STATUS2])), ''),
        NULLIF(LTRIM(RTRIM(c.[STATUSP])), ''),
        TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM(c.[OUTSTANDING1])), '')),
        TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM(c.[OUTSTANDING2])), '')),
        TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM(c.[OUTSTANDINGP])), '')),
        TRY_CONVERT(DATE, LEFT(NULLIF(LTRIM(RTRIM(c.[LASTBILLEDDATE1])), ''), 10), 23),
        TRY_CONVERT(DATE, LEFT(NULLIF(LTRIM(RTRIM(c.[LASTBILLEDDATE2])), ''), 10), 23),
        TRY_CONVERT(DATE, LEFT(NULLIF(LTRIM(RTRIM(c.[LASTBILLEDDATEP])), ''), 10), 23),
        NULLIF(LTRIM(RTRIM(c.[HEALTHCARECLAIMTYPEID1])), ''),
        NULLIF(LTRIM(RTRIM(c.[HEALTHCARECLAIMTYPEID2])), ''),
        c.synthetic_fixture_flag,
        c.source_name,
        c.source_file,
        c.pipeline_run_id
    FROM raw.claim c
    INNER JOIN core.member m
        ON m.source_patient_id = LTRIM(RTRIM(c.[PATIENTID]))
    INNER JOIN core.encounter e
        ON e.source_encounter_id = LTRIM(RTRIM(c.[APPOINTMENTID]))
    LEFT JOIN core.provider rp
        ON rp.source_provider_id = NULLIF(LTRIM(RTRIM(c.[PROVIDERID])), '')
    LEFT JOIN core.provider refp
        ON refp.source_provider_id = NULLIF(LTRIM(RTRIM(c.[REFERRINGPROVIDERID])), '')
    LEFT JOIN core.provider spp
        ON spp.source_provider_id = NULLIF(LTRIM(RTRIM(c.[SUPERVISINGPROVIDERID])), '')
    LEFT JOIN core.payer pp
        ON pp.source_payer_id = NULLIF(LTRIM(RTRIM(c.[PRIMARYPATIENTINSURANCEID])), '')
    LEFT JOIN core.payer spay
        ON spay.source_payer_id = NULLIF(LTRIM(RTRIM(c.[SECONDARYPATIENTINSURANCEID])), '');

    SET @inserted_rows = @@ROWCOUNT;
    IF @inserted_rows <> @raw_claim_rows
        THROW 51434, 'core.claim insert did not reconcile one-for-one to raw.claim.', 1;

    INSERT INTO core.claim_diagnosis (
        claim_id,
        diagnosis_sequence,
        diagnosis_code,
        synthetic_fixture_flag,
        source_name,
        source_file,
        pipeline_run_id
    )
    SELECT
        cc.claim_id,
        d.diagnosis_sequence,
        LTRIM(RTRIM(d.diagnosis_code)),
        c.synthetic_fixture_flag,
        c.source_name,
        c.source_file,
        c.pipeline_run_id
    FROM raw.claim c
    INNER JOIN core.claim cc
        ON cc.source_claim_id = LTRIM(RTRIM(c.[Id]))
    CROSS APPLY (
        VALUES
            (CONVERT(TINYINT, 1), c.[DIAGNOSIS1]),
            (CONVERT(TINYINT, 2), c.[DIAGNOSIS2]),
            (CONVERT(TINYINT, 3), c.[DIAGNOSIS3]),
            (CONVERT(TINYINT, 4), c.[DIAGNOSIS4]),
            (CONVERT(TINYINT, 5), c.[DIAGNOSIS5]),
            (CONVERT(TINYINT, 6), c.[DIAGNOSIS6]),
            (CONVERT(TINYINT, 7), c.[DIAGNOSIS7]),
            (CONVERT(TINYINT, 8), c.[DIAGNOSIS8])
    ) d (diagnosis_sequence, diagnosis_code)
    WHERE NULLIF(LTRIM(RTRIM(d.diagnosis_code)), '') IS NOT NULL;

    SET @inserted_rows = @@ROWCOUNT;
    IF @inserted_rows <> @expected_claim_diagnosis_rows
        THROW 51435, 'core.claim_diagnosis insert did not reconcile to populated raw diagnosis positions.', 1;

    /* Claim-dependent transaction relationship checks now that core.claim has been refreshed. */
    SELECT
        @missing_claim = SUM(CASE WHEN c.claim_id IS NULL THEN 1 ELSE 0 END),
        @missing_member = SUM(CASE WHEN m.member_id IS NULL THEN 1 ELSE 0 END),
        @missing_encounter = SUM(CASE WHEN NULLIF(LTRIM(RTRIM(t.[APPOINTMENTID])), '') IS NOT NULL
                                           AND e.encounter_id IS NULL
                                      THEN 1 ELSE 0 END),
        @missing_provider = SUM(CASE WHEN NULLIF(LTRIM(RTRIM(t.[PROVIDERID])), '') IS NOT NULL
                                          AND p.provider_id IS NULL
                                     THEN 1 ELSE 0 END),
        @missing_supervising_provider = SUM(CASE WHEN NULLIF(LTRIM(RTRIM(t.[SUPERVISINGPROVIDERID])), '') IS NOT NULL
                                                      AND sp.provider_id IS NULL
                                                 THEN 1 ELSE 0 END),
        @claim_member_mismatch = SUM(CASE WHEN c.claim_id IS NOT NULL AND m.member_id IS NOT NULL
                                               AND c.member_id <> m.member_id
                                          THEN 1 ELSE 0 END),
        @claim_encounter_mismatch = SUM(CASE WHEN c.claim_id IS NOT NULL
                                                  AND NULLIF(LTRIM(RTRIM(t.[APPOINTMENTID])), '') IS NOT NULL
                                                  AND e.encounter_id IS NOT NULL
                                                  AND c.encounter_id <> e.encounter_id
                                             THEN 1 ELSE 0 END)
    FROM raw.claim_transaction t
    LEFT JOIN core.claim c
        ON c.source_claim_id = NULLIF(LTRIM(RTRIM(t.[CLAIMID])), '')
    LEFT JOIN core.member m
        ON m.source_patient_id = NULLIF(LTRIM(RTRIM(t.[PATIENTID])), '')
    LEFT JOIN core.encounter e
        ON e.source_encounter_id = NULLIF(LTRIM(RTRIM(t.[APPOINTMENTID])), '')
    LEFT JOIN core.provider p
        ON p.source_provider_id = NULLIF(LTRIM(RTRIM(t.[PROVIDERID])), '')
    LEFT JOIN core.provider sp
        ON sp.source_provider_id = NULLIF(LTRIM(RTRIM(t.[SUPERVISINGPROVIDERID])), '');

    IF COALESCE(@missing_claim, 0) <> 0
        THROW 51436, 'raw.claim_transaction contains CLAIMID values not found in refreshed core.claim.', 1;
    IF COALESCE(@missing_member, 0) <> 0
        THROW 51437, 'raw.claim_transaction contains PATIENTID values not found in core.member.', 1;
    IF COALESCE(@missing_encounter, 0) <> 0
        THROW 51438, 'raw.claim_transaction contains nonblank APPOINTMENTID values not found in core.encounter.', 1;
    IF COALESCE(@missing_provider, 0) <> 0
        THROW 51439, 'raw.claim_transaction contains nonblank PROVIDERID values not found in core.provider.', 1;
    IF COALESCE(@missing_supervising_provider, 0) <> 0
        THROW 51440, 'raw.claim_transaction contains nonblank SUPERVISINGPROVIDERID values not found in core.provider.', 1;
    IF COALESCE(@claim_member_mismatch, 0) <> 0
        THROW 51442, 'raw.claim_transaction PATIENTID does not match the parent claim member.', 1;
    IF COALESCE(@claim_encounter_mismatch, 0) <> 0
        THROW 51443, 'raw.claim_transaction APPOINTMENTID does not match the parent claim encounter.', 1;

    INSERT INTO core.claim_transaction (
        source_transaction_id,
        source_charge_id,
        claim_id,
        member_id,
        encounter_id,
        provider_id,
        supervising_provider_id,
        source_patient_insurance_id,
        place_organization_id,
        transaction_type,
        amount,
        method,
        service_from_date,
        service_to_date,
        source_place_value,
        procedure_code,
        modifier_1,
        modifier_2,
        diagnosis_reference_1,
        diagnosis_reference_2,
        diagnosis_reference_3,
        diagnosis_reference_4,
        units,
        department_id,
        notes,
        unit_amount,
        transfer_out_id,
        transfer_type,
        payments,
        adjustments,
        transfers,
        outstanding,
        line_note,
        fee_schedule_id,
        synthetic_fixture_flag,
        source_name,
        source_file,
        pipeline_run_id
    )
    SELECT
        LTRIM(RTRIM(t.[ID])),
        NULLIF(LTRIM(RTRIM(t.[CHARGEID])), ''),
        c.claim_id,
        m.member_id,
        e.encounter_id,
        p.provider_id,
        sp.provider_id,
        NULLIF(LTRIM(RTRIM(t.[PATIENTINSURANCEID])), ''),
        o.organization_id,
        LTRIM(RTRIM(t.[TYPE])),
        TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM(t.[AMOUNT])), '')),
        NULLIF(LTRIM(RTRIM(t.[METHOD])), ''),
        d.service_from_date,
        CASE
            WHEN d.source_service_to_date = CONVERT(DATE, '1970-01-01') THEN NULL
            WHEN d.source_service_to_date < d.service_from_date THEN NULL
            ELSE d.source_service_to_date
        END,
        NULLIF(LTRIM(RTRIM(t.[PLACEOFSERVICE])), ''),
        NULLIF(LTRIM(RTRIM(t.[PROCEDURECODE])), ''),
        NULLIF(LTRIM(RTRIM(t.[MODIFIER1])), ''),
        NULLIF(LTRIM(RTRIM(t.[MODIFIER2])), ''),
        TRY_CONVERT(TINYINT, NULLIF(LTRIM(RTRIM(t.[DIAGNOSISREF1])), '')),
        TRY_CONVERT(TINYINT, NULLIF(LTRIM(RTRIM(t.[DIAGNOSISREF2])), '')),
        TRY_CONVERT(TINYINT, NULLIF(LTRIM(RTRIM(t.[DIAGNOSISREF3])), '')),
        TRY_CONVERT(TINYINT, NULLIF(LTRIM(RTRIM(t.[DIAGNOSISREF4])), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(t.[UNITS])), '')),
        NULLIF(LTRIM(RTRIM(t.[DEPARTMENTID])), ''),
        NULLIF(LTRIM(RTRIM(t.[NOTES])), ''),
        TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM(t.[UNITAMOUNT])), '')),
        NULLIF(LTRIM(RTRIM(t.[TRANSFEROUTID])), ''),
        NULLIF(LTRIM(RTRIM(t.[TRANSFERTYPE])), ''),
        TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM(t.[PAYMENTS])), '')),
        TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM(t.[ADJUSTMENTS])), '')),
        TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM(t.[TRANSFERS])), '')),
        TRY_CONVERT(DECIMAL(19,2), NULLIF(LTRIM(RTRIM(t.[OUTSTANDING])), '')),
        NULLIF(LTRIM(RTRIM(t.[LINENOTE])), ''),
        NULLIF(LTRIM(RTRIM(t.[FEESCHEDULEID])), ''),
        t.synthetic_fixture_flag,
        t.source_name,
        t.source_file,
        t.pipeline_run_id
    FROM raw.claim_transaction t
    CROSS APPLY (
        VALUES (
            CONVERT(DATE, LEFT(LTRIM(RTRIM(t.[FROMDATE])), 10), 23),
            CONVERT(DATE, LEFT(LTRIM(RTRIM(t.[TODATE])), 10), 23)
        )
    ) d (service_from_date, source_service_to_date)
    INNER JOIN core.claim c
        ON c.source_claim_id = LTRIM(RTRIM(t.[CLAIMID]))
    INNER JOIN core.member m
        ON m.source_patient_id = LTRIM(RTRIM(t.[PATIENTID]))
    LEFT JOIN core.encounter e
        ON e.source_encounter_id = NULLIF(LTRIM(RTRIM(t.[APPOINTMENTID])), '')
    LEFT JOIN core.provider p
        ON p.source_provider_id = NULLIF(LTRIM(RTRIM(t.[PROVIDERID])), '')
    LEFT JOIN core.provider sp
        ON sp.source_provider_id = NULLIF(LTRIM(RTRIM(t.[SUPERVISINGPROVIDERID])), '')
    LEFT JOIN core.organization o
        ON o.source_organization_id = NULLIF(LTRIM(RTRIM(t.[PLACEOFSERVICE])), '');

    SET @inserted_rows = @@ROWCOUNT;
    IF @inserted_rows <> @raw_transaction_rows
        THROW 51444, 'core.claim_transaction insert did not reconcile one-for-one to raw.claim_transaction.', 1;

    IF (SELECT COUNT_BIG(*) FROM core.claim_transaction WHERE service_to_date IS NULL)
       <> COALESCE(@epoch_service_to_rows, 0) + COALESCE(@reversed_non_epoch_service_to_rows, 0)
        THROW 51445, 'core.claim_transaction service_to_date normalization count does not reconcile to raw anomalies.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;

SELECT
    @pipeline_run_id AS pipeline_run_id,
    @raw_claim_rows AS raw_claim_rows,
    (SELECT COUNT_BIG(*) FROM core.claim) AS core_claim_rows,
    @expected_claim_diagnosis_rows AS expected_claim_diagnosis_rows,
    (SELECT COUNT_BIG(*) FROM core.claim_diagnosis) AS core_claim_diagnosis_rows,
    @raw_transaction_rows AS raw_transaction_rows,
    (SELECT COUNT_BIG(*) FROM core.claim_transaction) AS core_transaction_rows,
    (SELECT COUNT_BIG(*) FROM core.claim WHERE synthetic_fixture_flag = 1) AS fixture_claim_rows,
    (SELECT COUNT_BIG(*) FROM core.claim_diagnosis WHERE synthetic_fixture_flag = 1) AS fixture_claim_diagnosis_rows,
    (SELECT COUNT_BIG(*) FROM core.claim_transaction WHERE synthetic_fixture_flag = 1) AS fixture_transaction_rows,
    (SELECT COUNT_BIG(*) FROM core.claim_transaction WHERE source_patient_insurance_id IS NOT NULL) AS transactions_with_source_patient_insurance_id,
    (SELECT COUNT_BIG(*) FROM core.claim_transaction WHERE place_organization_id IS NOT NULL) AS transactions_with_place_organization,
    (SELECT COUNT_BIG(*) FROM core.claim_transaction WHERE source_place_value IN ('11', '21')) AS transactions_with_fixture_pos_style_value,
    @epoch_service_to_rows AS normalized_epoch_service_to_rows,
    @reversed_non_epoch_service_to_rows AS normalized_reversed_service_to_rows,
    (SELECT COUNT_BIG(*) FROM core.claim_transaction WHERE service_to_date IS NULL) AS core_null_service_to_date_rows;
GO
