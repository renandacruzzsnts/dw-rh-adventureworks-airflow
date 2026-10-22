-- dw: f_empregado_historico
-- Grao: uma linha por passagem de um empregado por um departamento
-- (cada linha de HumanResources.EmployeeDepartmentHistory).
--
-- As medidas "_referencia", dias_desde_ultimo_reajuste, horas_* e as FKs de
-- escalao e faixa etaria sao retratos do empregado na data de referencia e se
-- repetem em todas as linhas dele: os KPIs que as usam devem filtrar
-- flag_registro_atual = 1 para nao contar o mesmo empregado duas vezes.
CREATE TABLE IF NOT EXISTS dw.f_empregado_historico (
    id                          BIGSERIAL PRIMARY KEY,

    -- chave natural (identifica o registro na origem)
    cod_empregado               INT      NOT NULL,
    cod_departamento            SMALLINT NOT NULL,
    cod_turno                   SMALLINT NOT NULL,   -- dimensao degenerada (ShiftID)
    data_inicio                 DATE     NOT NULL,

    -- chaves estrangeiras das dimensoes
    empregado_id                INT      NOT NULL REFERENCES dw.d_empregado (id),
    cargo_id                    INT      NOT NULL REFERENCES dw.d_cargo (id),
    departamento_id             INT      NOT NULL REFERENCES dw.d_departamento (id),
    escalao_id                  SMALLINT NOT NULL REFERENCES dw.d_escalao_salarial (id),  -- classifica rate_referencia
    faixa_etaria_id             SMALLINT NOT NULL REFERENCES dw.d_faixa_etaria (id),      -- classifica idade_referencia
    calendario_inicio_id        INT      NOT NULL REFERENCES dw.d_calendario (id),
    calendario_fim_id           INT      NOT NULL REFERENCES dw.d_calendario (id),        -- -1 = em aberto
    calendario_contratacao_id   INT      NOT NULL REFERENCES dw.d_calendario (id),

    -- medidas no inicio do registro
    rate_inicio                 NUMERIC(10,4) NOT NULL,
    idade_inicio                SMALLINT      NOT NULL,
    anos_exp_inicio             NUMERIC(5,2)  NOT NULL,

    -- medidas na data de referencia
    rate_referencia             NUMERIC(10,4) NOT NULL,
    idade_referencia            SMALLINT      NOT NULL,
    anos_exp_referencia         NUMERIC(5,2)  NOT NULL,

    -- tempo
    dias_no_departamento        INT NOT NULL CHECK (dias_no_departamento >= 0),
    dias_desde_ultimo_reajuste  INT NOT NULL CHECK (dias_desde_ultimo_reajuste >= 0),

    -- retratos da tabela Employee
    horas_ferias                SMALLINT NOT NULL,
    horas_licenca_doenca        SMALLINT NOT NULL,

    -- indicadores
    flag_atrito                 SMALLINT NOT NULL CHECK (flag_atrito IN (0, 1)),          -- EndDate preenchido
    flag_registro_atual         SMALLINT NOT NULL CHECK (flag_registro_atual IN (0, 1)),  -- EndDate nulo

    -- controle
    dt_modificacao_origem       TIMESTAMP,
    dt_carga                    TIMESTAMP DEFAULT now(),

    CONSTRAINT uq_f_empregado_historico
        UNIQUE (cod_empregado, cod_departamento, cod_turno, data_inicio),
    CONSTRAINT ck_f_atrito_ou_atual
        CHECK (flag_atrito + flag_registro_atual = 1)
);

CREATE INDEX IF NOT EXISTS ix_f_emp_hist_empregado    ON dw.f_empregado_historico (empregado_id);
CREATE INDEX IF NOT EXISTS ix_f_emp_hist_cargo        ON dw.f_empregado_historico (cargo_id);
CREATE INDEX IF NOT EXISTS ix_f_emp_hist_departamento ON dw.f_empregado_historico (departamento_id);
CREATE INDEX IF NOT EXISTS ix_f_emp_hist_cod_emp      ON dw.f_empregado_historico (cod_empregado);
CREATE INDEX IF NOT EXISTS ix_f_emp_hist_atual        ON dw.f_empregado_historico (flag_registro_atual);
