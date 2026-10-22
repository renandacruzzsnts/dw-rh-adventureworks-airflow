from datetime import datetime

from airflow.sdk import dag, task, get_current_context
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.standard.operators.empty import EmptyOperator

# conexoes 
ORIGEM = "aw_source"   
STAGE = "pg_stage"     
DW = "pg_dw"          

# tabelas de origem (chave do controle de watermark)
T_EMPREGADO = "HumanResources.Employee"
T_DEPARTAMENTO = "HumanResources.Department"
T_HIST_DEP = "HumanResources.EmployeeDepartmentHistory"
T_HIST_PAG = "HumanResources.EmployeePayHistory"

DAG_ID = "etl_rh_carga_incremental"


def _mssql():
    from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook

    return MsSqlHook(mssql_conn_id=ORIGEM)


def _pg(conn_id):
    from airflow.providers.postgres.hooks.postgres import PostgresHook

    return PostgresHook(postgres_conn_id=conn_id)


def _ids_sql(ids):
    return ",".join(str(int(i)) for i in ids)


def _carregar_stage(tabela, colunas, linhas):
    """Esvazia a tabela de stage e grava somente o delta da execucao."""
    pg = _pg(STAGE)
    pg.run(f"TRUNCATE TABLE {tabela}")
    if linhas:
        pg.insert_rows(
            table=tabela, rows=linhas, target_fields=colunas, commit_every=500
        )
    print(f"{tabela}: {len(linhas)} linha(s) carregada(s) no stage")
    return len(linhas)


@dag(
    dag_id=DAG_ID,
    schedule=None,  
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    params={"data_referencia": "2014-12-31"},
    tags=["rh", "etl", "incremental"],
)
def etl_rh_carga_incremental():

    inicio = EmptyOperator(task_id="inicio")


    @task
    def ler_watermarks():
        linhas = _pg(DW).get_records(
            "SELECT tabela_origem, ultimo_modified_date FROM etl.controle_carga"
        )
        wm = {tabela: dt.isoformat() for tabela, dt in linhas}
        print(f"Watermarks atuais: {wm}")
        return wm


    @task
    def identificar_empregados_delta(wm):
        sql = """
            SELECT BusinessEntityID FROM HumanResources.Employee
             WHERE ModifiedDate > %s
            UNION
            SELECT BusinessEntityID FROM HumanResources.EmployeeDepartmentHistory
             WHERE ModifiedDate > %s
            UNION
            SELECT BusinessEntityID FROM HumanResources.EmployeePayHistory
             WHERE ModifiedDate > %s
        """
        params = (
            datetime.fromisoformat(wm[T_EMPREGADO]),
            datetime.fromisoformat(wm[T_HIST_DEP]),
            datetime.fromisoformat(wm[T_HIST_PAG]),
        )
        ids = sorted(int(r[0]) for r in _mssql().get_records(sql, parameters=params))
        print(f"Empregados no delta: {len(ids)}")
        return ids

    # extract + load stg 
    @task
    def extrair_empregado(ids):
        colunas = [
            "business_entity_id", "job_title", "birth_date", "marital_status",
            "gender", "hire_date", "salaried_flag", "vacation_hours",
            "sick_leave_hours", "current_flag", "modified_date",
        ]
        linhas = []
        if ids:
            sql = f"""
                SELECT BusinessEntityID, JobTitle, BirthDate, MaritalStatus,
                       Gender, HireDate, SalariedFlag, VacationHours,
                       SickLeaveHours, CurrentFlag, ModifiedDate
                  FROM HumanResources.Employee
                 WHERE BusinessEntityID IN ({_ids_sql(ids)})
            """
            linhas = [tuple(r) for r in _mssql().get_records(sql)]
        return _carregar_stage("stage.stg_empregado", colunas, linhas)

    @task
    def extrair_departamento(wm):
        colunas = ["department_id", "name", "group_name", "modified_date"]
        sql = """
            SELECT DepartmentID, Name, GroupName, ModifiedDate
              FROM HumanResources.Department
             WHERE ModifiedDate > %s
        """
        params = (datetime.fromisoformat(wm[T_DEPARTAMENTO]),)
        linhas = [tuple(r) for r in _mssql().get_records(sql, parameters=params)]
        return _carregar_stage("stage.stg_departamento", colunas, linhas)

    @task
    def extrair_historico_departamento(ids):
        colunas = [
            "business_entity_id", "department_id", "shift_id",
            "start_date", "end_date", "modified_date",
        ]
        linhas = []
        if ids:
            sql = f"""
                SELECT BusinessEntityID, DepartmentID, ShiftID,
                       StartDate, EndDate, ModifiedDate
                  FROM HumanResources.EmployeeDepartmentHistory
                 WHERE BusinessEntityID IN ({_ids_sql(ids)})
            """
            linhas = [tuple(r) for r in _mssql().get_records(sql)]
        return _carregar_stage("stage.stg_historico_departamento", colunas, linhas)

    @task
    def extrair_historico_pagamento(ids):
        colunas = [
            "business_entity_id", "rate_change_date", "rate",
            "pay_frequency", "modified_date",
        ]
        linhas = []
        if ids:
            sql = f"""
                SELECT BusinessEntityID, RateChangeDate, Rate,
                       PayFrequency, ModifiedDate
                  FROM HumanResources.EmployeePayHistory
                 WHERE BusinessEntityID IN ({_ids_sql(ids)})
            """
            linhas = [tuple(r) for r in _mssql().get_records(sql)]
        return _carregar_stage("stage.stg_historico_pagamento", colunas, linhas)

    fim_stage = EmptyOperator(task_id="fim_stage")

    #load do dw
    load_d_departamento = SQLExecuteQueryOperator(
        task_id="load_d_departamento", conn_id=DW, sql="sql/load_d_departamento.sql"
    )
    load_d_cargo = SQLExecuteQueryOperator(
        task_id="load_d_cargo", conn_id=DW, sql="sql/load_d_cargo.sql"
    )
    load_d_empregado = SQLExecuteQueryOperator(
        task_id="load_d_empregado", conn_id=DW, sql="sql/load_d_empregado.sql"
    )

    fim_dimensoes = EmptyOperator(task_id="fim_dimensoes")

    load_f_empregado_historico = SQLExecuteQueryOperator(
        task_id="load_f_empregado_historico",
        conn_id=DW,
        sql="sql/load_f_empregado_historico.sql",
    )

    # a validacao da carga  
    @task
    def validar_carga():
        pg = _pg(DW)
        esperado = pg.get_first(
            "SELECT COUNT(*) FROM stage.stg_historico_departamento"
        )[0]
        carregado = pg.get_first(
            """SELECT COUNT(*) FROM dw.f_empregado_historico
                WHERE cod_empregado IN (SELECT business_entity_id FROM stage.stg_empregado)"""
        )[0]
        print(f"Registros no stage: {esperado} | registros na fato: {carregado}")
        if esperado != carregado:
            raise ValueError(
                f"Carga inconsistente: stage={esperado}, fato={carregado}. "
                "Verifique chaves sem correspondencia nas dimensoes."
            )
        return {"lidos": int(esperado), "carregados": int(carregado)}

   
    @task
    def atualizar_controle_e_log(wm, ids, contagens, validacao):
        run_id = get_current_context()["run_id"]
        pg = _pg(DW)

        pg.run(
            """
            UPDATE etl.controle_carga c
               SET ultimo_modified_date = GREATEST(
                       c.ultimo_modified_date,
                       COALESCE(s.novo, c.ultimo_modified_date)),
                   dt_ultima_execucao = now(),
                   status = 'OK'
              FROM (
                    SELECT 'HumanResources.Employee' AS tabela, MAX(modified_date) AS novo
                      FROM stage.stg_empregado
                    UNION ALL
                    SELECT 'HumanResources.Department', MAX(modified_date)
                      FROM stage.stg_departamento
                    UNION ALL
                    SELECT 'HumanResources.EmployeeDepartmentHistory', MAX(modified_date)
                      FROM stage.stg_historico_departamento
                    UNION ALL
                    SELECT 'HumanResources.EmployeePayHistory', MAX(modified_date)
                      FROM stage.stg_historico_pagamento
                   ) s
             WHERE c.tabela_origem = s.tabela
            """
        )

        novos = {
            tabela: dt
            for tabela, dt in pg.get_records(
                "SELECT tabela_origem, ultimo_modified_date FROM etl.controle_carga"
            )
        }

        etapas = [
            (T_EMPREGADO, contagens[0]),
            (T_DEPARTAMENTO, contagens[1]),
            (T_HIST_DEP, contagens[2]),
            (T_HIST_PAG, contagens[3]),
        ]
        for tabela, qtd in etapas:
            pg.run(
                """INSERT INTO etl.log_execucao
                       (dag_id, run_id, etapa, watermark_anterior, watermark_novo,
                        qtd_lidos, qtd_carregados)
                   VALUES (%s, %s, %s, %s, %s, %s, %s)""",
                parameters=(
                    DAG_ID, run_id, tabela,
                    datetime.fromisoformat(wm[tabela]), novos[tabela], qtd, qtd,
                ),
            )
        pg.run(
            """INSERT INTO etl.log_execucao
                   (dag_id, run_id, etapa, qtd_lidos, qtd_carregados)
               VALUES (%s, %s, %s, %s, %s)""",
            parameters=(
                DAG_ID, run_id, "dw.f_empregado_historico",
                validacao["lidos"], validacao["carregados"],
            ),
        )
        pg.run(
            """INSERT INTO etl.log_execucao
                   (dag_id, run_id, etapa, qtd_lidos, qtd_carregados)
               VALUES (%s, %s, %s, %s, %s)""",
            parameters=(DAG_ID, run_id, "empregados_no_delta", len(ids), len(ids)),
        )
        print(f"Controle atualizado: {novos}")

    fim = EmptyOperator(task_id="fim")

    # a orquestracao das tarefas quee serao executadas
    wm = ler_watermarks()
    ids = identificar_empregados_delta(wm)

    e_empregado = extrair_empregado(ids)
    e_departamento = extrair_departamento(wm)
    e_hist_dep = extrair_historico_departamento(ids)
    e_hist_pag = extrair_historico_pagamento(ids)

    validacao = validar_carga()
    controle = atualizar_controle_e_log(
        wm, ids, [e_empregado, e_departamento, e_hist_dep, e_hist_pag], validacao
    )

    inicio >> wm
    [e_empregado, e_departamento, e_hist_dep, e_hist_pag] >> fim_stage
    fim_stage >> [load_d_departamento, load_d_cargo, load_d_empregado] >> fim_dimensoes
    fim_dimensoes >> load_f_empregado_historico >> validacao >> controle >> fim


etl_rh_carga_incremental()
