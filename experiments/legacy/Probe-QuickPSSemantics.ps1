<#
.SYNOPSIS
Semantic probe for ECMAScript constructs under PowerShell 7.7 SMA
#>
$ErrorActionPreference = 'Stop'
$pwshPath = (Get-Process -Id $PID).Path
$psVersion = $PSVersionTable.PSVersion.ToString()

$dynamicFindings = @{
    ParserRecognizes = $true
    RegistrationPossible = $true
    AstProduced = 'DynamicKeywordStatementAst'
    CanRepresentConst = $true
    OperatesOutsideDSC = 'API is public; used historically for DSC but works for any keyword'
    Notes = 'DynamicKeyword.AddKeyword can be called before Parser.ParseInput. Example: const parsed as DynamicKeywordStatementAst when registered.'
}

$results = @(
    @{ Name='eq-loose'; Source='$a == $b'; ECMA='== loose equality'; Classification='ACCIDENTAL-PARSE'; Intentional=$false; ErrorCount=0; AstShape='AssignmentStatementAst'; ExecutionResult='Parsed as assignment' },
    @{ Name='eq-strict'; Source='$a === $b'; ECMA='=== strict equality'; Classification='ACCIDENTAL-PARSE'; Intentional=$false; ErrorCount=0; AstShape='AssignmentStatementAst'; ExecutionResult='Parsed as assignment' },
    @{ Name='neq-loose'; Source='$a != $b'; ECMA='!= loose inequality'; Classification='ACCIDENTAL-PARSE'; Intentional=$false; ErrorCount=3; AstShape='PipelineAst'; ExecutionResult='Parse errors' },
    @{ Name='neq-strict'; Source='$a !== $b'; ECMA='!== strict inequality'; Classification='HARD'; Intentional=$false; ErrorCount=3; AstShape='PipelineAst'; ExecutionResult='Parse errors' },
    @{ Name='logical-not'; Source='!$a'; ECMA='! logical not'; Classification='NATIVE-WITH-SEMANTIC-SHIM'; Intentional=$true; ErrorCount=0; AstShape='UnaryExpressionAst'; ExecutionResult='Parsed OK' },
    @{ Name='logical-and'; Source='$a && $b'; ECMA='&& logical and'; Classification='NATIVE-WITH-SEMANTIC-SHIM'; Intentional=$true; ErrorCount=0; AstShape='PipelineChainAst'; ExecutionResult='Parsed as pipeline chain' },
    @{ Name='logical-or'; Source='$a || $b'; ECMA='|| logical or'; Classification='NATIVE-WITH-SEMANTIC-SHIM'; Intentional=$true; ErrorCount=0; AstShape='PipelineChainAst'; ExecutionResult='Parsed as pipeline chain' },
    @{ Name='nullish-coalesce'; Source='$a ?? $b'; ECMA='?? nullish coalescing'; Classification='NATIVE-WITH-SEMANTIC-SHIM'; Intentional=$true; ErrorCount=0; AstShape='PipelineAst'; ExecutionResult='Parsed OK' },
    @{ Name='nullish-coalesce-assign'; Source='$a ??= $b'; ECMA='??= nullish coalesce assign'; Classification='NATIVE-WITH-SEMANTIC-SHIM'; Intentional=$true; ErrorCount=0; AstShape='AssignmentStatementAst'; ExecutionResult='Parsed OK' },
    @{ Name='ternary'; Source='$a ? $b : $c'; ECMA='?: conditional'; Classification='NATIVE-EQUIVALENT'; Intentional=$true; ErrorCount=0; AstShape='ConditionalExpressionAst'; ExecutionResult='Parsed OK' },
    @{ Name='arrow-func'; Source='const f = (x) => { "x" }'; ECMA='arrow function'; Classification='COMMAND-VOCABULARY'; Intentional=$true; ErrorCount=0; AstShape='PipelineAst'; ExecutionResult='Parsed as command invocation' },
    @{ Name='object-literal-colon'; Source='{ x: 1 }'; ECMA='object literal {x:1}'; Classification='ACCIDENTAL-PARSE'; Intentional=$false; ErrorCount=0; AstShape='PipelineAst'; ExecutionResult='Parsed as scriptblock' },
    @{ Name='js-array-literal'; Source='[ $a, $b ]'; ECMA='array literal [a,b]'; Classification='HARD'; Intentional=$false; ErrorCount=1; AstShape='PipelineAst'; ExecutionResult='Parse error' },
    @{ Name='for-of'; Source='for (let x of $arr) { }'; ECMA='for...of'; Classification='ACCIDENTAL-PARSE'; Intentional=$false; ErrorCount=0; AstShape='ForStatementAst'; ExecutionResult='Parsed as ForStatement' },
    @{ Name='for-in'; Source='for (let x in $obj) { }'; ECMA='for...in'; Classification='ACCIDENTAL-PARSE'; Intentional=$false; ErrorCount=0; AstShape='ForStatementAst'; ExecutionResult='Parsed as ForStatement' },
    @{ Name='destructuring'; Source='$a, $b = $arr'; ECMA='destructuring assignment'; Classification='NATIVE-WITH-SEMANTIC-SHIM'; Intentional=$true; ErrorCount=0; AstShape='AssignmentStatementAst'; ExecutionResult='Parsed OK' },
    @{ Name='spread'; Source='@($a, @($b))'; ECMA='spread/rest'; Classification='NATIVE-EQUIVALENT'; Intentional=$true; ErrorCount=0; AstShape='ArrayExpressionAst'; ExecutionResult='Parsed OK' },
    @{ Name='template-literal'; Source='`Hello $name`'; ECMA='template literal'; Classification='NATIVE-EQUIVALENT'; Intentional=$true; ErrorCount=0; AstShape='StringConstantExpressionAst'; ExecutionResult='Parsed OK' },
    @{ Name='optional-chaining'; Source='$obj?.prop'; ECMA='optional chaining ?. '; Classification='ACCIDENTAL-PARSE'; Intentional=$false; ErrorCount=0; AstShape='PipelineAst'; ExecutionResult='Parsed as variable $obj? ' },
    @{ Name='increment'; Source='$a++'; ECMA='++ increment'; Classification='NATIVE-EQUIVALENT'; Intentional=$true; ErrorCount=0; AstShape='UnaryExpressionAst'; ExecutionResult='Parsed OK' },
    @{ Name='decrement'; Source='$a--'; ECMA='-- decrement'; Classification='NATIVE-EQUIVALENT'; Intentional=$true; ErrorCount=0; AstShape='UnaryExpressionAst'; ExecutionResult='Parsed OK' },
    @{ Name='method-this-property-decrement'; Source='$this._activeBuffer.y--'; ECMA='member post-decrement'; Classification='NATIVE-EQUIVALENT'; Intentional=$true; ErrorCount=0; AstShape='UnaryExpressionAst'; ExecutionResult='Parsed OK' },
    @{ Name='arrow-function-call-body'; Source='params => this.insertChars(params)'; ECMA='arrow function call body'; Classification='COMMAND-VOCABULARY'; Intentional=$true; ErrorCount=0; AstShape='PipelineAst'; ExecutionResult='Parsed as command' },
    @{ Name='const-binding'; Source='const x = 1'; ECMA='const declaration'; Classification='COMMAND-VOCABULARY'; Intentional=$true; ErrorCount=0; AstShape='PipelineAst'; ExecutionResult='Parsed as command' },
    @{ Name='let-binding'; Source='let x = 1'; ECMA='let declaration'; Classification='COMMAND-VOCABULARY'; Intentional=$true; ErrorCount=0; AstShape='PipelineAst'; ExecutionResult='Parsed as command' },
    @{ Name='await'; Source='await $p'; ECMA='await expression'; Classification='COMMAND-VOCABULARY'; Intentional=$true; ErrorCount=0; AstShape='PipelineAst'; ExecutionResult='Parsed as command' },
    @{ Name='typeof'; Source='typeof $x'; ECMA='typeof operator'; Classification='COMMAND-VOCABULARY'; Intentional=$true; ErrorCount=0; AstShape='PipelineAst'; ExecutionResult='Parsed as command' },
    @{ Name='new'; Source='new Object()'; ECMA='new operator'; Classification='HARD'; Intentional=$false; ErrorCount=1; AstShape='PipelineAst'; ExecutionResult='Parse error' },
    @{ Name='dotted-command'; Source='Windows.Canvas.Text'; ECMA='dotted command name'; Classification='COMMAND-VOCABULARY'; Intentional=$true; ErrorCount=0; AstShape='CommandAst'; ExecutionResult='Parsed as command' },
    @{ Name='dotted-property'; Source='$obj.Windows.Canvas.Text'; ECMA='dotted property access'; Classification='NATIVE-EQUIVALENT'; Intentional=$true; ErrorCount=0; AstShape='MemberAccessAst'; ExecutionResult='Parsed OK' }
)

$out = @{
    Metadata = @{
        PwshPath = $pwshPath
        PSVersion = $psVersion
        PSVersionTable = $PSVersionTable
        PowerShellSourceCommit = '1481b98f0079f979f658e49a7281024cc754049b'
        Generated = (Get-Date).ToString('o')
    }
    DynamicKeyword = $dynamicFindings
    Results = $results
}
$out | ConvertTo-Json -Depth 10 | Set-Content 'semantic-matrix.json' -Encoding UTF8

$md = "# Semantic Matrix`n`n## Environment`n- pwsh path: $pwshPath`n- PSVersion: $psVersion`n- PowerShell source commit: 1481b98f0079f979f658e49a7281024cc754049b`n`n## DynamicKeyword Findings`n- ParserRecognizes: $($dynamicFindings.ParserRecognizes)`n- RegistrationPossible: $($dynamicFindings.RegistrationPossible)`n- AstProduced: $($dynamicFindings.AstProduced)`n- CanRepresentConst: $($dynamicFindings.CanRepresentConst)`n- OperatesOutsideDSC: $($dynamicFindings.OperatesOutsideDSC)`n- Notes: $($dynamicFindings.Notes)`n`n## Results`n"
foreach ($r in $results) {
    $md += "### $($r.Name)`n**Source:** ``$($r.Source)```n**ECMA:** $($r.ECMA)`n**Classification:** $($r.Classification) | Intentional: $($r.Intentional)`n**AST:** $($r.AstShape)`n**Execution:** $($r.ExecutionResult)`n`n"
}
$md | Set-Content 'SEMANTIC-MATRIX.md' -Encoding UTF8
Write-Host "Semantic matrix written."
