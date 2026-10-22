-- dw: d_cargo (origem: HumanResources.Employee.JobTitle, valores distintos)
CREATE TABLE IF NOT EXISTS dw.d_cargo (
    id        SERIAL PRIMARY KEY,
    titulo    VARCHAR(100) NOT NULL UNIQUE,
    dt_carga  TIMESTAMP DEFAULT now()
);
