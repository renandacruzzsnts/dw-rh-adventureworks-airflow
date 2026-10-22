-- seed: escaloes salariais (Rate por hora)
INSERT INTO dw.d_escalao_salarial (id, nome, rate_minimo, rate_maximo, ordem) VALUES
    (1, 'Até 10,00',       0,  10,   1),
    (2, '10,01 a 15,00',  10,  15,   2),
    (3, '15,01 a 25,00',  15,  25,   3),
    (4, '25,01 a 40,00',  25,  40,   4),
    (5, 'Acima de 40,00', 40,  NULL, 5)
ON CONFLICT (id) DO NOTHING;
