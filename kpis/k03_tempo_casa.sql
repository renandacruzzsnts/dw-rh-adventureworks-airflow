
\echo '--- K3.1 Experiencia media dos empregados atuais (anos)'
SELECT ROUND(AVG(f.anos_exp_referencia), 2) AS experiencia_media_anos,
       MIN(f.anos_exp_referencia)           AS minimo,
       MAX(f.anos_exp_referencia)           AS maximo
FROM dw.f_empregado_historico f
WHERE f.flag_registro_atual = 1;

\echo '--- K3.2 Distribuicao por tempo de casa'
SELECT CASE WHEN f.anos_exp_referencia < 2 THEN '1) Menos de 2 anos'
            WHEN f.anos_exp_referencia < 4 THEN '2) 2 a 4 anos'
            WHEN f.anos_exp_referencia < 6 THEN '3) 4 a 6 anos'
            ELSE '4) 6 anos ou mais' END AS tempo_de_casa,
       COUNT(*) AS empregados,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM dw.f_empregado_historico f
WHERE f.flag_registro_atual = 1
GROUP BY 1
ORDER BY 1;

\echo '--- K3.3 Experiencia media por departamento (anos)'
SELECT d.nome AS departamento,
       COUNT(*) AS empregados,
       ROUND(AVG(f.anos_exp_referencia), 2) AS experiencia_media_anos
FROM dw.f_empregado_historico f
JOIN dw.d_departamento d ON d.id = f.departamento_id
WHERE f.flag_registro_atual = 1
GROUP BY d.nome
ORDER BY experiencia_media_anos DESC, d.nome;
