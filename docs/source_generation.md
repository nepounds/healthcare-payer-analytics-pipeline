# Synthetic Source Data Generation

## Purpose

The project uses Synthea to generate the synthetic healthcare source data used by the payer analytics pipeline. The generated CSV files are treated as immutable source data and are not committed to the repository.

A separate deterministic FUH fixture package is generated later to supplement the Synthea population with inpatient mental-health episodes needed to exercise FUH measure logic.

## Synthea Version

- Synthea: **v4.0.0**
- Java: **Eclipse Temurin OpenJDK 17**
- Operating system used during development: Windows 11

Synthea was installed separately from the project repository under:

```text
C:\Tools\synthea
```

## Generation Parameters

The Phase 1 source population was generated using the following fixed parameters:

| Parameter | Value |
|---|---|
| State | North Carolina |
| Requested living population | 5,000 |
| Random seed | 424242 |
| Reference date | 2026-10-18 |
| CSV export | Enabled |
| FHIR export | Disabled |

The fixed seed and reference date are used to make source generation reproducible.

## Generation Command

From the Synthea installation directory:

```powershell
.\run_synthea.bat -c "C:/Projects/Healthcare Payer Analytics Pipeline/config/local.synthea.properties" -s 424242 -p 5000 -r 20261018 "North Carolina"
```

Forward slashes are used in the configuration-file path because Windows-style backslashes caused argument parsing errors in the Synthea Gradle/Groovy wrapper.

## Local Export Configuration

The local configuration file is:

```text
config/local.synthea.properties
```

This file is intentionally excluded from Git because it contains a machine-specific absolute path.

The development configuration enables CSV output and disables unused export formats. Generated source data is written to:

```text
data/generated/synthea/
```

Generated data is also excluded from Git.

## Resulting Population

The generation run completed successfully and produced:

- **5,631 total patient records**
- **5,000 living patients**
- **631 deceased patients**

Synthea retains patients who die during simulation, so the total number of patient records can exceed the requested living population.

The generated dataset includes source files for patients, encounters, conditions, claims, claim transactions, payer transitions, providers, organizations, payers, and additional clinical domains.

## FUH Data Sufficiency Finding

Profiling the generated population showed that Synthea produced behavioral-health diagnoses and ambulatory behavioral-health encounters, but no inpatient mental-health encounters suitable for the FUH denominator.

The project therefore uses a separate deterministic FUH fixture generator:

```text
python/generate_fuh_fixtures.py
```

The fixture generator does not modify the original Synthea CSV files. It creates supplemental records under:

```text
data/generated/fuh_fixtures/
```

The controlled fixture population contains 40 eligible psychiatric discharge episodes with expected FUH results of:

- **FUH-7:** 18 / 40 = 45.0%
- **FUH-30:** 32 / 40 = 80.0%

Fixture rows are identified in the raw layer with:

```text
synthetic_fixture_flag = 1
```

while original Synthea rows use:

```text
synthetic_fixture_flag = 0
```

This separation preserves the original source population while providing deterministic data for measure development and validation.