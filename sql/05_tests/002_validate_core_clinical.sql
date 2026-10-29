/*
Healthcare Payer Analytics Pipeline
Phase 2 - executable clinical-core validation

Stable test IDs:
- T-CORE-011 encounter grain / source reconciliation / required fields
- T-CORE-012 encounter relationship, chronology, and numeric integrity
- T-CORE-013 condition grain / source reconciliation / required fields
- T-CORE-014 condition relationship, coding-system, and chronology integrity
- T-CORE-015 controlled fixture lineage preservation

Current pinned-source benchmark (informational, not the generic invariant):
- approximately 313,094 raw/core encounters
- approximately 194,647 raw/core conditions
- 76 controlled fixture encounters
- 76 controlled fixture condition rows
*/

USE HealthcarePayerAnalytics;
GO

SET NOCOUNT ON;
GO

/* T-CORE-011: one core encounter per raw encounter/source encounter ID. */
IF (SELECT COUNT_BIG(*) FROM core.encounter) <> (SELECT COUNT_BIG(*) FROM raw.encounter)
    THROW 51301, 'T-CORE-011 failed: core.encounter row count does not equal raw.encounter row count.', 1;

IF EXISTS (
    SELECT source_encounter_id
    FROM core.encounter
    GROUP BY source_encounter_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 51302, 'T-CORE-011 failed: duplicate source_encounter_id in core.encounter.', 1;

IF EXISTS (
    SELECT encounter_id
    FROM core.encounter
    GROUP BY encounter_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 51303, 'T-CORE-011 failed: duplicate encounter_id primary key value.', 1;

IF EXISTS (
    SELECT 1
    FROM core.encounter
    WHERE source_encounter_id IS NULL
       OR member_id IS NULL
       OR encounter_start_datetime IS NULL
       OR encounter_end_datetime IS NULL
       OR NULLIF(LTRIM(RTRIM(encounter_type)), '') IS NULL
       OR source_name IS NULL
       OR source_file IS NULL
       OR pipeline_run_id IS NULL
)
    THROW 51304, 'T-CORE-011 failed: core.encounter contains a null/blank required field.', 1;

/* T-CORE-012: encounter relationships, chronology, and source numeric integrity. */
IF EXISTS (
    SELECT 1
    FROM core.encounter e
    LEFT JOIN core.member m ON m.member_id = e.member_id
    WHERE m.member_id IS NULL
)
    THROW 51305, 'T-CORE-012 failed: orphan member_id in core.encounter.', 1;

IF EXISTS (
    SELECT 1
    FROM core.encounter e
    LEFT JOIN core.organization o ON o.organization_id = e.organization_id
    WHERE e.organization_id IS NOT NULL
      AND o.organization_id IS NULL
)
    THROW 51306, 'T-CORE-012 failed: orphan organization_id in core.encounter.', 1;

IF EXISTS (
    SELECT 1
    FROM core.encounter e
    LEFT JOIN core.provider p ON p.provider_id = e.provider_id
    WHERE e.provider_id IS NOT NULL
      AND p.provider_id IS NULL
)
    THROW 51307, 'T-CORE-012 failed: orphan provider_id in core.encounter.', 1;

IF EXISTS (
    SELECT 1
    FROM core.encounter e
    LEFT JOIN core.payer p ON p.payer_id = e.payer_id
    WHERE e.payer_id IS NOT NULL
      AND p.payer_id IS NULL
)
    THROW 51308, 'T-CORE-012 failed: orphan payer_id in core.encounter.', 1;

IF EXISTS (
    SELECT 1
    FROM core.encounter e
    INNER JOIN core.provider p ON p.provider_id = e.provider_id
    WHERE e.organization_id IS NOT NULL
      AND p.organization_id <> e.organization_id
)
    THROW 51309, 'T-CORE-012 failed: encounter provider belongs to a different core organization.', 1;

IF EXISTS (
    SELECT 1
    FROM core.encounter
    WHERE encounter_end_datetime < encounter_start_datetime
)
    THROW 51310, 'T-CORE-012 failed: encounter end precedes encounter start.', 1;

IF EXISTS (
    SELECT 1
    FROM core.encounter
    WHERE base_encounter_cost < 0
       OR total_claim_cost < 0
       OR payer_coverage < 0
)
    THROW 51311, 'T-CORE-012 failed: encounter contains a negative source cost.', 1;

/* T-CORE-013: preserve one core row per source condition record. */
IF (SELECT COUNT_BIG(*) FROM core.condition) <> (SELECT COUNT_BIG(*) FROM raw.condition)
    THROW 51312, 'T-CORE-013 failed: core.condition row count does not equal raw.condition row count.', 1;

IF EXISTS (
    SELECT condition_id
    FROM core.condition
    GROUP BY condition_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 51313, 'T-CORE-013 failed: duplicate condition_id primary key value.', 1;

IF EXISTS (
    SELECT 1
    FROM core.condition
    WHERE member_id IS NULL
       OR NULLIF(LTRIM(RTRIM(code_system)), '') IS NULL
       OR NULLIF(LTRIM(RTRIM(diagnosis_code)), '') IS NULL
       OR condition_start_date IS NULL
       OR source_name IS NULL
       OR source_file IS NULL
       OR pipeline_run_id IS NULL
)
    THROW 51314, 'T-CORE-013 failed: core.condition contains a null/blank required field.', 1;

/* T-CORE-014: condition relationships, coding system, and chronology. */
IF EXISTS (
    SELECT 1
    FROM core.condition c
    LEFT JOIN core.member m ON m.member_id = c.member_id
    WHERE m.member_id IS NULL
)
    THROW 51315, 'T-CORE-014 failed: orphan member_id in core.condition.', 1;

IF EXISTS (
    SELECT 1
    FROM core.condition c
    LEFT JOIN core.encounter e ON e.encounter_id = c.encounter_id
    WHERE c.encounter_id IS NOT NULL
      AND e.encounter_id IS NULL
)
    THROW 51316, 'T-CORE-014 failed: orphan encounter_id in core.condition.', 1;

IF EXISTS (
    SELECT 1
    FROM core.condition c
    INNER JOIN core.encounter e ON e.encounter_id = c.encounter_id
    WHERE c.member_id <> e.member_id
)
    THROW 51317, 'T-CORE-014 failed: condition member differs from referenced encounter member.', 1;

IF EXISTS (
    SELECT 1
    FROM core.condition
    WHERE condition_end_date IS NOT NULL
      AND condition_end_date < condition_start_date
)
    THROW 51318, 'T-CORE-014 failed: condition end precedes condition start.', 1;

/* Every nonblank source ENCOUNTER must resolve to a core encounter. */
IF EXISTS (
    SELECT 1
    FROM raw.condition r
    LEFT JOIN core.encounter e
        ON e.source_encounter_id = NULLIF(LTRIM(RTRIM(r.[ENCOUNTER])), '')
    WHERE NULLIF(LTRIM(RTRIM(r.[ENCOUNTER])), '') IS NOT NULL
      AND e.encounter_id IS NULL
)
    THROW 51319, 'T-CORE-014 failed: a nonblank raw.condition ENCOUNTER did not resolve to core.encounter.', 1;

/* T-CORE-015: controlled fixture lineage is preserved one-for-one. */
IF (SELECT COUNT_BIG(*) FROM core.encounter WHERE synthetic_fixture_flag = 1)
   <> (SELECT COUNT_BIG(*) FROM raw.encounter WHERE synthetic_fixture_flag = 1)
    THROW 51320, 'T-CORE-015 failed: encounter fixture count does not reconcile to raw.encounter.', 1;

IF (SELECT COUNT_BIG(*) FROM core.condition WHERE synthetic_fixture_flag = 1)
   <> (SELECT COUNT_BIG(*) FROM raw.condition WHERE synthetic_fixture_flag = 1)
    THROW 51321, 'T-CORE-015 failed: condition fixture count does not reconcile to raw.condition.', 1;

IF EXISTS (
    SELECT 1
    FROM core.condition
    WHERE synthetic_fixture_flag = 1
      AND UPPER(LTRIM(RTRIM(code_system))) <> 'ICD-10-CM'
)
    THROW 51322, 'T-CORE-015 failed: a controlled fixture condition lost its ICD-10-CM code-system lineage.', 1;

/* Visible QA/profile output. */
SELECT
    (SELECT COUNT_BIG(*) FROM raw.encounter) AS raw_encounter_rows,
    (SELECT COUNT_BIG(*) FROM core.encounter) AS core_encounter_rows,
    (SELECT COUNT_BIG(*) FROM raw.condition) AS raw_condition_rows,
    (SELECT COUNT_BIG(*) FROM core.condition) AS core_condition_rows,
    (SELECT COUNT_BIG(*) FROM core.encounter WHERE synthetic_fixture_flag = 1) AS fixture_encounter_rows,
    (SELECT COUNT_BIG(*) FROM core.condition WHERE synthetic_fixture_flag = 1) AS fixture_condition_rows,
    (SELECT COUNT_BIG(*) FROM core.condition WHERE encounter_id IS NULL) AS conditions_without_encounter;

SELECT
    encounter_type,
    synthetic_fixture_flag,
    COUNT_BIG(*) AS encounter_rows
FROM core.encounter
GROUP BY encounter_type, synthetic_fixture_flag
ORDER BY encounter_type, synthetic_fixture_flag;

SELECT
    code_system,
    synthetic_fixture_flag,
    COUNT_BIG(*) AS condition_rows
FROM core.condition
GROUP BY code_system, synthetic_fixture_flag
ORDER BY code_system, synthetic_fixture_flag;

PRINT 'Core clinical validation passed: T-CORE-011 through T-CORE-015.';
GO
