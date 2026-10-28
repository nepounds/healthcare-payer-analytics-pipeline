# Quality Performance Milestone Skill Coverage

## Excel

| Skill | Natural use? | Where |
|---|---:|---|
| Power Query import | Yes | SQL/source validation imports |
| Power Query clean | Yes | normalize validation extract |
| Power Query merge | Yes | compare SQL result with source-derived check |
| Power Query refresh | Yes | repeat reconciliation |
| Unpivot | Maybe | use only if source shape genuinely requires it |
| Pivot tables | Yes | reconciliation and quality summaries |
| Calculated fields | Maybe | use only where meaningful |
| Slicers | Yes | validation pivots |
| XLOOKUP | Yes | targeted cross-checks |
| INDEX/MATCH | Yes | deliberate practice alternative |
| VLOOKUP | Optional | legacy-skill demonstration only |
| SUMIFS | Yes | summary checks |
| COUNTIFS | Yes | episode counts/exception counts |
| AVERAGEIFS | Yes | days-to-follow-up checks where useful |
| IFERROR | Yes | reconciliation |
| Nested IF | Yes, lightly | exception categorization |
| Data validation | Yes | parameter/selection cells |
| EOMONTH | Maybe | reporting-period checks |
| DATEDIF | Maybe | age/duration practice |
| NETWORKDAYS | Not natural | do not force it into FUH |
| Conditional formatting | Yes | exception flagging |

## SQL

| Skill | Natural use? | Where |
|---|---:|---|
| data typing/conversion | Yes | raw-to-core standardization |
| INNER JOIN | Yes | core relationships |
| LEFT JOIN | Yes | follow-up search / missing records |
| LEFT JOIN + null check | Yes | gaps / missing follow-up |
| GROUP BY | Yes | summaries and trends |
| HAVING | Yes | duplicate/multi-event checks |
| COUNT(DISTINCT) | Yes | member and episode QA |
| CASE WHEN | Yes | buckets/flags |
| CTEs | Yes | core transformations and FUH stages |
| ROW_NUMBER | Yes | first follow-up / deterministic selection |
| LAG | Yes where useful | enrollment gaps / episode exploration |
| gaps-and-islands | Yes | enrollment normalization |
| GETDATE | Limited | prefer configurable as-of date for reproducibility |
| DATEADD | Yes | follow-up deadlines |
| DATEDIFF | Yes | days to follow-up |
| window aggregates | Yes where useful | trend/population analysis |
| referential-integrity QA | Yes | source/core relationship testing |

## Power BI

| Skill | Natural use? | Where |
|---|---:|---|
| star schema | Yes | Quality model |
| relationship cardinality | Yes | dimensions/facts |
| date dimension | Yes | trend reporting |
| CALCULATE | Yes | measure rates |
| FILTER | Yes | filtered rates/gaps |
| time intelligence | Yes | monthly/quarterly trend |
| drill/filter interactions | Yes | population and gap analysis |
| JSON theme | Yes | consistent report formatting |

## Healthcare / quality analytics evidence

| Capability | Project evidence |
|---|---|
| large relational healthcare data | SQL Server raw/core model over Synthea claims, encounters, conditions, enrollment, and related entities |
| performance-measure analysis | FUH-style denominator/numerator logic and audit-grain episode output |
| patterns and trends | monthly/quarterly quality reporting |
| quality improvement support | open/missed follow-up gap analysis |
| population analysis | age and other appropriate stratifications |
| physical-health integration | condition/comorbidity context linked to the FUH population |
| pharmacy integration | focused medication source/model and documented pharmacy-related quality analysis |
| reproducible reporting | source lineage, assumptions, SQL outputs, Excel reconciliation, and refreshable Power BI |

## Principle

Do not force a skill or keyword into the project if doing so makes the design worse.

A capability is considered portfolio-ready only when the repository contains an implementation, validation evidence, and documentation sufficient to explain it in an interview.
