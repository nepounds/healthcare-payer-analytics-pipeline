/*
Healthcare Payer Analytics Pipeline
Phase 2 - executable core foundation validation

Stable test IDs:
- T-CORE-001 member grain / reconciliation
- T-CORE-002 payer grain / reconciliation
- T-CORE-003 enrollment source-row reconciliation
- T-CORE-004 normalized span separation
- T-CORE-005 relationship integrity
- T-CORE-006 Medicaid benefit-flag derivation

Current pinned-source benchmark (informational, not the generic invariant):
- 5,671 core members
- 10 core payers
- 204,896 raw payer-transition rows
- 36,632 normalized enrollment spans
- 5,654 members with enrollment
- 17 members without enrollment
*/

USE HealthcarePayerAnalytics;
GO

SET NOCOUNT ON;
GO

/* T-CORE-001: one core member per raw patient / source patient identifier. */
IF (SELECT COUNT_BIG(*) FROM core.member) <> (SELECT COUNT_BIG(*) FROM raw.patient)
    THROW 51101, 'T-CORE-001 failed: core.member row count does not equal raw.patient row count.', 1;

IF EXISTS (
    SELECT source_patient_id
    FROM core.member
    GROUP BY source_patient_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 51102, 'T-CORE-001 failed: duplicate source_patient_id in core.member.', 1;

/* T-CORE-002: one core payer per raw payer / source payer identifier. */
IF (SELECT COUNT_BIG(*) FROM core.payer) <> (SELECT COUNT_BIG(*) FROM raw.payer)
    THROW 51103, 'T-CORE-002 failed: core.payer row count does not equal raw.payer row count.', 1;

IF EXISTS (
    SELECT source_payer_id
    FROM core.payer
    GROUP BY source_payer_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 51104, 'T-CORE-002 failed: duplicate source_payer_id in core.payer.', 1;

/* T-CORE-003: every raw payer-transition row is represented in exactly one normalized span. */
IF COALESCE((SELECT SUM(CONVERT(BIGINT, source_rows_merged)) FROM core.enrollment_span), 0)
   <> (SELECT COUNT_BIG(*) FROM raw.payer_transition)
    THROW 51105, 'T-CORE-003 failed: enrollment source_rows_merged does not reconcile to raw.payer_transition.', 1;

IF EXISTS (
    SELECT 1
    FROM core.enrollment_span
    WHERE source_rows_merged < 1
)
    THROW 51106, 'T-CORE-003 failed: enrollment span has source_rows_merged < 1.', 1;

/*
T-CORE-004: after normalization, no two spans in the same business/lineage partition
may overlap or touch. Direct adjacency should already have been merged.
*/
IF EXISTS (
    SELECT 1
    FROM (
        SELECT
            es.enrollment_start_date,
            MAX(es.enrollment_end_date) OVER (
                PARTITION BY
                    es.member_id,
                    es.payer_id,
                    es.medical_benefit_flag,
                    es.behavioral_health_benefit_flag,
                    es.synthetic_fixture_flag,
                    es.source_name,
                    es.pipeline_run_id
                ORDER BY
                    es.enrollment_start_date,
                    es.enrollment_end_date,
                    es.enrollment_span_id
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ) AS prior_max_end_date
        FROM core.enrollment_span es
    ) ordered_spans
    WHERE prior_max_end_date IS NOT NULL
      AND enrollment_start_date <= DATEADD(DAY, 1, prior_max_end_date)
)
    THROW 51107, 'T-CORE-004 failed: overlapping or adjacent enrollment spans remain after normalization.', 1;

/* T-CORE-005: relationship integrity. Foreign keys enforce this too; the query makes it visible. */
IF EXISTS (
    SELECT 1
    FROM core.enrollment_span es
    LEFT JOIN core.member m ON m.member_id = es.member_id
    WHERE m.member_id IS NULL
)
    THROW 51108, 'T-CORE-005 failed: orphan member_id in core.enrollment_span.', 1;

IF EXISTS (
    SELECT 1
    FROM core.enrollment_span es
    LEFT JOIN core.payer p ON p.payer_id = es.payer_id
    WHERE p.payer_id IS NULL
)
    THROW 51109, 'T-CORE-005 failed: orphan payer_id in core.enrollment_span.', 1;

/* T-CORE-006: current A-018 benefit approximation. */
IF EXISTS (
    SELECT 1
    FROM core.enrollment_span es
    INNER JOIN core.payer p ON p.payer_id = es.payer_id
    WHERE UPPER(LTRIM(RTRIM(p.payer_name))) = 'MEDICAID'
      AND (es.medical_benefit_flag <> 1 OR es.behavioral_health_benefit_flag <> 1)
)
    THROW 51110, 'T-CORE-006 failed: Medicaid span does not have both benefit flags = 1.', 1;

IF EXISTS (
    SELECT 1
    FROM core.enrollment_span es
    INNER JOIN core.payer p ON p.payer_id = es.payer_id
    WHERE UPPER(LTRIM(RTRIM(p.payer_name))) <> 'MEDICAID'
      AND (es.medical_benefit_flag <> 0 OR es.behavioral_health_benefit_flag <> 0)
)
    THROW 51111, 'T-CORE-006 failed: non-Medicaid span has a benefit flag enabled under A-018.', 1;

/* Visible QA/profile output. */
SELECT
    (SELECT COUNT_BIG(*) FROM raw.patient) AS raw_patient_rows,
    (SELECT COUNT_BIG(*) FROM core.member) AS core_member_rows,
    (SELECT COUNT_BIG(*) FROM raw.payer) AS raw_payer_rows,
    (SELECT COUNT_BIG(*) FROM core.payer) AS core_payer_rows,
    (SELECT COUNT_BIG(*) FROM raw.payer_transition) AS raw_payer_transition_rows,
    (SELECT COUNT_BIG(*) FROM core.enrollment_span) AS core_enrollment_spans,
    (SELECT COUNT(DISTINCT member_id) FROM core.enrollment_span) AS members_with_enrollment,
    (SELECT COUNT_BIG(*) FROM core.member)
        - (SELECT COUNT(DISTINCT member_id) FROM core.enrollment_span) AS members_without_enrollment,
    (SELECT SUM(CONVERT(BIGINT, source_rows_merged)) FROM core.enrollment_span) AS reconciled_source_rows;

SELECT
    p.payer_name,
    es.medical_benefit_flag,
    es.behavioral_health_benefit_flag,
    COUNT_BIG(*) AS enrollment_spans,
    SUM(CONVERT(BIGINT, es.source_rows_merged)) AS source_rows_represented
FROM core.enrollment_span es
INNER JOIN core.payer p
    ON p.payer_id = es.payer_id
GROUP BY
    p.payer_name,
    es.medical_benefit_flag,
    es.behavioral_health_benefit_flag
ORDER BY p.payer_name;

PRINT 'Core foundation validation passed: T-CORE-001 through T-CORE-006.';
GO
