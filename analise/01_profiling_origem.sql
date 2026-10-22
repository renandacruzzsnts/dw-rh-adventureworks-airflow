USE AdventureWorks2025;
SET NOCOUNT ON;

PRINT '--- Q1: empregados por CurrentFlag';
SELECT CurrentFlag, COUNT(*) AS qtd
FROM HumanResources.Employee
GROUP BY CurrentFlag;

PRINT '--- Q2: historico de departamento (EndDate preenchido)';
SELECT COUNT(*) AS total_linhas,
       COUNT(DISTINCT BusinessEntityID) AS empregados,
       SUM(CASE WHEN EndDate IS NOT NULL THEN 1 ELSE 0 END) AS com_enddate
FROM HumanResources.EmployeeDepartmentHistory;

PRINT '--- Q3: empregados sem departamento aberto (nenhum EndDate nulo)';
SELECT BusinessEntityID, COUNT(*) AS linhas
FROM HumanResources.EmployeeDepartmentHistory
GROUP BY BusinessEntityID
HAVING SUM(CASE WHEN EndDate IS NULL THEN 1 ELSE 0 END) = 0;

PRINT '--- Q4: empregados com mais de uma passagem por departamento';
SELECT COUNT(*) AS empregados_com_mudanca
FROM (
    SELECT BusinessEntityID
    FROM HumanResources.EmployeeDepartmentHistory
    GROUP BY BusinessEntityID
    HAVING COUNT(*) > 1
) t;

PRINT '--- Q5: distribuicao do Rate (valor por hora)';
SELECT DISTINCT
       MIN(Rate) OVER () AS minimo,
       PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Rate) OVER () AS p25,
       PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Rate) OVER () AS mediana,
       PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Rate) OVER () AS p75,
       MAX(Rate) OVER () AS maximo
FROM HumanResources.EmployeePayHistory;

PRINT '--- Q6: historico de pagamento (linhas e empregados)';
SELECT COUNT(*) AS linhas, COUNT(DISTINCT BusinessEntityID) AS empregados
FROM HumanResources.EmployeePayHistory;

PRINT '--- Q7: faixas de datas';
SELECT MIN(BirthDate) AS nasc_min, MAX(BirthDate) AS nasc_max,
       MIN(HireDate) AS contrat_min, MAX(HireDate) AS contrat_max,
       MIN(ModifiedDate) AS mod_min, MAX(ModifiedDate) AS mod_max
FROM HumanResources.Employee;

PRINT '--- Q8: genero e estado civil';
SELECT Gender, MaritalStatus, COUNT(*) AS qtd
FROM HumanResources.Employee
GROUP BY Gender, MaritalStatus;

PRINT '--- Q9: departamentos';
SELECT DepartmentID, Name, GroupName
FROM HumanResources.Department
ORDER BY DepartmentID;
