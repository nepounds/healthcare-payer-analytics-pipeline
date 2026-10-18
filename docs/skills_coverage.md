# v0.1 Skill Coverage

## Excel

| Skill | Natural use in v0.1? | Where |
|---|---:|---|
| Power Query import | Yes | SQL/source validation imports |
| Power Query clean | Yes | normalize validation extract |
| Power Query merge | Yes | compare SQL result with source-derived check |
| Power Query refresh | Yes | repeat reconciliation |
| Unpivot | Maybe | use only if source shape genuinely requires it |
| Pivot tables | Yes | reconciliation summary |
| Calculated fields | Maybe | use only where meaningful |
| Slicers | Yes | validation pivots |
| XLOOKUP | Yes | targeted cross-checks |
| INDEX/MATCH | Yes | deliberate practice alternative |
| VLOOKUP | Optional | legacy-skill demonstration only |
| SUMIFS | Yes | summary checks |
| COUNTIFS | Yes | episode counts/exception counts |
| AVERAGEIFS | Maybe | days-to-follow-up checks |
| IFERROR | Yes | reconciliation |
| Nested IF | Yes, lightly | exception categorization |
| Data validation | Yes | parameter/selection cells |
| EOMONTH | Maybe | reporting-period checks |
| DATEDIF | Maybe | age/duration practice |
| NETWORKDAYS | Not natural | do not force it into FUH |
| Conditional formatting | Yes | exception flagging |

## SQL

| Skill | Natural use in v0.1? | Where |
|---|---:|---|
| INNER JOIN | Yes | core relationships |
| LEFT JOIN | Yes | follow-up search / missing records |
| LEFT JOIN + null check | Yes | gaps / missing follow-up |
| GROUP BY | Yes | summaries |
| HAVING | Yes | duplicate/multi-event checks |
| COUNT(DISTINCT) | Yes | member and episode QA |
| CASE WHEN | Yes | buckets/flags |
| CTEs | Yes | FUH stages |
| ROW_NUMBER | Yes | first follow-up |
| LAG | Maybe | episode/readmission exploration |
| GETDATE | Limited | prefer configurable as-of date for reproducibility |
| DATEADD | Yes | follow-up deadlines |
| DATEDIFF | Yes | days to follow-up |

## Power BI

| Skill | Natural use in v0.1? | Where |
|---|---:|---|
| star schema | Yes | Quality model |
| relationship cardinality | Yes | dimensions/fact |
| date dimension | Yes | trend |
| CALCULATE | Yes | measure rates |
| FILTER | Yes | filtered rates/gaps |
| time intelligence | Yes | trend/YTD where meaningful |
| JSON theme | Yes | consistent report formatting |

## Principle

Do not force a skill into the project if doing so makes the design worse. The portfolio should show judgment as well as tool exposure.
