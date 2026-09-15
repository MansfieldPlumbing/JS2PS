[CmdletBinding()]
param(
    [string] $AssemblyPath
)

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

Add-ProofResult 'SourceEdit ledger' {
    & (Join-Path $PSScriptRoot 'Stage0-Ledger.ps1')
} {
    param($output)
    @($output).Count -eq 5 -and @($output | Where-Object { -not $_.Pass }).Count -eq 0
}

Add-ProofResult 'DynamicKeyword statement extension' {
    & (Join-Path $PSScriptRoot 'Prove-DynamicKeywordParserExtension.ps1')
} {
    param($output)
    @($output).Count -eq 1 -and $output[0].Passed
}

Add-ProofResult 'Speculative convergence' {
    & (Join-Path $PSScriptRoot 'Prove-SpeculativeConvergence.ps1')
} {
    param($output)
    @($output).Count -eq 9 -and @($output | Where-Object { -not $_.Passed }).Count -eq 0
}

if ($AssemblyPath) {
    Add-ProofResult 'Esprima identifier projection' {
        & (Join-Path $PSScriptRoot 'Prove-EsprimaIdentifierProjection.ps1') -AssemblyPath $AssemblyPath
    } {
        param($output)
        @($output).Count -eq 4 -and @($output | Where-Object { -not $_.Passed }).Count -eq 0
    }

    Add-ProofResult 'AST-guided hill climbing' {
        & (Join-Path $PSScriptRoot 'Prove-AstGuidedHillClimb.ps1') -AssemblyPath $AssemblyPath
    } {
        param($output)
        @($output).Count -eq 3 -and @($output | Where-Object { -not $_.Passed }).Count -eq 0
    }

    Add-ProofResult 'OGL graphics admission matrix' {
        & (Join-Path $PSScriptRoot 'Measure-GraphicsAdmission.ps1') -AssemblyPath $AssemblyPath
    } {
        param($output)
        if (@($output).Count -ne 1 -or -not $output[0].Passed) { return $false }
        $total = ($output[0].Summary.Total | Measure-Object -Sum).Sum
        $irreducible = ($output[0].Summary.Irreducible | Measure-Object -Sum).Sum
        $total -eq 444 -and $irreducible -eq 22
    }
}

[pscustomobject]@{
    Passed = $true
    ExternalParserTestsIncluded = [bool] $AssemblyPath
    Proofs = $results.ToArray()
}
