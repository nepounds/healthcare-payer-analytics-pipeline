# v0.2bigdaddy Build Plan

## Gate 0 — v0.1 exists

Required before any Big Daddy work:

- v0.1 public repo;
- FUH pipeline works;
- Excel reconciliation works;
- Power BI page works;
- README is complete.

If not, return to v0.1.

## Phase 1 — Harden and scale

- introduce `stg`, `mart`, and `audit`;
- run 5k → 10k → 25k → 50k member scaling tests;
- capture row counts and runtime;
- add indexes only where evidence supports them;
- document performance changes.

## Phase 2 — IET

- define public-description-based assumptions;
- build IET episode logic;
- add test cases;
- extend Excel validation;
- add Quality report content.

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

If a feature does not strengthen one of these themes, defer it:

1. payer-domain understanding;
2. SQL/Excel/Power BI fluency;
3. auditability;
4. data modeling;
5. practical analyst workflow.

Do not add technology only to increase the tool count.
