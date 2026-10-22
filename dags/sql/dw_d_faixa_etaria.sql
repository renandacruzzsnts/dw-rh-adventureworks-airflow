-- dw: d_faixa_etaria (seed fixo)
-- regra: idade_minima <= idade <= idade_maxima (maxima NULL = sem limite)
CREATE TABLE IF NOT EXISTS dw.d_faixa_etaria (
    id            SMALLINT PRIMARY KEY,
    nome          VARCHAR(10) NOT NULL UNIQUE,
    idade_minima  SMALLINT NOT NULL,
    idade_maxima  SMALLINT,
    ordem         SMALLINT NOT NULL
);
