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
$deploymentProject = Join-Path $repositoryRoot 'application\backend\tools\CloudArchitectureTraining.DatabaseDeployment\CloudArchitectureTraining.DatabaseDeployment.csproj'
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

    dotnet run --project $deploymentProject --configuration Release -- `
        --runtime-identity-name $RuntimeIdentityName `
        --runtime-identity-principal-id $RuntimeIdentityPrincipalId
    Assert-NativeCommand 'Azure SQL deployment'
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
