function foo { param($a,$b); "FUNCTION:$a,$b" }
$foo = { param($a,$b); "SCRIPTBLOCK:$a,$b" }
class ProbeObject {
    [string] foo($a,$b) { return "METHOD:$a,$b" }
}
$obj = [ProbeObject]::new()
$a = 10
$b = 20
@(
    @{Name='foo($a,$b)'; Code='foo($a,$b)'}
    @{Name='$foo($a,$b)'; Code='& $foo $a $b'}
    @{Name='$obj.foo($a,$b)'; Code='$obj.foo($a,$b)'}
) | ForEach-Object {
    try { $r = Invoke-Expression $_.Code; Write-Host "$($_.Name) => $r" }
    catch { Write-Host "$($_.Name) ERROR: $($_.Exception.Message)" }
}
