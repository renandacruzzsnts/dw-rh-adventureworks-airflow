-- dw: d_departamento (origem: HumanResources.Department)
CREATE TABLE IF NOT EXISTS dw.d_departamento (
    id                     SERIAL PRIMARY KEY,
    cod_departamento       SMALLINT NOT NULL UNIQUE,   -- DepartmentID
    nome                   VARCHAR(50),
    grupo                  VARCHAR(50),
    dt_modificacao_origem  TIMESTAMP,
    dt_carga               TIMESTAMP DEFAULT now()
);
