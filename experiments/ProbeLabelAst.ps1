$code = @'
$x = {
    key: "hello"
    count: 42
}
'@
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)

Write-Host "All AST Nodes in Tree:"
$ast.FindAll({ $true }, $true) | ForEach-Object {
    "[$($_.GetType().Name)] '$($_.Extent.Text.Trim())'"
}
