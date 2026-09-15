class SourceEdit {
    [int]$OrigStart
    [int]$OrigLength
    [int]$WorkStart
    [int]$WorkLength
    [string]$Kind

    [int] Delta() {
        return $this.WorkLength - $this.OrigLength
    }
}

class WorkingSourceResult {
    [string]$WorkingText
    [SourceEdit[]]$Edits

    [int] ToOriginalOffset([int]$workOffset) {
        $cumDelta = 0
        foreach($e in $this.Edits) {
            if($workOffset -lt $e.WorkStart) { return $workOffset - $cumDelta }
            $eEndWork = $e.WorkStart + $e.WorkLength
            if($workOffset -ge $e.WorkStart -and $workOffset -lt $eEndWork) {
                return $e.OrigStart
            }
            $cumDelta += $e.Delta()
        }
        return $workOffset - $cumDelta
    }

    [int] ToWorkingOffset([int]$origOffset) {
        $cumDelta = 0
        foreach($e in $this.Edits) {
            if($origOffset -lt $e.OrigStart) { return $origOffset + $cumDelta }
            $eEndOrig = $e.OrigStart + $e.OrigLength
            if($origOffset -ge $e.OrigStart -and $origOffset -lt $eEndOrig) {
                return $e.WorkStart
            }
            $cumDelta += $e.Delta()
        }
        return $origOffset + $cumDelta
    }
}

function Test-Stage0 {
    $tests=@()
    # no edits
    $r=[WorkingSourceResult]@{WorkingText='abc';Edits=@()}
    $tests+= [pscustomobject]@{Name='no edits';Pass=($r.ToOriginalOffset(1) -eq 1 -and $r.ToWorkingOffset(1) -eq 1)}
    # zero delta
    $e=[SourceEdit]@{OrigStart=1;OrigLength=1;WorkStart=1;WorkLength=1;Kind='Z'}
    $r=[WorkingSourceResult]@{WorkingText='abc';Edits=@($e)}
    $tests+= [pscustomobject]@{Name='zero delta';Pass=($r.ToOriginalOffset(1) -eq 1 -and $r.ToWorkingOffset(1) -eq 1)}
    # positive delta
    $e=[SourceEdit]@{OrigStart=1;OrigLength=1;WorkStart=1;WorkLength=3;Kind='Pos'}
    $r=[WorkingSourceResult]@{WorkingText='aXXXbc';Edits=@($e)}
    $tests+= [pscustomobject]@{Name='positive delta';Pass=($r.ToOriginalOffset(2) -eq 1 -and $r.ToWorkingOffset(2) -eq 4)}
    # negative delta
    $e=[SourceEdit]@{OrigStart=1;OrigLength=3;WorkStart=1;WorkLength=1;Kind='Neg'}
    $r=[WorkingSourceResult]@{WorkingText='aXc';Edits=@($e)}
    $tests+= [pscustomobject]@{Name='negative delta';Pass=($r.ToOriginalOffset(1) -eq 1 -and $r.ToWorkingOffset(4) -eq 2)}
    # multiple
    $e1=[SourceEdit]@{OrigStart=0;OrigLength=1;WorkStart=0;WorkLength=2;Kind='A'}
    $e2=[SourceEdit]@{OrigStart=2;OrigLength=1;WorkStart=4;WorkLength=1;Kind='B'}
    $r=[WorkingSourceResult]@{WorkingText='XXcc';Edits=@($e1,$e2)}
    $tests+= [pscustomobject]@{Name='multiple';Pass=($r.ToOriginalOffset(3) -eq 2 -and $r.ToWorkingOffset(2) -eq 4)}
$resultsDirectory = Join-Path (Split-Path $PSScriptRoot -Parent) 'results'
New-Item -ItemType Directory -Path $resultsDirectory -Force | Out-Null
$tests | ConvertTo-Json | Out-File (Join-Path $resultsDirectory 'stage0-results.json')
    $tests
}
Test-Stage0
