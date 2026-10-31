# Excel Analytics Workbook

Phase 4 Excel artifact:

`healthcare_payer_analysis.xlsx`

## Purpose

The workbook is a compact, refreshable Excel analysis and practice sandbox backed by the SQL Server `analysis` schema. Large source/detail tables remain in SQL Server.

## Workbook sheets

- `README` — purpose and refresh notes;
- `Encounter_Data` — `analysis.excel_encounter_activity` loaded as `tblEncounter`;
- `Member_Data` — `analysis.excel_member_data` loaded as `tblMember`;
- `FUH_Data` — `analysis.excel_fuh_data` loaded as `tblFUH`;
- `Payer_Lookup` — `analysis.excel_payer_lookup` loaded as `tblPayer`;
- `Formula_Practice` — VLOOKUP, XLOOKUP, IFERROR, SUMIFS, COUNTIFS, and IF examples;
- `Pivot_Analysis` — three manually built PivotTables;
- `Charts` — three charts based on real project data;
- `SQL_Reconciliation` — SQL-vs-Excel controls.

## Refresh

1. Start local SQL Server and confirm `HealthcarePayerAnalytics` is online.
2. Open the workbook.
3. Select **Data -> Refresh All**.
4. Wait for the four Power Query loads to complete.
5. Confirm all rows on `SQL_Reconciliation` show `Difference = 0` and `Status = PASS`.

The workbook uses `localhost` for the local default SQL Server instance in the current development environment.

## Reconciliation benchmark

| Metric | Expected |
|---|---:|
| Members | 5,671 |
| Encounters | 313,094 |
| Claims | 573,681 |
| FUH denominator | 40 |
| FUH 7-day numerator | 18 |
| FUH 30-day numerator | 32 |

## Data handling

The workbook intentionally excludes unnecessary personal-looking synthetic fields such as names, SSNs, driver's-license values, street addresses, phone numbers, and email addresses.

`Encounter_Data` is aggregated. Do not sum `member_count` across encounter groups and call it total distinct membership; use `Member_Data` for one-row-per-member reconciliation.

## Closeout

The final workbook was inspected with Excel Document Inspector, document properties/personal information were removed, and the workbook was reopened and successfully refreshed afterward. Final size was approximately 1.7 MB.
