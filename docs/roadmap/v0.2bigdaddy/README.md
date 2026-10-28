# v0.2bigdaddy — Expanded Payer Analytics Platform

## Relationship to the Quality Performance milestone

v0.2bigdaddy remains the full expansion plan for the Healthcare Payer Analytics Pipeline.

The project roadmap has been **reordered, not reduced**. The current Quality Performance milestone is completed first because it creates the strongest end-to-end analyst workflow early. Once that milestone is stable, development continues here.

A public release of the Quality milestone is recommended before major expansion, but publication itself is no longer an artificial blocker if the underlying milestone is already working, tested, reconciled, and documented.

## Entry condition

Begin expanded-platform work when the Quality Performance milestone has:

- a tested core relational model;
- working FUH-style episode and rate logic;
- reproducible quality trend/population/gap outputs;
- Excel reconciliation;
- a working Power BI Quality report;
- current documentation and assumptions.

Do not use later-domain work to avoid finishing those foundations.

## Scope

One shared synthetic North Carolina Medicaid dataset supports four reporting domains:

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

Scale only after the Quality Performance milestone logic is correct. Performance tuning is part of this expanded-platform work.

## Architecture

v0.2bigdaddy expands to seven SQL schemas:

```text
raw
stg
core
ref
measure
mart
audit
```

The report layer uses curated star-schema marts rather than direct access to normalized core tables where the additional abstraction improves usability and governance.

## Additional goals

- automated end-to-end pipeline;
- rerunnable build;
- data-quality tests;
- fuller HIPAA-aware security/governance design;
- explicit lineage;
- richer documentation;
- multiple Power BI pages over consistent dimensions;
- performance testing at 50k-member scale.

## Measure disclaimer

FUH and IET remain educational/public-description-based approximations unless the project later obtains properly licensed specifications. They must not be represented as certified HEDIS calculations.

Public NCQA references:

FUH:
https://www.ncqa.org/report-cards/health-plans/state-of-health-care-quality-report/follow-up-after-hospitalization-for-mental-illness-fuh/

IET:
https://www.ncqa.org/report-cards/health-plans/state-of-health-care-quality-report/initiation-and-engagement-of-substance-use-disorder-treatment-iet/

## Definition of done

v0.2bigdaddy is complete when all four domains run over one shared model, validation is repeatable, the automated pipeline is stable, documentation is current, and the GitHub repository remains understandable without a guided tour.
