from airflow.sdk import dag
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from datetime import datetime


@dag(
    dag_id="simular_mudancas_origem",
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["rh", "etl", "teste"],
)
def simular_mudancas_origem():
    """Altera dados no SQL Server para demonstrar a carga incremental."""

    SQLExecuteQueryOperator(
        task_id="simular_mudancas",
        conn_id="aw_source",
        sql="sql/simular_mudancas_origem.sql",
    )


simular_mudancas_origem()
