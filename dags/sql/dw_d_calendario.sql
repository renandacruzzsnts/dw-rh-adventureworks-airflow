-- dw: d_calendario (id no formato AAAAMMDD; -1 = "Em aberto", usado quando EndDate e nulo)
CREATE TABLE IF NOT EXISTS dw.d_calendario (
    id               INT PRIMARY KEY,
    data             DATE NOT NULL UNIQUE,
    dia              SMALLINT,
    mes              SMALLINT,
    ano              SMALLINT,
    mes_ano          INT,
    nome_mes         VARCHAR(15),
    trimestre        SMALLINT,
    nome_dia_semana  VARCHAR(15),
    dia_semana       SMALLINT
);
