[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ResourceGroupName,
    [Parameter(Mandatory)] [string] $SqlServerName,
    [Parameter(Mandatory)] [string] $DatabaseName,
    [Parameter(Mandatory)] [string] $RuntimeIdentityName,
    [Parameter(Mandatory)] [Guid] $RuntimeIdentityPrincipalId,
    [Parameter(Mandatory)] [ValidatePattern('^([0-9]{1,3}\.){3}[0-9]{1,3}$')] [string] $ClientIp
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $repositoryRoot 'application\backend'
$firewallRuleName = "temporary-migration-$((Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss'))"
$serverFqdn = "$SqlServerName.database.windows.net"
$previousProvider = $env:Database__Provider
$previousConnection = $env:ConnectionStrings__TrainingDatabase

function Assert-NativeCommand([string] $description) {
    if ($LASTEXITCODE -ne 0) {
        throw "$description failed with exit code $LASTEXITCODE."
    }
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI (az) is required. Install it and run az login before this script.'
}

if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    throw 'sqlcmd is required to provision the managed-identity database user.'
}

Write-Host "Creating temporary Azure SQL firewall rule for $ClientIp..."
az sql server firewall-rule create `
    --resource-group $ResourceGroupName `
    --server $SqlServerName `
    --name $firewallRuleName `
    --start-ip-address $ClientIp `
    --end-ip-address $ClientIp `
    --output none
Assert-NativeCommand 'Temporary firewall-rule creation'

try {
    $env:Database__Provider = 'SqlServer'
    $env:ConnectionStrings__TrainingDatabase = "Server=tcp:$serverFqdn,1433;Initial Catalog=$DatabaseName;Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

    Write-Host 'Applying the reviewed SQL Server migration history with the signed-in Entra identity...'
    Push-Location $backendRoot
    try {
        dotnet tool restore
        Assert-NativeCommand 'dotnet tool restore'
        dotnet ef database update `
            --project migrations\CloudArchitectureTraining.Migrations.SqlServer `
            --startup-project src\CloudArchitectureTraining.Api
        Assert-NativeCommand 'Azure SQL migration'
    }
    finally {
        Pop-Location
    }

    $escapedIdentityName = $RuntimeIdentityName.Replace(']', ']]')
    $principalId = $RuntimeIdentityPrincipalId.ToString()
    $provisionRuntimeUser = @"
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$($RuntimeIdentityName.Replace("'", "''"))')
    CREATE USER [$escapedIdentityName] FROM EXTERNAL PROVIDER WITH OBJECT_ID='$principalId';
ALTER ROLE db_datareader ADD MEMBER [$escapedIdentityName];
ALTER ROLE db_datawriter ADD MEMBER [$escapedIdentityName];
"@

    Write-Host 'Granting the runtime managed identity data access without schema-owner permission...'
    sqlcmd -S $serverFqdn -d $DatabaseName -G -b -Q $provisionRuntimeUser
    Assert-NativeCommand 'Managed-identity database user provisioning'
}
finally {
    if ($null -eq $previousProvider) {
        Remove-Item Env:Database__Provider -ErrorAction SilentlyContinue
    }
    else {
        $env:Database__Provider = $previousProvider
    }

    if ($null -eq $previousConnection) {
        Remove-Item Env:ConnectionStrings__TrainingDatabase -ErrorAction SilentlyContinue
    }
    else {
        $env:ConnectionStrings__TrainingDatabase = $previousConnection
    }

    Write-Host 'Removing the temporary Azure SQL firewall rule...'
    az sql server firewall-rule delete `
        --resource-group $ResourceGroupName `
        --server $SqlServerName `
        --name $firewallRuleName `
        --yes `
        --output none
    Assert-NativeCommand 'Temporary firewall-rule removal'
}

Write-Host 'Azure SQL migration and runtime identity provisioning completed.'
