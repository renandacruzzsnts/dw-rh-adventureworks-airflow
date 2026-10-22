

\echo '--- K5.1 Custo por hora por departamento'
SELECT d.nome AS departamento,
       COUNT(*) AS empregados,
       ROUND(SUM(f.rate_referencia), 2) AS custo_hora_total,
       ROUND(AVG(f.rate_referencia), 2) AS rate_medio,
       ROUND((percentile_cont(0.5) WITHIN GROUP (ORDER BY f.rate_referencia))::numeric, 2) AS rate_mediano
FROM dw.f_empregado_historico f
JOIN dw.d_departamento d ON d.id = f.departamento_id
WHERE f.flag_registro_atual = 1
GROUP BY d.nome
ORDER BY custo_hora_total DESC, d.nome;

\echo '--- K5.2 Distribuicao por escalao salarial'
SELECT es.nome AS escalao,
       COUNT(f.id) AS empregados,
       ROUND(100.0 * COUNT(f.id) / SUM(COUNT(f.id)) OVER (), 1) AS pct
FROM dw.d_escalao_salarial es
LEFT JOIN dw.f_empregado_historico f
       ON f.escalao_id = es.id AND f.flag_registro_atual = 1
GROUP BY es.nome, es.ordem
ORDER BY es.ordem;

\echo '--- K5.3 Total geral'
SELECT COUNT(*) AS empregados,
       ROUND(SUM(f.rate_referencia), 2) AS custo_hora_total,
       ROUND(AVG(f.rate_referencia), 2) AS rate_medio,
       ROUND((percentile_cont(0.5) WITHIN GROUP (ORDER BY f.rate_referencia))::numeric, 2) AS rate_mediano
FROM dw.f_empregado_historico f
WHERE f.flag_registro_atual = 1;
