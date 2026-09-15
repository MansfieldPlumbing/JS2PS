# Full End-to-End Bridge Test
. (Join-Path $PSScriptRoot 'ScannerPrototype.ps1')

$sample = @'
// Direct object literal and array test from Calculator.html style
const button = { buttonLabel: "C", buttonCategory: "function", gridColumnIndex: 0, gridRowIndex: 0 }
let state = { currentDisplayString: "0", requiresReset: false }
const arr = [1, 2, 3]

if ($button.buttonCategory == "function") {
    $state.currentDisplayString = "RESET"
}
'@

$res = Convert-QuickPSStage1 $sample
Write-Host "=== CONVERTED CODE ==="
Write-Host $res.WorkingText

Write-Host "`n=== EDITS RECORDED ==="
$res.Edits | Format-Table -AutoSize

Write-Host "`n=== SMA PARSER & EXECUTION CHECK ==="
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($res.WorkingText, [ref]$tokens, [ref]$errors)
Write-Host "SMA Parse Error Count: $($errors.Count)"

$sb = $ast.GetScriptBlock()
& $sb

Write-Host "`n=== PROVING VALUES SURVIVED IN SCOPE ==="
Write-Host "button.buttonLabel         = $($button.buttonLabel)"
Write-Host "button.buttonCategory      = $($button.buttonCategory)"
Write-Host "state.currentDisplayString  = $($state.currentDisplayString)"
Write-Host "state.requiresReset        = $($state.requiresReset)"
Write-Host "arr count                  = $($arr.Count)"
