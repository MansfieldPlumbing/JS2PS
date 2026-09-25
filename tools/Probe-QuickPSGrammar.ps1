<#
.SYNOPSIS
Probe PowerShell 7.7 SMA parser to map ECMAScript-looking lexical forms.
Outputs grammar-matrix.json and GRAMMAR-MATRIX.md
#>

$ErrorActionPreference = 'Stop'

$pwshPath = $PSCommandPath ? (Get-Process -Id $PID).Path : $null
if (-not $pwshPath) {
    # Fallback to $PSHOME
    $pwshPath = "$env:PSHOME\pwsh.exe"
}
$psVersion = $PSVersionTable.PSVersion.ToString()
Write-Host "Running under pwsh: $pwshPath"
Write-Host "PSVersion: $psVersion"

function Probe-Fragment {
    param(
        [string]$Name,
        [string]$Source
    )
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Source, [ref]$tokens, [ref]$errors)
    $errorCount = if ($errors) { $errors.Count } else { 0 }
    $tokenInfo = @()
    if ($tokens) {
        foreach ($t in $tokens) {
            $tokenInfo += [PSCustomObject]@{
                Kind = $t.Kind.ToString()
                Text = $t.Text
                Start = $t.Extent.StartOffset
                End = $t.Extent.EndOffset
            }
        }
    }
    $astTypes = @()
    if ($ast) {
        # collect top-level statement types
        $astTypes += $ast.GetType().Name
        if ($ast.EndBlock) {
            foreach ($s in $ast.EndBlock.Statements) {
                $astTypes += $s.GetType().Name
            }
        }
    }
    # Find command name if any CommandAst
    $commandName = $null
    $commandElements = @()
    if ($ast) {
        $cmds = $ast.FindAll({ param($a) $a -is [System.Management.Automation.Language.CommandAst] }, $true)
        foreach ($cmd in $cmds) {
            if ($cmd.CommandElements.Count -gt 0) {
                $first = $cmd.CommandElements[0]
                if ($first -is [System.Management.Automation.Language.CommandAst]) {
                    # nested, skip
                } else {
                    $cmdName = $first.Extent.Text
                    $commandName = $cmdName
                    foreach ($ce in $cmd.CommandElements) {
                        $commandElements += $ce.Extent.Text
                    }
                    break
                }
            }
        }
    }
    # Classification comes from SMA's own parse, never from the source text:
    # HARD when SMA reports errors, COMMAND when any part was read as a command,
    # EXPRESSION otherwise.
    $classification = if ($errorCount -gt 0) { 'HARD' }
        elseif ($ast -and $ast.Find({ param($a) $a -is [System.Management.Automation.Language.CommandAst] }, $true)) { 'COMMAND' }
        else { 'EXPRESSION' }
    [PSCustomObject]@{
        Name = $Name
        Source = $Source
        ErrorCount = $errorCount
        Tokens = $tokenInfo
        AstTypes = $astTypes
        CommandName = $commandName
        CommandElements = $commandElements
        Classification = $classification
        Parseable = $errorCount -eq 0
        ExecutionPossible = $errorCount -eq 0
    }
}

$tests = @(
    @{ Name='comment-command-//'; Source='function // { "CALLED" } // THIS LOOKS LIKE A COMMENT' },
    @{ Name='const-declaration'; Source='const Draw = { param($x); "hi" }' },
    @{ Name='let-declaration'; Source='let x = 1' },
    @{ Name='await-identifier'; Source='await something' },
    @{ Name='typeof-identifier'; Source='typeof x' },
    @{ Name='new-identifier'; Source='new Object()' },
    @{ Name='dotted-command'; Source='function Windows.Canvas.Text { } Windows.Canvas.Text' },
    @{ Name='dotted-property-access'; Source='$obj.Windows.Canvas.Text' },
    @{ Name='strict-equality'; Source='$a === $b' },
    @{ Name='loose-equality'; Source='$a == $b' },
    @{ Name='strict-inequality'; Source='$a !== $b' },
    @{ Name='logical-and'; Source='$a && $b' },
    @{ Name='logical-or'; Source='$a || $b' },
    @{ Name='not-operator'; Source='!$a' },
    @{ Name='increment'; Source='$a++' },
    @{ Name='decrement'; Source='$a--' },
    @{ Name='nullish-coalescing'; Source='$a ?? $b' },
    @{ Name='nullish-coalescing-assign'; Source='$a ??= $b' },
    @{ Name='ternary'; Source='$a ? $b : $c' },
    @{ Name='arrow-function-like'; Source='const f = (x) => { "x" }' },
    @{ Name='object-literal-colon'; Source='{ x: 1 }' },
    @{ Name='array-literal'; Source='@($a,$b,$c)' },
    @{ Name='js-array-literal'; Source='[ $a, $b ]' },
    @{ Name='for-loop'; Source='for ($i=0;$i -lt 10;$i++) { }' },
    @{ Name='for-of'; Source='for (let x of $arr) { }' },
    @{ Name='for-in'; Source='for (let x in $obj) { }' },
    @{ Name='foreach'; Source='foreach ($x in $arr) { }' },
    @{ Name='arrow-function-call-body'; Source='params => this.insertChars(params)' },
    @{ Name='arrow-function-multi-call'; Source='(data, start, end) => this.print(data, start, end)' },
    @{ Name='method-this-property-decrement'; Source='$this._activeBuffer.y--' },
    @{ Name='while-condition-decrement'; Source='while ($param--) { }' },
    @{ Name='block-comment-c-style'; Source="/*`n * | Col 1 | Col 2 |`n * | ----- | ----- |`n */" },
    @{ Name='destructuring'; Source='$a, $b = $arr' },
    @{ Name='spread'; Source='@($a, @($b))' },
    @{ Name='template-string'; Source="`"Hello $name`"" },
    @{ Name='optional-chaining'; Source='$obj?.prop' },
    @{ Name='console.log'; Source='function console.log { } console.log "hi"' }
)

$results = foreach ($t in $tests) {
    Probe-Fragment -Name $t.Name -Source $t.Source
}

# Save JSON with metadata
$jsonPath = Join-Path $PSScriptRoot 'grammar-matrix.json'
$jsonOutput = @{
    Metadata = @{
        PwshPath = $pwshPath
        PSVersion = $psVersion
        PSVersionTable = $PSVersionTable
        PowerShellSourceCommit = '1481b98f0079f979f658e49a7281024cc754049b'
        Generated = (Get-Date).ToString('o')
    }
    Results = $results
}
$jsonOutput | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8

# Save Markdown
$mdPath = Join-Path $PSScriptRoot 'GRAMMAR-MATRIX.md'
$md = @()
$md += '# Grammar Matrix'
$md += ''
$md += "## Environment"
$md += ""
$md += "- pwsh path: $pwshPath"
$md += "- PSVersion: $psVersion"
$md += "- PSVersionTable: $($PSVersionTable | ConvertTo-Json -Compress)"
$md += "- PowerShell source commit: 1481b98f0079f979f658e49a7281024cc754049b"
$md += "- Generated: $(Get-Date -Format o)"
$md += ''

foreach ($r in $results) {
    $md += "## $($r.Name)"
    $md += ''
    $md += "**Source:** ``$($r.Source.Replace('`','``'))``"
    $md += ''
    $md += "**Parseable:** $($r.Parseable) | **Errors:** $($r.ErrorCount) | **Classification:** $($r.Classification)"
    $md += ''
    $md += '**Tokens:**'
    $md += ''
    $md += '| Kind | Text |'
    $md += '|------|------|'
    foreach ($tok in $r.Tokens) {
        $md += "| $($tok.Kind) | $($tok.Text.Replace('|','\|')) |"
    }
    $md += ''
    $md += '**AST Types:** ' + ($r.AstTypes -join ', ')
    $md += ''
}
$md -join "`n" | Set-Content $mdPath -Encoding UTF8

Write-Host "Probe complete. Results written to $jsonPath and $mdPath"
$results | Format-Table Name,Parseable,ErrorCount,Classification -AutoSize
