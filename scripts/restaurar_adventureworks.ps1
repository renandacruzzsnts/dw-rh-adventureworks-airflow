

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (-not (Test-Path "backup\AdventureWorks2025.bak")) {
    Write-Error "Arquivo backup\AdventureWorks2025.bak nao encontrado."
}

# le a senha do SQL Server no .env
$linha = Get-Content ".env" | Where-Object { $_ -match '^MSSQL_SA_PASSWORD=' } | Select-Object -First 1
if (-not $linha) { Write-Error "MSSQL_SA_PASSWORD nao encontrada no .env" }
$senha = ($linha -replace '^MSSQL_SA_PASSWORD=', '').Trim()

$sqlcmd = "/opt/mssql-tools18/bin/sqlcmd"

$restore = "RESTORE DATABASE AdventureWorks2025 FROM DISK = '/var/opt/mssql/backup/AdventureWorks2025.bak' WITH MOVE 'AdventureWorks' TO '/var/opt/mssql/data/AdventureWorks2025.mdf', MOVE 'AdventureWorks_log' TO '/var/opt/mssql/data/AdventureWorks2025_log.ldf', REPLACE"

Write-Host "Restaurando AdventureWorks2025..."
docker compose exec sqlserver $sqlcmd -S localhost -U sa -P $senha -C -Q $restore

Write-Host "Conferindo..."
docker compose exec sqlserver $sqlcmd -S localhost -U sa -P $senha -C -d AdventureWorks2025 -Q "SELECT COUNT(*) AS total_empregados FROM HumanResources.Employee"
