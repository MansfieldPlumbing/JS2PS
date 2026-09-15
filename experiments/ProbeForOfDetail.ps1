$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput('for (let x of $arr) { $out += $x }', [ref]$tokens, [ref]$errors)
Write-Host "parseable: $($errors.Count -eq 0)"
$for = $ast.EndBlock.Statements[0]
Write-Host "ForStatementAst: $($for -is [System.Management.Automation.Language.ForStatementAst])"
Write-Host "Initializer type: $($for.Initializer.GetType().Name)"
$init = $for.Initializer
if ($init.PipelineElements.Count -gt 0) {
    $elem = $init.PipelineElements[0]
    Write-Host "Initializer element type: $($elem.GetType().Name)"
}
