[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$results = [Collections.Generic.List[object]]::new()

function Add-ProofResult {
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][scriptblock] $Run,
        [Parameter(Mandatory)][scriptblock] $Accept
    )
    $output = @(& $Run)
    if (-not (& $Accept $output)) {
        throw "JS2PS proof '$Name' did not satisfy its acceptance gate."
    }
    $results.Add([pscustomobject]@{ Name = $Name; Passed = $true; Records = $output.Count })
}

Add-ProofResult 'Pinned fixture integrity' {
    & (Join-Path $PSScriptRoot 'Verify-FixtureIntegrity.ps1')
} {
    param($output)
    @($output).Count -eq 1 -and $output[0].Passed -and $output[0].Files.Count -eq 4
}

Add-ProofResult 'DynamicKeyword statement extension' {
    & (Join-Path $PSScriptRoot 'Prove-DynamicKeywordParserExtension.ps1')
} {
    param($output)
    @($output).Count -eq 1 -and $output[0].Passed
}

[pscustomobject]@{
    Passed = $true
    Proofs = $results.ToArray()
}
