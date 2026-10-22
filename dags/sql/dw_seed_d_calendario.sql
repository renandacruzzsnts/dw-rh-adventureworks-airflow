-- seed: membro "Em aberto" (usado quando EndDate e nulo)
INSERT INTO dw.d_calendario (id, data, dia, mes, ano, mes_ano, nome_mes, trimestre, nome_dia_semana, dia_semana)
VALUES (-1, DATE '9999-12-31', 31, 12, 9999, 999912, 'Em aberto', 4, 'Em aberto', 0)
ON CONFLICT (id) DO NOTHING;

-- seed: calendario de 2000-01-01 a 2030-12-31
INSERT INTO dw.d_calendario (id, data, dia, mes, ano, mes_ano, nome_mes, trimestre, nome_dia_semana, dia_semana)
SELECT
    to_char(d, 'YYYYMMDD')::INT,
    d::DATE,
    EXTRACT(DAY FROM d)::SMALLINT,
    EXTRACT(MONTH FROM d)::SMALLINT,
    EXTRACT(YEAR FROM d)::SMALLINT,
    to_char(d, 'YYYYMM')::INT,
    (ARRAY['Janeiro','Fevereiro','Março','Abril','Maio','Junho',
           'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'])[EXTRACT(MONTH FROM d)::INT],
    EXTRACT(QUARTER FROM d)::SMALLINT,
    (ARRAY['Segunda','Terça','Quarta','Quinta','Sexta','Sábado','Domingo'])[EXTRACT(ISODOW FROM d)::INT],
    EXTRACT(ISODOW FROM d)::SMALLINT
FROM generate_series('2000-01-01'::TIMESTAMP, '2030-12-31'::TIMESTAMP, INTERVAL '1 day') AS g(d)
ON CONFLICT (id) DO NOTHING;
