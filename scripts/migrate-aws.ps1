[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $FunctionName
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw 'AWS CLI is required. Configure an authenticated, short-lived AWS session first.'
}
if ([string]::IsNullOrWhiteSpace($env:AWS_DATABASE_ADMIN_PASSWORD)) {
    throw 'Set AWS_DATABASE_ADMIN_PASSWORD in the current process. Do not pass it on the command line.'
}

$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) "cloud-training-aws-migration-$([Guid]::NewGuid().ToString('N'))"
$requestPath = Join-Path $temporaryRoot 'request.json'
$responsePath = Join-Path $temporaryRoot 'response.json'
New-Item -ItemType Directory -Force -Path $temporaryRoot | Out-Null

try {
    @{ adminPassword = $env:AWS_DATABASE_ADMIN_PASSWORD } |
        ConvertTo-Json -Compress |
        Set-Content -LiteralPath $requestPath -Encoding utf8NoBOM

    $metadata = aws lambda invoke `
        --function-name $FunctionName `
        --cli-binary-format raw-in-base64-out `
        --payload "fileb://$($requestPath.Replace('\', '/'))" `
        --output json `
        $responsePath | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0) { throw "Lambda invocation failed with exit code $LASTEXITCODE." }
    $response = Get-Content -LiteralPath $responsePath -Raw | ConvertFrom-Json
    if ($metadata.FunctionError -or -not $response.succeeded) {
        throw 'Database migration failed. Review the migration Lambda log without exposing its request payload.'
    }

    Write-Host "$($response.message) Applied migration count: $($response.appliedMigrationCount)."
}
finally {
    Remove-Item Env:AWS_DATABASE_ADMIN_PASSWORD -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
