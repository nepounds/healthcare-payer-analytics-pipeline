# v0.2 — Expanded Payer Analytics Platform

## Relationship to the current project roadmap

v0.2 Expanded Payer Analytics Platform is the longer-term expansion plan for the Healthcare Payer Analytics Pipeline. It is **not** the immediate next phase.

The current sequence is:

1. Phase 0 — setup — complete;
2. Phase 1 — raw ingestion — complete;
3. Phase 2 — core relational model — complete;
4. Phase 3 — FUH-style quality measure and reporting — complete;
5. Phase 4 — Excel analytics, reconciliation, and SQL practice sandbox;
6. Phase 5 — Power BI reporting;
7. portfolio release polish;
8. expanded payer-platform work in this folder.

The roadmap has been reordered so the project first finishes a complete analyst workflow using SQL, Excel, and Power BI before expanding into additional payer domains.

## Entry condition

Begin expanded-platform work when the current portfolio workflow has:

- a tested core relational model;
- working FUH-style event and rate logic;
- reproducible quality trend/population/gap outputs;
- a validated Excel analytics/reconciliation workbook;
- a working Power BI Quality report;
- current documentation and assumptions.

Do not use later-domain work to avoid finishing those foundations.

## Scope

One shared synthetic North Carolina Medicaid dataset could eventually support four reporting domains:

1. **Quality**
   - FUH-style approximation;
   - IET-style approximation;
   - measure trends;
   - open quality gaps;
   - supporting population/clinical context.

2. **Claims Operations**
   - denial rate;
   - denial reasons;
   - clean-claim rate;
   - days to adjudication;
   - aging buckets.

3. **Finance**
   - PMPM cost;
   - utilization per thousand;
   - service-category mix;
   - high-cost-member concentration;
   - budget-to-actual variance.

4. **Network**
   - providers by county;
   - members per provider;
   - geographic/access indicators;
   - provider coverage gaps.

## Scale

Target approximately **50,000 synthetic members** across two to three years.

Scale only after the current SQL/Excel/Power BI workflow is correct and documented. Performance tuning belongs in this expanded-platform work rather than being forced into the current milestone.

## Architecture

v0.2 may expand to seven SQL schemas:

```text
raw
stg
core
ref
measure
mart
audit
```

The report layer may use curated star-schema marts where the additional abstraction improves usability and governance.

## Additional goals

- automated end-to-end pipeline;
- rerunnable build;
- broader data-quality tests;
- fuller HIPAA-aware security/governance design;
- explicit lineage;
- richer documentation;
- multiple Power BI pages over consistent dimensions;
- performance testing at larger scale.

## Measure disclaimer

FUH and IET remain educational/public-description-based approximations unless the project later obtains properly licensed specifications. They must not be represented as certified HEDIS calculations.

## Definition of done

v0.2 Expanded Payer Analytics Platform is complete when the selected payer domains run over one shared model, validation is repeatable, the automated pipeline is stable, documentation is current, and the GitHub repository remains understandable without a guided tour.
