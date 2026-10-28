# Start Here

## Project name

**Healthcare Payer Analytics Pipeline**

## Recommended local path

```text
C:\Projects\Healthcare Payer Analytics Pipeline
```

If you prefer folder names without spaces:

```text
C:\Projects\HealthcarePayerAnalyticsPipeline
```

Either is fine. Use one consistently.

## Recommended GitHub repository name

```text
healthcare-payer-analytics-pipeline
```

## Open first

1. **File Explorer**
   - Put this project folder under `C:\Projects\`.

2. **VS Code**
   - Open the entire project folder.

3. **GitHub Desktop or Git CLI**
   - Initialize this exact folder as the Git repository.
   - Default branch: `main`.
   - Repository visibility: **Private initially**.

4. **SQL Server Developer Edition**
   - Install/open the local SQL Server instance.

5. **SQL Server Management Studio (SSMS)**
   - Use it for database setup, table inspection, and manual SQL practice.

Excel and Power BI can remain closed until SQL produces validated FUH and quality-analysis outputs.

## Suggested first commits

```text
chore: initialize healthcare payer analytics project
docs: add quality milestone architecture and assumptions
build: add local Python environment scaffold
```

## First technical milestone

Before Synthea, FUH, Excel, or Power BI:

1. create a local SQL Server database named `HealthcarePayerAnalytics`;
2. create schemas `raw`, `core`, `ref`, and `measure`;
3. create a Python virtual environment;
4. connect Python to SQL Server;
5. insert one test row;
6. read that row back successfully.

Once that works, begin synthetic-data ingestion.

## Development sequence

The project is built in this order:

1. environment and source generation;
2. raw ingestion;
3. typed core relational model;
4. FUH-style performance-measure logic;
5. quality analysis, including trends, gaps, population segmentation, physical-health context, and a focused pharmacy integration;
6. Excel reconciliation;
7. Power BI reporting;
8. Quality Performance milestone documentation/publication;
9. expanded payer-platform work in `docs/roadmap/v0.2bigdaddy/`.

## Build later, not never

The following remain part of the full project but should not interrupt the current Quality Performance milestone:

- IET;
- claims operations;
- finance;
- network analytics;
- 50,000-member scaling;
- `stg`, `mart`, and `audit` expansion;
- production-style orchestration;
- expanded governance controls;
- cloud/dbt work only if later evidence shows they add portfolio value.

These items are **sequenced after the Quality milestone; they are not canceled**.
