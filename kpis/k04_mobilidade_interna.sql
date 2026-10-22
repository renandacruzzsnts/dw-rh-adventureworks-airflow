

\echo '--- K4.1 Saidas de departamento e taxa de atrito'
SELECT SUM(f.flag_atrito)                                         AS saidas,
       COUNT(*)                                                   AS registros_de_alocacao,
       ROUND(100.0 * SUM(f.flag_atrito) / COUNT(*), 2)            AS taxa_atrito_pct,
       COUNT(DISTINCT f.empregado_id) FILTER (WHERE f.flag_atrito = 1) AS empregados_que_mudaram,
       ROUND(AVG(f.dias_no_departamento) FILTER (WHERE f.flag_atrito = 1) / 365.25, 2) AS anos_medios_ate_mudar
FROM dw.f_empregado_historico f;

\echo '--- K4.2 Saidas por departamento (departamento deixado)'
SELECT d.nome AS departamento_deixado,
       COUNT(*) AS registros,
       SUM(f.flag_atrito) AS saidas,
       ROUND(100.0 * SUM(f.flag_atrito) / COUNT(*), 1) AS taxa_pct
FROM dw.f_empregado_historico f
JOIN dw.d_departamento d ON d.id = f.departamento_id
GROUP BY d.nome
ORDER BY saidas DESC, registros DESC, d.nome;

\echo '--- K4.3 Detalhe das saidas'
SELECT f.cod_empregado,
       d.nome  AS departamento_deixado,
       ci.data AS inicio,
       cf.data AS fim,
       f.dias_no_departamento
FROM dw.f_empregado_historico f
JOIN dw.d_departamento d ON d.id = f.departamento_id
JOIN dw.d_calendario  ci ON ci.id = f.calendario_inicio_id
JOIN dw.d_calendario  cf ON cf.id = f.calendario_fim_id
WHERE f.flag_atrito = 1
ORDER BY cf.data, f.cod_empregado;
