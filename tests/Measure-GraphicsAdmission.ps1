param(
    [Parameter(Mandatory)]
    [string] $AssemblyPath,

    [string[]] $SourcePath = @(
        (Join-Path $PSScriptRoot '..\fixtures\ogl\extras\Box.js'),
        (Join-Path $PSScriptRoot '..\fixtures\ogl\math\Vec3.js'),
        (Join-Path $PSScriptRoot '..\fixtures\ogl\math\Mat4.js')
    )
)

$ErrorActionPreference = 'Stop'

if (-not ('Esprima.JavaScriptParser' -as [type])) {
    Add-Type -Path (Resolve-Path -LiteralPath $AssemblyPath)
}

function Test-SmaExpressionShape {
    param([Parameter(Mandatory)][AllowEmptyString()][string] $Source)

    $tokens = $null
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseInput($Source, [ref] $tokens, [ref] $errors)
    $wrongShape = @($ast.FindAll({
        param($node)
        $node -is [Management.Automation.Language.CommandAst] -or
        $node -is [Management.Automation.Language.ErrorExpressionAst] -or
        $node -is [Management.Automation.Language.ErrorStatementAst]
    }, $true))
    [pscustomobject]@{
        Accepted = $errors.Count -eq 0 -and $wrongShape.Count -eq 0
        ParseErrors = $errors.Count
        WrongShapeNodes = $wrongShape.Count
    }
}

function Convert-ExpressionIdentifiers {
    param(
        [Parameter(Mandatory)] $Root,
        [Parameter(Mandatory)][string] $Source
    )

    $starts = [Collections.Generic.List[int]]::new()
    function Visit-Node {
        param($Node, $Parent)
        if ($Node.Type -eq [Esprima.Ast.Nodes]::ThisExpression) {
            $starts.Add($Node.Range.Start - $Root.Range.Start)
        } elseif ($Node.Type -eq [Esprima.Ast.Nodes]::Identifier) {
            $isReference = -not (
                $Parent -and
                $Parent.Type -eq [Esprima.Ast.Nodes]::MemberExpression -and
                -not $Parent.Computed -and
                [object]::ReferenceEquals($Parent.Property, $Node)
            )
            if ($isReference) {
                $starts.Add($Node.Range.Start - $Root.Range.Start)
            }
        }
        foreach ($child in $Node.ChildNodes) {
            Visit-Node $child $Node
        }
    }
    Visit-Node $Root $null

    $working = $Source
    foreach ($start in $starts | Sort-Object -Descending) {
        $working = $working.Insert($start, '$')
    }
    [pscustomobject]@{ Working = $working; Insertions = $starts.Count }
}

$expressionKinds = @(
    [Esprima.Ast.Nodes]::ArrayExpression,
    [Esprima.Ast.Nodes]::AssignmentExpression,
    [Esprima.Ast.Nodes]::BinaryExpression,
    [Esprima.Ast.Nodes]::CallExpression,
    [Esprima.Ast.Nodes]::ConditionalExpression,
    [Esprima.Ast.Nodes]::MemberExpression,
    [Esprima.Ast.Nodes]::NewExpression,
    [Esprima.Ast.Nodes]::ObjectExpression,
    [Esprima.Ast.Nodes]::UnaryExpression,
    [Esprima.Ast.Nodes]::UpdateExpression
)

$observations = [Collections.Generic.List[object]]::new()
foreach ($path in $SourcePath) {
    $text = Get-Content -Raw -LiteralPath $path
    $nodes = [Collections.Generic.List[object]]::new()
    $options = [Esprima.ParserOptions]::new()
    $options.Tolerant = $false
    $options.OnNodeCreated = { param($node) $nodes.Add($node) }
    $null = ([Esprima.JavaScriptParser]::new($options)).ParseModule($text, $path)

    foreach ($node in $nodes) {
        if ($node.Type -notin $expressionKinds) { continue }
        $source = $text.Substring($node.Range.Start, $node.Range.End - $node.Range.Start)
        $raw = Test-SmaExpressionShape $source
        $projection = Convert-ExpressionIdentifiers $node $source
        $projected = Test-SmaExpressionShape $projection.Working
        $status = if ($raw.Accepted) {
            'Unchanged'
        } elseif ($projected.Accepted) {
            'IdentifierRepair'
        } else {
            'Irreducible'
        }
        $observations.Add([pscustomobject]@{
            File = Split-Path $path -Leaf
            Kind = $node.Type.ToString()
            Start = $node.Range.Start
            Length = $node.Range.End - $node.Range.Start
            Insertions = $projection.Insertions
            RawErrors = $raw.ParseErrors
            ProjectedErrors = $projected.ParseErrors
            Status = $status
            Sample = ($source -replace '\s+', ' ').Substring(0, [Math]::Min(100, ($source -replace '\s+', ' ').Length))
        })
    }
}

$summary = @(
    $observations |
        Group-Object Kind |
        Sort-Object Name |
        ForEach-Object {
            $group = @($_.Group)
            [pscustomobject]@{
                Kind = $_.Name
                Total = $group.Count
                Unchanged = @($group | Where-Object Status -eq 'Unchanged').Count
                IdentifierRepair = @($group | Where-Object Status -eq 'IdentifierRepair').Count
                Irreducible = @($group | Where-Object Status -eq 'Irreducible').Count
            }
        }
)

if (-not $observations.Count) { throw 'No graphics expressions were measured.' }

[pscustomobject]@{
    Summary = $summary
    Observations = $observations.ToArray()
    Note = 'Syntactic measurement only. Semantic admission requires a separate execution oracle.'
    Passed = $true
}
