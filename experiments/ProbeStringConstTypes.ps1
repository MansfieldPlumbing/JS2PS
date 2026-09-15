function Show-StringConstTypes {
    param([string]$Source)
    $ast=[System.Management.Automation.Language.Parser]::ParseInput($Source,[ref]$null,[ref]$null)
    Write-Host "`n=== $Source ==="
    $ast.FindAll({param($n)$n -is [System.Management.Automation.Language.StringConstantExpressionAst]}, $true) | ForEach-Object {
        [pscustomobject]@{
            Text=$_.Extent.Text
            StringConstantType=$_.StringConstantType
            Parent=$_.Parent.GetType().Name
            ParentText=$_.Parent.Extent.Text
        }
    } | Format-Table -AutoSize
}

@(
    'y + 1'
    '(y + 1)'
    '($y + 1)'
    'player.x'
    '($player.x)'
    '($player.x)'
    'let x = (y + 1)'
    'let x = (player.x + y)'
) | ForEach-Object { Show-StringConstTypes $_ }
