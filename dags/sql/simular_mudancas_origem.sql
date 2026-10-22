-- Simula mudancas no AdventureWorks (SQL Server) para provar a carga incremental.
-- Idempotente: pode ser executado mais de uma vez.

-- 1) alteracao cadastral: +8 horas de ferias para os dois primeiros empregados
UPDATE HumanResources.Employee
SET VacationHours = CASE WHEN VacationHours + 8 > 240 THEN VacationHours ELSE VacationHours + 8 END,
    ModifiedDate  = GETDATE()
WHERE BusinessEntityID IN (SELECT TOP 2 BusinessEntityID FROM HumanResources.Employee ORDER BY BusinessEntityID);

-- 2) novo reajuste salarial (+10%) para o empregado 5, em 20/12/2014
INSERT INTO HumanResources.EmployeePayHistory (BusinessEntityID, RateChangeDate, Rate, PayFrequency, ModifiedDate)
SELECT TOP 1 p.BusinessEntityID, '2014-12-20', p.Rate * 1.10, p.PayFrequency, GETDATE()
FROM HumanResources.EmployeePayHistory p
WHERE p.BusinessEntityID = 5
  AND NOT EXISTS (SELECT 1 FROM HumanResources.EmployeePayHistory x
                  WHERE x.BusinessEntityID = 5 AND x.RateChangeDate = '2014-12-20')
ORDER BY p.RateChangeDate DESC;
