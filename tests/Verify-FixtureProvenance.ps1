[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$fixtureRoot = Join-Path $PSScriptRoot '..\fixtures\ogl'
$manifest = Get-Content -Raw -LiteralPath (Join-Path $fixtureRoot 'manifest.json') | ConvertFrom-Json
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ('js2ps-ogl-' + [Guid]::NewGuid().ToString('N'))
$archivePath = Join-Path $temporaryRoot 'package.tgz'

try {
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
    Invoke-WebRequest -Uri $manifest.tarball -OutFile $archivePath

    $integrityPrefix = 'sha512-'
    if (-not ([string]$manifest.integrity).StartsWith($integrityPrefix, [StringComparison]::Ordinal)) {
        throw "Pinned integrity value does not start with '$integrityPrefix'."
    }
    $expectedIntegrity = ([string]$manifest.integrity).Substring($integrityPrefix.Length)
    $actualIntegrity = [Convert]::ToBase64String(
        [Security.Cryptography.SHA512]::HashData([IO.File]::ReadAllBytes($archivePath)))
    if ($actualIntegrity -cne $expectedIntegrity) {
        throw 'Downloaded package did not match the pinned SHA-512 integrity value.'
    }

    & tar -xf $archivePath -C $temporaryRoot
    if ($LASTEXITCODE -ne 0) { throw "tar exited with code $LASTEXITCODE." }

    foreach ($file in $manifest.files) {
        $localPath = Join-Path $fixtureRoot $file.path
        $packagePath = Join-Path $temporaryRoot $file.packagePath
        $localHash = (Get-FileHash -LiteralPath $localPath -Algorithm SHA256).Hash
        $packageHash = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash
        if ($localHash -cne $packageHash) {
            throw "Pinned fixture differs from the package: $($file.path)"
        }
    }

    [pscustomobject]@{
        Passed = $true
        Package = $manifest.package
        TarballIntegrity = $actualIntegrity
        FilesCompared = $manifest.files.Count
    }
}
finally {
    if ($temporaryRoot.StartsWith([IO.Path]::GetTempPath(), [StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $temporaryRoot)) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
