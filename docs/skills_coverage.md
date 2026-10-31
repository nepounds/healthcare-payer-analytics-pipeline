# Skill / Capability Coverage

This file maps portfolio claims to concrete repository evidence. A keyword is not considered covered merely because it appears in prose.

## Current implemented capability

| Capability | Concrete repository evidence | Coverage |
|---|---|---|
| Microsoft SQL Server | DDL/views/tests under `sql/`; database target `HealthcarePayerAnalytics` | Implemented |
| large datasets | typed core model includes 5.2M+ claim transactions plus hundreds of thousands of claims/encounters/conditions | Implemented |
| relational databases | PK/FK constraints and typed relationships across `core.*`; `T-CORE-001`–`T-CORE-022` | Implemented |
| healthcare payer analytics | `core.payer`, `core.enrollment_span`, payer lineage on measure and analysis outputs | Implemented |
| behavioral health | project-owned BH diagnosis rules, psychiatric fixtures, FUH-style measure pipeline | Implemented |
| performance measures | `measure.fuh_index_event_detail`, `fuh_followup_event_detail`, `fuh_measure_result`, `fuh_measure_summary` | Implemented |
| HEDIS-oriented / HEDIS-style analysis | measure configuration explicitly marks project HEDIS-oriented and not official; `docs/fuh_methodology.md` | Implemented honestly |
| quality assurance | executable structural, relationship, reconciliation, fixture, closeout, and Excel-analysis tests using `THROW` | Implemented |
| quality improvement analytics | open-gap and follow-up timing outputs identify missed/tardy follow-up patterns | Implemented |
| analytical reporting | payer/month, demographic, timing, open-gap, and Excel analytical outputs | Implemented |
| statistical analysis | counts, percentages/rates, timing distributions, average follow-up days | Implemented descriptive analytics |
| pattern identification | timing bands, gap classifications, payer/month structures, encounter mix | Implemented |
| trend analysis | month-level measure/report structures plus 2025 monthly encounter-volume Excel chart | Implemented |
| information synthesis | event-level result combines member, encounter, enrollment, diagnosis, payer, and follow-up evidence | Implemented |
| result interpretation | methodology/reporting docs state what current fixture outputs do and do not support | Implemented |
| reproducible reporting | fixed measure config, deterministic fixtures, analysis views, Power Query refresh workflow | Implemented |
| data-source references / lineage | source IDs/files/pipeline run IDs and fixture flags retained through measure layers | Implemented |
| enrollment / eligibility analysis | payer-specific 30-day continuous coverage and medical/BH benefit logic | Implemented |
| numerator / denominator methodology | explicit eligibility, deterministic first follow-up, 7/30-day flags and aggregate rates | Implemented |
| automated validation | `004_validate_fuh_index.sql` through `008_validate_phase4_excel_analysis.sql` | Implemented |

## SQL skills demonstrated naturally

| Skill | Evidence |
|---|---|
| joins | core relationships, measure lineage, and `sql/06_analysis/001_create_excel_analysis_views.sql` |
| `INNER JOIN` | FUH Excel view to validated payer reference |
| `LEFT JOIN` / missing-row logic | encounter activity preserves unattributed encounters; QA/gap logic |
| one-to-many aggregation | claims are aggregated to encounter grain before encounter summary join |
| distinct counting | grouped distinct member counts in `analysis.excel_encounter_activity` |
| `CROSS APPLY` / `OUTER APPLY` | typed diagnosis selection, enrollment selection, deterministic first follow-up |
| `CASE` | eligibility, numerator flags, timing bands, gap status, age bands |
| `DATEADD` / `DATEDIFF` | follow-up windows, age, days-to-follow-up |
| aggregation | measure summary, reporting views, and Excel-facing encounter activity |
| window functions | report denominator percentages |
| safe arithmetic | zero-denominator rate handling |
| constraints / indexes | Phase 2 core relational model |
| automated QA | `THROW`-based test suites through `T-XL-012` |

The database remains a large SQL practice sandbox for joins, CTEs, grouping, date logic, window functions, subqueries, optimization, and reconciliation exercises.

## Implemented Phase 4 — Excel skills

| Excel capability | Concrete evidence | Status |
|---|---|---|
| Excel Tables / structured references | `tblEncounter`, `tblMember`, `tblFUH`, `tblPayer` in `excel/healthcare_payer_analysis.xlsx` | Implemented |
| Power Query | four refreshable SQL-backed source tables | Implemented |
| VLOOKUP | `Formula_Practice`: payer ID -> payer name using `tblPayer` | Implemented |
| XLOOKUP | `Formula_Practice`: payer ID -> payer type using named table columns | Implemented |
| IFERROR | `Formula_Practice`: VLOOKUP wrapped with lookup-error handling | Implemented |
| SUMIFS | `Formula_Practice`: total encounters by payer and 2025 encounters by payer | Implemented |
| COUNTIFS | `Formula_Practice`: FUH 7-day, 30-day, missed-30-day, and missed-7/met-30 checks | Implemented |
| IF | `Formula_Practice` and `SQL_Reconciliation`: PASS/FAIL controls | Implemented |
| PivotTables | three manually built analytical PivotTables on `Pivot_Analysis` | Implemented |
| charts / graphs | three charts on `Charts`: monthly trend, encounter/payer mix, FUH timing | Implemented |
| reconciliation | six SQL-vs-Excel controls on `SQL_Reconciliation`, all zero difference / PASS | Implemented |
| analytical interpretation | chart/pivot choices documented in Phase 4 docs and workbook README | Implemented |
| reproducibility | `excel/README.md`, workbook README sheet, Power Query refresh path | Implemented |

Resume-safe Excel wording:

**Excel: PivotTables, VLOOKUP/XLOOKUP, SUMIFS/COUNTIFS, IF/IFERROR, charts, Power Query, data reconciliation**

## Planned Phase 5 — Power BI

Power BI remains **planned**, not implemented. No Power BI resume claim should be based on this repository until Phase 5 artifacts exist and are validated.
