
\echo '--- K8.1 Resumo'
WITH ocupacao AS (
    SELECT f.cargo_id, COUNT(*) AS ocupantes
    FROM dw.f_empregado_historico f
    WHERE f.flag_registro_atual = 1
    GROUP BY f.cargo_id
)
SELECT COUNT(*) AS total_cargos,
       COUNT(*) FILTER (WHERE ocupantes = 1) AS cargos_ocupante_unico,
       ROUND(100.0 * COUNT(*) FILTER (WHERE ocupantes = 1) / COUNT(*), 1) AS pct_cargos_unicos
FROM ocupacao;

\echo '--- K8.2 Cargos de ocupante unico por departamento (quantidade)'
SELECT d.nome AS departamento,
       COUNT(*) AS cargos_ocupante_unico
FROM dw.f_empregado_historico f
JOIN dw.d_departamento d ON d.id = f.departamento_id
WHERE f.flag_registro_atual = 1
  AND f.cargo_id IN (SELECT cargo_id
                       FROM dw.f_empregado_historico
                      WHERE flag_registro_atual = 1
                      GROUP BY cargo_id
                     HAVING COUNT(*) = 1)
GROUP BY d.nome
ORDER BY cargos_ocupante_unico DESC, d.nome;

\echo '--- K8.3 Cruzamento com K2: cargos de ocupante unico ocupados por quem tem 56+'
SELECT d.nome   AS departamento,
       c.titulo AS cargo,
       f.idade_referencia AS idade
FROM dw.f_empregado_historico f
JOIN dw.d_departamento d ON d.id = f.departamento_id
JOIN dw.d_cargo        c ON c.id = f.cargo_id
WHERE f.flag_registro_atual = 1
  AND f.idade_referencia >= 56
  AND f.cargo_id IN (SELECT cargo_id
                       FROM dw.f_empregado_historico
                      WHERE flag_registro_atual = 1
                      GROUP BY cargo_id
                     HAVING COUNT(*) = 1)
ORDER BY d.nome, c.titulo;
