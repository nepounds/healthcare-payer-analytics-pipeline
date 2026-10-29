# Project Manifest

Core project/documentation:

- `.env.example`
- `.gitignore`
- `README.md`
- `START_HERE.md`
- `MANIFEST.md`
- `requirements.txt`
- `setup_local.ps1`
- `config/README.md`
- `docs/architecture.md`
- `docs/assumptions_register.md`
- `docs/build_plan.md`
- `docs/data_dictionary.md`
- `docs/fuh_methodology.md`
- `docs/security_data_handling.md`
- `docs/skills_coverage.md`
- `excel/README.md`
- `powerbi/README.md`
- `python/README.md`
- `python/generate_fuh_fixtures.py`
- `python/load_raw.py`
- `python/test_connection.py`
- `screenshots/README.md`

SQL:

- `sql/00_setup/001_create_database_and_schemas.sql`
- `sql/00_setup/README.md`
- `sql/01_raw/001_create_raw_tables.sql`
- `sql/01_raw/README.md`
- `sql/02_core/001_create_core_member.sql`
- `sql/02_core/002_create_core_payer.sql`
- `sql/02_core/003_create_core_enrollment_span.sql`
- `sql/02_core/004_load_core_foundation.sql`
- `sql/02_core/005_create_core_organization.sql`
- `sql/02_core/006_create_core_provider.sql`
- `sql/02_core/007_load_core_remaining.sql`
- `sql/02_core/008_create_core_encounter.sql`
- `sql/02_core/009_create_core_condition.sql`
- `sql/02_core/010_create_core_claim.sql`
- `sql/02_core/011_create_core_claim_diagnosis.sql`
- `sql/02_core/012_create_core_claim_transaction.sql`
- `sql/02_core/013_load_core_claims.sql`
- `sql/02_core/README.md`
- `sql/03_ref/001_create_measure_reference.sql`
- `sql/03_ref/README.md`
- `sql/04_measure/README.md`
- `sql/04_measure/fuh/001_create_fuh_index_event_detail.sql`
- `sql/04_measure/fuh/002_create_fuh_followup_event_detail.sql`
- `sql/04_measure/fuh/003_create_fuh_measure_result.sql`
- `sql/04_measure/fuh/004_create_fuh_measure_summary.sql`
- `sql/04_measure/fuh/005_create_fuh_reporting_views.sql`
- `sql/04_measure/fuh/README.md`
- `sql/05_tests/000_validate_core_foundation.sql`
- `sql/05_tests/001_validate_core_network.sql`
- `sql/05_tests/002_validate_core_clinical.sql`
- `sql/05_tests/003_validate_core_claims.sql`
- `sql/05_tests/004_validate_fuh_index.sql`
- `sql/05_tests/005_validate_fuh_measure.sql`
- `sql/05_tests/006_validate_fuh_reporting.sql`
- `sql/05_tests/007_validate_phase3_closeout.sql`
- `sql/05_tests/README.md`
- `sql/05_tests/TEST_CASES.md`

Generated source/output folders remain excluded or represented by `.gitkeep` according to `.gitignore`.
