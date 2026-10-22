

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$linha = Get-Content ".env" | Where-Object { $_ -match '^POSTGRES_USER=' } | Select-Object -First 1
$usuario = ($linha -replace '^POSTGRES_USER=', '').Trim()

Get-Content "initdb\01_criar_dw.sql" | docker compose exec -T postgres psql -U $usuario -d postgres
docker compose exec postgres psql -U $usuario -d postgres -c "\l"
