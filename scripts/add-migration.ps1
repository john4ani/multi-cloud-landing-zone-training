param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z][A-Za-z0-9]*$')]
    [string]$Name
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $repositoryRoot 'application\backend'
$apiProject = 'src\CloudArchitectureTraining.Api\CloudArchitectureTraining.Api.csproj'

$providers = @(
    @{
        Name = 'PostgreSql'
        Project = 'migrations\CloudArchitectureTraining.Migrations.PostgreSql\CloudArchitectureTraining.Migrations.PostgreSql.csproj'
    },
    @{
        Name = 'SqlServer'
        Project = 'migrations\CloudArchitectureTraining.Migrations.SqlServer\CloudArchitectureTraining.Migrations.SqlServer.csproj'
    }
)

$previousProvider = $env:Database__Provider
Push-Location $backendRoot
try {
    dotnet tool restore
    if ($LASTEXITCODE -ne 0) { throw 'Failed to restore local .NET tools.' }

    foreach ($provider in $providers) {
        $env:Database__Provider = $provider.Name
        dotnet ef migrations add $Name `
            --project $provider.Project `
            --startup-project $apiProject `
            --output-dir Migrations
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to generate the $($provider.Name) migration."
        }
    }
} finally {
    $env:Database__Provider = $previousProvider
    Pop-Location
}
