[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]] $Path,
    [string] $Root = (Split-Path $PSScriptRoot -Parent)
)

# Observes how SMA, in its current state on the calling thread, perceives unmodified
# source files. The source text is read and never edited. Units are the tokens SMA itself
# produces whose whole text spells one ECMAScript IdentifierName; SMA decides where every
# token starts and ends. Runtime SMA state (for example registered DynamicKeywords) is
# deliberately not reset here: the caller owns the state being observed.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IdentifierName {
    param([string] $Text)
    if ([string]::IsNullOrEmpty($Text)) { return $false }
    $first = $Text[0]
    if (-not ([char]::IsLetter($first) -or $first -eq '_' -or $first -eq '$')) { return $false }
    foreach ($c in $Text.ToCharArray()) {
        if (-not ([char]::IsLetterOrDigit($c) -or $c -eq '_' -or $c -eq '$')) { return $false }
    }
    $true
}

foreach ($relative in $Path) {
    $full = Join-Path $Root $relative
    $bytes = [IO.File]::ReadAllBytes($full)
    $text = [Text.Encoding]::UTF8.GetString($bytes)
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref] $tokens, [ref] $errors)
    $units = foreach ($token in $tokens) {
        if (-not (Test-IdentifierName $token.Text)) { continue }
        [pscustomobject]@{
            Start = $token.Extent.StartOffset
            Length = $token.Extent.EndOffset - $token.Extent.StartOffset
            Text = $token.Text
            SmaTokenKind = $token.Kind.ToString()
            SmaKeywordFlag = [int] $token.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::Keyword)
            SmaCommandNameFlag = [int] $token.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::CommandName)
        }
    }
    [pscustomobject]@{
        Path = $relative
        Sha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
        TokenCount = $tokens.Count
        ErrorIds = @($errors | ForEach-Object { $_.ErrorId })
        StatementTypes = @($ast.EndBlock.Statements | ForEach-Object { $_.GetType().Name })
        Units = @($units)
    }
}
