

\echo '--- K1.1 Total de empregados (historico) e empregados ativos (CurrentFlag = 1)'
SELECT COUNT(DISTINCT f.empregado_id)                                   AS total_empregados,
       COUNT(DISTINCT f.empregado_id) FILTER (WHERE e.flag_ativo = 1)   AS empregados_ativos
FROM dw.f_empregado_historico f
JOIN dw.d_empregado e ON e.id = f.empregado_id;

\echo '--- K1.2 Headcount por departamento'
SELECT d.nome  AS departamento,
       d.grupo AS grupo,
       COUNT(*) AS empregados,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM dw.f_empregado_historico f
JOIN dw.d_departamento d ON d.id = f.departamento_id
WHERE f.flag_registro_atual = 1
GROUP BY d.nome, d.grupo
ORDER BY empregados DESC, d.nome;

\echo '--- K1.3 Headcount por grupo de departamento'
SELECT d.grupo AS grupo,
       COUNT(*) AS empregados,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM dw.f_empregado_historico f
JOIN dw.d_departamento d ON d.id = f.departamento_id
WHERE f.flag_registro_atual = 1
GROUP BY d.grupo
ORDER BY empregados DESC, d.grupo;
