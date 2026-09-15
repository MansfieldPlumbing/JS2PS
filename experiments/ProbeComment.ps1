$x = 0

try {
    /* $x = 99 */
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
}

Write-Host "X=$x"
