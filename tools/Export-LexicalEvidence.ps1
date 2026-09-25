[CmdletBinding()]
param(
    [string[]] $Train = @('fixtures/ogl/extras/Box.js'),
    [string[]] $HeldOut = @('fixtures/ogl/math/Vec3.js', 'fixtures/ogl/math/Mat4.js'),
    [Parameter(Mandatory)][string] $OutFile,
    [string] $Node = 'node'
)

# Produces a JS2PS experience set for ChangeModel: how pristine SMA perceives pinned,
# unmodified source, plus an independent oracle outcome for every unit. JS2PS is the
# sensor; it does not learn, search or decide anything.
#
# Oracle contract (ECMA-262, Static Semantics: Early Errors for BindingIdentifier and
# ReservedWord): in strict-mode Script code, is this IdentifierName a ReservedWord that
# cannot be a BindingIdentifier? Authority: Node's own parser via vm.Script, compiling a
# probe program built from the token text alone. The specimen itself is never edited or
# executed. The oracle is a reference authority only; it is not part of any product path.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

$integrity = & (Join-Path $root 'tests/Verify-FixtureIntegrity.ps1')
if (-not $integrity.Passed) { throw 'Pinned fixture integrity failed.' }
if ([System.Management.Automation.Language.DynamicKeyword]::GetKeyword().Count -ne 0) {
    throw 'Evidence must be observed from pristine SMA: DynamicKeywords are registered on this thread.'
}

$observe = Join-Path $PSScriptRoot 'Observe-SmaPerception.ps1'
$trainObs = @(& $observe -Path $Train -Root $root)
$heldObs = @(& $observe -Path $HeldOut -Root $root)

$words = [Collections.Generic.SortedSet[string]]::new([StringComparer]::Ordinal)
foreach ($obs in $trainObs + $heldObs) { foreach ($u in $obs.Units) { [void] $words.Add($u.Text) } }

$oracleScript = @'
const vm = require('vm');
const words = JSON.parse(process.argv[1]);
const out = {};
for (const w of words) {
  try { new vm.Script('"use strict"; var ' + w + ';'); out[w] = 0; }
  catch (e) { if (e instanceof SyntaxError) { out[w] = 1; } else { throw e; } }
}
process.stdout.write(JSON.stringify({ node: process.version, outcomes: out }));
'@
$oracleJson = & $Node -e $oracleScript ([string[]] $words | ConvertTo-Json -Compress -AsArray)
if ($LASTEXITCODE -ne 0) { throw "Oracle process failed with exit code $LASTEXITCODE." }
$oracle = $oracleJson | ConvertFrom-Json

$sma = [System.Management.Automation.PSObject].Assembly
$evidence = [ordered]@{
    Schema = 1
    Provenance = [ordered]@{
        JS2PSCommit = (& git -C $root rev-parse HEAD).Trim()
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        SmaAssemblyVersion = $sma.GetName().Version.ToString()
        SmaModuleVersionId = $sma.ManifestModule.ModuleVersionId.ToString()
        Sensor = 'tools/Observe-SmaPerception.ps1'
    }
    Oracle = [ordered]@{
        Id = 'ecma262.strict-binding-identifier'
        Contract = 'In strict-mode Script code, the IdentifierName is a ReservedWord and cannot be a BindingIdentifier (1) or it can (0).'
        Authority = 'node vm.Script'
        AuthorityVersion = $oracle.node
    }
    OracleOutcomes = $oracle.outcomes
    Train = $trainObs
    HeldOut = $heldObs
}
$evidence | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutFile -Encoding utf8NoBOM
Get-Item -LiteralPath $OutFile
