$arr = @(10,20,30)
$out = @()

try {
    for (let x of $arr) {
        $out += $x
    }
    Write-Host "OUT=" + ($out -join ',')
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
}
