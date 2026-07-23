$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$workflowFiles = Get-ChildItem (Join-Path $repositoryRoot '.github\workflows') -Filter '*.yml'
$errors = [System.Collections.Generic.List[string]]::new()

foreach ($workflow in $workflowFiles) {
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $workflow.FullName) {
        $lineNumber++
        if ($line -match '^\s*(?:-\s*)?uses:\s*([^#\s]+)') {
            $reference = $Matches[1]
            if (-not $reference.StartsWith('./') -and $reference -notmatch '@[0-9a-f]{40}$') {
                $errors.Add("$($workflow.Name):$lineNumber action is not pinned to a full commit SHA: $reference")
            }
        }
        if ($line -match '^\s*pull_request_target\s*:') {
            $errors.Add("$($workflow.Name):$lineNumber pull_request_target is prohibited.")
        }
        if ($line -match '^\s*(aws-access-key-id|aws-secret-access-key)\s*:') {
            $errors.Add("$($workflow.Name):$lineNumber long-lived AWS access-key inputs are prohibited; use GitHub OIDC.")
        }
    }
}

if ($errors.Count -gt 0) {
    throw "Workflow security validation failed:`n$($errors -join [Environment]::NewLine)"
}

Write-Host "Validated $($workflowFiles.Count) workflow file(s): actions are immutable and pull_request_target is absent."
