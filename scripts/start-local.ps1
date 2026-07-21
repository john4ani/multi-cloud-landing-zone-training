$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot

docker compose --file (Join-Path $repositoryRoot 'compose.yaml') up --detach postgres
Write-Host 'PostgreSQL is starting on localhost:5432.'
Write-Host 'Run the API: dotnet run --project application/backend/src/CloudArchitectureTraining.Api'
Write-Host 'Run Angular: npm start --prefix application/web-angular'
