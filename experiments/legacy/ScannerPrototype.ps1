# Master Refactor Engine: JS -> Pure, Executable PowerShell
class SourceEdit {
    [int]$OrigStart
    [int]$OrigLength
    [int]$WorkStart
    [int]$WorkLength
    [string]$Kind
    [int] Delta(){ return $this.WorkLength - $this.OrigLength }
}

class WorkingSourceResult {
    [string]$WorkingText
    [SourceEdit[]]$Edits
    [int] ToOriginalOffset([int]$w){
        $cum=0
        foreach($e in $this.Edits){
            if($w -lt $e.WorkStart){return $w-$cum}
            if($w -ge $e.WorkStart -and $w -lt $e.WorkStart+$e.WorkLength){return $e.OrigStart}
            $cum+=$e.Delta()
        }
        return $w-$cum
    }
    [int] ToWorkingOffset([int]$o){
        $cum=0
        foreach($e in $this.Edits){
            if($o -lt $e.OrigStart){return $o+$cum}
            if($o -ge $e.OrigStart -and $o -lt $e.OrigStart+$e.OrigLength){return $e.WorkStart}
            $cum+=$e.Delta()
        }
        return $o+$cum
    }
}

# Attach JavaScript-style methods to projected arrays globally via ETS
Update-TypeData -TypeName 'JS2PS.Array' -MemberType ScriptMethod -MemberName 'push' -Value {
    param($val)
    $this.Add($val)
    return $this.Count
} -Force

Update-TypeData -TypeName 'JS2PS.Array' -MemberType ScriptMethod -MemberName 'pop' -Value {
    if ($this.Count -eq 0) { return $null }
    $lastIdx = $this.Count - 1
    $val = $this[$lastIdx]
    $this.RemoveAt($lastIdx)
    return $val
} -Force

Update-TypeData -TypeName 'JS2PS.Array' -MemberType ScriptMethod -MemberName 'map' -Value {
    param([ScriptBlock]$fn)
    $result = [System.Collections.Generic.List[object]]::new()
    $result.PSObject.TypeNames.Insert(0, 'JS2PS.Array')
    foreach ($item in $this) {
        $result.Add((& $fn $item))
    }
    return $result
} -Force

function New-JS2PSArray {
    param([Parameter(ValueFromRemainingArguments)]$Elements)
    $arr = [System.Collections.Generic.List[object]]::new()
    $arr.PSObject.TypeNames.Insert(0, 'JS2PS.Array')
    if ($Elements) {
        foreach ($el in $Elements) { $null = $arr.Add($el) }
    }
    return ,$arr
}

function Convert-JsToPowerShell {
    param([string]$Original)
    $sb = [System.Text.StringBuilder]::new($Original.Length)
    $edits = [System.Collections.Generic.List[SourceEdit]]::new()
    $i=0; $workPos=0; $state='code'
    $n=$Original.Length

    while($i -lt $n){
        $c=$Original[$i]
        switch($state){
            'code'{
                # 1. Comments
                if($c -eq '/' -and $i+1 -lt $n){
                    $next=$Original[$i+1]
                    if($next -eq '*'){ $state='blockComment'; $i+=2; continue }
                    if($next -eq '/'){ $state='lineComment'; $i+=2; continue }
                }
                if($c -eq "'"){ $state='sgl'; $null=$sb.Append($c); $workPos++; $i++; continue }
                if($c -eq '"'){ $state='dbl'; $null=$sb.Append($c); $workPos++; $i++; continue }
                if($c -eq '`'){ $state='backtick'; $null=$sb.Append($c); $workPos++; $i++; continue }

                # 2. Function declarations: function foo(a, b) -> function foo($a, $b)
                if($c -eq 'f' -and ($i -eq 0 -or $Original[$i-1] -match '\s|;|\{|}')){
                    if($Original.Substring($i) -match '^function\s+([a-zA-Z0-9_$]+)\s*\(([^)]*)\)'){
                        $fullMatch = $Matches[0]
                        $fnName = $Matches[1]
                        $rawParams = $Matches[2]
                        $paramList = @()
                        if ($rawParams.Trim().Length -gt 0) {
                            $paramList = ($rawParams -split ',' | ForEach-Object { "`$$($_.Trim())" })
                        }
                        $rep = "function $fnName($($paramList -join ', '))"
                        $edits.Add([SourceEdit]@{OrigStart=$i;OrigLength=$fullMatch.Length;WorkStart=$workPos;WorkLength=$rep.Length;Kind='FunctionDecl'})
                        $null=$sb.Append($rep); $workPos+=$rep.Length; $i+=$fullMatch.Length; continue
                    }
                }

                # 3. Loops: for (const x of list) -> foreach ($x in $list)
                if($c -eq 'f' -and ($i -eq 0 -or $Original[$i-1] -match '\s|;|\{|}')){
                    if($Original.Substring($i) -match '^for\s*\(\s*(?:const|let|var)?\s*([a-zA-Z0-9_$]+)\s+of\s+([^)]+)\)'){
                        $fullMatch = $Matches[0]
                        $varName = $Matches[1]
                        $target = $Matches[2].Trim()
                        if (-not $target.StartsWith('$')) { $target = "`$$target" }
                        $rep = "foreach (`$$varName in $target)"
                        $edits.Add([SourceEdit]@{OrigStart=$i;OrigLength=$fullMatch.Length;WorkStart=$workPos;WorkLength=$rep.Length;Kind='ForOfLoop'})
                        $null=$sb.Append($rep); $workPos+=$rep.Length; $i+=$fullMatch.Length; continue
                    }
                }

                # 4. new Operator: new Foo(args) -> [Foo]::new(args)
                if($c -eq 'n' -and ($i -eq 0 -or $Original[$i-1] -match '\s|;|\{|}|\(')){
                    if($Original.Substring($i) -match '^new\s+([a-zA-Z0-9_$.]+)\s*\('){
                        $fullMatch = $Matches[0]
                        $className = $Matches[1]
                        $rep = "[$className]::new("
                        $edits.Add([SourceEdit]@{OrigStart=$i;OrigLength=$fullMatch.Length;WorkStart=$workPos;WorkLength=$rep.Length;Kind='NewOperator'})
                        $null=$sb.Append($rep); $workPos+=$rep.Length; $i+=$fullMatch.Length; continue
                    }
                }

                # 5. const / let / var normalization: "const x =" -> "$x ="
                if(($c -eq 'c' -or $c -eq 'l' -or $c -eq 'v') -and ($i -eq 0 -or $Original[$i-1] -match '\s|;|\{|}')){
                    $sub = $Original.Substring($i, [Math]::Min(6, $n - $i))
                    if($sub -match '^(const|let|var)\s'){
                        $kwLen = $Matches[0].Length
                        $edits.Add([SourceEdit]@{OrigStart=$i;OrigLength=$kwLen;WorkStart=$workPos;WorkLength=1;Kind='VarDecl'})
                        $null=$sb.Append('$')
                        $workPos += 1
                        $i += $kwLen
                        continue
                    }
                }

                # 6. Literals: false -> $false, true -> $true, null -> $null
                if($Original.Substring($i) -match '^(false|true|null)\b'){
                    $lit = $Matches[1]
                    $rep = "`$$lit"
                    $edits.Add([SourceEdit]@{OrigStart=$i;OrigLength=$lit.Length;WorkStart=$workPos;WorkLength=$rep.Length;Kind='KeywordLiteral'})
                    $null=$sb.Append($rep); $workPos+=$rep.Length; $i+=$lit.Length; continue
                }

                # 7. Comparison operators == and !=
                if($c -eq '=' -and $i+1 -lt $n -and $Original[$i+1] -eq '='){
                    $origStart=$i; $origLen=2; $rep='-eq'
                    if($i+2 -lt $n -and $Original[$i+2] -eq '='){ $origLen=3; $rep='-ceq' }
                    $edits.Add([SourceEdit]@{OrigStart=$origStart;OrigLength=$origLen;WorkStart=$workPos;WorkLength=$rep.Length;Kind='OpEq'})
                    $null=$sb.Append($rep); $workPos+=$rep.Length; $i+=$origLen; continue
                }
                if($c -eq '!' -and $i+1 -lt $n -and $Original[$i+1] -eq '='){
                    $origStart=$i; $origLen=2; $rep='-ne'
                    if($i+2 -lt $n -and $Original[$i+2] -eq '='){ $origLen=3; $rep='-cne' }
                    $edits.Add([SourceEdit]@{OrigStart=$origStart;OrigLength=$origLen;WorkStart=$workPos;WorkLength=$rep.Length;Kind='OpNe'})
                    $null=$sb.Append($rep); $workPos+=$rep.Length; $i+=$origLen; continue
                }

                # 8. Array literals: [1, 2, 3] -> (New-JS2PSArray 1, 2, 3)
                if($c -eq '['){
                    $j=$i+1
                    while($j -lt $n -and $Original[$j] -match '\s'){ $j++ }
                    if($j -lt $n -and $Original[$j] -match '[0-9"''\[{]'){
                        $end=$i+1; $depth=1
                        while($end -lt $n -and $depth -gt 0){
                            if($Original[$end] -eq '['){ $depth++ }
                            elseif($Original[$end] -eq ']'){ $depth--; if($depth -eq 0){ break } }
                            $end++
                        }
                        if($depth -eq 0){
                            $origLen=$end-$i+1
                            $inner=$Original.Substring($i+1,$origLen-2)
                            $rep='(New-JS2PSArray '+$inner+')'
                            $edits.Add([SourceEdit]@{OrigStart=$i;OrigLength=$origLen;WorkStart=$workPos;WorkLength=$rep.Length;Kind='ArrayLiteral'})
                            $null=$sb.Append($rep); $workPos+=$rep.Length; $i=$end+1; continue
                        }
                    }
                }

                # 9. Object literals: { key: value, ... }
                if($c -eq '{'){
                    $j=$i+1
                    while($j -lt $n -and $Original[$j] -match '\s'){ $j++ }
                    if($j -lt $n -and $Original.Substring($j) -match '^[a-zA-Z0-9_$"'']+\s*:'){
                        $end=$i+1; $depth=1
                        while($end -lt $n -and $depth -gt 0){
                            if($Original[$end] -eq '{'){ $depth++ }
                            elseif($Original[$end] -eq '}'){ $depth--; if($depth -eq 0){ break } }
                            $end++
                        }
                        if($depth -eq 0){
                            $origLen=$end-$i+1
                            $inner=$Original.Substring($i+1,$origLen-2)
                            $innerConverted = $inner -replace '\btrue\b', '$true' -replace '\bfalse\b', '$false' -replace '\bnull\b', '$null'
                            $tokens = $innerConverted -split ',' | ForEach-Object {
                                if ($_ -match '^\s*([a-zA-Z0-9_$"'']+)\s*:\s*(.*)$') {
                                    "$($Matches[1]) = $($Matches[2])"
                                } else {
                                    $_
                                }
                            }
                            $convertedInner = $tokens -join '; '
                            $rep='[pscustomobject]@{' + $convertedInner + '}'
                            $edits.Add([SourceEdit]@{OrigStart=$i;OrigLength=$origLen;WorkStart=$workPos;WorkLength=$rep.Length;Kind='ObjectLiteral'})
                            $null=$sb.Append($rep); $workPos+=$rep.Length; $i=$end+1; continue
                        }
                    }
                }

                $null=$sb.Append($c); $workPos++; $i++
            }
            'blockComment'{
                if($c -eq '*' -and $i+1 -lt $n -and $Original[$i+1] -eq '/'){ $state='code'; $i+=2 } else { $i++ }
            }
            'lineComment'{
                if($c -eq "`r" -or $c -eq "`n"){ $state='code' }
                $i++
            }
            'sgl'{
                if($c -eq "'" -and ($i -eq 0 -or $Original[$i-1] -ne '`')){ $state='code' }
                $null=$sb.Append($c); $workPos++; $i++
            }
            'dbl'{
                if($c -eq '"' -and ($i -eq 0 -or $Original[$i-1] -ne '`')){ $state='code' }
                $null=$sb.Append($c); $workPos++; $i++
            }
            'backtick'{
                if($c -eq '`' -and ($i -eq 0 -or $Original[$i-1] -ne '`')){ $state='code' }
                $null=$sb.Append($c); $workPos++; $i++
            }
        }
    }
    [WorkingSourceResult]@{WorkingText=$sb.ToString();Edits=$edits.ToArray()}
}
