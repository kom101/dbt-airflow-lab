from datetime import datetime, timedelta
from pathlib import Path
from airflow import DAG
from airflow.operators.bash import BashOperator
from cosmos import DbtTaskGroup, ProjectConfig, ProfileConfig, ExecutionConfig, RenderConfig
from cosmos.constants import TestBehavior, InvocationMode
import os
import json
import urllib.request
import logging

# 1. Ścieżki wewnątrz kontenera
DBT_PROJECT_PATH = Path("/usr/local/airflow/dbt_project")
DBT_EXECUTABLE = os.environ.get("DBT_CLI", "dbt")

# 2. Konfiguracja profilu - używamy dbt_project/profiles.yml
profile_config = ProfileConfig(
    profile_name="bigquery",
    target_name="dev",
    profiles_yml_filepath=DBT_PROJECT_PATH / "profiles.yml"
)

default_args = {
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "sla": timedelta(hours=1),
}

def _on_failure_callback(context):
    try:
        dag_id = context.get('dag').dag_id if context.get('dag') else 'unknown_dag'
        task_id = context.get('task_instance').task_id if context.get('task_instance') else 'unknown_task'
        try_number = context.get('task_instance').try_number if context.get('task_instance') else 0
        ts = context.get('ts', '')
        exception = str(context.get('exception', ''))
        message = f":x: Task failed | DAG: {dag_id} | Task: {task_id} | Try: {try_number} | When: {ts} | Exception: {exception}"

        # Slack webhook (opcjonalnie)
        webhook = os.environ.get("SLACK_WEBHOOK_URL")
        if webhook:
            data = json.dumps({"text": message}).encode("utf-8")
            req = urllib.request.Request(webhook, data=data, headers={"Content-Type": "application/json"})
            urllib.request.urlopen(req, timeout=10).read()

        # E-mail (opcjonalnie; wymaga konfiguracji SMTP w Airflow)
        emails = os.environ.get("ALERT_EMAILS")
        if emails:
            try:
                from airflow.utils.email import send_email
                to_list = [e.strip() for e in emails.split(",") if e.strip()]
                if to_list:
                    send_email(to=to_list, subject=f"[Airflow] Task failed: {dag_id}.{task_id}", html_content=message)
            except Exception as e:
                logging.getLogger(__name__).warning(f"Email send failed: {e}")
    except Exception as e:
        logging.getLogger(__name__).warning(f"Failure callback error: {e}")

with DAG(
    dag_id="gcp_ecommerce_pipeline",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@daily",
    catchup=False,
    default_args=default_args,
    on_failure_callback=_on_failure_callback,
) as dag:

    # 3. Grupa zadań dbt
    dbt_tasks = DbtTaskGroup(
        group_id="dbt_project",
        project_config=ProjectConfig(
            DBT_PROJECT_PATH,
        ),
        execution_config=ExecutionConfig(
            dbt_executable_path=DBT_EXECUTABLE,
            invocation_mode=InvocationMode.SUBPROCESS,
        ),
        render_config=RenderConfig(
            emit_datasets=False,
            test_behavior=TestBehavior.AFTER_EACH,
        ),
        operator_args={
            "install_deps": False,
            "env": {
                "OPENLINEAGE_URL": os.environ.get("OPENLINEAGE_URL", "http://marquez:5000"),
                "OPENLINEAGE_NAMESPACE": "gcp-bigquery-prod",
                "DBT_USE_COLORS": "false",
                "OPENLINEAGE_DEBUG": "true",
                "DBT_PACKAGES_DIR": "/tmp/dbt_packages",
                "DBT_TARGET_PATH": "/tmp/dbt_target",
                "GOOGLE_APPLICATION_CREDENTIALS": "/usr/local/airflow/gcp_credentials.json",
            },
        },
        profile_config=profile_config,
    )

    # 4. Generowanie dokumentacji
    generate_docs = BashOperator(
        task_id="generate_docs",
        bash_command=f"cd {DBT_PROJECT_PATH} && {DBT_EXECUTABLE} docs generate --profiles-dir {DBT_PROJECT_PATH} --target-path /tmp/dbt_target",
        env={
            "DBT_PACKAGES_DIR": "/tmp/dbt_packages",
            "DBT_TARGET_PATH": "/tmp/dbt_target",
            "GOOGLE_APPLICATION_CREDENTIALS": "/usr/local/airflow/gcp_credentials.json",
        },
    )

    dbt_tasks >> generate_docs
