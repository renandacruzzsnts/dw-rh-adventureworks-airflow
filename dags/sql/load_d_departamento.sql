-- carga incremental: stage.stg_departamento -> dw.d_departamento (upsert)
INSERT INTO dw.d_departamento (cod_departamento, nome, grupo, dt_modificacao_origem)
SELECT department_id, name, group_name, modified_date
FROM stage.stg_departamento
ON CONFLICT (cod_departamento) DO UPDATE
SET nome                  = EXCLUDED.nome,
    grupo                 = EXCLUDED.grupo,
    dt_modificacao_origem = EXCLUDED.dt_modificacao_origem,
    dt_carga              = now();
