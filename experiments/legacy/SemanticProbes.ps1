# SemanticProbes - Verify AST shapes and execution behavior
$ErrorActionPreference = 'Stop'

# Probe: optional chaining
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput('$obj?.prop', [ref]$tokens, [ref]$errors)
Write-Host "optional-chaining parseable: ($($errors.Count -eq 0))"
if ($ast) {
    $ast.FindAll({ $_ -is [System.Management.Automation.Language.VariableExpressionAst] }, $true) | ForEach-Object {
        Write-Host "  Variable: $($_.Extent.Text) Path: $($_.VariablePath.UserPath)"
    }
}

# Probe: object literal
try {
    $x = { x: 1 }
    Write-Host "object-literal parseable: True"
    Write-Host "  Type: $($x.GetType().FullName)"
    Write-Host "  ScriptBlockAst count: $($x.Ast.Count)"
    # Check the first statement type
    if ($x.Ast.EndBlock -and $x.Ast.EndBlock.Statements.Count -gt 0) {
        Write-Host "  First statement type: $($x.Ast.EndBlock.Statements[0].GetType().Name)"
    }
} catch {
    Write-Host "object-literal ERROR: $($_.Exception.Message)"
}

# Probe: for-of
$arr = @(10,20,30)
$out = @()
try {
    for ($i = 0; $i -lt $arr.Count; $i++) {
        # This is how you'd simulate for...of
        $x = $arr[$i]
        $out += $x
    }
    # Actually test the PS for statement with let
    $out2 = @()
    try {
        for (let $x in $arr) {
            $out2 += $x
        }
        Write-Host "for-of OUT: ($($out2 -join ','))"
    } catch {
        Write-Host "for-of ERROR: $($_.Exception.Message)"
    }
} catch {
    Write-Host "for-of outer ERROR: $($_.Exception.Message)"
}

# Probe: for-in
$obj = [ordered]@{ a=1; b=2 }
$out = @()
try {
    for (let $x in $obj) {
        $out += $x
    }
    Write-Host "for-in OUT: ($($out -join ','))"
} catch {
    Write-Host "for-in ERROR: $($_.Exception.Message)"
}

# Probe: C-style comment
$x = 0
try {
    /* $x = 99 */
} catch {
    Write-Host "comment ERROR: $($_.Exception.Message)"
}
Write-Host "X after comment: $x"

# Probe: loose equality vs strict
Write-Host "`n=== Loose equality probe ==="
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput('$a == $b', [ref]$tokens, [ref]$errors)
Write-Host "  parseable: ($($errors.Count -eq 0))"
$ast.FindAll({ $_ -is [System.Management.Automation.Language.AssignmentStatementAst] }, $true) | ForEach-Object {
    Write-Host "  Found AssignmentStatementAst"
}

Write-Host "`n=== Strict equality probe ==="
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput('$a === $b', [ref]$tokens, [ref]$errors)
Write-Host "  parseable: ($($errors.Count -eq 0))"
$ast.FindAll({ $_ -is [System.Management.Automation.Language.AssignmentStatementAst] }, $true) | ForEach-Object {
    Write-Host "  Found AssignmentStatementAst"
}

Write-Host "`n=== nullish coalescing probe ==="
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput('$a ?? $b', [ref]$tokens, [ref]$errors)
Write-Host "  parseable: ($($errors.Count -eq 0))"
$ast.FindAll({ $_ -is [System.Management.Automation.Language.BinaryExpressionAst] }, $true) | ForEach-Object {
    Write-Host "  Found BinaryExpressionAst"
}

Write-Host "`n=== increment probe ==="
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput('$a++', [ref]$tokens, [ref]$errors)
Write-Host "  parseable: ($($errors.Count -eq 0))"
$ast.FindAll({ $_ -is [System.Management.Automation.Language.UnaryExpressionAst] }, $true) | ForEach-Object {
    Write-Host "  Found UnaryExpressionAst"
}