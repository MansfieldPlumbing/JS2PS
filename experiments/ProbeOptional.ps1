# Probe optional chaining execution
$obj = $null
try {
    $r1 = $obj?.prop
    Write-Host "null => [$r1]"
} catch {
    Write-Host "null ERROR: $($_.Exception.Message)"
}

$obj = [pscustomobject]@{ prop = 123 }
try {
    $r2 = $obj?.prop
    Write-Host "value => [$r2]"
} catch {
    Write-Host "value ERROR: $($_.Exception.Message)"
}

# Probe parse variable name
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput('$obj?.prop', [ref]$tokens, [ref]$errors)
Write-Host "optional-chaining parseable: $($errors.Count -eq 0)"
$ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.VariableExpressionAst] }, $true) | ForEach-Object {
    [pscustomobject]@{
        Text = $_.Extent.Text
        VariablePath = $_.VariablePath.UserPath
    } | ForEach-Object { Write-Host "Variable: $($_.Text) Path: $($_.VariablePath)" }
}
