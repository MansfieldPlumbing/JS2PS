# Grammar Matrix

> Generated exploratory output. Parser acceptance and the classifications below are observations, not compatibility guarantees. See the repository README and executable proofs for current claims.


## Environment

- pwsh path: local PowerShell executable (machine-specific path omitted)
- PSVersion: 7.7.0-preview.5
- PSVersionTable: {"PSCompatibleVersions":[{"Major":1,"Minor":0,"Build":-1,"Revision":-1,"MajorRevision":-1,"MinorRevision":-1},{"Major":2,"Minor":0,"Build":-1,"Revision":-1,"MajorRevision":-1,"MinorRevision":-1},{"Major":3,"Minor":0,"Build":-1,"Revision":-1,"MajorRevision":-1,"MinorRevision":-1},{"Major":4,"Minor":0,"Build":-1,"Revision":-1,"MajorRevision":-1,"MinorRevision":-1},{"Major":5,"Minor":0,"Build":-1,"Revision":-1,"MajorRevision":-1,"MinorRevision":-1},{"Major":5,"Minor":1,"Build":-1,"Revision":-1,"MajorRevision":-1,"MinorRevision":-1},{"Major":6,"Minor":0,"Build":-1,"Revision":-1,"MajorRevision":-1,"MinorRevision":-1},{"Major":7,"Minor":0,"Build":-1,"Revision":-1,"MajorRevision":-1,"MinorRevision":-1}],"PSVersion":{"Major":7,"Minor":7,"Patch":0,"PreReleaseLabel":"preview.5","BuildLabel":null},"PSRemotingProtocolVersion":{"Major":2,"Minor":4,"Build":-1,"Revision":-1,"MajorRevision":-1,"MinorRevision":-1},"Platform":"Unix","WSManStackVersion":{"Major":3,"Minor":0,"Build":-1,"Revision":-1,"MajorRevision":-1,"MinorRevision":-1},"PSEdition":"Core","SerializationVersion":{"Major":1,"Minor":1,"Build":0,"Revision":1,"MajorRevision":0,"MinorRevision":1},"OS":"Ubuntu 24.04.4 LTS","GitCommitId":"7.7.0-preview.5"}
- PowerShell source commit: 1481b98f0079f979f658e49a7281024cc754049b
- Generated: 2026-09-25T09:35:21.2820319+00:00
## comment-command-//

**Source:** `function // { "CALLED" } // THIS LOOKS LIKE A COMMENT`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| Function | function |
| Generic | // |
| LCurly | { |
| StringExpandable | "CALLED" |
| RCurly | } |
| Generic | // |
| Identifier | THIS |
| Identifier | LOOKS |
| Identifier | LIKE |
| Identifier | A |
| Identifier | COMMENT |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, FunctionDefinitionAst, PipelineAst

## const-declaration

**Source:** `const Draw = { param($x); "hi" }`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| Identifier | const |
| Identifier | Draw |
| Generic | = |
| LCurly | { |
| Param | param |
| LParen | ( |
| Variable | $x |
| RParen | ) |
| Semi | ; |
| StringExpandable | "hi" |
| RCurly | } |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## let-declaration

**Source:** `let x = 1`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| Identifier | let |
| Identifier | x |
| Generic | = |
| Number | 1 |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## await-identifier

**Source:** `await something`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| Identifier | await |
| Identifier | something |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## typeof-identifier

**Source:** `typeof x`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| Identifier | typeof |
| Identifier | x |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## new-identifier

**Source:** `new Object()`

**Parseable:** False | **Errors:** 1 | **Classification:** HARD

**Tokens:**

| Kind | Text |
|------|------|
| Identifier | new |
| Identifier | Object |
| LParen | ( |
| RParen | ) |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## dotted-command

**Source:** `function Windows.Canvas.Text { } Windows.Canvas.Text`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| Function | function |
| Generic | Windows.Canvas.Text |
| LCurly | { |
| RCurly | } |
| Generic | Windows.Canvas.Text |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, FunctionDefinitionAst, PipelineAst

## dotted-property-access

**Source:** `$obj.Windows.Canvas.Text`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $obj |
| Dot | . |
| Identifier | Windows |
| Dot | . |
| Identifier | Canvas |
| Dot | . |
| Identifier | Text |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## strict-equality

**Source:** `$a === $b`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $a |
| Equals | = |
| Generic | == |
| Variable | $b |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, AssignmentStatementAst

## loose-equality

**Source:** `$a == $b`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $a |
| Equals | = |
| Equals | = |
| Variable | $b |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, AssignmentStatementAst

## strict-inequality

**Source:** `$a !== $b`

**Parseable:** False | **Errors:** 3 | **Classification:** HARD

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $a |
| Exclaim | ! |
| Equals | = |
| Equals | = |
| Variable | $b |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst, AssignmentStatementAst

## logical-and

**Source:** `$a && $b`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $a |
| AndAnd | && |
| Variable | $b |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineChainAst

## logical-or

**Source:** `$a || $b`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $a |
| OrOr | \|\| |
| Variable | $b |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineChainAst

## not-operator

**Source:** `!$a`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| Exclaim | ! |
| Variable | $a |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## increment

**Source:** `$a++`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $a |
| PlusPlus | ++ |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## decrement

**Source:** `$a--`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $a |
| MinusMinus | -- |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## nullish-coalescing

**Source:** `$a ?? $b`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $a |
| QuestionQuestion | ?? |
| Variable | $b |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## nullish-coalescing-assign

**Source:** `$a ??= $b`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $a |
| QuestionQuestionEquals | ??= |
| Variable | $b |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, AssignmentStatementAst

## ternary

**Source:** `$a ? $b : $c`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $a |
| QuestionMark | ? |
| Variable | $b |
| Colon | : |
| Variable | $c |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## arrow-function-like

**Source:** `const f = (x) => { "x" }`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| Identifier | const |
| Identifier | f |
| Generic | = |
| LParen | ( |
| Identifier | x |
| RParen | ) |
| Generic | => |
| LCurly | { |
| StringExpandable | "x" |
| RCurly | } |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## object-literal-colon

**Source:** `{ x: 1 }`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| LCurly | { |
| Generic | x: |
| Number | 1 |
| RCurly | } |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## array-literal

**Source:** `@($a,$b,$c)`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| AtParen | @( |
| Variable | $a |
| Comma | , |
| Variable | $b |
| Comma | , |
| Variable | $c |
| RParen | ) |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## js-array-literal

**Source:** `[ $a, $b ]`

**Parseable:** False | **Errors:** 1 | **Classification:** HARD

**Tokens:**

| Kind | Text |
|------|------|
| LBracket | [ |
| Variable | $a |
| Comma | , |
| Variable | $b |
| Generic | ] |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## for-loop

**Source:** `for ($i=0;$i -lt 10;$i++) { }`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| For | for |
| LParen | ( |
| Variable | $i |
| Equals | = |
| Number | 0 |
| Semi | ; |
| Variable | $i |
| Ilt | -lt |
| Number | 10 |
| Semi | ; |
| Variable | $i |
| PlusPlus | ++ |
| RParen | ) |
| LCurly | { |
| RCurly | } |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, ForStatementAst

## for-of

**Source:** `for (let x of $arr) { }`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| For | for |
| LParen | ( |
| Identifier | let |
| Identifier | x |
| Identifier | of |
| Variable | $arr |
| RParen | ) |
| LCurly | { |
| RCurly | } |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, ForStatementAst

## for-in

**Source:** `for (let x in $obj) { }`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| For | for |
| LParen | ( |
| Identifier | let |
| Identifier | x |
| Generic | in |
| Variable | $obj |
| RParen | ) |
| LCurly | { |
| RCurly | } |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, ForStatementAst

## foreach

**Source:** `foreach ($x in $arr) { }`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| Foreach | foreach |
| LParen | ( |
| Variable | $x |
| In | in |
| Variable | $arr |
| RParen | ) |
| LCurly | { |
| RCurly | } |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, ForEachStatementAst

## arrow-function-call-body

**Source:** `params => this.insertChars(params)`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| Identifier | params |
| Generic | => |
| Generic | this.insertChars |
| LParen | ( |
| Identifier | params |
| RParen | ) |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## arrow-function-multi-call

**Source:** `(data, start, end) => this.print(data, start, end)`

**Parseable:** False | **Errors:** 3 | **Classification:** HARD

**Tokens:**

| Kind | Text |
|------|------|
| LParen | ( |
| Data | data |
| Comma | , |
| Identifier | start |
| Comma | , |
| Generic | end |
| RParen | ) |
| Equals | = |
| Redirection | > |
| Generic | this.print |
| LParen | ( |
| Data | data |
| Comma | , |
| Identifier | start |
| Comma | , |
| Generic | end |
| RParen | ) |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, AssignmentStatementAst

## method-this-property-decrement

**Source:** `$this._activeBuffer.y--`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $this |
| Dot | . |
| Identifier | _activeBuffer |
| Dot | . |
| Identifier | y |
| MinusMinus | -- |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## while-condition-decrement

**Source:** `while ($param--) { }`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| While | while |
| LParen | ( |
| Variable | $param |
| MinusMinus | -- |
| RParen | ) |
| LCurly | { |
| RCurly | } |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, WhileStatementAst

## block-comment-c-style

**Source:** `/*
 * | Col 1 | Col 2 |
 * | ----- | ----- |
 */`

**Parseable:** False | **Errors:** 8 | **Classification:** HARD

**Tokens:**

| Kind | Text |
|------|------|
| Generic | /* |
| NewLine | 
 |
| Multiply | * |
| Pipe | \| |
| Identifier | Col |
| Number | 1 |
| Pipe | \| |
| Identifier | Col |
| Number | 2 |
| Pipe | \| |
| NewLine | 
 |
| Multiply | * |
| Pipe | \| |
| MinusMinus | -- |
| MinusMinus | -- |
| Minus | - |
| Pipe | \| |
| MinusMinus | -- |
| MinusMinus | -- |
| Minus | - |
| Pipe | \| |
| NewLine | 
 |
| Generic | */ |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst, PipelineAst

## destructuring

**Source:** `$a, $b = $arr`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $a |
| Comma | , |
| Variable | $b |
| Equals | = |
| Variable | $arr |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, AssignmentStatementAst

## spread

**Source:** `@($a, @($b))`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| AtParen | @( |
| Variable | $a |
| Comma | , |
| AtParen | @( |
| Variable | $b |
| RParen | ) |
| RParen | ) |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## template-string

**Source:** `"Hello "`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| StringExpandable | "Hello " |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## optional-chaining

**Source:** `$obj?.prop`

**Parseable:** True | **Errors:** 0 | **Classification:** EXPRESSION

**Tokens:**

| Kind | Text |
|------|------|
| Variable | $obj? |
| Dot | . |
| Identifier | prop |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, PipelineAst

## console.log

**Source:** `function console.log { } console.log "hi"`

**Parseable:** True | **Errors:** 0 | **Classification:** COMMAND

**Tokens:**

| Kind | Text |
|------|------|
| Function | function |
| Generic | console.log |
| LCurly | { |
| RCurly | } |
| Generic | console.log |
| StringExpandable | "hi" |
| EndOfInput |  |

**AST Types:** ScriptBlockAst, FunctionDefinitionAst, PipelineAst
