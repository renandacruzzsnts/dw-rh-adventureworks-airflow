# DW de RH - AdventureWorks com Airflow e PostgreSQL

Projeto individual (Unisales): Data Warehouse em **star schema** com **ETL incremental** orquestrada pelo Apache Airflow 3.3.1.

**Fluxo:** SQL Server (AdventureWorks2025, restaurado do `.bak`) -> Airflow -> PostgreSQL 16 (`stage` -> `dw`).

Estrutura baseada no exemplo da disciplina (`aula.etl.2`): DAGs de construcao do stage e do DW (`@once`), DDLs em `dags/sql/` e `EmptyOperator` como marcador entre as etapas.

## Pre-requisitos

- Docker Desktop com pelo menos 6 GB de memoria disponivel (SQL Server + Airflow + Postgres).
- Arquivo `AdventureWorks2025.bak` dentro da pasta `backup/` (fora do Git).

## Inicializacao

1. Copie `.env.example` para `.env` e preencha `AIRFLOW_FERNET_KEY`, `AIRFLOW_API_SECRET_KEY` e `AIRFLOW_JWT_SECRET`:

	```powershell
	docker run --rm apache/airflow:3.3.1 python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
	docker run --rm apache/airflow:3.3.1 python -c "import secrets; print(secrets.token_urlsafe(48))"
	```

	Mantenha usuario e senha das linhas `AIRFLOW_CONN_*` iguais aos de `POSTGRES_*` e `MSSQL_SA_PASSWORD`.

2. Suba o ambiente:

	```powershell
	docker compose up airflow-init
	docker compose up -d
	```

3. Restaure o backup no SQL Server:

	```powershell
	.\scripts\restaurar_adventureworks.ps1
	```

4. Crie o banco `dw` no PostgreSQL (so e necessario se o volume do Postgres ja existia; em volume novo a pasta `initdb/` faz isso sozinha):

	```powershell
	.\scripts\criar_banco_dw.ps1
	```

5. Abra `http://localhost:8080` e entre com as credenciais definidas em `.env`.

## Ordem de execucao das DAGs

As DAGs nascem pausadas. Ative e dispare (**Trigger**) na ordem:

| # | DAG | O que faz |
|---|---|---|
| 1 | `teste_conexoes` | Valida as conexoes com o SQL Server e o PostgreSQL |
| 2 | `etl_build_stage` | Cria os schemas e as tabelas de stage |
| 3 | `etl_build_dw` | Cria dimensoes, fato, seeds e a tabela de controle da carga |
| 4 | `etl_rh_carga_incremental` | Extrai o delta da origem, carrega o stage e o DW (a 1a execucao e a carga completa) |
| 5 | `simular_mudancas_origem` | Altera dados no SQL Server para demonstrar a carga incremental |
| 6 | `etl_rh_carga_incremental` | Roda de novo: processa apenas os empregados alterados |

## Estrategia de ETL incremental

- **Controle:** `etl.controle_carga` guarda o ultimo `ModifiedDate` processado de cada tabela de origem (watermark). Comeca em `1900-01-01`, entao a primeira execucao carrega tudo.
- **Delta:** sao considerados os empregados com qualquer registro novo ou alterado (`Employee`, `EmployeeDepartmentHistory` ou `EmployeePayHistory`).
- **Stage:** recebe o historico completo apenas desses empregados (e os departamentos alterados) e e esvaziado a cada execucao.
- **Dimensoes:** upsert (`INSERT ... ON CONFLICT DO UPDATE`).
- **Fato:** rotacao (delete + insert) dos registros dos empregados do delta, como na estrategia "incremento controlado por data com rotacao" da disciplina.
- **Qualidade:** a task `validar_carga` compara as linhas do stage com as da fato e falha se houver diferenca.
- **Watermark:** so avanca depois de a fato carregar; `etl.log_execucao` registra quantos registros cada execucao processou (evidencia do incremental).

A data de referencia dos KPIs de estado atual (idade, experiencia, rate vigente) e o parametro `data_referencia` da DAG (padrao `2014-12-31`).

## Estrutura de pastas

```text
.
|-- analise/        # SQL de analise da origem (profiling)
|-- backup/         # AdventureWorks2025.bak (fora do Git)
|-- config/
|-- dags/
|   |-- sql/        # DDLs (stage e DW), seeds e cargas usados pelas DAGs
|   |-- etl_build_schema_stg.py
|   |-- etl_build_schema_dw.py
|   |-- etl_rh_carga_incremental.py
|   |-- simular_mudancas_origem.py
|   `-- teste_conexoes.py
|-- data/
|-- docs/           # diagramas, dicionario de dados, documentacao
|-- initdb/         # cria o banco dw no Postgres (volume novo)
|-- kpis/           # SQL dos 10 indicadores
|-- logs/
|-- plugins/
|-- scripts/        # restauracao do .bak e criacao do banco dw
|-- docker-compose.yml
|-- .env  /  .env.example
`-- README.md
```

## Comandos uteis

```powershell
docker compose ps
docker compose logs -f airflow-scheduler
docker compose stop sqlserver
docker compose down
```

O ambiente usa `LocalExecutor`, sem Redis nem workers separados. As credenciais deste projeto sao apenas de desenvolvimento local.
