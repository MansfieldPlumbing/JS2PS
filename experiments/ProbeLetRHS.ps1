function let {
    param([Parameter(ValueFromRemainingArguments)] $Args)
    Write-Host "ArgCount: $($Args.Count)"
    for ($i=0; $i -lt $Args.Count; $i++) {
        $v = $Args[$i]
        Write-Host "Arg[$i]: [$v] <$($v.GetType().FullName)>"
    }
    Write-Host "---"
}

function foo {
    param([Parameter(ValueFromRemainingArguments)] $Args)
    Write-Host "foo called with $($Args.Count) args"
}

$foo = [pscustomobject]@{ bar = 42 }

let a = 1 + 2
let b = (1 + 2)
let c = @(1,2)
let d = foo
let e = $foo.bar
let f = foo(1,2)
let g = $true
let h = $null
