# Quality Performance Milestone Build Plan

## Milestone objective

Build the first complete business-facing slice of the Healthcare Payer Analytics Pipeline around payer quality performance.

The sequence is optimized to make the project analytically useful early without removing any later payer-platform scope.

The milestone ends with a reproducible SQL Server quality workflow, Excel reconciliation, Power BI reporting, and portfolio-ready documentation. Development then continues into `docs/roadmap/v0.2bigdaddy/`.

## Phase 0 — Environment

Deliverables:

- SQL Server Developer Edition installed;
- SSMS installed;
- Python environment confirmed;
- Power BI Desktop confirmed;
- Excel with Power Query confirmed;
- repository created;
- `.gitignore` prevents local database/backups/temp extracts from being committed.

Exit condition: a trivial Python script can connect to local SQL Server and create/read a test table.

## Phase 1 — Source and raw load

Deliverables:

- synthetic-data generator/source selected and documented;
- initial population approximately 5,000 members;
- Python loader;
- `raw` tables;
- load metadata;
- row-count checks;
- deterministic FUH fixture generation.

Practice focus:

- Python file handling;
- database connection;
- bulk loading;
- basic data profiling;
- reproducible source generation.

Exit condition: raw load can be rerun from scratch with consistent row counts and fixture expectations.

## Phase 2 — Core relational model

Deliverables:

- `core.member`;
- `core.payer`;
- `core.enrollment_span`;
- `core.organization`;
- `core.provider`;
- `core.encounter`;
- `core.condition`;
- `core.claim`;
- `core.claim_diagnosis`;
- `core.claim_transaction`;
- keys, constraints, focused indexes, lineage fields, and executable data-quality checks appropriate to each grain.

Implemented scope note: the source supports a transaction/event grain rather than a trustworthy claim-line grain, so Phase 2 does not fabricate `core.claim_line`. A separate provider-location table is also unnecessary for the current source because provider location is represented through `core.provider -> core.organization`. No Phase 2 date/reference table is required to close the relational layer; measure-specific reference/value-set objects belong to Phase 3 when FUH logic is implemented.

Practice focus:

- data typing and normalization;
- `INNER JOIN`;
- `LEFT JOIN`;
- null checks;
- duplicate detection;
- keys and relationships;
- gaps-and-islands enrollment logic;
- `GROUP BY`;
- `HAVING`;
- `COUNT(DISTINCT)`;
- source-to-core row-count reconciliation.

Exit condition: keys, grains, row counts, lineage, and relationships are documented and tested; source-to-core transformations can be rerun without unexplained loss or duplication. **Status: complete for the current pinned source and fixture package.**

## Phase 3 — FUH performance-measure logic

Deliverables:

- project-defined diagnosis/service reference sets;
- candidate episodes;
- eligibility;
- exclusions;
- denominator;
- candidate follow-up;
- first qualifying follow-up;
- 7-day and 30-day flags;
- candidate-discharge audit table with eligibility, exclusion, and denominator flags;
- open-gap view;
- summary output;
- controlled-fixture validation.

Practice focus:

- CTEs;
- `CASE`;
- `ROW_NUMBER`;
- `DATEADD`;
- `DATEDIFF`;
- `LEFT JOIN ... IS NULL`;
- readable multi-step business logic;
- auditability and reproducibility.

Exit condition: all boundary test cases pass and the deterministic fixture package returns the documented expected FUH-7 and FUH-30 results.

## Phase 4 — Quality analysis and reporting layer

Deliverables:

- monthly and/or quarterly FUH trend output;
- denominator/numerator volume reporting;
- open/missed follow-up gap analysis;
- age/population stratification;
- payer/coverage stratification where analytically meaningful;
- physical-health condition/comorbidity context for the FUH population;
- focused pharmacy integration by promoting the relevant Synthea medication source through `raw`/`core` and producing at least one documented pharmacy-related analysis;
- report-ready SQL views/tables with clear source lineage;
- references to source objects and assumptions sufficient to reproduce reported results.

Practice focus:

- information synthesis;
- patterns and trends;
- population analysis;
- quality-improvement-oriented gap identification;
- integrating clinical, coverage, and pharmacy context;
- user-facing report design;
- reproducible analytical outputs.

Exit condition: SQL Server can reproduce the principal quality KPIs, trends, population breakdowns, and gap outputs from documented source objects without manual spreadsheet business logic.

## Phase 5 — Excel reconciliation

Deliverables:

- Power Query connection/import;
- SQL episode output;
- filtered source-level validation extract;
- merge/reconciliation;
- exception column;
- pivot summary;
- slicers;
- conditional formatting;
- at least one deliberate discrepancy test proving the workbook surfaces an error.

Practice focus:

- Power Query clean/merge/refresh;
- XLOOKUP;
- INDEX/MATCH where useful for practice;
- SUMIFS;
- COUNTIFS;
- IFERROR;
- date functions;
- pivots;
- reconciliation and exception handling.

Exit condition: deliberate test discrepancies are visible and explainable, and a clean run reconciles to the authoritative SQL outputs.

## Phase 6 — Power BI Quality report

Deliverables:

- date dimension;
- clean relationships;
- core FUH measures;
- trend visual;
- denominator/numerator cards;
- gap table;
- population/stratification visuals;
- physical-health/pharmacy context where useful;
- useful filters/slicers;
- simple reusable theme.

Practice focus:

- star-schema thinking;
- cardinality;
- `CALCULATE`;
- `FILTER`;
- time intelligence;
- DAX measures;
- report formatting.

Power BI may aggregate and present authoritative SQL results, but it should not recreate the FUH eligibility algorithm.

Exit condition: a hiring manager can understand the business problem, measure performance, major trends, and actionable gaps in roughly two minutes.

## Phase 7 — Quality Performance milestone release

Deliverables:

- polished README;
- architecture diagram;
- screenshots;
- assumptions register;
- data dictionary;
- run instructions;
- limitations;
- test/reconciliation evidence;
- clean Git history/repository structure.

Exit condition: the Quality Performance milestone works as a stand-alone portfolio artifact and every major technical/analytical claim made about it is supported by a visible project artifact.

## Transition condition — continue into the expanded payer platform

The Quality Performance milestone is a checkpoint, **not a project stop condition**.

After the milestone is stable, continue into `docs/roadmap/v0.2bigdaddy/` in the documented order. Later phases retain IET, claims operations, finance, network analytics, scaling, governance, and automation.

Do not interrupt the Quality milestone with later-domain work unless the dependency is required for a current deliverable.
