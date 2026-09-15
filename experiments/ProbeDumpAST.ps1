$Source='let x = (y + 1)'
$t=$null;$e=$null
$ast=[System.Management.Automation.Language.Parser]::ParseInput($Source,[ref]$t,[ref]$e)
$ast.FindAll({$true},{ $true }) | ForEach-Object { Write-Host $_.GetType().Name " : "$_.Extent.Text }
