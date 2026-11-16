-- Validacoes cruzadas: as somas dos KPIs precisam bater com os totais.
-- Valores esperados (296, 290 e 6) vem do profiling da origem sem alteracoes.
\echo '--- Validacoes cruzadas'
WITH base AS (
    SELECT * FROM dw.f_empregado_historico WHERE flag_registro_atual = 1
),
checks AS (
    SELECT 'Registros na fato (origem: 296)' AS verificacao,
           296::bigint AS esperado,
           (SELECT COUNT(*) FROM dw.f_empregado_historico)::numeric AS obtido
    UNION ALL
    SELECT 'Registros atuais = total de empregados (290)', 290,
           (SELECT COUNT(*) FROM base)
    UNION ALL
    SELECT 'Saidas de departamento (6)', 6,
           (SELECT COALESCE(SUM(flag_atrito), 0) FROM dw.f_empregado_historico)
    UNION ALL
    SELECT 'Um registro atual por empregado',
           (SELECT COUNT(DISTINCT empregado_id) FROM dw.f_empregado_historico),
           (SELECT COUNT(DISTINCT empregado_id) FROM base)
    UNION ALL
    SELECT 'K1: soma do headcount por departamento = empregados atuais',
           (SELECT COUNT(*) FROM base),
           (SELECT SUM(n) FROM (SELECT COUNT(*) AS n FROM base GROUP BY departamento_id) t)
    UNION ALL
    SELECT 'K2: soma por faixa etaria = empregados atuais',
           (SELECT COUNT(*) FROM base),
           (SELECT COUNT(*) FROM base b JOIN dw.d_faixa_etaria fe ON fe.id = b.faixa_etaria_id)
    UNION ALL
    SELECT 'K4: soma das saidas por departamento = total de saidas',
           (SELECT COALESCE(SUM(flag_atrito), 0) FROM dw.f_empregado_historico),
           (SELECT COALESCE(SUM(s), 0) FROM (SELECT SUM(flag_atrito) AS s
                                               FROM dw.f_empregado_historico
                                              GROUP BY departamento_id) t)
    UNION ALL
    SELECT 'K5: soma por escalao salarial = empregados atuais',
           (SELECT COUNT(*) FROM base),
           (SELECT COUNT(*) FROM base b JOIN dw.d_escalao_salarial es ON es.id = b.escalao_id)
    UNION ALL
    SELECT 'K7: soma das contratacoes por ano = total de empregados',
           (SELECT COUNT(DISTINCT empregado_id) FROM dw.f_empregado_historico),
           (SELECT SUM(n) FROM (SELECT COUNT(DISTINCT f.empregado_id) AS n
                                  FROM dw.f_empregado_historico f
                                  JOIN dw.d_calendario c ON c.id = f.calendario_contratacao_id
                                 GROUP BY c.ano) t)
)
SELECT verificacao, esperado, obtido,
       CASE WHEN esperado = obtido THEN 'OK' ELSE 'FALHOU' END AS resultado
FROM checks;
