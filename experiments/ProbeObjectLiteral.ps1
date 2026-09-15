try {
    $x = { x: 1 }
    Write-Host "TYPE=$($x.GetType().FullName)"
    Write-Host "VALUE=[$x]"
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
}
