

\echo '--- K10.1 Media geral de horas de licenca-doenca'
SELECT ROUND(AVG(f.horas_licenca_doenca), 1) AS media_horas,
       MIN(f.horas_licenca_doenca) AS minimo,
       MAX(f.horas_licenca_doenca) AS maximo
FROM dw.f_empregado_historico f
WHERE f.flag_registro_atual = 1;

\echo '--- K10.2 Horas de licenca-doenca por departamento'
WITH geral AS (
    SELECT AVG(horas_licenca_doenca) AS media
    FROM dw.f_empregado_historico
    WHERE flag_registro_atual = 1
)
SELECT d.nome AS departamento,
       COUNT(*) AS empregados,
       ROUND(AVG(f.horas_licenca_doenca), 1) AS media_horas,
       MIN(f.horas_licenca_doenca) AS minimo,
       MAX(f.horas_licenca_doenca) AS maximo,
       ROUND(AVG(f.horas_licenca_doenca) - g.media, 1) AS diferenca_vs_media_geral
FROM dw.f_empregado_historico f
JOIN dw.d_departamento d ON d.id = f.departamento_id
CROSS JOIN geral g
WHERE f.flag_registro_atual = 1
GROUP BY d.nome, g.media
ORDER BY media_horas DESC, d.nome;
