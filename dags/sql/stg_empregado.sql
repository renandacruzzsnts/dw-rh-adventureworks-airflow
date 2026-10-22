-- stage: empregado (origem: HumanResources.Employee)
DROP TABLE IF EXISTS stage.stg_empregado;
CREATE TABLE stage.stg_empregado (
    business_entity_id  INT,
    job_title           VARCHAR(50),
    birth_date          DATE,
    marital_status      CHAR(1),
    gender              CHAR(1),
    hire_date           DATE,
    salaried_flag       BOOLEAN,
    vacation_hours      SMALLINT,
    sick_leave_hours    SMALLINT,
    current_flag        BOOLEAN,
    modified_date       TIMESTAMP,
    dt_extracao         TIMESTAMP DEFAULT now()
);
