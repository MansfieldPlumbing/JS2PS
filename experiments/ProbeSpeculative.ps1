function Test-Speculative {
    param([string]$Original)
    $tests=@(
        $Original
        '$' + $Original
    )
    foreach ($src in $tests) {
        $t=$null;$e=$null
        $ast=[System.Management.Automation.Language.Parser]::ParseInput($src,[ref]$t,[ref]$e)
        Write-Host "`n=== $src ==="
        Write-Host "Errors:$($e.Count)"
        $t | ForEach-Object { Write-Host "- $($_.Text) Kind=$($_.Kind) Flags=$($_.TokenFlags)" }
        $nodes=@()
        $ast.FindAll({$true},{ $true }) | ForEach-Object { $nodes += $_.GetType().Name }
        $uniq=$nodes | Sort-Object -Unique
        Write-Host "AST nodes:$($uniq -join ', ')"
    }
}

@(
    'player.x'
    'obj[prop]'
    'arr[i + 1]'
    'foo(a,b)'
    'y + 1'
    'player.x + y'
) | ForEach-Object { Test-Speculative $_ }
