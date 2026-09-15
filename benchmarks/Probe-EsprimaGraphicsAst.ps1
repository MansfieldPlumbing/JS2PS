param(
    [Parameter(Mandatory)]
    [string] $AssemblyPath,

    [int] $Iterations = 500,

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

$sources = @(
    foreach ($path in $SourcePath) {
        [pscustomobject]@{
            Path = $path
            Text = Get-Content -Raw -LiteralPath $path
        }
    }
)

$results = @(
    foreach ($source in $sources) {
        $script:nodeCount = 0
        $script:spanFailures = 0
        $options = [Esprima.ParserOptions]::new()
        $options.Tolerant = $false
        $options.OnNodeCreated = {
            param($node)
            $script:nodeCount++
            if ($node.Range.Start -lt 0 -or $node.Range.End -gt $source.Text.Length) {
                $script:spanFailures++
            }
        }
        $parser = [Esprima.JavaScriptParser]::new($options)
        $tree = $parser.ParseModule($source.Text, $source.Path)
        if ($script:spanFailures) {
            throw "$($source.Path) produced $script:spanFailures invalid source ranges."
        }
        [pscustomobject]@{
            File = Split-Path $source.Path -Leaf
            Nodes = $script:nodeCount
            SpanFailures = $script:spanFailures
            Root = $tree.Type.ToString()
        }
    }
)

$benchmarkParser = [Esprima.JavaScriptParser]::new()
foreach ($source in $sources) {
    $null = $benchmarkParser.ParseModule($source.Text, $source.Path)
}
$elapsed = Measure-Command {
    for ($iteration = 0; $iteration -lt $Iterations; $iteration++) {
        foreach ($source in $sources) {
            $null = $benchmarkParser.ParseModule($source.Text, $source.Path)
        }
    }
}
$parses = $Iterations * $sources.Count

[pscustomobject]@{
    EsprimaVersion = [Esprima.JavaScriptParser].Assembly.GetName().Version.ToString()
    Results = $results
    Benchmark = [pscustomobject]@{
        Parses = $parses
        ElapsedMilliseconds = $elapsed.TotalMilliseconds
        MillisecondsPerFile = $elapsed.TotalMilliseconds / $parses
        FilesPerSecond = $parses / $elapsed.TotalSeconds
    }
    Passed = $true
}
