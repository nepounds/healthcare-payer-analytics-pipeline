# v0.2 Expanded Payer Analytics Platform Assumptions Register

Carry forward every unresolved v0.1 assumption and add domain-specific assumptions.

## Quality

| ID | Issue | Implementation direction | Limitation |
|---|---|---|---|
| Q-001 | FUH specification | retain documented public-description-based approximation | not certified HEDIS |
| Q-002 | IET specification | public-description-based approximation | not certified HEDIS |
| Q-003 | Value sets | distributable project-defined references | not proprietary NCQA VSD |
| Q-004 | Analysis date | configurable fixed as-of date | synthetic operational timing |
| Q-005 | Episode overlap | explicit per-measure rule | approximation must be documented |

## Claims operations

| ID | Issue | Implementation direction | Limitation |
|---|---|---|---|
| C-001 | Clean claim definition | define project rule explicitly | organizations may define differently |
| C-002 | Denial reason categories | map source reasons into project categories | synthetic source may lack production richness |
| C-003 | Adjudication days | receipt/service-to-final decision rule must be explicit | source dates may be simulated |
| C-004 | Aging buckets | documented project bucket boundaries | may differ by organization |

## Finance

| ID | Issue | Implementation direction | Limitation |
|---|---|---|---|
| F-001 | PMPM denominator | covered member months | depends on enrollment model |
| F-002 | Service category | project mapping table | not an organizational grouper |
| F-003 | High-cost member | define threshold/ranking method | analytical definition, not universal standard |
| F-004 | Budget | synthetic plan budget | not actuarial or financial guidance |

## Network

| ID | Issue | Implementation direction | Limitation |
|---|---|---|---|
| N-001 | Provider capacity | use project proxy | synthetic data do not represent appointment availability |
| N-002 | Access gap | define county/specialty demand-supply proxy | not a regulatory network-adequacy determination |
| N-003 | Member geography | synthetic NC county assignment | not real member distribution |

## Governance

| ID | Issue | Implementation direction | Limitation |
|---|---|---|---|
| G-001 | HIPAA | HIPAA-aware controls modeled on synthetic data | no claim of compliance |
| G-002 | Role access | local SQL Server role examples | not enterprise identity management |
| G-003 | Audit | pipeline/access design examples | not a production SIEM/audit program |

## Requirement

Any metric shown in Power BI must have either:

1. a documented definition in this register/reference documentation; or
2. a direct derivation from an already documented metric.

“No one remembers how that number is calculated” is treated as a design failure.
