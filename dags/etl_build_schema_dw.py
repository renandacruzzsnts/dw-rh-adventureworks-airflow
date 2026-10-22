from airflow.sdk import dag
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.standard.operators.empty import EmptyOperator
from datetime import datetime


@dag(
    dag_id="etl_build_dw",
    schedule="@once",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["rh", "etl", "dw"],
)
def etl_build_dw():

    create_schemas = SQLExecuteQueryOperator(
        task_id="create_schemas",
        conn_id="pg_dw",
        sql="sql/schemas.sql",
    )

    # dimensoes
    create_d_calendario = SQLExecuteQueryOperator(
        task_id="create_d_calendario", conn_id="pg_dw", sql="sql/dw_d_calendario.sql"
    )
    create_d_departamento = SQLExecuteQueryOperator(
        task_id="create_d_departamento", conn_id="pg_dw", sql="sql/dw_d_departamento.sql"
    )
    create_d_cargo = SQLExecuteQueryOperator(
        task_id="create_d_cargo", conn_id="pg_dw", sql="sql/dw_d_cargo.sql"
    )
    create_d_empregado = SQLExecuteQueryOperator(
        task_id="create_d_empregado", conn_id="pg_dw", sql="sql/dw_d_empregado.sql"
    )
    create_d_escalao_salarial = SQLExecuteQueryOperator(
        task_id="create_d_escalao_salarial", conn_id="pg_dw", sql="sql/dw_d_escalao_salarial.sql"
    )
    create_d_faixa_etaria = SQLExecuteQueryOperator(
        task_id="create_d_faixa_etaria", conn_id="pg_dw", sql="sql/dw_d_faixa_etaria.sql"
    )

    # seeds das dimensoes fixas
    seed_d_calendario = SQLExecuteQueryOperator(
        task_id="seed_d_calendario", conn_id="pg_dw", sql="sql/dw_seed_d_calendario.sql"
    )
    seed_d_escalao_salarial = SQLExecuteQueryOperator(
        task_id="seed_d_escalao_salarial", conn_id="pg_dw", sql="sql/dw_seed_d_escalao_salarial.sql"
    )
    seed_d_faixa_etaria = SQLExecuteQueryOperator(
        task_id="seed_d_faixa_etaria", conn_id="pg_dw", sql="sql/dw_seed_d_faixa_etaria.sql"
    )

    # controle da carga incremental
    create_controle_etl = SQLExecuteQueryOperator(
        task_id="create_controle_etl", conn_id="pg_dw", sql="sql/dw_controle_etl.sql"
    )

    dummy_operation = EmptyOperator(task_id="dummy_operation")

    # fato
    create_f_empregado_historico = SQLExecuteQueryOperator(
        task_id="create_f_empregado_historico",
        conn_id="pg_dw",
        sql="sql/dw_f_empregado_historico.sql",
    )

    create_schemas >> [
        create_d_calendario,
        create_d_departamento,
        create_d_cargo,
        create_d_empregado,
        create_d_escalao_salarial,
        create_d_faixa_etaria,
        create_controle_etl,
    ]

    create_d_calendario >> seed_d_calendario
    create_d_escalao_salarial >> seed_d_escalao_salarial
    create_d_faixa_etaria >> seed_d_faixa_etaria

    [
        seed_d_calendario,
        seed_d_escalao_salarial,
        seed_d_faixa_etaria,
        create_d_departamento,
        create_d_cargo,
        create_d_empregado,
        create_controle_etl,
    ] >> dummy_operation >> create_f_empregado_historico


etl_build_dw()
