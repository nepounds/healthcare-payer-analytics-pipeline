# v0.2 Expanded Payer Analytics Platform HIPAA-Aware Governance Design

## Positioning

This repository contains synthetic data and does not claim to be a HIPAA-compliant production system.

The purpose of this layer is to demonstrate that the project author understands how a real healthcare organization would think about confidentiality, integrity, availability, access, auditing, and risk.

HHS states that the HIPAA Security Rule applies to ePHI maintained or transmitted by regulated entities and requires administrative, physical, and technical safeguards.

Official overview:
https://www.hhs.gov/hipaa/for-professionals/security/laws-regulations/index.html

## Data classification

Suggested project classifications:

| Class | Example in project | Handling |
|---|---|---|
| Public | README, diagrams, aggregate screenshots | GitHub allowed |
| Synthetic restricted-like | row-level synthetic member/claim data | local only by default |
| Configuration | connection settings | no secrets in Git |
| Secrets | passwords/tokens | environment/secret store only |

Even though row-level project data are synthetic, treating them as restricted-like data is useful practice.

## Access model

Example SQL roles:

```text
role_data_engineer
role_quality_analyst
role_finance_analyst
role_network_analyst
role_report_reader
```

Demonstrate least-privilege concepts:

- raw/staging access limited;
- analysts consume only domains they need;
- report readers consume marts/views;
- write permission separated from read permission.

This is a demonstration model, not an enterprise IAM implementation.

## Audit controls

`audit` schema can capture:

- pipeline run ID;
- start/end time;
- source file/version;
- loaded row counts;
- rejected row counts;
- validation status;
- test results;
- mart refresh status.

Optional local SQL auditing examples may be added, but the project does not need to become a security engineering portfolio.

## Integrity

Demonstrate:

- primary/foreign keys where practical;
- uniqueness checks;
- reconciliation totals;
- source-to-core counts;
- null-rate checks;
- referential checks;
- metric test cases;
- exception logging.

## Availability and recovery

Document rather than overbuild:

- local database backup approach;
- script-based rebuild capability;
- source reproducibility;
- environment prerequisites;
- expected recovery path.

For a portfolio repository, “can rebuild from source + scripts” is an important resilience property.

## Risk register

| Risk | Example | Mitigation |
|---|---|---|
| accidental real data inclusion | user drops a real extract into project directory | synthetic-only rule, ignored data directories, README warning |
| secret leakage | password committed to Git | environment variables and `.gitignore` |
| excessive access | all users query raw data | role examples, mart/report views |
| metric integrity failure | logic changes without validation | SQL tests + Excel reconciliation + assumptions register |
| stale report | BI refresh not aligned with pipeline | run IDs / refresh timestamp |
| misleading compliance claim | README says “HIPAA compliant” | explicit synthetic/HIPAA-aware disclaimer |
| proprietary measure misuse | licensed value sets copied into repo | public-description-based approximation only |

## Minimum-necessary mindset

For each output, ask:

> What is the minimum set of fields required to answer this business question?

Power BI marts should not expose every field from raw claims merely because it is available.
