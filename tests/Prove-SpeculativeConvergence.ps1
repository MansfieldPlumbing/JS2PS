$ErrorActionPreference='Stop'

function Get-StructuralScore {
    param([Management.Automation.Language.Ast]$Ast)
    $weights=@{
        VariableExpressionAst=10;MemberExpressionAst=10;IndexExpressionAst=10
        BinaryExpressionAst=8;InvokeMemberExpressionAst=8;CommandExpressionAst=5
        CommandAst=-5;ErrorExpressionAst=-10;StringConstantExpressionAst=-1
    }
    $score=0
    $Ast.FindAll({$true},$true)|ForEach-Object{
        $name=$_.GetType().Name
        if($weights.ContainsKey($name)){$score+=$weights[$name]}
    }
    $score
}

function Invoke-SpeculativeConvergence {
    param([string]$Source)
    $history=[Collections.Generic.List[object]]::new()
    for($iteration=1;$iteration-le 32;$iteration++){
        $tokens=$null;$errors=$null
        $ast=[Management.Automation.Language.Parser]::ParseInput($Source,[ref]$tokens,[ref]$errors)
        $command=$ast.FindAll({param($node)$node-is[Management.Automation.Language.CommandAst]},$true)|Select-Object -First 1
        if(-not $command){
            return [PSCustomObject]@{Source=$Source;Ast=$ast;Errors=@($errors);History=$history.ToArray()}
        }
        $element=$command.CommandElements[0]
        if(-not $element){throw "Command AST has no first element in '$Source'."}
        $candidate=$Source.Insert($element.Extent.StartOffset,'$')
        $candidateTokens=$null;$candidateErrors=$null
        $candidateAst=[Management.Automation.Language.Parser]::ParseInput($candidate,[ref]$candidateTokens,[ref]$candidateErrors)
        $before=Get-StructuralScore $ast;$after=Get-StructuralScore $candidateAst
        $accepted=$after-gt $before
        $history.Add([PSCustomObject]@{Iteration=$iteration;Before=$Source;Candidate=$candidate;ScoreBefore=$before;ScoreAfter=$after;Accepted=$accepted})
        if(-not $accepted){throw "Hill climb rejected its only candidate '$candidate' ($before -> $after)."}
        $Source=$candidate
    }
    throw 'Speculative convergence exceeded 32 iterations.'
}

$cases=@(
    @{Input='player.x';Final='$player.x';Setup={$player=[pscustomobject]@{x=7}};Expected=7},
    @{Input='obj[prop]';Final='$obj[$prop]';Setup={$obj=@{alpha=11};$prop='alpha'};Expected=11},
    @{Input='arr[i + 1]';Final='$arr[$i + 1]';Setup={$arr=@(10,20,30);$i=1};Expected=30},
    @{Input='arr[i + player.x]';Final='$arr[$i + $player.x]';Setup={$arr=@(0,1,2,3,4);$i=1;$player=[pscustomobject]@{x=2}};Expected=3},
    @{Input='player.x + obj[prop]';Final='$player.x + $obj[$prop]';Setup={$player=[pscustomobject]@{x=2};$obj=@{alpha=5};$prop='alpha'};Expected=7},
    @{Input='obj[player.x + y]';Final='$obj[$player.x + $y]';Setup={$player=[pscustomobject]@{x=2};$y=1;$obj=@{3=17}};Expected=17},
    @{Input='obj[arr[i + 1]]';Final='$obj[$arr[$i + 1]]';Setup={$arr=@('zero','one','alpha');$i=1;$obj=@{alpha=23}};Expected=23},
    @{Input='arr[obj[i + player.x]]';Final='$arr[$obj[$i + $player.x]]';Setup={$arr=@(10,20,30,40,50);$obj=@{3=4};$i=1;$player=[pscustomobject]@{x=2}};Expected=50},
    @{Input='player.x + arr[obj[prop] + y]';Final='$player.x + $arr[$obj[$prop] + $y]';Setup={$player=[pscustomobject]@{x=2};$arr=@(10,20,30);$obj=@{alpha=1};$prop='alpha';$y=1};Expected=32}
)

$results=foreach($case in $cases){
    $result=Invoke-SpeculativeConvergence $case.Input
    if($result.Errors.Count){throw "Final source '$($result.Source)' has $($result.Errors.Count) parse errors."}
    if($result.Source-cne $case.Final){throw "Expected '$($case.Final)', produced '$($result.Source)'."}
    . $case.Setup
    $actual=& ([scriptblock]::Create($result.Source))
    if($actual-cne $case.Expected){throw "'$($case.Input)' evaluated to '$actual'; expected '$($case.Expected)'."}
    [PSCustomObject]@{Input=$case.Input;Output=$result.Source;AcceptedMutations=$result.History.Count;ParseErrors=0;Actual=$actual;Expected=$case.Expected;Passed=$true}
}

$results
