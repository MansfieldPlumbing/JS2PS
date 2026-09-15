<#
.SYNOPSIS
Admission Matrix - Tests which JS-shaped forms PowerShell can natively parse
and which require pre-parse transcription.
#>
$ErrorActionPreference = 'Stop'

# Host identification - prevents Windows PowerShell 5.1 contamination
Write-Host "Host:    $((Get-Process -Id $PID).Path)"
Write-Host "Version: $($PSVersionTable.PSVersion)"
Write-Host "Edition: $($PSVersionTable.PSEdition)"
Write-Host ""

function Invoke-QuickPSPreParse {
    param([Parameter(Mandatory)][string]$Source)
    $result = $Source

    # 1. Block comments /* ... */ -> <# ... #>
    $result = $result -replace '/\*', '<#' -replace '\*/', '#>'

    # 2. !== -> -ne
    $result = $result -replace '!==', '-ne'

    # 3. != -> -ne
    $result = $result -replace '!=', '-ne'

    # 4. === -> -eq
    $result = $result -replace '===', '-eq'

    # 5. == -> -eq
    $result = $result -replace '==', '-eq'

    # 6. [ ... ] -> @( ... ) - balanced brackets, not in strings/comments
    $result = Convert-JsArrayToPsArray $result

    return $result
}

function Convert-JsArrayToPsArray {
    param([string]$Text)
    $result = [System.Text.StringBuilder]::new()
    $i = 0
    $len = $Text.Length
    $inSingleQuote = $false
    $inDoubleQuote = $false
    $inBlockComment = $false

    while ($i -lt $len) {
        $ch = $Text[$i]

        # Handle string/comment state
        if ($inSingleQuote) {
            [void]$result.Append($ch)
            if ($ch -eq "'") {
                if ($i + 1 -lt $len -and $Text[$i + 1] -eq "'") {
                    [void]$result.Append($Text[$i + 1])
                    $i += 2
                    continue
                }
                $inSingleQuote = $false
            }
            $i++
            continue
        }
        if ($inDoubleQuote) {
            [void]$result.Append($ch)
            if ($ch -eq '"') {
                if ($i -gt 0 -and $Text[$i - 1] -eq '`') {
                    # escaped quote, stay in string
                } else {
                    $inDoubleQuote = $false
                }
            }
            $i++
            continue
        }
        if ($inBlockComment) {
            [void]$result.Append($ch)
            if ($ch -eq '#' -and $i + 1 -lt $len -and $Text[$i + 1] -eq '>') {
                [void]$result.Append($Text[$i + 1])
                $i += 2
                $inBlockComment = $false
                continue
            }
            $i++
            continue
        }

        # Check for transitions into protected regions
        if ($ch -eq "'") {
            $inSingleQuote = $true
            [void]$result.Append($ch)
            $i++
            continue
        }
        if ($ch -eq '"') {
            $inDoubleQuote = $true
            [void]$result.Append($ch)
            $i++
            continue
        }
        if ($ch -eq '<' -and $i + 1 -lt $len -and $Text[$i + 1] -eq '#') {
            $inBlockComment = $true
            [void]$result.Append('<#')
            $i += 2
            continue
        }

        # Now check for [ ... ] array literal
        if ($ch -eq '[') {
            $start = $i
            $bracketCount = 1
            $i++
            while ($i -lt $len -and $bracketCount -gt 0) {
                $c = $Text[$i]
                if ($c -eq '[') { $bracketCount++ }
                elseif ($c -eq ']') { $bracketCount-- }
                $i++
            }
            if ($bracketCount -eq 0) {
                $end = $i - 1
                $inner = $Text.Substring($start + 1, $end - $start - 1)
                [void]$result.Append("@($inner)")
            } else {
                [void]$result.Append($Text[$start])
                $i = $start + 1
            }
            continue
        }

        [void]$result.Append($ch)
        $i++
    }
    return $result.ToString()
}

function Get-AstShape {
    param([System.Management.Automation.Language.ScriptBlockAst]$Ast)
    if (-not $Ast.EndBlock -or $Ast.EndBlock.Statements.Count -eq 0) {
        return @{ Root = $Ast.GetType().Name; Statement = 'N/A'; Descendants = @() }
    }
    $first = $Ast.EndBlock.Statements[0]
    $desc = $Ast.FindAll({ $true }, $true) |
        ForEach-Object GetType |
        ForEach-Object Name |
        Select-Object -Unique
    @{ Root = $Ast.GetType().Name; Statement = $first.GetType().Name; Descendants = $desc }
}

function Test-Admission {
    param([string]$Name, [string]$Source)

    # Test 1: Raw parse
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Source, [ref]$tokens, [ref]$errors)
    $rawParseable = $errors.Count -eq 0
    $rawErrorCount = $errors.Count
    $rawShape = if ($rawParseable) { Get-AstShape $ast } else { @{ Root='N/A'; Statement='N/A'; Descendants=@() } }

    # Test 2: Pre-parsed parse
    $prepared = Invoke-QuickPSPreParse $Source
    $tokens2 = $null; $errors2 = $null
    $ast2 = [System.Management.Automation.Language.Parser]::ParseInput($prepared, [ref]$tokens2, [ref]$errors2)
    $preParseable = $errors2.Count -eq 0
    $preErrorCount = $errors2.Count
    $preShape = if ($preParseable) { Get-AstShape $ast2 } else { @{ Root='N/A'; Statement='N/A'; Descendants=@() } }

    # Classification
    $classification = 'PREPARSE-REQUIRED'
    if ($rawParseable -and $preParseable) {
        # Same AST shape = native correct
        if ($rawShape.Statement -eq $preShape.Statement) {
            $classification = 'NATIVE-CORRECT'
        } else {
            $classification = 'PARSES-WRONG'
        }
    } elseif ($rawParseable -and -not $preParseable) {
        $classification = 'REGRESSION'
    }

    [PSCustomObject]@{
        Name            = $Name
        Source          = $Source
        Prepared        = $prepared
        RawParseable    = $rawParseable
        RawErrors       = $rawErrorCount
        RawStatement    = $rawShape.Statement
        RawDescendants  = $rawShape.Descendants -join ','
        PreParseable    = $preParseable
        PreErrors       = $preErrorCount
        PreStatement    = $preShape.Statement
        PreDescendants  = $preShape.Descendants -join ','
        Classification  = $classification
    }
}

$Cases = @(
    # NATIVE in 7.x (should be NATIVE-CORRECT)
    @{ Name='ternary'; Source='$a ? $b : $c' },
    @{ Name='increment'; Source='$a++' },
    @{ Name='decrement'; Source='$a--' },
    @{ Name='nullish-coalesce'; Source='$a ?? $b' },
    @{ Name='nullish-coalesce-assign'; Source='$a ??= $b' },
    @{ Name='logical-not'; Source='!$a' },
    @{ Name='member-decrement'; Source='$this._activeBuffer.y--' },
    @{ Name='dotted-property'; Source='$obj.Windows.Canvas.Text' },

    # PARSES but WRONG MEANING (should be PARSES-WRONG)
    @{ Name='loose-equality'; Source='$a == $b' },
    @{ Name='strict-equality'; Source='$a === $b' },
    @{ Name='optional-chaining'; Source='$obj?.prop' },
    @{ Name='object-literal'; Source='{ x: 1 }' },
    @{ Name='for-of'; Source='for (let x of $arr) { }' },
    @{ Name='for-in'; Source='for (let x in $obj) { }' },

    # CANNOT ENTER PARSER (should be PREPARSE-REQUIRED)
    @{ Name='js-array-literal'; Source='[1,2,3]' },
    @{ Name='loose-inequality'; Source='$a != $b' },
    @{ Name='strict-inequality'; Source='$a !== $b' },
    @{ Name='new-operator'; Source='new Object()' },
    @{ Name='arrow-multi'; Source='(data, start, end) => this.print(data, start, end)' },
    @{ Name='c-comment'; Source='/* hello */' }
)

$results = foreach ($c in $Cases) {
    Test-Admission -Name $c.Name -Source $c.Source
}

$results | Format-Table Name, Classification, RawParseable, RawStatement, PreParseable, PreStatement -AutoSize
Write-Host ""
Write-Host "=== DETAILED DESCENDANTS ==="
foreach ($r in $results) {
    Write-Host "[$($r.Name)] Raw: $($r.RawDescendants)"
    Write-Host "[$($r.Name)] Pre: $($r.PreDescendants)"
}