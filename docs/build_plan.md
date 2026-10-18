# v0.1 Build Plan

## Release objective

Ship one complete FUH-focused payer-quality project before expanding scope.

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
- row-count checks.

Practice focus:

- Python file handling;
- database connection;
- bulk loading;
- basic data profiling.

Exit condition: raw load can be rerun from scratch with consistent row counts.

## Phase 2 — Core relational model

Deliverables:

- member;
- enrollment span;
- encounter;
- claim;
- claim line;
- claim diagnosis;
- provider;
- provider location;
- date/reference tables.

Practice focus:

- `INNER JOIN`;
- `LEFT JOIN`;
- null checks;
- duplicate detection;
- keys and relationships;
- `GROUP BY`;
- `HAVING`;
- `COUNT(DISTINCT)`.

Exit condition: keys, grains, row counts, and relationships are documented and tested.

## Phase 3 — FUH logic

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
- gap view.

Practice focus:

- CTEs;
- `CASE`;
- `ROW_NUMBER`;
- `DATEADD`;
- `DATEDIFF`;
- `LEFT JOIN ... IS NULL`;
- readable multi-step logic.

Exit condition: all boundary test cases pass.

## Phase 4 — Excel reconciliation

Deliverables:

- Power Query connection/import;
- SQL episode output;
- filtered source-level validation extract;
- merge/reconciliation;
- exception column;
- pivot summary;
- slicers;
- conditional formatting.

Practice focus:

- Power Query clean/merge/refresh;
- XLOOKUP;
- INDEX/MATCH;
- SUMIFS;
- COUNTIFS;
- IFERROR;
- date functions;
- pivots.

Exit condition: deliberate test discrepancies are visible and explainable.

## Phase 5 — Power BI

Deliverables:

- date dimension;
- clean relationships;
- core FUH measures;
- trend visual;
- denominator/numerator cards;
- gap table;
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

Exit condition: a hiring manager can understand the business problem and result in roughly two minutes.

## Phase 6 — Publish

Deliverables:

- polished README;
- architecture diagram;
- screenshots;
- assumptions register;
- data dictionary;
- run instructions;
- limitations;
- clean Git history/repository structure.

Exit condition: public GitHub repository works as a portfolio artifact.

## Stop condition

After publication, stop development briefly and evaluate whether v0.2bigdaddy adds enough career value to justify its scope.

Do not expand simply because additional features are available.
