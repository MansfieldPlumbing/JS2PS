# Stage 1 Verification Test
. (Join-Path $PSScriptRoot 'ScannerPrototype.ps1')

$sampleJs = @'
// Single line header
/* Multi-line
   descriptive comment */
$values = [10, 20, 30]
if ($threshold == 20) {
    $flag != 0
}
'@

$result = Convert-QuickPSStage1 $sampleJs
Write-Host "=== CONVERTED WORKING TEXT ==="
Write-Host $result.WorkingText

Write-Host "`n=== RECORDED EDITS ==="
$result.Edits | Format-Table -AutoSize

Write-Host "`n=== SMA PARSER VERIFICATION ==="
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($result.WorkingText, [ref]$tokens, [ref]$errors)
Write-Host "SMA Parser Error Count: $($errors.Count)"
if ($errors.Count -eq 0) {
    Write-Host "SUCCESS: SMA parsed the converted JavaScript with 0 errors!"
} else {
    $errors | ForEach-Object { Write-Host "Error: $($_.Message)" }
}

Write-Host "`n=== SCRIPTBLOCK EXECUTION VERIFICATION ==="
$sb = $ast.GetScriptBlock()
Write-Host "ScriptBlock successfully generated from SMA AST: $([bool]$sb)"
& $sb
Write-Host "`nExecuted cleanly without runtime failure!"
