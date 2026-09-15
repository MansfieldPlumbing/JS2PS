$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ScannerPrototype.ps1')

function Compare-Parse {
    param($a,$b)
    $ta=$null; $ea=$null
    $aa = [System.Management.Automation.Language.Parser]::ParseInput($a, [ref]$ta, [ref]$ea)
    $tb=$null; $eb=$null
    $ab = [System.Management.Automation.Language.Parser]::ParseInput($b, [ref]$tb, [ref]$eb)
    return [PSCustomObject]@{
        ByteIdentical = $a -eq $b
        ParseableA = $ea.Count -eq 0
        ParseableB = $eb.Count -eq 0
        TokenCountA = $ta.Count
        TokenCountB = $tb.Count
        TokenEquivalent = ($ta | ForEach-Object {$_.Kind.ToString() + ':' + $_.Text}) -join '|' -eq ($tb | ForEach-Object {$_.Kind.ToString() + ':' + $_.Text}) -join '|'
    }
}

$samples = @(
    @{ Name='Hashtable'; PS='@{ x = 1; y = 2 }' },
    @{ Name='Array'; PS='@(1, 2, 3)' },
    @{ Name='Mixed'; PS="# comment`n`$a = @{ x = 1 }`nWrite-Host `$a" },
    @{ Name='StringLiteral'; PS="\$s = ' { x:1 } ' " },
    @{ Name='Comment'; PS="# { x:1 }`n`$a = 1" }
)

foreach ($s in $samples) {
    Write-Host "=== $($s.Name) ==="
    $ps = $s.PS
    $js = QuickPS-ToJS $ps
    $ps2 = QuickPS-ToPS $js
    $c = Compare-Parse $ps $ps2
    Write-Host "PS->JS->PS ByteIdentical: $($c.ByteIdentical) TokenEquivalent: $($c.TokenEquivalent) Parseable: $($c.ParseableA)/$($c.ParseableB)"

    # Reverse direction
    $js2 = QuickPS-ToJS $ps2
    $c2 = Compare-Parse $js $js2
    Write-Host "JS->PS->JS ByteIdentical: $($c2.ByteIdentical) TokenEquivalent: $($c2.TokenEquivalent)"
}

# Smoke test Calculator.ps1
$calcPs = Get-Content "$PSScriptRoot\Calculator.ps1" -Raw
# Find first hashtable/array
$jsCalc = QuickPS-ToJS $calcPs
$psBack = QuickPS-ToPS $jsCalc
$e = $null
[System.Management.Automation.Language.Parser]::ParseInput($psBack, [ref]$null, [ref]$e) | Out-Null
Write-Host "Calculator.ps1 roundtrip parseable: $($e.Count -eq 0)"
