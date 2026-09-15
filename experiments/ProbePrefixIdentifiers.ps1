function Prefix-BareIdentifiers {
    param([string]$Source)
    $t=$null;$e=$null
    $ast=[System.Management.Automation.Language.Parser]::ParseInput($Source,[ref]$t,[ref]$e)
    $span = [System.Collections.Generic.List[PSObject]]::new()
    $ast.FindAll({
        param($n,$a)
        $n -is [System.Management.Automation.Language.CommandAst] -and $a -is [System.Management.Automation.Language.ParenExpressionAst]
    },$true) | ForEach-Object {
        $cmd = $_
        $first = $cmd.CommandElements[0]
        if ($first -and $first.Extent.Text -match '^[A-Za-z_]\w*$') {
            $span.Add([PSCustomObject]@{Start=$first.Extent.StartOffset; Length=$first.Extent.Length; Text=$first.Extent.Text})
        }
    }
    # Replace from end to start
    $sb = [System.Text.StringBuilder]::new($Source)
    foreach ($s in $span | Sort-Object Start -Descending) {
        $sb.Remove($s.Start,$s.Length) | Out-Null
        $sb.Insert($s.Start,'$' + $s.Text) | Out-Null
    }
    $sb.ToString()
}

# Test
$src='let x = (y + 1)'
$out=Prefix-BareIdentifiers "let x = (y + 1)"
Write-Host "IN : $src"
Write-Host "OUT: $out"

$src2='let x = (player.x)'
$out2=Prefix-BareIdentifiers $src2
Write-Host "IN2 : $src2"
Write-Host "OUT2: $out2"
