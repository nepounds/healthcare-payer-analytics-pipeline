# Skill / Capability Coverage

This file maps portfolio claims to concrete repository evidence. A keyword is not considered covered merely because it appears in prose.

## Current implemented capability

| Capability | Concrete repository evidence | Coverage |
|---|---|---|
| Microsoft SQL Server | all DDL/views/tests under `sql/`; database target `HealthcarePayerAnalytics` | Implemented |
| large datasets | typed core model includes 5.2M+ claim transactions plus hundreds of thousands of claims/encounters/conditions | Implemented |
| relational databases | PK/FK constraints and typed relationships across `core.*`; `T-CORE-001`–`T-CORE-022` | Implemented |
| healthcare payer analytics | `core.payer`, `core.enrollment_span`, payer lineage on measure results, payer/month reporting | Implemented |
| behavioral health | project-owned BH diagnosis rules, psychiatric fixtures, FUH-style measure pipeline | Implemented |
| performance measures | `measure.fuh_index_event_detail`, `fuh_followup_event_detail`, `fuh_measure_result`, `fuh_measure_summary` | Implemented |
| HEDIS-oriented / HEDIS-style analysis | measure configuration explicitly marks the project HEDIS-oriented and not official; `docs/fuh_methodology.md` | Implemented honestly |
| quality assurance | executable structural, relationship, reconciliation, fixture, and closeout tests using `THROW` | Implemented |
| quality improvement analytics | open-gap and follow-up timing outputs identify missed/tardy follow-up patterns | Implemented |
| analytical reporting | payer/month, demographic, timing, and open-gap outputs | Implemented |
| statistical analysis | counts, percentages/rates, timing distributions, average follow-up days | Implemented descriptive analytics |
| pattern identification | timing bands and open-gap classifications; payer/month and demographic structures | Implemented |
| trend analysis | month-level performance/volume reporting structure | Implemented; fixture interpretation limited |
| information synthesis | event-level result combines member, encounter, enrollment, diagnosis, payer, and follow-up evidence | Implemented |
| result interpretation | methodology/reporting docs state what current fixture outputs do and do not support | Implemented |
| reproducible reporting | fixed measure config, SQL execution order, deterministic fixtures, report-ready views | Implemented |
| data-source references / lineage | source IDs/files/pipeline run IDs and fixture flags retained through measure layers | Implemented |
| enrollment / eligibility analysis | payer-specific 30-day continuous coverage and medical/BH benefit logic | Implemented |
| numerator / denominator methodology | explicit eligibility, deterministic first follow-up, 7/30-day flags and aggregate rates | Implemented |
| automated validation | `004_validate_fuh_index.sql` through `007_validate_phase3_closeout.sql` | Implemented |

## SQL skills demonstrated naturally

| Skill | Evidence |
|---|---|
| joins | core relationships and measure lineage |
| `LEFT JOIN` / missing-row logic | summary scopes, QA reconciliation, gap testing |
| `CROSS APPLY` / `OUTER APPLY` | typed diagnosis selection, enrollment selection, deterministic first follow-up |
| `CASE` | eligibility, numerator flags, timing bands, gap status |
| `DATEADD` / `DATEDIFF` | follow-up windows, age, days-to-follow-up |
| aggregation | measure summary and analytical reports |
| window functions | report denominator percentages |
| safe arithmetic | zero-denominator rate handling |
| constraints / indexes | Phase 2 core relational model |
| automated QA | `THROW`-based test suites |

The existing database is also intentionally retained as a large SQL practice sandbox. Phase 4 will add additional analysis/export queries specifically so the project can be reused for join, grouping, date, reconciliation, and reporting practice rather than treated as a finished static artifact.

## Planned Phase 4 — Excel skills

The following should remain **planned**, not claimed as implemented, until the Phase 4 workbook exists and is validated.

| Excel capability | Planned Phase 4 evidence | Current status |
|---|---|---|
| VLOOKUP | lookup/reference exercise using project data | Planned |
| XLOOKUP | modern lookup exercise using the same project data | Planned |
| SUMIFS / COUNTIFS | formula-based summaries and checks | Planned |
| PivotTables | at least three useful analytical pivots | Planned |
| charts / graphs | at least three charts based on project analysis | Planned |
| Excel Tables / structured references | workbook data and formula tabs | Planned |
| reconciliation | SQL-vs-Excel control sheet with zero-difference checks | Planned |
| Power Query | optional/expected refresh/import path where practical | Planned |

After Phase 4 passes, these claims may be changed from planned to implemented with direct workbook evidence.

## Planned Phase 5 — Power BI

| Capability | Planned evidence | Current status |
|---|---|---|
| Power BI Desktop | quality-performance report consuming SQL outputs | Planned |
| data modeling | report relationships/date structure as needed | Planned |
| DAX | presentation-oriented measures only where useful | Planned |
| interactive reporting | filters, trends, timing/gap views, KPI cards | Planned |

## Not claimed by the current implementation

These areas are intentionally **not** represented as completed capability:

- official/certified NCQA HEDIS implementation;
- proprietary value sets;
- regulatory submission capability;
- trustworthy principal-diagnosis/readmission rules not supported by the source;
- pharmacy integration;
- physical-health integration;
- disability analysis;
- cultural-factor analysis;
- production PHI handling.

They belong in future work only if suitable data/specifications are added.

## Principle

Do not force a skill or keyword into the project if doing so makes the design worse. Portfolio-ready claims require implementation, validation evidence, and documentation sufficient to explain the work in an interview.
