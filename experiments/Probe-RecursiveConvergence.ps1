function Get-AstTypes($ast){
    $set=@{}
    $ast.FindAll({$true},{ $true }) | ForEach-Object { $set[$_.GetType().Name] = $true }
    $set.Keys | Sort-Object
}
function Get-Score($ast){
    $reward=@{VariableExpressionAst=10;MemberExpressionAst=10;IndexExpressionAst=10;BinaryExpressionAst=8;InvokeMemberExpressionAst=8;CommandExpressionAst=5}
    $penalty=@{CommandAst=-5;ErrorExpressionAst=-10}
    $score=0
    $ast.FindAll({$true},{ $true }) | ForEach-Object {
        $t=$_.GetType().Name
        if($reward.ContainsKey($t)){ $score+=$reward[$t] }
        elseif($penalty.ContainsKey($t)){ $score+=$penalty[$t] }
    }
    $score
}
function Get-UnresolvedCount($ast){
    $cnt=0
    $ast.FindAll({$true},{ $true }) | ForEach-Object {
        if($_.GetType().Name -eq 'CommandAst'){ $cnt++ }
        if($_.GetType().Name -eq 'ErrorExpressionAst'){ $cnt++ }
    }
    $cnt
}
$cases=@(
    'arr[i + player.x]'
    'player.x + obj[prop]'
    'obj[player.x + y]'
    'arr[obj[prop] + player.x]'
    'player.x + obj[prop] + y'
    'obj[arr[i + 1]]'
    'obj[arr[player.x]]'
    'arr[obj[i + player.x]]'
    'player.x + arr[obj[prop] + y]'
)
$results=@()
foreach($base in $cases){
    $src=$base
    for($iter=1;$iter -le 12;$iter++){
        $t=$null;$e=$null
        $ast=[System.Management.Automation.Language.Parser]::ParseInput($src,[ref]$t,[ref]$e)
        $score=Get-Score $ast
        $types=Get-AstTypes $ast
        # find first CommandAst
        $cmd=$ast.FindAll({$true},{ $true }) | Where-Object {$_.GetType().Name -eq 'CommandAst'} | Select-Object -First 1
        if(-not $cmd){ $results+=([PSCustomObject]@{Case=$base;Iter=$iter;Source=$src;Score=$score;Errors=$e.Count;AST=$types -join ',';Done=$true}); break }
        $cmdEl=$cmd.CommandElements[0]
        if(-not $cmdEl){ break }
        $off=$cmdEl.Extent.StartOffset
        $txt=$cmdEl.Extent.Text
        $mutSrc=$src.Insert($off,'$')
        $t2=$null;$e2=$null
        $ast2=[System.Management.Automation.Language.Parser]::ParseInput($mutSrc,[ref]$t2,[ref]$e2)
        $score2=Get-Score $ast2
        $types2=Get-AstTypes $ast2
        $accept=$score2 -gt $score
        $results+=([PSCustomObject]@{
            Case=$base;Iter=$iter;SourceBefore=$src;SourceAfter=$mutSrc;CandidateText=$txt;Offset=$off;ScoreBefore=$score;ScoreAfter=$score2;ErrorsBefore=$e.Count;ErrorsAfter=$e2.Count;ASTBefore=$types -join ',';ASTAfter=$types2 -join ',';Accepted=$accept
        })
        if($accept){ $src=$mutSrc } else { break }
    }
}
$results | ConvertTo-Json -Depth 5 | Out-File tests\recursive-convergence.json
Write-Host 'Done'
