$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput('/* $x = 99 */', [ref]$tokens, [ref]$errors)
Write-Host "parseable: $($errors.Count -eq 0)"
Write-Host "Errors count: $($errors.Count)"
$errors | ForEach-Object { Write-Host $_.Message }
