param(
    [Parameter(Mandatory)]
    [string] $AssemblyPath
)

$ErrorActionPreference = 'Stop'

if (-not ('Esprima.JavaScriptParser' -as [type])) {
    Add-Type -Path (Resolve-Path -LiteralPath $AssemblyPath)
}

function Get-IdentifierReferences {
    param([Parameter(Mandatory)][string] $Source)

    $root = ([Esprima.JavaScriptParser]::new()).ParseExpression($Source)
    $references = [Collections.Generic.List[object]]::new()
    function Visit-Node {
        param($Node, $Parent)
        if ($Node.Type -eq [Esprima.Ast.Nodes]::Identifier) {
            $isReference = -not (
                $Parent -and
                $Parent.Type -eq [Esprima.Ast.Nodes]::MemberExpression -and
                -not $Parent.Computed -and
                [object]::ReferenceEquals($Parent.Property, $Node)
            )
            if ($isReference) {
                $references.Add([pscustomobject]@{
                    Start = $Node.Range.Start
                    Name = $Node.Name
                })
            }
        }
        foreach ($child in $Node.ChildNodes) {
            Visit-Node $child $Node
        }
    }
    Visit-Node $root $null
    @($references)
}

function Format-Candidate {
    param(
        [Parameter(Mandatory)][string] $Source,
        [Parameter(Mandatory)][object[]] $References,
        [Parameter(Mandatory)][AllowEmptyCollection()][Collections.Generic.HashSet[int]] $Selected
    )
    $working = $Source
    foreach ($index in $Selected | Sort-Object { $References[$_].Start } -Descending) {
        $working = $working.Insert($References[$index].Start, '$')
    }
    $working
}

function Measure-SmaShape {
    param([Parameter(Mandatory)][string] $Source)

    $tokens = $null
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseInput($Source, [ref] $tokens, [ref] $errors)
    $weights = @{
        VariableExpressionAst = 12
        MemberExpressionAst = 10
        IndexExpressionAst = 10
        BinaryExpressionAst = 8
        CommandExpressionAst = 5
        CommandAst = -7
        ErrorExpressionAst = -20
        StringConstantExpressionAst = -2
    }
    $score = -100 * $errors.Count
    foreach ($node in $ast.FindAll({ $true }, $true)) {
        $name = $node.GetType().Name
        if ($weights.ContainsKey($name)) {
            $score += $weights[$name]
        }
    }
    [pscustomobject]@{ Score = $score; Ast = $ast; Errors = @($errors) }
}

function Invoke-AstGuidedHillClimb {
    param([Parameter(Mandatory)][string] $Source)

    $references = @(Get-IdentifierReferences $Source)
    $selected = [Collections.Generic.HashSet[int]]::new()
    $evaluations = 1
    $currentSource = Format-Candidate $Source $references $selected
    $currentMeasure = Measure-SmaShape $currentSource
    $history = [Collections.Generic.List[object]]::new()

    while ($selected.Count -lt $references.Count) {
        $best = $null
        for ($index = 0; $index -lt $references.Count; $index++) {
            if ($selected.Contains($index)) { continue }
            $trialSelection = [Collections.Generic.HashSet[int]]::new($selected)
            $null = $trialSelection.Add($index)
            $trialSource = Format-Candidate $Source $references $trialSelection
            $trialMeasure = Measure-SmaShape $trialSource
            $evaluations++
            if ($null -eq $best -or $trialMeasure.Score -gt $best.Measure.Score) {
                $best = [pscustomobject]@{
                    Index = $index
                    Source = $trialSource
                    Measure = $trialMeasure
                }
            }
        }
        if ($null -eq $best -or $best.Measure.Score -le $currentMeasure.Score) { break }
        $null = $selected.Add($best.Index)
        $history.Add([pscustomobject]@{
            Name = $references[$best.Index].Name
            OriginalOffset = $references[$best.Index].Start
            BeforeScore = $currentMeasure.Score
            AfterScore = $best.Measure.Score
        })
        $currentSource = $best.Source
        $currentMeasure = $best.Measure
    }

    $oracleBest = [int]::MinValue
    $oracleSelections = [Collections.Generic.List[int]]::new()
    $combinationCount = [math]::Pow(2, $references.Count)
    for ($mask = 0; $mask -lt $combinationCount; $mask++) {
        $oracleSelected = [Collections.Generic.HashSet[int]]::new()
        for ($index = 0; $index -lt $references.Count; $index++) {
            if ($mask -band (1 -shl $index)) { $null = $oracleSelected.Add($index) }
        }
        $measure = Measure-SmaShape (Format-Candidate $Source $references $oracleSelected)
        if ($measure.Score -gt $oracleBest) {
            $oracleBest = $measure.Score
            $oracleSelections.Clear()
            $oracleSelections.Add($mask)
        } elseif ($measure.Score -eq $oracleBest) {
            $oracleSelections.Add($mask)
        }
    }

    [pscustomobject]@{
        Source = $currentSource
        Measure = $currentMeasure
        References = $references
        Selected = $selected
        History = $history.ToArray()
        Evaluations = $evaluations
        ExhaustiveEvaluations = [int] $combinationCount
        OracleBestScore = $oracleBest
        ReachedOracle = $currentMeasure.Score -eq $oracleBest
    }
}

$cases = @(
    @{
        Source = 'a[0] + b[0]'
        ExpectedSource = '$a[0] + $b[0]'
        Setup = { $a = @(7); $b = @(11) }
        ExpectedValue = 18
    },
    @{
        Source = 'ax + t * (b[0] - ax)'
        ExpectedSource = '$ax + $t * ($b[0] - $ax)'
        Setup = { $ax = 10; $t = 0.25; $b = @(30) }
        ExpectedValue = 15
    },
    @{
        Source = 'player.x + arr[obj[prop] + y]'
        ExpectedSource = '$player.x + $arr[$obj[$prop] + $y]'
        Setup = { $player = [pscustomobject]@{ x = 2 }; $arr = @(10, 20, 30); $obj = @{ alpha = 1 }; $prop = 'alpha'; $y = 1 }
        ExpectedValue = 32
    }
)

foreach ($case in $cases) {
    $result = Invoke-AstGuidedHillClimb $case.Source
    if (-not $result.ReachedOracle) { throw "Hill climb missed exhaustive best score for '$($case.Source)'." }
    if ($result.Source -cne $case.ExpectedSource) { throw "Unexpected final source '$($result.Source)'." }
    if ($result.Measure.Errors.Count) { throw "Final source has $($result.Measure.Errors.Count) SMA parse errors." }
    . $case.Setup
    $actual = & ([scriptblock]::Create($result.Source))
    if ($actual -cne $case.ExpectedValue) { throw "Expected '$($case.ExpectedValue)', received '$actual'." }
    [pscustomobject]@{
        Original = $case.Source
        Working = $result.Source
        AcceptedMutations = $result.History.Count
        SearchEvaluations = $result.Evaluations
        ExhaustiveEvaluations = $result.ExhaustiveEvaluations
        ReachedOracle = $result.ReachedOracle
        ParseErrors = 0
        Actual = $actual
        Passed = $true
    }
}
