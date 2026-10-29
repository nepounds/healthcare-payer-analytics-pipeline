# v0.2 Expanded Payer Analytics Platform Build Plan

## Gate 0 — Quality Performance milestone is stable

Required before major expanded-platform work:

- core relational model is tested;
- FUH-style pipeline works;
- quality trend/population/gap analysis works;
- focused physical-health/pharmacy integration is documented;
- Excel reconciliation works;
- Power BI Quality report works;
- assumptions, lineage, and run documentation are current.

A public GitHub release is recommended at this point, but the engineering gate is **working and validated**, not publication for its own sake.

The purpose of the gate is sequencing: finish the first end-to-end analyst workflow before adding new business domains.

## Phase 1 — Harden and scale

- introduce `stg`, `mart`, and `audit` where justified;
- run 5k → 10k → 25k → 50k member scaling tests;
- capture row counts and runtime;
- add indexes only where evidence supports them;
- document performance changes.

## Phase 2 — IET

- define public-description-based assumptions;
- build IET episode logic;
- add test cases;
- extend Excel validation;
- extend Quality report content.

## Phase 3 — Claims Operations

Metrics:

- denial rate;
- denial rate by reason;
- clean-claim rate;
- adjudication days;
- aging buckets.

Required outputs:

- claim-level auditability;
- documented metric definitions;
- operations page in Power BI;
- Excel spot checks.

## Phase 4 — Finance

Build member-month model first.

Metrics:

- PMPM;
- utilization per thousand;
- service-category cost;
- high-cost-member concentration;
- budget vs actual.

Required outputs:

- explicit denominator logic;
- synthetic budget assumptions;
- finance page;
- reconciliation checks.

## Phase 5 — Network

Metrics:

- providers by county/specialty;
- members per provider;
- demand/supply proxy;
- access-gap indicators.

Do not label a proxy as formal network-adequacy compliance.

## Phase 6 — Governance

Add:

- role examples;
- audit tables;
- risk register;
- lineage diagram;
- backup/rebuild note;
- expanded security documentation.

## Phase 7 — Automation

Create one-command pipeline execution.

Add:

- configuration;
- run IDs;
- structured logging;
- stop-on-test-failure;
- refresh/export handoff.

## Phase 8 — Portfolio polish

- repository index;
- architecture diagrams;
- screenshots;
- concise two-minute README path;
- deeper technical docs linked below;
- interview talking points;
- known limitations.

## Scope rule

If a feature does not strengthen one of these themes, defer it until the current milestone/domain is complete:

1. payer-domain understanding;
2. SQL/Excel/Power BI fluency;
3. auditability;
4. data modeling;
5. practical analyst workflow.

Do not add technology only to increase the tool count.
