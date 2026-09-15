function Get-StructuralScore {
    param($Ast)
    $score=0
    $nodes=@()
    $ast.FindAll({$true},{ $true }) | ForEach-Object { $nodes += $_ }
    $counts = @{}
    $nodes | ForEach-Object { $t=$_.GetType().Name; $counts[$t] = [int]($counts[$t] + 1) }
    $reward = @{
        VariableExpressionAst=10
        MemberExpressionAst=10
        IndexExpressionAst=10
        BinaryExpressionAst=8
        InvokeMemberExpressionAst=8
        CommandExpressionAst=5
    }
    $penalty = @{
        CommandAst=-5
        ErrorExpressionAst=-10
        StringConstantExpressionAst=-1
    }
    foreach ($k in $reward.Keys) { if ($counts.ContainsKey($k)) { $score += $counts[$k] * $reward[$k] } }
    foreach ($k in $penalty.Keys) { if ($counts.ContainsKey($k)) { $score += $counts[$k] * $penalty[$k] } }
    return [PSCustomObject]@{Score=$score;Counts=$counts}
}

function Get-FirstIsland {
    param($Ast,$Source)
    $islands=@()
    $ast.FindAll({$true},{ $true }) | ForEach-Object {
        $n=$_
        if ($n -is [System.Management.Automation.Language.CommandAst]) {
            $cmdName=$n.CommandElements[0]
            if ($cmdName) {
                $islands += [PSCustomObject]@{Node=$n; Offset=$cmdName.Extent.StartOffset; Length=$cmdName.Extent.Length; Text=$cmdName.Extent.Text}
            }
        }
    }
    if ($islands.Count -eq 0) { return $null }
    $islands | Sort-Object Offset | Select-Object -First 1
}

$cases=@(
    'player.x'
    'y + 1'
    'player.x + y'
    'obj[prop]'
    'arr[i + 1]'
    'obj[player.x]'
    'arr[i + player.x]'
    'player.x + obj[prop]'
    'foo(a,b)'
    'foo(player.x, y + 1)'
)

$results=@()
foreach ($case in $cases) {
    $source=$case
    $iter=0
    $history=@()
    while ($iter -lt 12) {
        $iter++
        $t=$null;$e=$null
        $ast=[System.Management.Automation.Language.Parser]::ParseInput($source,[ref]$t,[ref]$e)
        $scoreObj=Get-StructuralScore $ast
        $island=Get-FirstIsland $ast $source
        $record=[PSCustomObject]@{
            Original=$case
            Iteration=$iter
            SourceBefore=$source
            ParseErrors=$e.Count
            Score=$scoreObj.Score
            Island=$null
            Mutation=$null
            SourceAfter=$null
            Accepted=$null
            Reason=$null
        }
        if (-not $island) { $record.ASTTypes='Native'; $results += $record; break }
        $record.Island=$island.Text
        $mutOffset=$island.Offset
        $mutSource="$source"
        $mutSource=$mutSource.Insert($mutOffset,'$')
        # Reparse after mutation
        $t2=$null;$e2=$null
        $ast2=[System.Management.Automation.Language.Parser]::ParseInput($mutSource,[ref]$t2,[ref]$e2)
        $score2=Get-StructuralScore $ast2
        $accept=$score2.Score -gt $scoreObj.Score
        $record.SourceAfter=$mutSource
        $record.Mutation="Insert '$' at $mutOffset"
        $record.Accepted=$accept
        $record.Reason=("Score $($scoreObj.Score)->$($score2.Score)")
        $results += $record
        if ($accept) { $source=$mutSource } else { break }
        if ($score2.Score -eq $scoreObj.Score -and $e2.Count -ge $e.Count) { break }
    }
}

$results | ConvertTo-Json -Depth 10 | Out-File tests\convergence-results.json
$md="# Convergence Results`n`n"
foreach ($r in $results) {
    $md+="_Original_: $($r.Original)`n"
    $md+="Iteration $($r.Iteration): $($r.SourceBefore) -> $($r.SourceAfter) Accepted=$($r.Accepted) Score=$($r.Score) Reason=$($r.Reason)`n`n"
}
$md | Out-File tests\convergence-results.md
Write-Host "Done"
