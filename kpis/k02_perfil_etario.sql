-- K2 - Perfil etario: quando o conhecimento comeca a sair?
-- Idade calculada na data de referencia (parametro da DAG, padrao 31/12/2014).

\echo '--- K2.1 Idade media dos empregados atuais'
SELECT ROUND(AVG(f.idade_referencia), 1) AS idade_media,
       MIN(f.idade_referencia)           AS idade_minima,
       MAX(f.idade_referencia)           AS idade_maxima,
       COUNT(*)                          AS empregados
FROM dw.f_empregado_historico f
WHERE f.flag_registro_atual = 1;

\echo '--- K2.2 Distribuicao por faixa etaria'
SELECT fe.nome AS faixa_etaria,
       COUNT(f.id) AS empregados,
       ROUND(100.0 * COUNT(f.id) / SUM(COUNT(f.id)) OVER (), 1) AS pct
FROM dw.d_faixa_etaria fe
LEFT JOIN dw.f_empregado_historico f
       ON f.faixa_etaria_id = fe.id AND f.flag_registro_atual = 1
GROUP BY fe.nome, fe.ordem
ORDER BY fe.ordem;

\echo '--- K2.3 Risco de sucessao: empregados com 56+ por departamento'
SELECT d.nome AS departamento,
       COUNT(*) AS empregados,
       COUNT(*) FILTER (WHERE f.idade_referencia >= 56) AS com_56_mais,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.idade_referencia >= 56) / COUNT(*), 1) AS pct_56_mais
FROM dw.f_empregado_historico f
JOIN dw.d_departamento d ON d.id = f.departamento_id
WHERE f.flag_registro_atual = 1
GROUP BY d.nome
ORDER BY com_56_mais DESC, pct_56_mais DESC, d.nome;
