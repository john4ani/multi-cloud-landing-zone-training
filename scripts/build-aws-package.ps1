[CmdletBinding()]
param(
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutputPath) {
    $OutputPath = Join-Path $repositoryRoot 'artifacts\aws\cloud-architecture-training-api.zip'
}

$outputDirectory = Split-Path -Parent $OutputPath
if ([IO.Path]::IsPathRooted($outputDirectory)) {
    $resolvedOutputDirectory = [IO.Path]::GetFullPath($outputDirectory)
}
else {
    $resolvedOutputDirectory = [IO.Path]::GetFullPath((Join-Path $repositoryRoot $outputDirectory))
}
$resolvedOutputPath = Join-Path $resolvedOutputDirectory (Split-Path -Leaf $OutputPath)
$stagingRoot = Join-Path ([IO.Path]::GetTempPath()) "cloud-training-aws-package-$([Guid]::NewGuid().ToString('N'))"
$publishRoot = Join-Path $stagingRoot 'publish'
$apiProject = Join-Path $repositoryRoot 'application\backend\src\CloudArchitectureTraining.Api\CloudArchitectureTraining.Api.csproj'

New-Item -ItemType Directory -Force -Path $publishRoot, $resolvedOutputDirectory | Out-Null

try {
    dotnet publish $apiProject `
        --configuration Release `
        --runtime linux-x64 `
        --self-contained false `
        --output $publishRoot
    if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed with exit code $LASTEXITCODE." }

    Invoke-WebRequest `
        -Uri 'https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem' `
        -OutFile (Join-Path $publishRoot 'global-bundle.pem')

    if (Test-Path -LiteralPath $resolvedOutputPath) {
        Remove-Item -LiteralPath $resolvedOutputPath -Force
    }
    Compress-Archive -Path (Join-Path $publishRoot '*') -DestinationPath $resolvedOutputPath -CompressionLevel Optimal

    $hash = (Get-FileHash -LiteralPath $resolvedOutputPath -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-Host "AWS Lambda package created: $resolvedOutputPath"
    Write-Host "SHA256: $hash"
}
finally {
    if (Test-Path -LiteralPath $stagingRoot) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }
}
