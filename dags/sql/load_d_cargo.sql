-- carga incremental: stage.stg_empregado -> dw.d_cargo (so insere cargos novos)
INSERT INTO dw.d_cargo (titulo)
SELECT DISTINCT job_title
FROM stage.stg_empregado
WHERE job_title IS NOT NULL
ON CONFLICT (titulo) DO NOTHING;
