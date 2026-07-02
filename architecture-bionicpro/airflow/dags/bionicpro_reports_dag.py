from __future__ import annotations

import json
import os
from datetime import datetime
from urllib.parse import urlencode
from urllib.request import Request, urlopen

import psycopg2
from airflow import DAG
from airflow.operators.python import PythonOperator


CLICKHOUSE_URL = os.environ.get("CLICKHOUSE_URL", "http://clickhouse:8123")
CLICKHOUSE_DATABASE = os.environ.get("CLICKHOUSE_DATABASE", "bionicpro")
CLICKHOUSE_USER = os.environ.get("CLICKHOUSE_USER", "default")
CLICKHOUSE_PASSWORD = os.environ.get("CLICKHOUSE_PASSWORD", "")


def clickhouse_query(sql: str, database: str = CLICKHOUSE_DATABASE) -> str:
    params = urlencode(
        {
            "database": database,
            "user": CLICKHOUSE_USER,
            "password": CLICKHOUSE_PASSWORD,
        }
    )
    request = Request(
        f"{CLICKHOUSE_URL}/?{params}",
        data=sql.encode("utf-8"),
        method="POST",
    )
    with urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8")


def clickhouse_json_each_row(sql: str) -> list[dict]:
    body = clickhouse_query(f"{sql} FORMAT JSONEachRow")
    return [json.loads(line) for line in body.splitlines() if line.strip()]


def ensure_clickhouse_tables() -> None:
    clickhouse_query(
        """
        CREATE TABLE IF NOT EXISTS crm_prostheses (
          username String,
          prosthesis_id String,
          full_name String,
          model String,
          activated_at Date
        )
        ENGINE = MergeTree
        ORDER BY (username, prosthesis_id)
        """
    )
    clickhouse_query(
        """
        CREATE TABLE IF NOT EXISTS report_mart (
          report_date Date,
          username String,
          prosthesis_id String,
          full_name String,
          model String,
          total_usage_seconds UInt64,
          total_movements UInt64,
          avg_battery_level Float64,
          total_errors UInt64
        )
        ENGINE = MergeTree
        ORDER BY (username, report_date, prosthesis_id)
        """
    )
    clickhouse_query(
        """
        CREATE TABLE IF NOT EXISTS etl_runs (
          period_start Date,
          period_end Date,
          status String,
          processed_at DateTime,
          records_loaded UInt64,
          error_message String
        )
        ENGINE = MergeTree
        ORDER BY (period_start, period_end, processed_at)
        """
    )


def extract_crm_to_clickhouse() -> None:
    ensure_clickhouse_tables()
    connection = psycopg2.connect(
        host=os.environ["CRM_DB_HOST"],
        port=os.environ.get("CRM_DB_PORT", "5432"),
        dbname=os.environ["CRM_DB_NAME"],
        user=os.environ["CRM_DB_USER"],
        password=os.environ["CRM_DB_PASSWORD"],
    )
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT c.username, p.prosthesis_id, c.full_name, p.model, p.activated_at
                FROM customers c
                JOIN prostheses p ON p.username = c.username
                ORDER BY c.username, p.prosthesis_id
                """
            )
            rows = cursor.fetchall()
    finally:
        connection.close()

    clickhouse_query("TRUNCATE TABLE crm_prostheses")
    if not rows:
        return

    payload = "\n".join(
        json.dumps(
            {
                "username": username,
                "prosthesis_id": prosthesis_id,
                "full_name": full_name,
                "model": model,
                "activated_at": activated_at.isoformat(),
            }
        )
        for username, prosthesis_id, full_name, model, activated_at in rows
    )
    clickhouse_query(f"INSERT INTO crm_prostheses FORMAT JSONEachRow\n{payload}")


def build_report_mart() -> dict:
    ensure_clickhouse_tables()
    coverage = clickhouse_json_each_row(
        """
        SELECT
          toString(min(toDate(event_time))) AS period_start,
          toString(max(toDate(event_time))) AS period_end
        FROM raw_telemetry
        """
    )[0]

    if not coverage["period_start"] or not coverage["period_end"]:
        raise ValueError("raw_telemetry has no rows")

    clickhouse_query("TRUNCATE TABLE report_mart")
    clickhouse_query(
        """
        INSERT INTO report_mart
        SELECT
          toDate(t.event_time) AS report_date,
          c.username,
          c.prosthesis_id,
          c.full_name,
          c.model,
          sum(t.usage_seconds) AS total_usage_seconds,
          sum(t.movement_count) AS total_movements,
          avg(t.battery_level) AS avg_battery_level,
          sum(t.error_count) AS total_errors
        FROM raw_telemetry t
        JOIN crm_prostheses c ON c.prosthesis_id = t.prosthesis_id
        GROUP BY
          report_date,
          c.username,
          c.prosthesis_id,
          c.full_name,
          c.model
        """
    )

    records = clickhouse_json_each_row("SELECT count() AS records_loaded FROM report_mart")[0][
        "records_loaded"
    ]
    return {
        "period_start": coverage["period_start"],
        "period_end": coverage["period_end"],
        "records_loaded": records,
    }


def record_success(**context) -> None:
    result = context["ti"].xcom_pull(task_ids="build_report_mart")
    payload = json.dumps(
        {
            "period_start": result["period_start"],
            "period_end": result["period_end"],
            "status": "success",
            "processed_at": datetime.utcnow().replace(microsecond=0).isoformat(sep=" "),
            "records_loaded": result["records_loaded"],
            "error_message": "",
        }
    )
    clickhouse_query(f"INSERT INTO etl_runs FORMAT JSONEachRow\n{payload}")


with DAG(
    dag_id="bionicpro_reports_etl",
    description="Builds BionicPRO user report mart from CRM and prosthesis telemetry",
    start_date=datetime(2026, 6, 20),
    schedule_interval="@daily",
    catchup=False,
    tags=["bionicpro", "reports"],
) as dag:
    extract_crm = PythonOperator(
        task_id="extract_crm_to_clickhouse",
        python_callable=extract_crm_to_clickhouse,
    )
    build_mart = PythonOperator(
        task_id="build_report_mart",
        python_callable=build_report_mart,
    )
    save_run = PythonOperator(
        task_id="record_successful_etl_run",
        python_callable=record_success,
    )

    extract_crm >> build_mart >> save_run
