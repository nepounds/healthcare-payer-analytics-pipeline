# v0.1 Security and Data Handling

## Scope

v0.1 uses synthetic data only. It is not intended to contain PHI or ePHI and does not claim HIPAA compliance.

The purpose of this document is to demonstrate basic healthcare-data awareness without turning the first release into a governance project.

## Repository rules

- Never commit real patient/member data.
- Never commit credentials.
- Keep connection strings/secrets in local configuration or environment variables.
- Ignore local SQL database files, backups, temporary extracts, and generated files that do not need version control.
- Label all sample datasets as synthetic.
- Avoid realistic combinations of personal identifiers that could be mistaken for real individuals.

## Design choices inspired by healthcare security practice

Even with synthetic data, v0.1 should demonstrate:

- separation between source/raw data and analytical outputs;
- limited export of fields needed for the report;
- stable internal identifiers rather than unnecessary personal identifiers;
- documented data lineage;
- repeatable validation;
- explicit assumptions;
- basic access separation if practical in local SQL Server.

These are design exercises, not evidence that the repository satisfies HIPAA.

## HIPAA framing

HHS describes the HIPAA Security Rule as requiring regulated entities to protect the confidentiality, integrity, and availability of ePHI using administrative, physical, and technical safeguards. Those obligations apply in real regulated environments.

Official overview:
https://www.hhs.gov/hipaa/for-professionals/security/laws-regulations/index.html

Because this repository intentionally contains synthetic data only, the portfolio should say that it is **HIPAA-aware in design** rather than “HIPAA compliant.”

## Deferred to v0.2 Expanded Payer Analytics Platform

- fuller role-based access-control example;
- security control matrix;
- explicit risk assessment;
- audit logging design;
- data-retention/disposal discussion;
- backup/recovery assumptions;
- more formal data classification.
