-- stage: historico de departamento (origem: HumanResources.EmployeeDepartmentHistory)
DROP TABLE IF EXISTS stage.stg_historico_departamento;
CREATE TABLE stage.stg_historico_departamento (
    business_entity_id  INT,
    department_id       SMALLINT,
    shift_id            SMALLINT,
    start_date          DATE,
    end_date            DATE,
    modified_date       TIMESTAMP,
    dt_extracao         TIMESTAMP DEFAULT now()
);
