/*
Healthcare Payer Analytics Pipeline
Phase 2 - executable organization/provider validation

Stable test IDs:
- T-CORE-007 organization grain / reconciliation
- T-CORE-008 provider grain / reconciliation
- T-CORE-009 provider-to-organization relationship integrity
- T-CORE-010 required fields, lineage, and fixture preservation

Current pinned-source benchmark (informational, not the generic invariant):
- approximately 1,662 raw/core organizations
- approximately 1,662 raw/core providers
*/

USE HealthcarePayerAnalytics;
GO

SET NOCOUNT ON;
GO

/* T-CORE-007: one core organization per raw organization/source organization identifier. */
IF (SELECT COUNT_BIG(*) FROM core.organization) <> (SELECT COUNT_BIG(*) FROM raw.organization)
    THROW 51301, 'T-CORE-007 failed: core.organization row count does not equal raw.organization row count.', 1;

IF EXISTS (
    SELECT source_organization_id
    FROM core.organization
    GROUP BY source_organization_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 51302, 'T-CORE-007 failed: duplicate source_organization_id in core.organization.', 1;

IF EXISTS (
    SELECT 1
    FROM core.organization
    WHERE source_organization_id IS NULL
       OR organization_name IS NULL
)
    THROW 51303, 'T-CORE-007 failed: required organization field is NULL.', 1;

/* T-CORE-008: one core provider per raw provider/source provider identifier. */
IF (SELECT COUNT_BIG(*) FROM core.provider) <> (SELECT COUNT_BIG(*) FROM raw.provider)
    THROW 51304, 'T-CORE-008 failed: core.provider row count does not equal raw.provider row count.', 1;

IF EXISTS (
    SELECT source_provider_id
    FROM core.provider
    GROUP BY source_provider_id
    HAVING COUNT_BIG(*) > 1
)
    THROW 51305, 'T-CORE-008 failed: duplicate source_provider_id in core.provider.', 1;

IF EXISTS (
    SELECT 1
    FROM core.provider
    WHERE source_provider_id IS NULL
       OR organization_id IS NULL
       OR provider_name IS NULL
)
    THROW 51306, 'T-CORE-008 failed: required provider field is NULL.', 1;

/* T-CORE-009: provider relationship resolves to the exact source organization mapping. */
IF EXISTS (
    SELECT 1
    FROM core.provider p
    LEFT JOIN core.organization o
        ON o.organization_id = p.organization_id
    WHERE o.organization_id IS NULL
)
    THROW 51307, 'T-CORE-009 failed: orphan organization_id in core.provider.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.provider rp
    INNER JOIN core.provider cp
        ON cp.source_provider_id = LTRIM(RTRIM(rp.[Id]))
    INNER JOIN core.organization co
        ON co.organization_id = cp.organization_id
    WHERE co.source_organization_id <> LTRIM(RTRIM(rp.[ORGANIZATION]))
)
    THROW 51308, 'T-CORE-009 failed: core.provider organization does not match raw.provider ORGANIZATION.', 1;

/* T-CORE-010: lineage and fixture flags survive raw -> core unchanged. */
IF EXISTS (
    SELECT 1
    FROM raw.organization ro
    INNER JOIN core.organization co
        ON co.source_organization_id = LTRIM(RTRIM(ro.[Id]))
    WHERE co.synthetic_fixture_flag <> ro.synthetic_fixture_flag
       OR co.source_name <> ro.source_name
       OR co.pipeline_run_id <> ro.pipeline_run_id
)
    THROW 51309, 'T-CORE-010 failed: organization lineage/fixture values do not match raw.', 1;

IF EXISTS (
    SELECT 1
    FROM raw.provider rp
    INNER JOIN core.provider cp
        ON cp.source_provider_id = LTRIM(RTRIM(rp.[Id]))
    WHERE cp.synthetic_fixture_flag <> rp.synthetic_fixture_flag
       OR cp.source_name <> rp.source_name
       OR cp.pipeline_run_id <> rp.pipeline_run_id
)
    THROW 51310, 'T-CORE-010 failed: provider lineage/fixture values do not match raw.', 1;

IF EXISTS (
    SELECT 1
    FROM core.organization
    WHERE (latitude IS NOT NULL AND latitude NOT BETWEEN -90 AND 90)
       OR (longitude IS NOT NULL AND longitude NOT BETWEEN -180 AND 180)
)
    THROW 51311, 'T-CORE-010 failed: invalid typed organization latitude/longitude.', 1;

/* Visible QA/profile output. */
SELECT
    (SELECT COUNT_BIG(*) FROM raw.organization) AS raw_organization_rows,
    (SELECT COUNT_BIG(*) FROM core.organization) AS core_organization_rows,
    (SELECT COUNT_BIG(*) FROM raw.provider) AS raw_provider_rows,
    (SELECT COUNT_BIG(*) FROM core.provider) AS core_provider_rows,
    (SELECT COUNT_BIG(*) FROM core.organization WHERE synthetic_fixture_flag = 1) AS fixture_organization_rows,
    (SELECT COUNT_BIG(*) FROM core.provider WHERE synthetic_fixture_flag = 1) AS fixture_provider_rows;

SELECT TOP (20)
    o.organization_name,
    o.state_code,
    COUNT_BIG(*) AS provider_count
FROM core.provider p
INNER JOIN core.organization o
    ON o.organization_id = p.organization_id
GROUP BY
    o.organization_name,
    o.state_code
ORDER BY provider_count DESC, o.organization_name;

PRINT 'Core network validation passed: T-CORE-007 through T-CORE-010.';
GO
