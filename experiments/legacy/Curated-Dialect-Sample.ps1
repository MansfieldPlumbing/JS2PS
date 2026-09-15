# Historical curated dialect sample. This is not a JavaScript compatibility claim.
. (Join-Path $PSScriptRoot 'ScannerPrototype.ps1')

$rawJsCode = @'
// 1. Comments
/* Multi-line comment */

// 2. Variable declarations and Object Literals
const config = {
    title: "Graphics Engine",
    targetFps: 60,
    vsync: true
};

// 3. Resizable Dynamic Arrays with JS methods
const list = [10, 20, 30];
$list.push(40);
$list.push(50);
const popped = $list.pop();

// 4. Function Declarations
function calculateBounds(width, height) {
    const area = $width * $height;
    return $area;
}

// 5. Instantiation (new Operator)
const rand = new System.Random();
const roll = $rand.Next(1, 100);

// 6. for...of Loop
const doubled = (New-JS2PSArray);
for (const item of list) {
    if ($item != 20) {
        $doubled.push($item * 2);
    }
}
'@

$res = Convert-JsToPowerShell $rawJsCode
Write-Host "========================================="
Write-Host "     REFACTORED POWERSHELL CODE"
Write-Host "========================================="
Write-Host $res.WorkingText

Write-Host "`n========================================="
Write-Host "     SMA AST COMPILATION & EXECUTION"
Write-Host "========================================="
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($res.WorkingText, [ref]$tokens, [ref]$errors)
Write-Host "SMA Parser Error Count: $($errors.Count)"

if ($errors.Count -eq 0) {
    # Dot-source the converted script so variables/functions survive in our test scope
    . ([ScriptBlock]::Create($res.WorkingText))

    Write-Host "`n========================================="
    Write-Host "     RUNTIME STATE VERIFICATION"
    Write-Host "========================================="
    Write-Host "config.title   : $($config.title)"
    Write-Host "config.vsync   : $($config.vsync)"
    Write-Host "list count     : $($list.Count) (Items: $($list -join ', '))"
    Write-Host "popped item    : $popped"
    Write-Host "calculateBounds: $(calculateBounds 10 20)"
    Write-Host "random roll    : $roll"
    Write-Host "doubled count  : $($doubled.Count) (Items: $($doubled -join ', '))"
    Write-Host "`nPASS: The curated dialect sample parsed and executed."
} else {
    $errors | ForEach-Object { Write-Host "Error: $($_.Message)" }
}
