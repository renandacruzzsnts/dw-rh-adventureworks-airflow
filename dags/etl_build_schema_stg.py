from airflow.sdk import dag
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.standard.operators.empty import EmptyOperator
from datetime import datetime


@dag(
    dag_id="etl_build_stage",
    schedule="@once",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["rh", "etl", "stage"],
)
def etl_build_stage():

    create_schemas = SQLExecuteQueryOperator(
        task_id="create_schemas",
        conn_id="pg_stage",
        sql="sql/schemas.sql",
    )

    create_stg_empregado = SQLExecuteQueryOperator(
        task_id="create_stg_empregado",
        conn_id="pg_stage",
        sql="sql/stg_empregado.sql",
    )

    create_stg_departamento = SQLExecuteQueryOperator(
        task_id="create_stg_departamento",
        conn_id="pg_stage",
        sql="sql/stg_departamento.sql",
    )

    create_stg_historico_departamento = SQLExecuteQueryOperator(
        task_id="create_stg_historico_departamento",
        conn_id="pg_stage",
        sql="sql/stg_historico_departamento.sql",
    )

    create_stg_historico_pagamento = SQLExecuteQueryOperator(
        task_id="create_stg_historico_pagamento",
        conn_id="pg_stage",
        sql="sql/stg_historico_pagamento.sql",
    )

    dummy_operation = EmptyOperator(task_id="dummy_operation")

    create_schemas >> [
        create_stg_empregado,
        create_stg_departamento,
        create_stg_historico_departamento,
        create_stg_historico_pagamento,
    ] >> dummy_operation


etl_build_stage()
