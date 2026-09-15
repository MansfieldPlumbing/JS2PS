function Prefix-BareIdentifiersRegex {
    param([string]$Source)
    # Only touch content inside parentheses that are RHS of let/const
    # Simple heuristic: replace bare identifiers at start of parenthesized expr
    $pattern = '\(\s*([A-Za-z_]\w*)\s*([+\-*/%]\s*[A-Za-z_]\w*)'
    $Source -replace $pattern, '($1 + $2)' # placeholder
}

$src='let x = (y + 1)'
Write-Host $src
