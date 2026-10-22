-- carga incremental: stage.stg_empregado -> dw.d_empregado (upsert)
INSERT INTO dw.d_empregado (
    cod_empregado, genero, estado_civil, data_nascimento, data_contratacao,
    flag_ativo, flag_assalariado, dt_modificacao_origem
)
SELECT
    business_entity_id, gender, marital_status, birth_date, hire_date,
    CASE WHEN current_flag  THEN 1 ELSE 0 END,
    CASE WHEN salaried_flag THEN 1 ELSE 0 END,
    modified_date
FROM stage.stg_empregado
ON CONFLICT (cod_empregado) DO UPDATE
SET genero                = EXCLUDED.genero,
    estado_civil          = EXCLUDED.estado_civil,
    data_nascimento       = EXCLUDED.data_nascimento,
    data_contratacao      = EXCLUDED.data_contratacao,
    flag_ativo            = EXCLUDED.flag_ativo,
    flag_assalariado      = EXCLUDED.flag_assalariado,
    dt_modificacao_origem = EXCLUDED.dt_modificacao_origem,
    dt_carga              = now();
