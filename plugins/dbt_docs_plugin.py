from airflow.plugins_manager import AirflowPlugin
from flask import Blueprint, send_from_directory
from pathlib import Path
import os

import logging

# Konfiguracja loggera
log = logging.getLogger(__name__)

# Ścieżka do wygenerowanej dokumentacji dbt (tymczasowy katalog w kontenerze)
DBT_DOCS_DIR = Path("/tmp/dbt_target")

log.info(f"Loading DbtDocsPlugin. Docs dir: {DBT_DOCS_DIR}")

# Tworzymy Blueprint
dbt_docs_bp = Blueprint(
    "dbt_docs",
    __name__,
    template_folder=str(DBT_DOCS_DIR),
    static_folder=str(DBT_DOCS_DIR),
    static_url_path="/dbt_docs/static"
)

@dbt_docs_bp.route("/dbt_docs/")
@dbt_docs_bp.route("/dbt_docs/<path:filename>")
def serve_dbt_docs(filename="index.html"):
    """
    Serwuje pliki dokumentacji dbt.
    Domyślnie serwuje index.html.
    """
    log.info(f"Serving dbt docs file: {filename}")
    # Sprawdzamy, czy plik istnieje, aby uniknąć błędów 500
    file_path = DBT_DOCS_DIR / filename
    if not file_path.exists():
         log.warning(f"File not found: {file_path}")
         return f"File {filename} not found in {DBT_DOCS_DIR}", 404
    
    return send_from_directory(DBT_DOCS_DIR, filename)

# Rejestrujemy wtyczkę
class DbtDocsPlugin(AirflowPlugin):
    name = "dbt_docs_plugin"
    flask_blueprints = [dbt_docs_bp]
