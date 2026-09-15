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
$cases=@('player.x','y + 1','player.x + y','obj[prop]','arr[i + 1]','obj[player.x]','arr[i + player.x]','player.x + obj[prop]','foo(a,b)','foo(player.x, y + 1)')
$out=@()
foreach($c in $cases){
    $src=$c
    for($i=1;$i -le 3;$i++){
        $t=$null;$e=$null
        $ast=[System.Management.Automation.Language.Parser]::ParseInput($src,[ref]$t,[ref]$e)
        $score=Get-Score $ast
        $out+=([PSCustomObject]@{Case=$c;Iter=$i;Source=$src;Errors=$e.Count;Score=$score})
        # find first CommandAst command name
        $island=$ast.FindAll({$true},{ $true }) | Where-Object {$_.GetType().Name -eq 'CommandAst'} | Select-Object -First 1
        if(-not $island){break}
        $cmdEl=$island.CommandElements[0]
        if(-not $cmdEl){break}
        $off=$cmdEl.Extent.StartOffset
        $src=$src.Insert($off,'$')
    }
}
$out | ConvertTo-Json -Depth 5 | Out-File tests\convergence-results.json
Write-Host 'Done'
