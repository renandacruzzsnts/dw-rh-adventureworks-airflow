

\echo '--- K9.1 Passivo estimado por departamento'
SELECT d.nome AS departamento,
       COUNT(*) AS empregados,
       SUM(f.horas_ferias) AS horas_acumuladas,
       ROUND(AVG(f.horas_ferias), 1) AS media_horas,
       ROUND(SUM(f.horas_ferias * f.rate_referencia), 2) AS passivo_estimado
FROM dw.f_empregado_historico f
JOIN dw.d_departamento d ON d.id = f.departamento_id
WHERE f.flag_registro_atual = 1
GROUP BY d.nome
ORDER BY passivo_estimado DESC, d.nome;

\echo '--- K9.2 Total geral'
SELECT COUNT(*) AS empregados,
       SUM(f.horas_ferias) AS horas_acumuladas,
       ROUND(SUM(f.horas_ferias * f.rate_referencia), 2) AS passivo_estimado
FROM dw.f_empregado_historico f
WHERE f.flag_registro_atual = 1;
