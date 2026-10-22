-- dw: d_empregado (origem: HumanResources.Employee)
CREATE TABLE IF NOT EXISTS dw.d_empregado (
    id                     SERIAL PRIMARY KEY,
    cod_empregado          INT NOT NULL UNIQUE,   -- BusinessEntityID
    genero                 CHAR(1),
    estado_civil           CHAR(1),
    data_nascimento        DATE,
    data_contratacao       DATE,
    flag_ativo             SMALLINT CHECK (flag_ativo IN (0, 1)),        -- CurrentFlag
    flag_assalariado       SMALLINT CHECK (flag_assalariado IN (0, 1)),  -- SalariedFlag
    dt_modificacao_origem  TIMESTAMP,
    dt_carga               TIMESTAMP DEFAULT now()
);
