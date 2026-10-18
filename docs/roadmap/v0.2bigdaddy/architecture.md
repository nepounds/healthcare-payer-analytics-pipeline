# v0.2bigdaddy Architecture

## Goal

Expand the shipped v0.1 FUH project into a multi-domain payer analytics platform without losing auditability.

## Schemas

```text
raw     -- source-shaped ingestion
stg     -- standardized and cleaned source records
core    -- reusable normalized payer entities
ref     -- shared reference data and project-defined value sets
measure -- quality-measure episode logic/results
mart    -- report-ready dimensional models
audit   -- pipeline, row-count, exception, and data-quality evidence
```

## Data flow

```text
Synthetic generator / source
            |
            v
        Python ingest
            |
            v
           raw
            |
            v
           stg
            |
            v
        core + ref
         /   |   \
        /    |    \
 quality   claims  finance/network logic
    |        |          |
    v        v          v
 measure  --------->   mart
        \              /
         \            /
          +--- audit --+
                 |
        +--------+---------+
        |                  |
        v                  v
      Excel              Power BI
   reconciliation     multi-page report
```

## Separation of concerns

### Python

Use for:

- synthetic generation;
- file discovery;
- ingestion;
- pipeline orchestration;
- configuration;
- logging;
- export utilities.

Do not move business metrics into Python merely because Python can calculate them.

### SQL Server

Use for:

- typing/standardization;
- core modeling;
- quality logic;
- claims metrics;
- finance calculations;
- network metrics;
- report marts;
- data-quality tests;
- lineage/audit evidence.

### Excel

Use for targeted independent reconciliation.

Each domain should have a small number of deliberately chosen controls rather than a duplicate warehouse built in spreadsheets.

### Power BI

Use for semantic/report modeling, DAX presentation measures, filtering, time intelligence, and visualization.

## Why the extra schemas now make sense

v0.1 can survive without dedicated `stg`, `mart`, and `audit` schemas.

v0.2bigdaddy cannot cleanly support four domains without them.

- `stg` keeps source cleanup out of business entities.
- `mart` prevents each report from inventing its own dataset.
- `audit` centralizes pipeline evidence and data-quality results.

The added structure is justified by actual complexity, not architecture theater.
