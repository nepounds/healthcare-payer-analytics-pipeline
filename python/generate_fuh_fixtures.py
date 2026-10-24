from __future__ import annotations

from pathlib import Path
from uuid import UUID, uuid5

import pandas as pd


NAMESPACE = UUID("3b5ce8f7-7ca3-4ee3-96a1-f5a5a1b87d35")
MEASUREMENT_YEAR = 2025
FIXTURE_COUNT = 40
FIXTURE_FLAG = 1

# Project-defined v0.1 fixture codes. These are test-data choices, not an
# official NCQA/HEDIS value set.
MH_DIAGNOSIS_CODE = "F32.2"
MH_DIAGNOSIS_DESCRIPTION = (
    "Major depressive disorder, single episode, severe without psychotic features"
)
FOLLOWUP_PROCEDURE_CODE = "99214"
INPATIENT_PROCEDURE_CODE = "99223"

PATIENT_COLUMNS = [
    "Id", "BIRTHDATE", "DEATHDATE", "SSN", "DRIVERS", "PASSPORT", "PREFIX",
    "FIRST", "MIDDLE", "LAST", "SUFFIX", "MAIDEN", "MARITAL", "RACE",
    "ETHNICITY", "GENDER", "BIRTHPLACE", "ADDRESS", "CITY", "STATE", "COUNTY",
    "FIPS", "ZIP", "LAT", "LON", "HEALTHCARE_EXPENSES", "HEALTHCARE_COVERAGE",
    "INCOME",
]

ENCOUNTER_COLUMNS = [
    "Id", "START", "STOP", "PATIENT", "ORGANIZATION", "PROVIDER", "PAYER",
    "ENCOUNTERCLASS", "CODE", "DESCRIPTION", "BASE_ENCOUNTER_COST",
    "TOTAL_CLAIM_COST", "PAYER_COVERAGE", "REASONCODE", "REASONDESCRIPTION",
]

CONDITION_COLUMNS = [
    "START", "STOP", "PATIENT", "ENCOUNTER", "SYSTEM", "CODE", "DESCRIPTION",
]

CLAIM_COLUMNS = [
    "Id", "PATIENTID", "PROVIDERID", "PRIMARYPATIENTINSURANCEID",
    "SECONDARYPATIENTINSURANCEID", "DEPARTMENTID", "PATIENTDEPARTMENTID",
    "DIAGNOSIS1", "DIAGNOSIS2", "DIAGNOSIS3", "DIAGNOSIS4", "DIAGNOSIS5",
    "DIAGNOSIS6", "DIAGNOSIS7", "DIAGNOSIS8", "REFERRINGPROVIDERID",
    "APPOINTMENTID", "CURRENTILLNESSDATE", "SERVICEDATE", "SUPERVISINGPROVIDERID",
    "STATUS1", "STATUS2", "STATUSP", "OUTSTANDING1", "OUTSTANDING2",
    "OUTSTANDINGP", "LASTBILLEDDATE1", "LASTBILLEDDATE2", "LASTBILLEDDATEP",
    "HEALTHCARECLAIMTYPEID1", "HEALTHCARECLAIMTYPEID2",
]

CLAIM_TX_COLUMNS = [
    "ID", "CLAIMID", "CHARGEID", "PATIENTID", "TYPE", "AMOUNT", "METHOD",
    "FROMDATE", "TODATE", "PLACEOFSERVICE", "PROCEDURECODE", "MODIFIER1",
    "MODIFIER2", "DIAGNOSISREF1", "DIAGNOSISREF2", "DIAGNOSISREF3",
    "DIAGNOSISREF4", "UNITS", "DEPARTMENTID", "NOTES", "UNITAMOUNT",
    "TRANSFEROUTID", "TRANSFERTYPE", "PAYMENTS", "ADJUSTMENTS", "TRANSFERS",
    "OUTSTANDING", "APPOINTMENTID", "LINENOTE", "PATIENTINSURANCEID",
    "FEESCHEDULEID", "PROVIDERID", "SUPERVISINGPROVIDERID",
]

PAYER_TRANSITION_COLUMNS = [
    "PATIENT", "MEMBERID", "START_DATE", "END_DATE", "PAYER", "SECONDARY_PAYER",
    "PLAN_OWNERSHIP", "OWNER_NAME",
]


def stable_uuid(label: str) -> str:
    return str(uuid5(NAMESPACE, label))


def iso_date(value: pd.Timestamp) -> str:
    return value.strftime("%Y-%m-%d")


def iso_datetime(value: pd.Timestamp) -> str:
    return value.strftime("%Y-%m-%dT%H:%M:%SZ")


def require_source_file(source_dir: Path, name: str) -> Path:
    path = source_dir / name
    if not path.exists():
        raise FileNotFoundError(f"Required Synthea source file not found: {path}")
    return path


def first_id(source_dir: Path, filename: str, column: str = "Id") -> str:
    path = require_source_file(source_dir, filename)
    df = pd.read_csv(path, usecols=[column], nrows=1, dtype=str)
    if df.empty or pd.isna(df.iloc[0][column]):
        raise ValueError(f"Could not get {column} from {path}")
    return str(df.iloc[0][column])


def blank_row(columns: list[str]) -> dict[str, object]:
    return {column: "" for column in columns}


def add_claim_bundle(
    *,
    claims: list[dict[str, object]],
    transactions: list[dict[str, object]],
    patient_id: str,
    provider_id: str,
    payer_id: str,
    encounter_id: str,
    service_start: pd.Timestamp,
    service_end: pd.Timestamp,
    procedure_code: str,
    place_of_service: str,
    amount: float,
    label: str,
) -> None:
    claim_id = stable_uuid(f"claim:{label}")
    tx_id = stable_uuid(f"claim_tx:{label}")
    charge_id = stable_uuid(f"charge:{label}")

    claim = blank_row(CLAIM_COLUMNS)
    claim.update(
        {
            "Id": claim_id,
            "PATIENTID": patient_id,
            "PROVIDERID": provider_id,
            "PRIMARYPATIENTINSURANCEID": payer_id,
            "DEPARTMENTID": "1",
            "PATIENTDEPARTMENTID": "1",
            "DIAGNOSIS1": MH_DIAGNOSIS_CODE,
            "APPOINTMENTID": encounter_id,
            "CURRENTILLNESSDATE": iso_date(service_start),
            "SERVICEDATE": iso_date(service_start),
            "SUPERVISINGPROVIDERID": provider_id,
            "STATUS1": "CLOSED",
            "STATUSP": "CLOSED",
            "OUTSTANDING1": 0,
            "OUTSTANDING2": 0,
            "OUTSTANDINGP": 0,
            "LASTBILLEDDATE1": iso_date(service_end),
            "LASTBILLEDDATEP": iso_date(service_end),
            "HEALTHCARECLAIMTYPEID1": "1",
        }
    )
    claim["synthetic_fixture_flag"] = FIXTURE_FLAG
    claims.append(claim)

    tx = blank_row(CLAIM_TX_COLUMNS)
    tx.update(
        {
            "ID": tx_id,
            "CLAIMID": claim_id,
            "CHARGEID": charge_id,
            "PATIENTID": patient_id,
            "TYPE": "CHARGE",
            "AMOUNT": amount,
            "METHOD": "FIXTURE",
            "FROMDATE": iso_date(service_start),
            "TODATE": iso_date(service_end),
            "PLACEOFSERVICE": place_of_service,
            "PROCEDURECODE": procedure_code,
            "DIAGNOSISREF1": "1",
            "UNITS": 1,
            "DEPARTMENTID": "1",
            "NOTES": "Controlled FUH fixture",
            "UNITAMOUNT": amount,
            "PAYMENTS": amount,
            "ADJUSTMENTS": 0,
            "TRANSFERS": 0,
            "OUTSTANDING": 0,
            "APPOINTMENTID": encounter_id,
            "PATIENTINSURANCEID": payer_id,
            "PROVIDERID": provider_id,
            "SUPERVISINGPROVIDERID": provider_id,
        }
    )
    tx["synthetic_fixture_flag"] = FIXTURE_FLAG
    transactions.append(tx)


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    source_dir = project_root / "data" / "generated" / "synthea" / "csv"
    output_dir = project_root / "data" / "generated" / "fuh_fixtures"
    output_dir.mkdir(parents=True, exist_ok=True)

    organization_id = first_id(source_dir, "organizations.csv")
    provider_id = first_id(source_dir, "providers.csv")
    payer_id = first_id(source_dir, "payers.csv")

    patients: list[dict[str, object]] = []
    encounters: list[dict[str, object]] = []
    conditions: list[dict[str, object]] = []
    claims: list[dict[str, object]] = []
    transactions: list[dict[str, object]] = []
    payer_transitions: list[dict[str, object]] = []
    manifest: list[dict[str, object]] = []

    # 40 measurement-year denominator fixtures. All are age 6+, continuously
    # enrolled, and discharged before December 2. Follow-up timing is varied so
    # later FUH SQL has known positive/negative outcomes without relying on chance.
    # Expected rates from these controlled rows alone:
    #   7-day: 18 / 40 = 45%
    #   30-day: 32 / 40 = 80%
    followup_days: list[int | None] = (
        [3] * 10
        + [7] * 8
        + [14] * 8
        + [30] * 6
        + [31] * 4
        + [None] * 4
    )

    first_discharge = pd.Timestamp("2025-01-10 10:00:00")

    for i, followup_day in enumerate(followup_days, start=1):
        fixture_key = f"FUH-{MEASUREMENT_YEAR}-{i:03d}"
        patient_id = stable_uuid(f"patient:{fixture_key}")
        member_id = stable_uuid(f"member:{fixture_key}")
        admission_id = stable_uuid(f"encounter:index:{fixture_key}")

        discharge = first_discharge + pd.Timedelta(days=(i - 1) * 7)
        admission = discharge - pd.Timedelta(days=3)
        birthdate = pd.Timestamp("1985-01-15") + pd.Timedelta(days=i * 11)

        patient = blank_row(PATIENT_COLUMNS)
        patient.update(
            {
                "Id": patient_id,
                "BIRTHDATE": iso_date(birthdate),
                "SSN": f"999-90-{i:04d}",
                "FIRST": f"Fixture{i:03d}",
                "LAST": "Patient",
                "MARITAL": "S",
                "RACE": "white" if i % 2 else "black",
                "ETHNICITY": "nonhispanic",
                "GENDER": "F" if i % 2 else "M",
                "BIRTHPLACE": "Raleigh NC US",
                "ADDRESS": f"{1000 + i} Fixture Way",
                "CITY": "Raleigh",
                "STATE": "North Carolina",
                "COUNTY": "Wake County",
                "FIPS": "37183",
                "ZIP": "27601",
                "LAT": 35.7796,
                "LON": -78.6382,
                "HEALTHCARE_EXPENSES": 0,
                "HEALTHCARE_COVERAGE": 0,
                "INCOME": 30000 + (i * 100),
            }
        )
        patient["synthetic_fixture_flag"] = FIXTURE_FLAG
        patients.append(patient)

        enrollment = blank_row(PAYER_TRANSITION_COLUMNS)
        enrollment.update(
            {
                "PATIENT": patient_id,
                "MEMBERID": member_id,
                "START_DATE": "2024-01-01",
                "END_DATE": "2026-12-31",
                "PAYER": payer_id,
                "PLAN_OWNERSHIP": "SELF",
                "OWNER_NAME": f"Fixture{i:03d} Patient",
            }
        )
        enrollment["synthetic_fixture_flag"] = FIXTURE_FLAG
        payer_transitions.append(enrollment)

        inpatient = blank_row(ENCOUNTER_COLUMNS)
        inpatient.update(
            {
                "Id": admission_id,
                "START": iso_datetime(admission),
                "STOP": iso_datetime(discharge),
                "PATIENT": patient_id,
                "ORGANIZATION": organization_id,
                "PROVIDER": provider_id,
                "PAYER": payer_id,
                "ENCOUNTERCLASS": "inpatient",
                "CODE": "FUH_FIXTURE_INPATIENT",
                "DESCRIPTION": "Controlled psychiatric inpatient hospitalization",
                "BASE_ENCOUNTER_COST": 6000.00,
                "TOTAL_CLAIM_COST": 8500.00,
                "PAYER_COVERAGE": 8500.00,
                "REASONCODE": MH_DIAGNOSIS_CODE,
                "REASONDESCRIPTION": MH_DIAGNOSIS_DESCRIPTION,
            }
        )
        inpatient["synthetic_fixture_flag"] = FIXTURE_FLAG
        encounters.append(inpatient)

        condition = blank_row(CONDITION_COLUMNS)
        condition.update(
            {
                "START": iso_date(admission),
                "STOP": iso_date(discharge),
                "PATIENT": patient_id,
                "ENCOUNTER": admission_id,
                "SYSTEM": "ICD-10-CM",
                "CODE": MH_DIAGNOSIS_CODE,
                "DESCRIPTION": MH_DIAGNOSIS_DESCRIPTION,
            }
        )
        condition["synthetic_fixture_flag"] = FIXTURE_FLAG
        conditions.append(condition)

        add_claim_bundle(
            claims=claims,
            transactions=transactions,
            patient_id=patient_id,
            provider_id=provider_id,
            payer_id=payer_id,
            encounter_id=admission_id,
            service_start=admission,
            service_end=discharge,
            procedure_code=INPATIENT_PROCEDURE_CODE,
            place_of_service="21",
            amount=8500.00,
            label=f"index:{fixture_key}",
        )

        followup_id = ""
        followup_date_str = ""
        if followup_day is not None:
            followup_start = discharge + pd.Timedelta(days=followup_day, hours=4)
            followup_end = followup_start + pd.Timedelta(minutes=30)
            followup_id = stable_uuid(f"encounter:followup:{fixture_key}")
            followup_date_str = iso_date(followup_start)

            followup = blank_row(ENCOUNTER_COLUMNS)
            followup.update(
                {
                    "Id": followup_id,
                    "START": iso_datetime(followup_start),
                    "STOP": iso_datetime(followup_end),
                    "PATIENT": patient_id,
                    "ORGANIZATION": organization_id,
                    "PROVIDER": provider_id,
                    "PAYER": payer_id,
                    "ENCOUNTERCLASS": "ambulatory",
                    "CODE": "FUH_FIXTURE_FOLLOWUP",
                    "DESCRIPTION": "Controlled behavioral-health follow-up",
                    "BASE_ENCOUNTER_COST": 175.00,
                    "TOTAL_CLAIM_COST": 175.00,
                    "PAYER_COVERAGE": 175.00,
                    "REASONCODE": MH_DIAGNOSIS_CODE,
                    "REASONDESCRIPTION": MH_DIAGNOSIS_DESCRIPTION,
                }
            )
            followup["synthetic_fixture_flag"] = FIXTURE_FLAG
            encounters.append(followup)

            followup_condition = blank_row(CONDITION_COLUMNS)
            followup_condition.update(
                {
                    "START": iso_date(followup_start),
                    "STOP": iso_date(followup_start),
                    "PATIENT": patient_id,
                    "ENCOUNTER": followup_id,
                    "SYSTEM": "ICD-10-CM",
                    "CODE": MH_DIAGNOSIS_CODE,
                    "DESCRIPTION": MH_DIAGNOSIS_DESCRIPTION,
                }
            )
            followup_condition["synthetic_fixture_flag"] = FIXTURE_FLAG
            conditions.append(followup_condition)

            add_claim_bundle(
                claims=claims,
                transactions=transactions,
                patient_id=patient_id,
                provider_id=provider_id,
                payer_id=payer_id,
                encounter_id=followup_id,
                service_start=followup_start,
                service_end=followup_end,
                procedure_code=FOLLOWUP_PROCEDURE_CODE,
                place_of_service="11",
                amount=175.00,
                label=f"followup:{fixture_key}",
            )

        expected_7d = int(followup_day is not None and 1 <= followup_day <= 7)
        expected_30d = int(followup_day is not None and 1 <= followup_day <= 30)

        manifest.append(
            {
                "fixture_key": fixture_key,
                "patient_id": patient_id,
                "index_encounter_id": admission_id,
                "followup_encounter_id": followup_id,
                "index_discharge_date": iso_date(discharge),
                "followup_date": followup_date_str,
                "followup_day": "" if followup_day is None else followup_day,
                "expected_denominator_flag": 1,
                "expected_fuh_7d_flag": expected_7d,
                "expected_fuh_30d_flag": expected_30d,
                "synthetic_fixture_flag": FIXTURE_FLAG,
            }
        )

    outputs = {
        "patients.csv": pd.DataFrame(patients),
        "encounters.csv": pd.DataFrame(encounters),
        "conditions.csv": pd.DataFrame(conditions),
        "claims.csv": pd.DataFrame(claims),
        "claims_transactions.csv": pd.DataFrame(transactions),
        "payer_transitions.csv": pd.DataFrame(payer_transitions),
        "fixture_manifest.csv": pd.DataFrame(manifest),
    }

    expected_columns = {
        "patients.csv": PATIENT_COLUMNS,
        "encounters.csv": ENCOUNTER_COLUMNS,
        "conditions.csv": CONDITION_COLUMNS,
        "claims.csv": CLAIM_COLUMNS,
        "claims_transactions.csv": CLAIM_TX_COLUMNS,
        "payer_transitions.csv": PAYER_TRANSITION_COLUMNS,
    }

    for filename, df in outputs.items():
        if filename in expected_columns:
            ordered = expected_columns[filename] + ["synthetic_fixture_flag"]
            df = df.reindex(columns=ordered)
        path = output_dir / filename
        df.to_csv(path, index=False)
        print(f"{filename:26s} {len(df):>4} rows  ->  {path}")

    manifest_df = outputs["fixture_manifest.csv"]
    denom = int(manifest_df["expected_denominator_flag"].sum())
    seven = int(manifest_df["expected_fuh_7d_flag"].sum())
    thirty = int(manifest_df["expected_fuh_30d_flag"].sum())

    print("\nControlled FUH fixture expectations")
    print(f"Denominator episodes : {denom}")
    print(f"7-day numerator      : {seven} ({seven / denom:.1%})")
    print(f"30-day numerator     : {thirty} ({thirty / denom:.1%})")
    print("\nSynthea source files were not modified.")


if __name__ == "__main__":
    main()
