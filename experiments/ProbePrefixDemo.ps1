$Source='let x = (y + 1) ; let a = (player.x) ; let b = (foo(a,b))'

# Simple regex-based identifier prefixing for demo
$pattern = '\((\s*)([A-Za-z_]\w*)(\s*[+\-*/%]\s*)([A-Za-z_]\w*)(\s*)\)'
$replaced = $Source -replace $pattern, {
    param($m)
    $left = $m.Groups[2].Value
    $op   = $m.Groups[3].Value
    $right= $m.Groups[4].Value
    "($" + '$' + $left + $op + '$' + $right + ")"
}
Write-Host $replaced
