$obj = [ordered]@{ a=1; b=2 }
$out = @()

try {
    for (let x in $obj) {
        $out += $x
    }
    Write-Host "OUT=" + ($out -join ',')
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
}
