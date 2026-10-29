/*
Healthcare Payer Analytics Pipeline
Phase 2 - executable claims-core validation

Stable test IDs:
- T-CORE-016 claim grain / source reconciliation / required fields
- T-CORE-017 claim relationships, chronology, and typed source-field integrity
- T-CORE-018 claim-diagnosis expansion grain / source reconciliation
- T-CORE-019 claim-transaction grain / source reconciliation / required fields
- T-CORE-020 claim-to-transaction relationship and source consistency
- T-CORE-021 transaction dates, diagnosis references, and mixed place-value semantics
- T-CORE-022 controlled fixture lineage preservation

Current pinned-source benchmark (informational, not the generic invariant):
- 573,681 raw/core claims
- 825,929 populated claim-diagnosis positions
- 5,220,492 raw/core claim transactions
- 76 fixture claims / 76 fixture claim-diagnosis rows / 76 fixture transactions
- 5,220,416 transaction place values resolve to source organizations
- 76 fixture transaction place values use POS-style values 11 or 21
*/

USE HealthcarePayerAnalytics;
GO

SET NOCOUNT ON;
GO

/* T-CORE-016: one core claim per raw claim/source claim ID. */
IF (SELECT COUNT_BIG(*) FROM core.claim) <> (SELECT COUNT_BIG(*) FROM raw.claim)
    THROW 51501, 'T-CORE-016 failed: core.claim row count does not equal raw.claim row count.', 1;

IF EXISTS (
    SELECT source_claim_id
    FROM core.claim
    GROUP BY source_claim_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 51502, 'T-CORE-016 failed: duplicate source_claim_id in core.claim.', 1;

IF EXISTS (
    SELECT claim_id
    FROM core.claim
    GROUP BY claim_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 51503, 'T-CORE-016 failed: duplicate claim_id primary key value.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim
    WHERE NULLIF(LTRIM(RTRIM(source_claim_id)), '') IS NULL
       OR member_id IS NULL
       OR encounter_id IS NULL
       OR service_date IS NULL
       OR source_name IS NULL
       OR source_file IS NULL
       OR pipeline_run_id IS NULL
)
    THROW 51504, 'T-CORE-016 failed: core.claim contains a null/blank required field.', 1;

/* T-CORE-017: claim relationships and typed-field integrity. */
IF EXISTS (
    SELECT 1
    FROM core.claim c
    LEFT JOIN core.member m ON m.member_id = c.member_id
    WHERE m.member_id IS NULL
)
    THROW 51505, 'T-CORE-017 failed: orphan member_id in core.claim.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim c
    LEFT JOIN core.encounter e ON e.encounter_id = c.encounter_id
    WHERE e.encounter_id IS NULL
)
    THROW 51506, 'T-CORE-017 failed: orphan encounter_id in core.claim.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim c
    INNER JOIN core.encounter e ON e.encounter_id = c.encounter_id
    WHERE c.member_id <> e.member_id
)
    THROW 51507, 'T-CORE-017 failed: claim member differs from referenced encounter member.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim c
    LEFT JOIN core.provider p ON p.provider_id = c.rendering_provider_id
    WHERE c.rendering_provider_id IS NOT NULL
      AND p.provider_id IS NULL
)
    THROW 51508, 'T-CORE-017 failed: orphan rendering_provider_id in core.claim.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim c
    LEFT JOIN core.provider p ON p.provider_id = c.referring_provider_id
    WHERE c.referring_provider_id IS NOT NULL
      AND p.provider_id IS NULL
)
    THROW 51509, 'T-CORE-017 failed: orphan referring_provider_id in core.claim.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim c
    LEFT JOIN core.provider p ON p.provider_id = c.supervising_provider_id
    WHERE c.supervising_provider_id IS NOT NULL
      AND p.provider_id IS NULL
)
    THROW 51510, 'T-CORE-017 failed: orphan supervising_provider_id in core.claim.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim c
    LEFT JOIN core.payer p ON p.payer_id = c.primary_payer_id
    WHERE c.primary_payer_id IS NOT NULL
      AND p.payer_id IS NULL
)
    THROW 51511, 'T-CORE-017 failed: orphan primary_payer_id in core.claim.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim c
    LEFT JOIN core.payer p ON p.payer_id = c.secondary_payer_id
    WHERE c.secondary_payer_id IS NOT NULL
      AND p.payer_id IS NULL
)
    THROW 51512, 'T-CORE-017 failed: orphan secondary_payer_id in core.claim.', 1;

/* Reconcile the core relationship back to raw source identifiers, not just FK existence. */
IF EXISTS (
    SELECT 1
    FROM raw.claim r
    INNER JOIN core.claim c
        ON c.source_claim_id = LTRIM(RTRIM(r.[Id]))
    INNER JOIN core.member m
        ON m.member_id = c.member_id
    INNER JOIN core.encounter e
        ON e.encounter_id = c.encounter_id
    WHERE m.source_patient_id <> LTRIM(RTRIM(r.[PATIENTID]))
       OR e.source_encounter_id <> LTRIM(RTRIM(r.[APPOINTMENTID]))
)
    THROW 51513, 'T-CORE-017 failed: core.claim member/encounter mapping does not reconcile to raw.claim.', 1;

/* T-CORE-018: one row per populated claim diagnosis position. */
DECLARE @expected_claim_diagnosis_rows BIGINT;
SELECT @expected_claim_diagnosis_rows = COUNT_BIG(*)
FROM raw.claim r
CROSS APPLY (
    VALUES
        (r.[DIAGNOSIS1]), (r.[DIAGNOSIS2]), (r.[DIAGNOSIS3]), (r.[DIAGNOSIS4]),
        (r.[DIAGNOSIS5]), (r.[DIAGNOSIS6]), (r.[DIAGNOSIS7]), (r.[DIAGNOSIS8])
) d (diagnosis_code)
WHERE NULLIF(LTRIM(RTRIM(d.diagnosis_code)), '') IS NOT NULL;

IF (SELECT COUNT_BIG(*) FROM core.claim_diagnosis) <> @expected_claim_diagnosis_rows
    THROW 51514, 'T-CORE-018 failed: core.claim_diagnosis row count does not reconcile to populated raw diagnosis positions.', 1;

IF EXISTS (
    SELECT claim_id, diagnosis_sequence
    FROM core.claim_diagnosis
    GROUP BY claim_id, diagnosis_sequence
    HAVING COUNT_BIG(*) > 1
)
    THROW 51515, 'T-CORE-018 failed: duplicate claim/diagnosis_sequence in core.claim_diagnosis.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim_diagnosis d
    LEFT JOIN core.claim c ON c.claim_id = d.claim_id
    WHERE c.claim_id IS NULL
       OR d.diagnosis_sequence NOT BETWEEN 1 AND 8
       OR NULLIF(LTRIM(RTRIM(d.diagnosis_code)), '') IS NULL
       OR d.source_name IS NULL
       OR d.source_file IS NULL
       OR d.pipeline_run_id IS NULL
)
    THROW 51516, 'T-CORE-018 failed: claim diagnosis required field/range/FK integrity violation.', 1;

/* T-CORE-019: one core transaction per source transaction/source ID. */
IF (SELECT COUNT_BIG(*) FROM core.claim_transaction) <> (SELECT COUNT_BIG(*) FROM raw.claim_transaction)
    THROW 51517, 'T-CORE-019 failed: core.claim_transaction row count does not equal raw.claim_transaction row count.', 1;

IF EXISTS (
    SELECT source_transaction_id
    FROM core.claim_transaction
    GROUP BY source_transaction_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 51518, 'T-CORE-019 failed: duplicate source_transaction_id in core.claim_transaction.', 1;

IF EXISTS (
    SELECT claim_transaction_id
    FROM core.claim_transaction
    GROUP BY claim_transaction_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 51519, 'T-CORE-019 failed: duplicate claim_transaction_id primary key value.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim_transaction
    WHERE NULLIF(LTRIM(RTRIM(source_transaction_id)), '') IS NULL
       OR claim_id IS NULL
       OR member_id IS NULL
       OR NULLIF(LTRIM(RTRIM(transaction_type)), '') IS NULL
       OR service_from_date IS NULL
       OR source_name IS NULL
       OR source_file IS NULL
       OR pipeline_run_id IS NULL
)
    THROW 51520, 'T-CORE-019 failed: core.claim_transaction contains a null/blank required field.', 1;

/* T-CORE-020: parent claim/member/encounter and optional source relationships remain coherent. */
IF EXISTS (
    SELECT 1
    FROM core.claim_transaction t
    LEFT JOIN core.claim c ON c.claim_id = t.claim_id
    WHERE c.claim_id IS NULL
)
    THROW 51521, 'T-CORE-020 failed: orphan claim_id in core.claim_transaction.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim_transaction t
    LEFT JOIN core.member m ON m.member_id = t.member_id
    WHERE m.member_id IS NULL
)
    THROW 51522, 'T-CORE-020 failed: orphan member_id in core.claim_transaction.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim_transaction t
    INNER JOIN core.claim c ON c.claim_id = t.claim_id
    WHERE t.member_id <> c.member_id
)
    THROW 51523, 'T-CORE-020 failed: transaction member differs from parent claim member.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim_transaction t
    INNER JOIN core.claim c ON c.claim_id = t.claim_id
    WHERE t.encounter_id IS NOT NULL
      AND t.encounter_id <> c.encounter_id
)
    THROW 51524, 'T-CORE-020 failed: transaction encounter differs from parent claim encounter.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim_transaction t
    LEFT JOIN core.encounter e ON e.encounter_id = t.encounter_id
    WHERE t.encounter_id IS NOT NULL
      AND e.encounter_id IS NULL
)
    THROW 51525, 'T-CORE-020 failed: orphan encounter_id in core.claim_transaction.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim_transaction t
    LEFT JOIN core.provider p ON p.provider_id = t.provider_id
    WHERE t.provider_id IS NOT NULL
      AND p.provider_id IS NULL
)
    THROW 51526, 'T-CORE-020 failed: orphan provider_id in core.claim_transaction.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim_transaction t
    LEFT JOIN core.provider p ON p.provider_id = t.supervising_provider_id
    WHERE t.supervising_provider_id IS NOT NULL
      AND p.provider_id IS NULL
)
    THROW 51527, 'T-CORE-020 failed: orphan supervising_provider_id in core.claim_transaction.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim_transaction t
    INNER JOIN raw.claim_transaction r
        ON LTRIM(RTRIM(r.[ID])) = t.source_transaction_id
    WHERE ISNULL(t.source_patient_insurance_id, '')
       <> ISNULL(NULLIF(LTRIM(RTRIM(r.[PATIENTINSURANCEID])), ''), '')
)
    THROW 51528, 'T-CORE-020 failed: source_patient_insurance_id does not preserve raw PATIENTINSURANCEID.', 1;

/*
PATIENTINSURANCEID is intentionally not treated as a payer or enrollment FK.
The authoritative Synthea v4.0.0 source does not support a universal
transaction-to-payer-transition invariant, and controlled fixtures use the
same raw column differently. T-CORE-020 therefore validates exact preservation
above while payer integrity is enforced at core.claim grain.
*/

IF EXISTS (
    SELECT 1
    FROM core.claim_transaction t
    LEFT JOIN core.organization o ON o.organization_id = t.place_organization_id
    WHERE t.place_organization_id IS NOT NULL
      AND o.organization_id IS NULL
)
    THROW 51529, 'T-CORE-020 failed: orphan place_organization_id in core.claim_transaction.', 1;

/* T-CORE-021: dates, diagnosis-position references, and mixed place semantics. */
IF EXISTS (
    SELECT 1
    FROM core.claim_transaction
    WHERE service_to_date IS NOT NULL
      AND service_to_date < service_from_date
)
    THROW 51530, 'T-CORE-021 failed: nonnull transaction service_to_date precedes service_from_date.', 1;

/*
Source-date normalization is deterministic:
- 1970-01-01 TODATE is treated as an unset/sentinel end date.
- any other TODATE earlier than FROMDATE is an invalid interval.
Both normalize to NULL in core while the raw row remains traceable by source_transaction_id.
*/
DECLARE @expected_null_service_to_rows BIGINT;

SELECT @expected_null_service_to_rows = COUNT_BIG(*)
FROM raw.claim_transaction r
CROSS APPLY (
    VALUES (
        TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM(r.[FROMDATE])), 10), 23),
        TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM(r.[TODATE])), 10), 23)
    )
) d (service_from_date, source_service_to_date)
WHERE d.source_service_to_date = CONVERT(DATE, '1970-01-01')
   OR d.source_service_to_date < d.service_from_date;

IF (SELECT COUNT_BIG(*) FROM core.claim_transaction WHERE service_to_date IS NULL)
   <> @expected_null_service_to_rows
    THROW 51537, 'T-CORE-021 failed: normalized null service_to_date count does not reconcile to raw date anomalies.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.claim_transaction r
    INNER JOIN core.claim_transaction c
        ON c.source_transaction_id = LTRIM(RTRIM(r.[ID]))
    CROSS APPLY (
        VALUES (
            TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM(r.[FROMDATE])), 10), 23),
            TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM(r.[TODATE])), 10), 23)
        )
    ) d (service_from_date, source_service_to_date)
    WHERE (d.source_service_to_date = CONVERT(DATE, '1970-01-01')
           OR d.source_service_to_date < d.service_from_date)
      AND c.service_to_date IS NOT NULL
)
    THROW 51538, 'T-CORE-021 failed: a raw invalid/sentinel end date was not normalized to NULL.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.claim_transaction r
    INNER JOIN core.claim_transaction c
        ON c.source_transaction_id = LTRIM(RTRIM(r.[ID]))
    CROSS APPLY (
        VALUES (
            TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM(r.[FROMDATE])), 10), 23),
            TRY_CONVERT(DATE, LEFT(LTRIM(RTRIM(r.[TODATE])), 10), 23)
        )
    ) d (service_from_date, source_service_to_date)
    WHERE d.source_service_to_date <> CONVERT(DATE, '1970-01-01')
      AND d.source_service_to_date >= d.service_from_date
      AND (c.service_to_date IS NULL OR c.service_to_date <> d.source_service_to_date)
)
    THROW 51539, 'T-CORE-021 failed: a valid raw service end date changed during core normalization.', 1;

/* Each populated diagnosis reference must resolve to an actually populated diagnosis position on that claim. */
IF EXISTS (
    SELECT 1
    FROM core.claim_transaction t
    CROSS APPLY (
        VALUES
            (t.diagnosis_reference_1),
            (t.diagnosis_reference_2),
            (t.diagnosis_reference_3),
            (t.diagnosis_reference_4)
    ) r (diagnosis_sequence)
    LEFT JOIN core.claim_diagnosis d
        ON d.claim_id = t.claim_id
       AND d.diagnosis_sequence = r.diagnosis_sequence
    WHERE r.diagnosis_sequence IS NOT NULL
      AND d.claim_diagnosis_id IS NULL
)
    THROW 51531, 'T-CORE-021 failed: transaction diagnosis reference does not resolve to a populated claim diagnosis position.', 1;

/* If a transaction was resolved to an organization from PLACEOFSERVICE, the raw source value must match it exactly. */
IF EXISTS (
    SELECT 1
    FROM core.claim_transaction t
    INNER JOIN core.organization o
        ON o.organization_id = t.place_organization_id
    WHERE t.source_place_value <> o.source_organization_id
)
    THROW 51532, 'T-CORE-021 failed: transaction place_organization_id does not match source_place_value.', 1;

/* T-CORE-022: controlled fixture lineage is preserved. */
IF (SELECT COUNT_BIG(*) FROM core.claim WHERE synthetic_fixture_flag = 1)
   <> (SELECT COUNT_BIG(*) FROM raw.claim WHERE synthetic_fixture_flag = 1)
    THROW 51533, 'T-CORE-022 failed: claim fixture count does not reconcile to raw.claim.', 1;

IF (SELECT COUNT_BIG(*) FROM core.claim_diagnosis WHERE synthetic_fixture_flag = 1)
   <> (
        SELECT COUNT_BIG(*)
        FROM raw.claim r
        CROSS APPLY (
            VALUES
                (r.[DIAGNOSIS1]), (r.[DIAGNOSIS2]), (r.[DIAGNOSIS3]), (r.[DIAGNOSIS4]),
                (r.[DIAGNOSIS5]), (r.[DIAGNOSIS6]), (r.[DIAGNOSIS7]), (r.[DIAGNOSIS8])
        ) d (diagnosis_code)
        WHERE r.synthetic_fixture_flag = 1
          AND NULLIF(LTRIM(RTRIM(d.diagnosis_code)), '') IS NOT NULL
      )
    THROW 51534, 'T-CORE-022 failed: claim-diagnosis fixture count does not reconcile to raw.claim.', 1;

IF (SELECT COUNT_BIG(*) FROM core.claim_transaction WHERE synthetic_fixture_flag = 1)
   <> (SELECT COUNT_BIG(*) FROM raw.claim_transaction WHERE synthetic_fixture_flag = 1)
    THROW 51535, 'T-CORE-022 failed: transaction fixture count does not reconcile to raw.claim_transaction.', 1;

IF EXISTS (
    SELECT 1
    FROM core.claim_transaction
    WHERE synthetic_fixture_flag = 1
      AND source_place_value NOT IN ('11', '21')
)
    THROW 51536, 'T-CORE-022 failed: a controlled fixture transaction lost its POS-style source place value.', 1;

/* Visible QA/profile output. */
SELECT
    (SELECT COUNT_BIG(*) FROM raw.claim) AS raw_claim_rows,
    (SELECT COUNT_BIG(*) FROM core.claim) AS core_claim_rows,
    @expected_claim_diagnosis_rows AS expected_claim_diagnosis_rows,
    (SELECT COUNT_BIG(*) FROM core.claim_diagnosis) AS core_claim_diagnosis_rows,
    (SELECT COUNT_BIG(*) FROM raw.claim_transaction) AS raw_transaction_rows,
    (SELECT COUNT_BIG(*) FROM core.claim_transaction) AS core_transaction_rows,
    (SELECT COUNT_BIG(*) FROM core.claim WHERE synthetic_fixture_flag = 1) AS fixture_claim_rows,
    (SELECT COUNT_BIG(*) FROM core.claim_diagnosis WHERE synthetic_fixture_flag = 1) AS fixture_claim_diagnosis_rows,
    (SELECT COUNT_BIG(*) FROM core.claim_transaction WHERE synthetic_fixture_flag = 1) AS fixture_transaction_rows,
    (SELECT COUNT_BIG(*) FROM core.claim_transaction WHERE place_organization_id IS NOT NULL) AS transactions_with_place_organization,
    (SELECT COUNT_BIG(*) FROM core.claim_transaction WHERE source_place_value IN ('11', '21')) AS transactions_with_pos_style_value,
    @expected_null_service_to_rows AS expected_null_service_to_date_rows,
    (SELECT COUNT_BIG(*) FROM core.claim_transaction WHERE service_to_date IS NULL) AS core_null_service_to_date_rows;

SELECT
    diagnosis_sequence,
    synthetic_fixture_flag,
    COUNT_BIG(*) AS claim_diagnosis_rows
FROM core.claim_diagnosis
GROUP BY diagnosis_sequence, synthetic_fixture_flag
ORDER BY diagnosis_sequence, synthetic_fixture_flag;

SELECT
    transaction_type,
    synthetic_fixture_flag,
    COUNT_BIG(*) AS transaction_rows
FROM core.claim_transaction
GROUP BY transaction_type, synthetic_fixture_flag
ORDER BY transaction_type, synthetic_fixture_flag;

PRINT 'Core claims validation passed: T-CORE-016 through T-CORE-022.';
GO
