$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput('for (let x of $arr) { $out += $x }', [ref]$tokens, [ref]$errors)
Write-Host "parseable: $($errors.Count -eq 0)"
Write-Host "Errors: $($errors.Count)"
if ($errors.Count -gt 0) { $errors | ForEach-Object { Write-Host $_.Message } }
