. (Join-Path $PSScriptRoot 'legacy\ScannerPrototype.ps1')
$cases = @(
'[1,2]',
'foo([1,2])',
'x = [1,2]',
'x ? [1] : [2]',
'[[1],[2]]',
'return [1,2]',
'foo[0]',
'foo [0]',
'obj[prop]',
'arr[i + 1]',
'obj?.[0]'
)
foreach($c in $cases){
    $in = "♠$c♣"
    $out = QuickPS-ToPS $in
    $t=$null;$e=$null
    [System.Management.Automation.Language.Parser]::ParseInput($out,[ref]$t,[ref]$e) | Out-Null
    Write-Host "IN:$c => OUT:$out | ParseErrors:$($e.Count)"
}
