function Show-Ast([string]$Source) {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Source,[ref]$tokens,[ref]$errors)
    [pscustomobject]@{
        Source = $Source
        Errors = $errors.Count
        Types  = ($ast.FindAll({$true},$true) | ForEach-Object {$_.GetType().Name} | Sort-Object -Unique) -join ', '
    }
}
$cases=@('foo(a,b)','$foo($a,$b)','$obj.foo($a,$b)','[Foo]::bar($a,$b)','& $foo $a $b')
foreach($c in $cases){ Show-Ast $c }
