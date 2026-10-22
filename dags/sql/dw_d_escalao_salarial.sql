-- dw: d_escalao_salarial (seed fixo)
-- regra de enquadramento: rate_minimo < rate <= rate_maximo (maximo NULL = sem limite)
CREATE TABLE IF NOT EXISTS dw.d_escalao_salarial (
    id           SMALLINT PRIMARY KEY,
    nome         VARCHAR(30) NOT NULL UNIQUE,
    rate_minimo  NUMERIC(10,4) NOT NULL,
    rate_maximo  NUMERIC(10,4),
    ordem        SMALLINT NOT NULL
);
