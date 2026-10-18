# v0.2bigdaddy Pipeline and Orchestration

## Goal

Support both a learning/manual mode and a repeatable automated mode.

The same underlying scripts should power both.

## Manual mode

Suggested order:

```text
01_create_database.sql
02_create_schemas.sql
03_create_raw_tables.sql
04_load_raw.py
05_stage.sql
06_build_core.sql
07_build_reference.sql
08_build_quality.sql
09_build_claims_ops.sql
10_build_finance.sql
11_build_network.sql
12_build_marts.sql
13_run_tests.sql
14_export_validation.py
```

This mode is used for learning and debugging.

## Automated mode

A single entry point should eventually run the sequence.

Example:

```text
python run_pipeline.py --config config/dev.yaml
```

or a PowerShell wrapper that invokes the same stages.

## Pipeline requirements

Each run should have a `run_id`.

Capture:

- stage;
- start timestamp;
- end timestamp;
- status;
- input row count;
- output row count;
- error message if any;
- configuration/as-of date.

## Failure behavior

The pipeline should stop on material integrity failures.

Examples:

- missing required source;
- duplicate business key where uniqueness is required;
- orphaned foreign keys above accepted threshold;
- measure test failure;
- failed mart build.

A failed test should not quietly produce a refreshed dashboard.

## Idempotence

Where practical, rerunning the pipeline from the same source and configuration should produce the same analytical result.

Use explicit load strategies:

- truncate/reload for simple synthetic source tables;
- deterministic transforms;
- controlled overwrite of derived outputs.

## Scheduling

Do not add Airflow, Prefect, Dagster, or another orchestration framework unless the project develops a real need.

A local scheduled PowerShell/Python entry point is enough for this portfolio.

Complex tooling is not a substitute for clear pipeline behavior.
