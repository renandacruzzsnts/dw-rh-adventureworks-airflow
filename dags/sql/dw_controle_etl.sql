-- etl: controle da carga incremental (um watermark por tabela de origem)
CREATE TABLE IF NOT EXISTS etl.controle_carga (
    tabela_origem         VARCHAR(100) PRIMARY KEY,
    ultimo_modified_date  TIMESTAMP NOT NULL DEFAULT '1900-01-01',
    dt_ultima_execucao    TIMESTAMP,
    status                VARCHAR(20)
);

-- etl: log de execucao (evidencia de que a carga incremental processa so o delta)
CREATE TABLE IF NOT EXISTS etl.log_execucao (
    id                  BIGSERIAL PRIMARY KEY,
    dag_id              VARCHAR(100),
    run_id              VARCHAR(200),
    etapa               VARCHAR(100),
    watermark_anterior  TIMESTAMP,
    watermark_novo      TIMESTAMP,
    qtd_lidos           INT,
    qtd_carregados      INT,
    dt_execucao         TIMESTAMP DEFAULT now()
);

-- watermark inicial: a primeira execucao equivale a uma carga completa
INSERT INTO etl.controle_carga (tabela_origem) VALUES
    ('HumanResources.Employee'),
    ('HumanResources.Department'),
    ('HumanResources.EmployeeDepartmentHistory'),
    ('HumanResources.EmployeePayHistory')
ON CONFLICT (tabela_origem) DO NOTHING;
