$Source='let x = (y + 1)'
$t=$null;$e=$null
$ast=[System.Management.Automation.Language.Parser]::ParseInput($Source,[ref]$t,[ref]$e)
$ast.FindAll({param($n,$p) $n -is [System.Management.Automation.Language.CommandAst] -and $p -is [System.Management.Automation.Language.ParenExpressionAst]}, $true) | ForEach-Object { Write-Host "Found:" $_.Extent.Text }
