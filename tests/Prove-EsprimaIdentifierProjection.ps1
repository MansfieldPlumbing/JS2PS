param(
    [Parameter(Mandatory)]
    [string] $AssemblyPath
)

$ErrorActionPreference = 'Stop'

if (-not ('Esprima.JavaScriptParser' -as [type])) {
    Add-Type -Path (Resolve-Path -LiteralPath $AssemblyPath)
}

function Convert-IdentifierReferences {
    param([Parameter(Mandatory)][string] $Source)

    $parser = [Esprima.JavaScriptParser]::new()
    $root = $parser.ParseExpression($Source)
    $references = [Collections.Generic.List[object]]::new()

    function Visit-Node {
        param($Node, $Parent)

        if ($Node.Type -eq [Esprima.Ast.Nodes]::Identifier) {
            $isReference = $true
            if ($Parent -and $Parent.Type -eq [Esprima.Ast.Nodes]::MemberExpression -and
                -not $Parent.Computed -and
                [object]::ReferenceEquals($Parent.Property, $Node)) {
                $isReference = $false
            }
            if ($isReference) {
                $references.Add([pscustomobject]@{
                    Start = $Node.Range.Start
                    End = $Node.Range.End
                    Name = $Node.Name
                })
            }
        }

        foreach ($child in $Node.ChildNodes) {
            Visit-Node $child $Node
        }
    }

    Visit-Node $root $null
    $working = $Source
    foreach ($reference in $references | Sort-Object Start -Descending) {
        $working = $working.Insert($reference.Start, '$')
    }

    [pscustomobject]@{
        Original = $Source
        Working = $working
        References = @($references)
    }
}

$cases = @(
    @{
        Source = '(wSegs + 1) * (hSegs + 1) * 2 + (wSegs + 1) * (dSegs + 1) * 2 + (hSegs + 1) * (dSegs + 1) * 2'
        ExpectedSource = '($wSegs + 1) * ($hSegs + 1) * 2 + ($wSegs + 1) * ($dSegs + 1) * 2 + ($hSegs + 1) * ($dSegs + 1) * 2'
        Setup = { $wSegs = 2; $hSegs = 3; $dSegs = 4 }
        ExpectedValue = 94
    },
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

$results = @(
    foreach ($case in $cases) {
        $projection = Convert-IdentifierReferences $case.Source
        if ($projection.Working -cne $case.ExpectedSource) {
            throw "Projection mismatch. Expected '$($case.ExpectedSource)', received '$($projection.Working)'."
        }
        $tokens = $null
        $errors = $null
        $null = [Management.Automation.Language.Parser]::ParseInput($projection.Working, [ref] $tokens, [ref] $errors)
        if ($errors.Count) {
            throw "SMA rejected '$($projection.Working)' with $($errors.Count) errors."
        }
        . $case.Setup
        $actual = & ([scriptblock]::Create($projection.Working))
        if ($actual -cne $case.ExpectedValue) {
            throw "'$($case.Source)' evaluated to '$actual'; expected '$($case.ExpectedValue)'."
        }
        [pscustomobject]@{
            Original = $case.Source
            Working = $projection.Working
            Insertions = $projection.References.Count
            ParseErrors = 0
            Actual = $actual
            Expected = $case.ExpectedValue
            Passed = $true
        }
    }
)

$results
