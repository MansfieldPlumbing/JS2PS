# Semantic Matrix

> Generated exploratory output. Several entries record accidental PowerShell parses. This file is evidence for investigation, not a JavaScript semantic-support claim.

## Environment
- pwsh path: local PowerShell executable (machine-specific path omitted)
- PSVersion: 7.7.0-preview.3
- PowerShell source commit: 1481b98f0079f979f658e49a7281024cc754049b

## DynamicKeyword Findings
- ParserRecognizes: True
- RegistrationPossible: True
- AstProduced: DynamicKeywordStatementAst
- CanRepresentConst: True
- OperatesOutsideDSC: API is public; used historically for DSC but works for any keyword
- Notes: DynamicKeyword.AddKeyword can be called before Parser.ParseInput. Example: const parsed as DynamicKeywordStatementAst when registered.

## Results
### eq-loose
**Source:** `$a == $b`
**ECMA:** == loose equality
**Classification:** ACCIDENTAL-PARSE | Intentional: False
**AST:** AssignmentStatementAst
**Execution:** Parsed as assignment

### eq-strict
**Source:** `$a === $b`
**ECMA:** === strict equality
**Classification:** ACCIDENTAL-PARSE | Intentional: False
**AST:** AssignmentStatementAst
**Execution:** Parsed as assignment

### neq-loose
**Source:** `$a != $b`
**ECMA:** != loose inequality
**Classification:** ACCIDENTAL-PARSE | Intentional: False
**AST:** PipelineAst
**Execution:** Parse errors

### neq-strict
**Source:** `$a !== $b`
**ECMA:** !== strict inequality
**Classification:** HARD | Intentional: False
**AST:** PipelineAst
**Execution:** Parse errors

### logical-not
**Source:** `!$a`
**ECMA:** ! logical not
**Classification:** NATIVE-WITH-SEMANTIC-SHIM | Intentional: True
**AST:** UnaryExpressionAst
**Execution:** Parsed OK

### logical-and
**Source:** `$a && $b`
**ECMA:** && logical and
**Classification:** NATIVE-WITH-SEMANTIC-SHIM | Intentional: True
**AST:** PipelineChainAst
**Execution:** Parsed as pipeline chain

### logical-or
**Source:** `$a || $b`
**ECMA:** || logical or
**Classification:** NATIVE-WITH-SEMANTIC-SHIM | Intentional: True
**AST:** PipelineChainAst
**Execution:** Parsed as pipeline chain

### nullish-coalesce
**Source:** `$a ?? $b`
**ECMA:** ?? nullish coalescing
**Classification:** NATIVE-WITH-SEMANTIC-SHIM | Intentional: True
**AST:** PipelineAst
**Execution:** Parsed OK

### nullish-coalesce-assign
**Source:** `$a ??= $b`
**ECMA:** ??= nullish coalesce assign
**Classification:** NATIVE-WITH-SEMANTIC-SHIM | Intentional: True
**AST:** AssignmentStatementAst
**Execution:** Parsed OK

### ternary
**Source:** `$a ? $b : $c`
**ECMA:** ?: conditional
**Classification:** NATIVE-EQUIVALENT | Intentional: True
**AST:** ConditionalExpressionAst
**Execution:** Parsed OK

### arrow-func
**Source:** `const f = (x) => { "x" }`
**ECMA:** arrow function
**Classification:** COMMAND-VOCABULARY | Intentional: True
**AST:** PipelineAst
**Execution:** Parsed as command invocation

### object-literal-colon
**Source:** `{ x: 1 }`
**ECMA:** object literal {x:1}
**Classification:** ACCIDENTAL-PARSE | Intentional: False
**AST:** PipelineAst
**Execution:** Parsed as scriptblock

### js-array-literal
**Source:** `[ $a, $b ]`
**ECMA:** array literal [a,b]
**Classification:** HARD | Intentional: False
**AST:** PipelineAst
**Execution:** Parse error

### for-of
**Source:** `for (let x of $arr) { }`
**ECMA:** for...of
**Classification:** ACCIDENTAL-PARSE | Intentional: False
**AST:** ForStatementAst
**Execution:** Parsed as ForStatement

### for-in
**Source:** `for (let x in $obj) { }`
**ECMA:** for...in
**Classification:** ACCIDENTAL-PARSE | Intentional: False
**AST:** ForStatementAst
**Execution:** Parsed as ForStatement

### destructuring
**Source:** `$a, $b = $arr`
**ECMA:** destructuring assignment
**Classification:** NATIVE-WITH-SEMANTIC-SHIM | Intentional: True
**AST:** AssignmentStatementAst
**Execution:** Parsed OK

### spread
**Source:** `@($a, @($b))`
**ECMA:** spread/rest
**Classification:** NATIVE-EQUIVALENT | Intentional: True
**AST:** ArrayExpressionAst
**Execution:** Parsed OK

### template-literal
**Source:** ``Hello $name``
**ECMA:** template literal
**Classification:** NATIVE-EQUIVALENT | Intentional: True
**AST:** StringConstantExpressionAst
**Execution:** Parsed OK

### optional-chaining
**Source:** `$obj?.prop`
**ECMA:** optional chaining ?.
**Classification:** ACCIDENTAL-PARSE | Intentional: False
**AST:** PipelineAst
**Execution:** Parsed as variable $obj?

### increment
**Source:** `$a++`
**ECMA:** ++ increment
**Classification:** NATIVE-EQUIVALENT | Intentional: True
**AST:** UnaryExpressionAst
**Execution:** Parsed OK

### decrement
**Source:** `$a--`
**ECMA:** -- decrement
**Classification:** NATIVE-EQUIVALENT | Intentional: True
**AST:** UnaryExpressionAst
**Execution:** Parsed OK

### method-this-property-decrement
**Source:** `$this._activeBuffer.y--`
**ECMA:** member post-decrement
**Classification:** NATIVE-EQUIVALENT | Intentional: True
**AST:** UnaryExpressionAst
**Execution:** Parsed OK

### arrow-function-call-body
**Source:** `params => this.insertChars(params)`
**ECMA:** arrow function call body
**Classification:** COMMAND-VOCABULARY | Intentional: True
**AST:** PipelineAst
**Execution:** Parsed as command

### const-binding
**Source:** `const x = 1`
**ECMA:** const declaration
**Classification:** COMMAND-VOCABULARY | Intentional: True
**AST:** PipelineAst
**Execution:** Parsed as command

### let-binding
**Source:** `let x = 1`
**ECMA:** let declaration
**Classification:** COMMAND-VOCABULARY | Intentional: True
**AST:** PipelineAst
**Execution:** Parsed as command

### await
**Source:** `await $p`
**ECMA:** await expression
**Classification:** COMMAND-VOCABULARY | Intentional: True
**AST:** PipelineAst
**Execution:** Parsed as command

### typeof
**Source:** `typeof $x`
**ECMA:** typeof operator
**Classification:** COMMAND-VOCABULARY | Intentional: True
**AST:** PipelineAst
**Execution:** Parsed as command

### new
**Source:** `new Object()`
**ECMA:** new operator
**Classification:** HARD | Intentional: False
**AST:** PipelineAst
**Execution:** Parse error

### dotted-command
**Source:** `Windows.Canvas.Text`
**ECMA:** dotted command name
**Classification:** COMMAND-VOCABULARY | Intentional: True
**AST:** CommandAst
**Execution:** Parsed as command

### dotted-property
**Source:** `$obj.Windows.Canvas.Text`
**ECMA:** dotted property access
**Classification:** NATIVE-EQUIVALENT | Intentional: True
**AST:** MemberAccessAst
**Execution:** Parsed OK
