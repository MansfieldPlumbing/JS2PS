. (Join-Path $PSScriptRoot 'legacy\ScannerPrototype.ps1')
$cases = @(
'return [1]',
'return []',
'throw [1]',
'yield [1]',
'obj[a,b]',
'obj[(a,b)]'
)
foreach($c in $cases){
    $in = "♠$c♣"
    try {
        $out = QuickPS-ToPS $in
        $t=$null;$e=$null
        [System.Management.Automation.Language.Parser]::ParseInput($out,[ref]$t,[ref]$e) | Out-Null
        Write-Host "IN:$c => OUT:$out | ParseErrors:$($e.Count)"
    } catch {
        Write-Host "IN:$c => ERROR:$($_.Exception.Message)"
    }
}
