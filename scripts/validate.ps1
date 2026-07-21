$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$nodeBin = Join-Path $repositoryRoot '.node-runtime\node-v24.18.0-win-x64'

Write-Host 'Formatting and testing .NET...'
dotnet format (Join-Path $repositoryRoot 'application\backend\CloudArchitectureTraining.slnx') --verify-no-changes
dotnet test (Join-Path $repositoryRoot 'application\backend\CloudArchitectureTraining.slnx') --configuration Release

Write-Host 'Building and testing Angular...'
Push-Location (Join-Path $repositoryRoot 'application\web-angular')
if (Test-Path $nodeBin) { $env:Path = "$nodeBin;$env:Path" }
npm run build
npm test -- --watch=false
Pop-Location

Write-Host 'Formatting Terraform...'
terraform fmt -check -recursive (Join-Path $repositoryRoot 'infrastructure')

Write-Host 'Validation completed.'
