$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput('for (let x of $arr) { $out += $x }', [ref]$tokens, [ref]$errors)
Write-Host "Root type: $($ast.GetType().Name)"
Write-Host "Statement count: $($ast.EndBlock.Statements.Count)"
$ast.EndBlock.Statements | ForEach-Object {
    Write-Host "Statement type: $($_.GetType().Name)"
    if ($_.GetType().Name -eq 'ForStatementAst') {
        $for = $_
        Write-Host "  Init: $($for.Initializer.GetType().Name)"
        Write-Host "  Condition: $($for.Condition.GetType().Name)"
        Write-Host "  Increment: $($for.Increment.GetType().Name)"
        # Explore initializer
        $init = $for.Initializer
        Write-Host "  Init statements: $($init.Statements.Count)"
        $init.Statements | ForEach-Object { Write-Host "    Init stmt type: $($_.GetType().Name)" }
    }
}
