$Source='let x = (y + 1)'
$t=$null;$e=$null
$ast=[System.Management.Automation.Language.Parser]::ParseInput($Source,[ref]$t,[ref]$e)

function Find-CommandsInParens {
    param($node,$parent,$results)
    if ($node -is [System.Management.Automation.Language.CommandAst] -and $parent -is [System.Management.Automation.Language.ParenExpressionAst]) {
        $results.Add($node)
    }
    $node = $node -as [System.Management.Automation.Language.Ast]
    if ($node) {
        foreach ($child in $node.FindAll({$true},{ $false })) { # no
        }
    }
}

# Use FindAll with custom walker
$found=@()
$walk = {
    param($n,$p)
    if ($n -is [System.Management.Automation.Language.CommandAst] -and $p -is [System.Management.Automation.Language.ParenExpressionAst]) {
        $script:found += $n
    }
}
$ast.Visit({param($n,$p) & $walk $n $p },$false)
Write-Host "Found $($found.Count)"
$found | ForEach-Object {Write-Host $_.Extent.Text}
