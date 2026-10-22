-- K6 - Equidade salarial: a remuneracao e justa entre generos?
-- A comparacao confiavel e dentro do mesmo cargo (K6.2).

\echo '--- K6.1 Composicao e remuneracao por genero'
SELECT e.genero,
       COUNT(*) AS empregados,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct,
       ROUND(AVG(f.rate_referencia), 2) AS rate_medio,
       ROUND((percentile_cont(0.5) WITHIN GROUP (ORDER BY f.rate_referencia))::numeric, 2) AS rate_mediano
FROM dw.f_empregado_historico f
JOIN dw.d_empregado e ON e.id = f.empregado_id
WHERE f.flag_registro_atual = 1
GROUP BY e.genero
ORDER BY e.genero;

\echo '--- K6.2 Cargos com homens e mulheres (comparaveis)'
SELECT c.titulo AS cargo,
       COUNT(*) FILTER (WHERE e.genero = 'F') AS qtd_f,
       COUNT(*) FILTER (WHERE e.genero = 'M') AS qtd_m,
       ROUND(AVG(f.rate_referencia) FILTER (WHERE e.genero = 'F'), 2) AS rate_medio_f,
       ROUND(AVG(f.rate_referencia) FILTER (WHERE e.genero = 'M'), 2) AS rate_medio_m,
       ROUND(AVG(f.rate_referencia) FILTER (WHERE e.genero = 'F')
           - AVG(f.rate_referencia) FILTER (WHERE e.genero = 'M'), 2) AS diferenca_f_menos_m
FROM dw.f_empregado_historico f
JOIN dw.d_empregado e ON e.id = f.empregado_id
JOIN dw.d_cargo     c ON c.id = f.cargo_id
WHERE f.flag_registro_atual = 1
GROUP BY c.titulo
HAVING COUNT(*) FILTER (WHERE e.genero = 'F') > 0
   AND COUNT(*) FILTER (WHERE e.genero = 'M') > 0
ORDER BY c.titulo;

\echo '--- K6.3 Composicao de genero por departamento'
SELECT d.nome AS departamento,
       COUNT(*) FILTER (WHERE e.genero = 'F') AS mulheres,
       COUNT(*) FILTER (WHERE e.genero = 'M') AS homens,
       ROUND(100.0 * COUNT(*) FILTER (WHERE e.genero = 'F') / COUNT(*), 1) AS pct_mulheres
FROM dw.f_empregado_historico f
JOIN dw.d_empregado    e ON e.id = f.empregado_id
JOIN dw.d_departamento d ON d.id = f.departamento_id
WHERE f.flag_registro_atual = 1
GROUP BY d.nome
ORDER BY d.nome;
