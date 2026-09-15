function Test-Parse { param([string]$s)
    $t=$null;$e=$null
    $ast=[System.Management.Automation.Language.Parser]::ParseInput($s,[ref]$t,[ref]$e)
    [PSCustomObject]@{Source=$s;Errors=$e.Count;AST=$ast.FindAll({$true},{ $true }) | ForEach-Object {$_.GetType().Name} | Sort-Object -Unique}
}
@(
    'obj¿.prop'
    'obj?.prop'
    'obj¿.[i]'
    'obj?.[i]'
    'condition ¿ a : b'
    'condition ? a : b'
) | ForEach-Object { Test-Parse $_ }
