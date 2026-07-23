[CmdletBinding()]
param(
    [Parameter(Mandatory)] [uri] $ApiBaseUrl,
    [Parameter(Mandatory)] [uri] $FrontendUrl,
    [ValidateSet('Azure', 'AWS')] [string] $Cloud = 'Azure',
    [string] $AccessToken
)

$ErrorActionPreference = 'Stop'
$apiRoot = $ApiBaseUrl.AbsoluteUri.TrimEnd('/')
$healthUrl = "$($ApiBaseUrl.Scheme)://$($ApiBaseUrl.Authority)/health"
$createdTopicId = $null
$apiHeaders = @{}
if (-not [string]::IsNullOrWhiteSpace($AccessToken)) {
    $apiHeaders.Authorization = "Bearer $AccessToken"
}

function Invoke-WithRetry([scriptblock] $Operation, [string] $Description) {
    for ($attempt = 1; $attempt -le 12; $attempt++) {
        try {
            return & $Operation
        }
        catch {
            if ($attempt -eq 12) { throw }
            Write-Host "$Description is not ready (attempt $attempt/12). Retrying in 10 seconds..."
            Start-Sleep -Seconds 10
        }
    }
}

Invoke-WithRetry { Invoke-RestMethod -Uri $healthUrl -TimeoutSec 20 } 'API health endpoint' | Out-Null
$topics = Invoke-RestMethod -Uri "$apiRoot/topics" -Headers $apiHeaders -TimeoutSec 20
Write-Host "API list endpoint returned $(@($topics).Count) topic(s)."

try {
    $uniqueName = "CI smoke test $([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
    $created = Invoke-RestMethod -Method Post -Uri "$apiRoot/topics" -Headers $apiHeaders -ContentType 'application/json' -Body (@{
        title = $uniqueName
        cloud = $Cloud
        notes = "Created by the guarded $Cloud deployment smoke test."
    } | ConvertTo-Json)
    $createdTopicId = $created.id
    if (-not $createdTopicId) { throw 'The create response did not include an id.' }

    $readBack = Invoke-RestMethod -Uri "$apiRoot/topics/$createdTopicId" -Headers $apiHeaders -TimeoutSec 20
    if ($readBack.title -ne $uniqueName) { throw 'The created topic could not be read back correctly.' }
}
finally {
    if ($createdTopicId) {
        Invoke-RestMethod -Method Delete -Uri "$apiRoot/topics/$createdTopicId" -Headers $apiHeaders -TimeoutSec 20 | Out-Null
    }
}

$frontend = Invoke-WithRetry { Invoke-WebRequest -Uri $FrontendUrl -TimeoutSec 20 } 'Frontend'
if ($frontend.StatusCode -ne 200 -or $frontend.Content -notmatch '<app-root') {
    throw 'The frontend did not return the expected Angular application shell.'
}

Write-Host "$Cloud API, database CRUD, and frontend smoke tests passed."
