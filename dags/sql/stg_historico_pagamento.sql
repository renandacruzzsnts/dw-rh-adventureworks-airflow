-- stage: historico de pagamento (origem: HumanResources.EmployeePayHistory)
DROP TABLE IF EXISTS stage.stg_historico_pagamento;
CREATE TABLE stage.stg_historico_pagamento (
    business_entity_id  INT,
    rate_change_date    TIMESTAMP,
    rate                NUMERIC(19,4),
    pay_frequency       SMALLINT,
    modified_date       TIMESTAMP,
    dt_extracao         TIMESTAMP DEFAULT now()
);
