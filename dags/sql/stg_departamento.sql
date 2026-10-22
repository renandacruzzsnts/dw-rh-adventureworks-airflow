-- stage: departamento (origem: HumanResources.Department)
DROP TABLE IF EXISTS stage.stg_departamento;
CREATE TABLE stage.stg_departamento (
    department_id   SMALLINT,
    name            VARCHAR(50),
    group_name      VARCHAR(50),
    modified_date   TIMESTAMP,
    dt_extracao     TIMESTAMP DEFAULT now()
);
