-- seed: faixas etarias
INSERT INTO dw.d_faixa_etaria (id, nome, idade_minima, idade_maxima, ordem) VALUES
    (1, '18-25', 18, 25,   1),
    (2, '26-35', 26, 35,   2),
    (3, '36-45', 36, 45,   3),
    (4, '46-55', 46, 55,   4),
    (5, '56+',   56, NULL, 5)
ON CONFLICT (id) DO NOTHING;
