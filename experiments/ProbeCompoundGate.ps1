. (Join-Path $PSScriptRoot 'legacy\ScannerPrototype.ps1')
$src = @'
♠
let a = [1,2]
const b = 3
return [a,b]
♣
'@
$out = QuickPS-ToPS $src
Write-Host "RESULTING TEXT:"
Write-Host $out
$t=$null;$e=$null;$ast=[System.Management.Automation.Language.Parser]::ParseInput($out,[ref]$t,[ref]$e)
Write-Host "ParseErrors:$($e.Count)"
$ast.EndBlock.Statements | ForEach-Object {
    $stmt=$_
    Write-Host "Stmt Type:$($stmt.GetType().Name) Text:$($stmt.Extent.Text.Trim())"
    if ($stmt -is [System.Management.Automation.Language.PipelineAst]) {
        $stmt.PipelineElements | ForEach-Object {
            Write-Host "  Elem Type:$($_.GetType().Name) Text:$($_.Extent.Text.Trim())"
        }
    }
}
