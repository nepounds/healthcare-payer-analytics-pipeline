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

Excel and Power BI can remain closed until SQL produces a valid FUH episode result.

## Suggested first commits

```text
chore: initialize healthcare payer analytics project
docs: add v0.1 architecture and assumptions
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

## Do not build yet

- IET
- claims operations
- finance
- network analytics
- 50,000-member data
- dbt
- cloud services
- production orchestration
- elaborate HIPAA control matrices

Those belong after v0.1 is working and public.
