# v0.2bigdaddy — Expanded Payer Analytics Platform

## Entry requirement

**Do not begin this release until v0.1 is publicly shipped.**

v0.2bigdaddy is intentionally broader. It converts the narrow Quality/FUH project into a shared payer analytics platform with multiple business domains.

## Scope

One shared synthetic North Carolina Medicaid dataset supports four reporting domains:

1. **Quality**
   - FUH-style approximation;
   - IET-style approximation;
   - measure trends;
   - open quality gaps.

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

Scale only after v0.1 logic is correct. Performance tuning is part of this release.

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

The report layer uses curated star-schema marts rather than direct access to normalized core tables.

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
