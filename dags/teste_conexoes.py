from datetime import datetime

from airflow.sdk import dag, task


@dag(
    dag_id="teste_conexoes",
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["setup"],
)
def teste_conexoes():
    @task
    def testar_origem():
        from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook

        hook = MsSqlHook(mssql_conn_id="aw_source")
        resultado = hook.get_first("SELECT DB_NAME()")
        print(f"Origem OK: {resultado[0]}")
        return resultado[0]

    @task
    def testar_destino():
        from airflow.providers.postgres.hooks.postgres import PostgresHook

        hook = PostgresHook(postgres_conn_id="pg_dw")
        resultado = hook.get_first("SELECT current_database()")
        print(f"Destino OK: {resultado[0]}")
        return resultado[0]

    testar_origem()
    testar_destino()


teste_conexoes()
