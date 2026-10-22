

\echo '--- K7.1 Resumo'
SELECT ROUND(AVG(f.dias_desde_ultimo_reajuste) / 365.25, 2) AS anos_medios_desde_reajuste,
       ROUND(MAX(f.dias_desde_ultimo_reajuste) / 365.25, 2) AS maior_defasagem_anos,
       COUNT(*) FILTER (WHERE f.dias_desde_ultimo_reajuste > 1461) AS sem_reajuste_ha_mais_de_4_anos,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.dias_desde_ultimo_reajuste > 1461) / COUNT(*), 1) AS pct
FROM dw.f_empregado_historico f
WHERE f.flag_registro_atual = 1;

\echo '--- K7.2 Distribuicao do tempo desde o ultimo reajuste'
SELECT CASE WHEN f.dias_desde_ultimo_reajuste < 365  THEN '1) Menos de 1 ano'
            WHEN f.dias_desde_ultimo_reajuste < 730  THEN '2) 1 a 2 anos'
            WHEN f.dias_desde_ultimo_reajuste < 1461 THEN '3) 2 a 4 anos'
            ELSE '4) 4 anos ou mais' END AS tempo_desde_reajuste,
       COUNT(*) AS empregados,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM dw.f_empregado_historico f
WHERE f.flag_registro_atual = 1
GROUP BY 1
ORDER BY 1;

\echo '--- K7.3 Defasagem por departamento'
SELECT d.nome AS departamento,
       COUNT(*) AS empregados,
       ROUND(AVG(f.dias_desde_ultimo_reajuste) / 365.25, 2) AS anos_medios,
       COUNT(*) FILTER (WHERE f.dias_desde_ultimo_reajuste > 1461) AS sem_reajuste_ha_mais_de_4_anos
FROM dw.f_empregado_historico f
JOIN dw.d_departamento d ON d.id = f.departamento_id
WHERE f.flag_registro_atual = 1
GROUP BY d.nome
ORDER BY anos_medios DESC, d.nome;
