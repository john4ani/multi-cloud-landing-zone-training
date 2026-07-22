$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot

function Find-RequiredNodeBin {
    $requiredVersion = (Get-Content (Join-Path $repositoryRoot 'application\web-angular\.nvmrc') -Raw).Trim().TrimStart('v')
    $nodeFromPath = Get-Command node.exe -ErrorAction SilentlyContinue
    $candidates = @()

    if ($nodeFromPath) {
        $candidates += Split-Path -Parent $nodeFromPath.Source
    }

    if ($env:NVM_SYMLINK) {
        $candidates += $env:NVM_SYMLINK
    }

    if ($env:NVM_HOME) {
        $candidates += @(
            (Join-Path $env:NVM_HOME $requiredVersion),
            (Join-Path $env:NVM_HOME "v$requiredVersion")
        )
    }

    $candidates += @(
        (Join-Path $env:LOCALAPPDATA "CloudArchitectureTraining\Node\node-v$requiredVersion-win-x64"),
        (Join-Path $repositoryRoot ".node-runtime\node-v$requiredVersion-win-x64")
    )

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        $nodeCommand = Join-Path $candidate 'node.exe'
        $npmCommand = Join-Path $candidate 'npm.cmd'
        if (-not (Test-Path $nodeCommand) -or -not (Test-Path $npmCommand)) {
            continue
        }

        $actualVersion = (& $nodeCommand --version).Trim().TrimStart('v')
        if ($actualVersion -eq $requiredVersion) {
            return $candidate
        }
    }

    throw "Node.js $requiredVersion with npm was not found. Follow 'Install or update Node.js' in README.md, open a new PowerShell session, and run this script again."
}

Write-Host 'Formatting and testing .NET...'
dotnet format (Join-Path $repositoryRoot 'application\backend\CloudArchitectureTraining.slnx') --verify-no-changes
dotnet test (Join-Path $repositoryRoot 'application\backend\CloudArchitectureTraining.slnx') --configuration Release

Write-Host 'Generating provider-specific migration scripts...'
$backendRoot = Join-Path $repositoryRoot 'application\backend'
$migrationOutput = Join-Path ([IO.Path]::GetTempPath()) 'cloud-architecture-training-migrations'
New-Item -ItemType Directory -Force -Path $migrationOutput | Out-Null
Push-Location $backendRoot
dotnet tool restore
$env:Database__Provider = 'PostgreSql'
dotnet ef migrations script --idempotent `
    --project migrations\CloudArchitectureTraining.Migrations.PostgreSql `
    --startup-project src\CloudArchitectureTraining.Api `
    --output (Join-Path $migrationOutput 'postgresql.sql')
$env:Database__Provider = 'SqlServer'
dotnet ef migrations script --idempotent `
    --project migrations\CloudArchitectureTraining.Migrations.SqlServer `
    --startup-project src\CloudArchitectureTraining.Api `
    --output (Join-Path $migrationOutput 'sqlserver.sql')
Remove-Item Env:Database__Provider -ErrorAction SilentlyContinue
Pop-Location

Write-Host 'Building and testing Angular...'
$nodeBin = Find-RequiredNodeBin
$nodeCommand = Join-Path $nodeBin 'node.exe'
$npmCommand = Join-Path $nodeBin 'npm.cmd'
Write-Host "Using $(& $nodeCommand --version) from $nodeBin"
$originalPath = $env:Path
Push-Location (Join-Path $repositoryRoot 'application\web-angular')
try {
    $env:Path = "$nodeBin;$originalPath"
    & $npmCommand run build
    if ($LASTEXITCODE -ne 0) {
        throw "Angular build failed with exit code $LASTEXITCODE."
    }

    & $npmCommand test -- --watch=false
    if ($LASTEXITCODE -ne 0) {
        throw "Angular tests failed with exit code $LASTEXITCODE."
    }
}
finally {
    $env:Path = $originalPath
    Pop-Location
}

Write-Host 'Formatting Terraform...'
terraform fmt -check -recursive (Join-Path $repositoryRoot 'infrastructure')

Write-Host 'Validation completed.'
