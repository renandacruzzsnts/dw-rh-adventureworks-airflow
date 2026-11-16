-- K7 - Contratacoes por ano: a empresa continua contratando?
-- Usa a dimensao de calendario no papel de data de contratacao
-- (f.calendario_contratacao_id). Conta empregados distintos, nao linhas da fato.

\echo '--- K7.1 Contratacoes por ano'
SELECT c.ano,
       COUNT(DISTINCT f.empregado_id) AS contratacoes,
       ROUND(100.0 * COUNT(DISTINCT f.empregado_id)
             / SUM(COUNT(DISTINCT f.empregado_id)) OVER (), 1) AS pct,
       SUM(COUNT(DISTINCT f.empregado_id)) OVER (ORDER BY c.ano) AS acumulado
FROM dw.f_empregado_historico f
JOIN dw.d_calendario c ON c.id = f.calendario_contratacao_id
GROUP BY c.ano
ORDER BY c.ano;

\echo '--- K7.2 Contratacoes por departamento de contratacao (primeira passagem)'
WITH primeira AS (
    SELECT DISTINCT ON (f.empregado_id)
           f.empregado_id, f.departamento_id, f.calendario_contratacao_id
    FROM dw.f_empregado_historico f
    ORDER BY f.empregado_id, f.calendario_inicio_id, f.id
)
SELECT d.nome AS departamento_de_contratacao,
       COUNT(*)  AS contratacoes,
       MIN(c.ano) AS primeiro_ano,
       MAX(c.ano) AS ultimo_ano
FROM primeira p
JOIN dw.d_departamento d ON d.id = p.departamento_id
JOIN dw.d_calendario   c ON c.id = p.calendario_contratacao_id
GROUP BY d.nome
ORDER BY contratacoes DESC, d.nome;

\echo '--- K7.3 Primeira e ultima contratacao e tempo sem contratar (referencia 2014-12-31)'
SELECT MIN(c.data) AS primeira_contratacao,
       MAX(c.data) AS ultima_contratacao,
       ROUND((DATE '2014-12-31' - MAX(c.data)) / 30.44, 1) AS meses_sem_contratar
FROM dw.f_empregado_historico f
JOIN dw.d_calendario c ON c.id = f.calendario_contratacao_id;
