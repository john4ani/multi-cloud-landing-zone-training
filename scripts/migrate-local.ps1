param(
    [ValidateSet('PostgreSql', 'SqlServer')]
    [string]$Provider = 'PostgreSql',

    [string]$ConnectionString
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $repositoryRoot 'application\backend'
$apiProject = 'src\CloudArchitectureTraining.Api\CloudArchitectureTraining.Api.csproj'

if ([string]::IsNullOrWhiteSpace($ConnectionString)) {
    $ConnectionString = if ($Provider -eq 'SqlServer') {
        'Server=localhost,1433;Database=cloud_training;User Id=sa;Password=Local-Only_password1!;TrustServerCertificate=True'
    } else {
        'Host=localhost;Port=5432;Database=cloud_training;Username=cloud_training;Password=local-only-change-me'
    }
}

$migrationProject = if ($Provider -eq 'SqlServer') {
    'migrations\CloudArchitectureTraining.Migrations.SqlServer\CloudArchitectureTraining.Migrations.SqlServer.csproj'
} else {
    'migrations\CloudArchitectureTraining.Migrations.PostgreSql\CloudArchitectureTraining.Migrations.PostgreSql.csproj'
}

$previousProvider = $env:Database__Provider
$previousConnectionString = $env:ConnectionStrings__TrainingDatabase

try {
    $env:Database__Provider = $Provider
    $env:ConnectionStrings__TrainingDatabase = $ConnectionString

    Push-Location $backendRoot
    dotnet tool restore
    if ($LASTEXITCODE -ne 0) { throw 'Failed to restore local .NET tools.' }

    dotnet ef database update --project $migrationProject --startup-project $apiProject
    if ($LASTEXITCODE -ne 0) { throw "Failed to apply $Provider migrations." }

    Write-Host "$Provider migrations applied successfully."
} finally {
    Pop-Location
    $env:Database__Provider = $previousProvider
    $env:ConnectionStrings__TrainingDatabase = $previousConnectionString
}
