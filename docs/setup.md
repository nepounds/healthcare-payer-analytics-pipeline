# Local Setup and Execution

## Project name

**Healthcare Payer Analytics Pipeline**

## Recommended local path

```text
C:\Projects\Healthcare Payer Analytics Pipeline
```

## Recommended GitHub repository name

```text
healthcare-payer-analytics-pipeline
```

## Main tools

1. VS Code for repository work.
2. Git/GitHub for version control.
3. SQL Server Developer Edition for the local database.
4. SQL Server Management Studio (SSMS) for SQL execution and validation.
5. Excel/Power Query and Power BI after the authoritative SQL outputs are validated.

## Implemented build sequence

1. environment and source generation;
2. raw ingestion;
3. typed core relational model;
4. Phase 3 performance-measure and quality-analytics layer:
   - measure configuration/reference rules;
   - FUH-style index-event detail;
   - enrollment/eligibility logic;
   - follow-up-event detail;
   - 7-day and 30-day numerator logic;
   - event-level measure results;
   - aggregate results;
   - payer/month, demographic, timing, and open-gap reporting;
   - executable QA and fixture acceptance testing;
5. Excel reconciliation;
6. Power BI reporting;
7. Quality Performance milestone documentation/publication;
8. later expanded payer-platform work where additional source domains are justified.

## Phase 3 execution order

Run the files in this order against `HealthcarePayerAnalytics`:

```text
sql/03_ref/001_create_measure_reference.sql
sql/04_measure/fuh/001_create_fuh_index_event_detail.sql
sql/04_measure/fuh/002_create_fuh_followup_event_detail.sql
sql/04_measure/fuh/003_create_fuh_measure_result.sql
sql/04_measure/fuh/004_create_fuh_measure_summary.sql
sql/04_measure/fuh/005_create_fuh_reporting_views.sql
sql/05_tests/004_validate_fuh_index.sql
sql/05_tests/005_validate_fuh_measure.sql
sql/05_tests/006_validate_fuh_reporting.sql
sql/05_tests/007_validate_phase3_closeout.sql
```

Expected controlled-fixture result:

```text
denominator = 40
7-day numerator = 18
30-day numerator = 32
7-day rate = 45.00%
30-day rate = 80.00%
```

## Important terminology

Use **FUH-style**, **HEDIS-oriented**, **HEDIS-style performance measure**, or **behavioral-health follow-up performance measure**.

Do not describe the project as an official NCQA HEDIS implementation. It does not contain the licensed specification or proprietary value sets.

## Build later, not fabricated now

The current source does not support truthful implementation of every payer-quality domain. Pharmacy integration, physical-health integration, disability/cultural-factor analysis, official regulatory submission logic, and licensed HEDIS value sets belong in future work only if suitable source data and specifications are added.


## Future roadmap

Expanded payer-platform design notes live under `docs/roadmap/v0.2-expanded-payer-platform/`.
