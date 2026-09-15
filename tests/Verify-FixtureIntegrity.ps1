[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$fixtureRoot = Join-Path $PSScriptRoot '..\fixtures\ogl'
$manifestPath = Join-Path $fixtureRoot 'manifest.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$results = foreach ($file in $manifest.files) {
    $path = Join-Path $fixtureRoot $file.path
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Pinned fixture is missing: $($file.path)"
    }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    [pscustomobject]@{
        Path = $file.path
        ExpectedSha256 = $file.sha256
        ActualSha256 = $actual
        Passed = $actual -eq $file.sha256
    }
}

$failures = @($results | Where-Object { -not $_.Passed })
if ($failures.Count) {
    throw "Fixture integrity failed for: $($failures.Path -join ', ')"
}

[pscustomobject]@{
    Passed = $true
    Package = $manifest.package
    Files = $results
}
