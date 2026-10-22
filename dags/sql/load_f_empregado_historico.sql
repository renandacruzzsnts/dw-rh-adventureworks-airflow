-- carga incremental com rotacao: remove e recarrega TODOS os registros dos
-- empregados que vieram no delta (o stage traz o historico completo deles).
-- Data de referencia: parametro da DAG (params.data_referencia).
DELETE FROM dw.f_empregado_historico
WHERE cod_empregado IN (SELECT business_entity_id FROM stage.stg_empregado);

INSERT INTO dw.f_empregado_historico (
    cod_empregado, cod_departamento, cod_turno, data_inicio,
    empregado_id, cargo_id, departamento_id, escalao_id, faixa_etaria_id,
    calendario_inicio_id, calendario_fim_id, calendario_contratacao_id,
    rate_inicio, idade_inicio, anos_exp_inicio,
    rate_referencia, idade_referencia, anos_exp_referencia,
    dias_no_departamento, dias_desde_ultimo_reajuste,
    horas_ferias, horas_licenca_doenca,
    flag_atrito, flag_registro_atual, dt_modificacao_origem
)
WITH param AS (
    SELECT DATE '{{ params.data_referencia }}' AS dt_ref
),
pag_ref AS (   -- rate vigente na data de referencia
    SELECT DISTINCT ON (p.business_entity_id)
           p.business_entity_id, p.rate, p.rate_change_date::date AS dt_reajuste
    FROM stage.stg_historico_pagamento p
    CROSS JOIN param
    WHERE p.rate_change_date::date <= param.dt_ref
    ORDER BY p.business_entity_id, p.rate_change_date DESC
),
pag_prim AS (  -- primeiro rate do empregado (plano B)
    SELECT DISTINCT ON (p.business_entity_id)
           p.business_entity_id, p.rate, p.rate_change_date::date AS dt_reajuste
    FROM stage.stg_historico_pagamento p
    ORDER BY p.business_entity_id, p.rate_change_date ASC
),
base AS (
    SELECT h.business_entity_id, h.department_id, h.shift_id,
           h.start_date, h.end_date, h.modified_date,
           e.job_title, e.birth_date, e.hire_date,
           e.vacation_hours, e.sick_leave_hours,
           COALESCE(ini.rate, pp.rate)               AS rate_inicio,
           COALESCE(pr.rate, pp.rate)                AS rate_ref,
           COALESCE(pr.dt_reajuste, pp.dt_reajuste)  AS dt_ult_reajuste,
           param.dt_ref
    FROM stage.stg_historico_departamento h
    JOIN stage.stg_empregado e ON e.business_entity_id = h.business_entity_id
    CROSS JOIN param
    LEFT JOIN pag_ref  pr ON pr.business_entity_id = h.business_entity_id
    LEFT JOIN pag_prim pp ON pp.business_entity_id = h.business_entity_id
    LEFT JOIN LATERAL (   -- rate vigente na data de inicio do registro
        SELECT p.rate
        FROM stage.stg_historico_pagamento p
        WHERE p.business_entity_id = h.business_entity_id
          AND p.rate_change_date::date <= h.start_date
        ORDER BY p.rate_change_date DESC
        LIMIT 1
    ) ini ON TRUE
),
calc AS (
    SELECT b.*,
           EXTRACT(YEAR FROM age(b.start_date, b.birth_date))::INT AS idade_ini,
           EXTRACT(YEAR FROM age(b.dt_ref,     b.birth_date))::INT AS idade_ref,
           GREATEST(0, ROUND(((b.start_date - b.hire_date) / 365.25)::NUMERIC, 2)) AS exp_ini,
           GREATEST(0, ROUND(((b.dt_ref     - b.hire_date) / 365.25)::NUMERIC, 2)) AS exp_ref
    FROM base b
)
SELECT
    c.business_entity_id, c.department_id, c.shift_id, c.start_date,
    de.id, dc.id, dd.id, es.id, fe.id,
    ci.id, cf.id, cc.id,
    c.rate_inicio, c.idade_ini, c.exp_ini,
    c.rate_ref, c.idade_ref, c.exp_ref,
    GREATEST(0, COALESCE(c.end_date, c.dt_ref) - c.start_date),
    GREATEST(0, c.dt_ref - c.dt_ult_reajuste),
    c.vacation_hours, c.sick_leave_hours,
    CASE WHEN c.end_date IS NULL THEN 0 ELSE 1 END,
    CASE WHEN c.end_date IS NULL THEN 1 ELSE 0 END,
    c.modified_date
FROM calc c
JOIN dw.d_empregado         de ON de.cod_empregado = c.business_entity_id
JOIN dw.d_cargo             dc ON dc.titulo = c.job_title
JOIN dw.d_departamento      dd ON dd.cod_departamento = c.department_id
JOIN dw.d_escalao_salarial  es ON c.rate_ref > es.rate_minimo
                              AND (es.rate_maximo IS NULL OR c.rate_ref <= es.rate_maximo)
JOIN dw.d_faixa_etaria      fe ON c.idade_ref >= fe.idade_minima
                              AND (fe.idade_maxima IS NULL OR c.idade_ref <= fe.idade_maxima)
JOIN dw.d_calendario        ci ON ci.data = c.start_date
JOIN dw.d_calendario        cf ON cf.data = COALESCE(c.end_date, DATE '9999-12-31')
JOIN dw.d_calendario        cc ON cc.data = c.hire_date;
