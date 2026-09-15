function Show-SmaRoles {
    param([string]$Source)
    $tokens=$null;$errors=$null
    $ast=[System.Management.Automation.Language.Parser]::ParseInput($Source,[ref]$tokens,[ref]$errors)
    Write-Host "`n=== $Source ==="
    $tokens | ForEach-Object {
        [pscustomobject]@{
            Text=$_.Text
            Kind=$_.Kind
            Flags=$_.TokenFlags
            Start=$_.Extent.StartOffset
            End=$_.Extent.EndOffset
        }
    } | Format-Table -AutoSize
    Write-Host "ERRORS: $($errors.Count)"
    $ast.FindAll({param($n)$true}, $true) | ForEach-Object {
        "{0,-32} {1}" -f $_.GetType().Name, $_.Extent.Text
    }
}

@(
    'y + 1'
    '(y + 1)'
    '($y + 1)'
    'player.x'
    '(player.x)'
    '($player.x)'
    'foo(a,b)'
    'obj[prop]'
    'let x = (y + 1)'
    'let x = (player.x + y)'
) | ForEach-Object { Show-SmaRoles $_ }
