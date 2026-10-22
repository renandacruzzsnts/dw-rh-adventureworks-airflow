

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$linha = Get-Content ".env" | Where-Object { $_ -match '^POSTGRES_USER=' } | Select-Object -First 1
$usuario = ($linha -replace '^POSTGRES_USER=', '').Trim()

# copia os SQLs para dentro do container (evita problemas de acentuacao no terminal)
docker compose exec postgres rm -rf /tmp/kpis
docker compose cp kpis postgres:/tmp/kpis

$saida = "docs\resultados_kpis.txt"
"Resultados dos KPIs - gerado em $(Get-Date -Format 'dd/MM/yyyy HH:mm')" | Out-File $saida -Encoding utf8

foreach ($f in Get-ChildItem "kpis\*.sql" | Sort-Object Name) {
    Write-Host "Executando $($f.Name)"
    "`n===== $($f.Name) =====" | Out-File $saida -Append -Encoding utf8
    docker compose exec postgres psql -U $usuario -d dw -P pager=off -f "/tmp/kpis/$($f.Name)" |
        Out-File $saida -Append -Encoding utf8
}

Get-Content $saida
Write-Host "`nResultados salvos em $saida"
