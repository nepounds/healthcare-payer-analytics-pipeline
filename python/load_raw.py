from __future__ import annotations

import csv
import os
import sys
import time
from datetime import datetime, timezone
from functools import lru_cache
from pathlib import Path
from uuid import uuid4

import pandas as pd
import pyodbc
from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SYNTHEA_DIR = PROJECT_ROOT / "data" / "generated" / "synthea" / "csv"
FIXTURE_DIR = PROJECT_ROOT / "data" / "generated" / "fuh_fixtures"
DEFAULT_CHUNK_SIZE = 10_000

TABLE_SPECS = {
    "raw.patient": {
        "filename": "patients.csv",
        "fixture": True,
    },
    "raw.encounter": {
        "filename": "encounters.csv",
        "fixture": True,
    },
    "raw.condition": {
        "filename": "conditions.csv",
        "fixture": True,
    },
    "raw.claim": {
        "filename": "claims.csv",
        "fixture": True,
    },
    "raw.claim_transaction": {
        "filename": "claims_transactions.csv",
        "fixture": True,
    },
    "raw.payer_transition": {
        "filename": "payer_transitions.csv",
        "fixture": True,
    },
    "raw.provider": {
        "filename": "providers.csv",
        "fixture": False,
    },
    "raw.organization": {
        "filename": "organizations.csv",
        "fixture": False,
    },
    "raw.payer": {
        "filename": "payers.csv",
        "fixture": False,
    },
}

MANIFEST_TABLE = "raw.fuh_fixture_manifest"
MANIFEST_FILE = "fixture_manifest.csv"

METADATA_COLUMNS = [
    "synthetic_fixture_flag",
    "source_name",
    "source_file",
    "pipeline_run_id",
    "loaded_at_utc",
]

TRUNCATE_ORDER = [
    "raw.fuh_fixture_manifest",
    "raw.claim_transaction",
    "raw.claim",
    "raw.condition",
    "raw.encounter",
    "raw.payer_transition",
    "raw.patient",
    "raw.provider",
    "raw.organization",
    "raw.payer",
]


class SourceLoadError(RuntimeError):
    """Load failure that preserves the number of rows already committed."""

    def __init__(self, message: str, *, loaded_rows: int) -> None:
        super().__init__(message)
        self.loaded_rows = loaded_rows


def utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None, microsecond=0)


def connection_string() -> str:
    load_dotenv(PROJECT_ROOT / ".env")

    server = os.getenv("SQL_SERVER", "localhost")
    database = os.getenv("SQL_DATABASE", "HealthcarePayerAnalytics")
    driver = os.getenv("SQL_DRIVER", "ODBC Driver 18 for SQL Server")
    trusted = os.getenv("SQL_TRUSTED_CONNECTION", "yes").strip().lower()

    parts = [
        f"DRIVER={{{driver}}}",
        f"SERVER={server}",
        f"DATABASE={database}",
        "Encrypt=yes",
        "TrustServerCertificate=yes",
    ]

    if trusted in {"yes", "true", "1"}:
        parts.append("Trusted_Connection=yes")
    else:
        user = os.getenv("SQL_USER")
        password = os.getenv("SQL_PASSWORD")
        if not user or not password:
            raise RuntimeError(
                "SQL_TRUSTED_CONNECTION is disabled, but SQL_USER/SQL_PASSWORD are missing."
            )
        parts.extend([f"UID={user}", f"PWD={password}"])

    return ";".join(parts) + ";"


def ensure_paths() -> None:
    missing = []
    for spec in TABLE_SPECS.values():
        path = SYNTHEA_DIR / spec["filename"]
        if not path.exists():
            missing.append(path)

    for spec in TABLE_SPECS.values():
        if spec["fixture"]:
            path = FIXTURE_DIR / spec["filename"]
            if not path.exists():
                missing.append(path)

    manifest = FIXTURE_DIR / MANIFEST_FILE
    if not manifest.exists():
        missing.append(manifest)

    if missing:
        joined = "\n".join(f"  - {p}" for p in missing)
        raise FileNotFoundError(f"Required input file(s) missing:\n{joined}")


def sql_columns(cursor: pyodbc.Cursor, schema: str, table: str) -> list[str]:
    rows = cursor.execute(
        """
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
        ORDER BY ORDINAL_POSITION;
        """,
        schema,
        table,
    ).fetchall()
    return [row[0] for row in rows]


def assert_tables_exist(cursor: pyodbc.Cursor) -> None:
    tables = list(TABLE_SPECS) + [MANIFEST_TABLE, "raw.load_run", "raw.load_file_audit"]
    missing = []
    for full_name in tables:
        schema, table = full_name.split(".", 1)
        exists = cursor.execute(
            "SELECT 1 FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id "
            "WHERE s.name=? AND t.name=?;",
            schema,
            table,
        ).fetchone()
        if not exists:
            missing.append(full_name)
    if missing:
        raise RuntimeError(
            "Raw tables are missing. Run sql/01_raw/001_create_raw_tables.sql first. "
            f"Missing: {', '.join(missing)}"
        )


def csv_header(path: Path) -> list[str]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.reader(handle)
        return next(reader)


@lru_cache(maxsize=None)
def count_csv_rows(path: Path) -> int:
    """Count parsed CSV records, excluding the header and truly blank lines."""
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.reader(handle)
        next(reader, None)
        return sum(1 for row in reader if row)


def truncate_raw(cursor: pyodbc.Cursor) -> None:
    for table in TRUNCATE_ORDER:
        cursor.execute(f"TRUNCATE TABLE {table};")


def insert_run(cursor: pyodbc.Cursor, run_id: str) -> None:
    cursor.execute(
        """
        INSERT INTO raw.load_run (
            pipeline_run_id, started_at_utc, status,
            synthea_source_path, fixture_source_path
        ) VALUES (?, ?, 'RUNNING', ?, ?);
        """,
        run_id,
        utc_now(),
        str(SYNTHEA_DIR),
        str(FIXTURE_DIR),
    )


def finish_run(cursor: pyodbc.Cursor, run_id: str, status: str, error: str | None = None) -> None:
    cursor.execute(
        """
        UPDATE raw.load_run
        SET completed_at_utc=?, status=?, error_message=?
        WHERE pipeline_run_id=?;
        """,
        utc_now(),
        status,
        error,
        run_id,
    )


def write_audit(
    cursor: pyodbc.Cursor,
    *,
    run_id: str,
    target_table: str,
    source_name: str,
    source_file: Path,
    expected_rows: int,
    loaded_rows: int,
    started_at: datetime,
    status: str,
    error: str | None = None,
) -> None:
    cursor.execute(
        """
        INSERT INTO raw.load_file_audit (
            pipeline_run_id, target_table, source_name, source_file,
            expected_rows, loaded_rows, started_at_utc, completed_at_utc,
            status, error_message
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """,
        run_id,
        target_table,
        source_name,
        str(source_file),
        expected_rows,
        loaded_rows,
        started_at,
        utc_now(),
        status,
        error,
    )


def insert_csv(
    conn: pyodbc.Connection,
    *,
    run_id: str,
    table: str,
    path: Path,
    source_name: str,
    fixture_flag: int,
    chunk_size: int,
) -> int:
    loaded = 0

    try:
        schema, table_name = table.split(".", 1)
        cursor = conn.cursor()
        target_cols = sql_columns(cursor, schema, table_name)
        table_source_cols = [c for c in target_cols if c not in METADATA_COLUMNS]

        header = csv_header(path)
        header_without_fixture = [c for c in header if c != "synthetic_fixture_flag"]

        # Synthea's CSV schema can vary slightly by release. Raw tables may keep
        # nullable compatibility columns (for example, provider.NPI) that are not
        # present in the pinned source version. Every CSV column must exist in the
        # SQL table, but nullable SQL-only columns are allowed and remain NULL.
        unknown_csv_cols = [c for c in header_without_fixture if c not in table_source_cols]
        if unknown_csv_cols:
            raise RuntimeError(
                f"Header mismatch for {path.name} -> {table}.\n"
                f"CSV contains columns not present in SQL: {unknown_csv_cols}\n"
                f"CSV: {header_without_fixture}\n"
                f"SQL: {table_source_cols}"
            )

        source_cols = header_without_fixture
        sql_only_cols = [c for c in table_source_cols if c not in source_cols]
        if sql_only_cols:
            print(
                "    Note: nullable SQL-only compatibility columns will remain NULL: "
                + ", ".join(sql_only_cols)
            )

        insert_cols = source_cols + METADATA_COLUMNS
        col_sql = ", ".join(f"[{c}]" for c in insert_cols)
        placeholders = ", ".join("?" for _ in insert_cols)
        insert_sql = f"INSERT INTO {table} ({col_sql}) VALUES ({placeholders});"

        loaded_at = utc_now()
        cursor.fast_executemany = True

        dtype_map = {column: str for column in header}
        for chunk in pd.read_csv(
            path,
            dtype=dtype_map,
            keep_default_na=False,
            chunksize=chunk_size,
            encoding="utf-8-sig",
        ):
            if "synthetic_fixture_flag" in chunk.columns:
                flags = chunk["synthetic_fixture_flag"].astype(str).str.strip()
                if not flags.isin({"1"}).all():
                    raise RuntimeError(
                        f"Fixture file contains a non-1 synthetic_fixture_flag: {path}"
                    )
                chunk = chunk.drop(columns=["synthetic_fixture_flag"])

            # Keep raw source blanks as empty strings. Typing/NULL normalization happens in core.
            rows = [
                tuple(row)
                + (
                    fixture_flag,
                    source_name,
                    path.name,
                    run_id,
                    loaded_at,
                )
                for row in chunk[source_cols].itertuples(index=False, name=None)
            ]

            cursor.executemany(insert_sql, rows)
            conn.commit()
            loaded += len(rows)
            print(f"    {loaded:>10,} rows", end="\r", flush=True)

        print(f"    {loaded:>10,} rows")
        return loaded

    except Exception as exc:
        # Prior chunks are committed individually, so preserve that count in the
        # audit row if a later chunk or validation step fails.
        raise SourceLoadError(str(exc), loaded_rows=loaded) from exc


def load_one_source(
    conn: pyodbc.Connection,
    *,
    run_id: str,
    table: str,
    path: Path,
    source_name: str,
    fixture_flag: int,
    chunk_size: int,
) -> int:
    expected = count_csv_rows(path)
    started = utc_now()
    print(f"  {source_name:<11} {path.name:<26} -> {table}  ({expected:,} expected)")

    try:
        loaded = insert_csv(
            conn,
            run_id=run_id,
            table=table,
            path=path,
            source_name=source_name,
            fixture_flag=fixture_flag,
            chunk_size=chunk_size,
        )
    except SourceLoadError as exc:
        write_audit(
            conn.cursor(),
            run_id=run_id,
            target_table=table,
            source_name=source_name,
            source_file=path,
            expected_rows=expected,
            loaded_rows=exc.loaded_rows,
            started_at=started,
            status="FAILED",
            error=str(exc)[:4000],
        )
        conn.commit()
        raise

    if loaded != expected:
        error = f"Row-count mismatch for {path}: expected {expected:,}, loaded {loaded:,}."
        write_audit(
            conn.cursor(),
            run_id=run_id,
            target_table=table,
            source_name=source_name,
            source_file=path,
            expected_rows=expected,
            loaded_rows=loaded,
            started_at=started,
            status="ROW_MISMATCH",
            error=error[:4000],
        )
        conn.commit()
        raise RuntimeError(error)

    write_audit(
        conn.cursor(),
        run_id=run_id,
        target_table=table,
        source_name=source_name,
        source_file=path,
        expected_rows=expected,
        loaded_rows=loaded,
        started_at=started,
        status="SUCCESS",
    )
    conn.commit()
    return loaded


def load_manifest(conn: pyodbc.Connection, run_id: str, chunk_size: int) -> int:
    return load_one_source(
        conn,
        run_id=run_id,
        table=MANIFEST_TABLE,
        path=FIXTURE_DIR / MANIFEST_FILE,
        source_name="FUH_FIXTURE",
        fixture_flag=1,
        chunk_size=chunk_size,
    )


def validate_table_totals(conn: pyodbc.Connection) -> None:
    cursor = conn.cursor()
    print("\nRaw row counts")
    print("-" * 68)
    for table, spec in TABLE_SPECS.items():
        synthea_rows = count_csv_rows(SYNTHEA_DIR / spec["filename"])
        fixture_rows = count_csv_rows(FIXTURE_DIR / spec["filename"]) if spec["fixture"] else 0
        expected = synthea_rows + fixture_rows
        actual = cursor.execute(f"SELECT COUNT_BIG(*) FROM {table};").fetchone()[0]
        marker = "OK" if actual == expected else "MISMATCH"
        print(f"{table:<28} expected={expected:>10,} actual={actual:>10,}  {marker}")
        if actual != expected:
            raise RuntimeError(f"Final row-count check failed for {table}.")

    expected_manifest = count_csv_rows(FIXTURE_DIR / MANIFEST_FILE)
    actual_manifest = cursor.execute(
        "SELECT COUNT_BIG(*) FROM raw.fuh_fixture_manifest;"
    ).fetchone()[0]
    marker = "OK" if actual_manifest == expected_manifest else "MISMATCH"
    print(
        f"{'raw.fuh_fixture_manifest':<28} expected={expected_manifest:>10,} "
        f"actual={actual_manifest:>10,}  {marker}"
    )
    if actual_manifest != expected_manifest:
        raise RuntimeError("Final row-count check failed for raw.fuh_fixture_manifest.")


def main() -> int:
    ensure_paths()
    chunk_size = int(os.getenv("RAW_LOAD_CHUNK_SIZE", DEFAULT_CHUNK_SIZE))
    run_id = str(uuid4())
    started = time.perf_counter()

    print("Healthcare Payer Analytics Pipeline - Phase 1 raw load")
    print(f"Pipeline run ID : {run_id}")
    print(f"Chunk size      : {chunk_size:,}")
    print(f"Synthea source  : {SYNTHEA_DIR}")
    print(f"Fixture source  : {FIXTURE_DIR}\n")

    conn = pyodbc.connect(connection_string(), autocommit=False)
    try:
        cursor = conn.cursor()
        assert_tables_exist(cursor)

        # Keep run history, replace only the current raw landing contents.
        truncate_raw(cursor)
        insert_run(cursor, run_id)
        conn.commit()

        for table, spec in TABLE_SPECS.items():
            load_one_source(
                conn,
                run_id=run_id,
                table=table,
                path=SYNTHEA_DIR / spec["filename"],
                source_name="SYNTHEA",
                fixture_flag=0,
                chunk_size=chunk_size,
            )

            if spec["fixture"]:
                load_one_source(
                    conn,
                    run_id=run_id,
                    table=table,
                    path=FIXTURE_DIR / spec["filename"],
                    source_name="FUH_FIXTURE",
                    fixture_flag=1,
                    chunk_size=chunk_size,
                )

        load_manifest(conn, run_id, chunk_size)
        validate_table_totals(conn)

        finish_run(conn.cursor(), run_id, "SUCCESS")
        conn.commit()

        elapsed = time.perf_counter() - started
        print(f"\nRAW LOAD SUCCESSFUL in {elapsed / 60:.1f} minutes")
        print(f"Pipeline run ID: {run_id}")
        return 0

    except Exception as exc:
        try:
            finish_run(conn.cursor(), run_id, "FAILED", str(exc)[:4000])
            conn.commit()
        except Exception:
            pass
        print(f"\nRAW LOAD FAILED: {exc}", file=sys.stderr)
        return 1
    finally:
        conn.close()


if __name__ == "__main__":
    raise SystemExit(main())
