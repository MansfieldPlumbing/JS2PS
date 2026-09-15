# Graphics Expression Admission

## Scope

This report measures expression syntax found in the current OGL `Box.js`, `Vec3.js`, and `Mat4.js` source files.

It does not measure all JavaScript. It does not establish semantic equivalence. Nested expression nodes are counted independently, so the totals must not be presented as a percentage of JavaScript language support.

## Gate definitions

- **Unchanged**: SMA parses the original node text without parser errors, `CommandAst`, `ErrorExpressionAst`, or `ErrorStatementAst` contamination.
- **IdentifierRepair**: the same gate passes after inserting `$` only at JavaScript identifier-reference and `this` coordinates supplied by Esprima.NET.
- **Irreducible**: neither form passes the syntactic gate. This means another experiment is required; it does not authorize a general lowering stage.

Static property names are not modified. In `player.x`, `player` is a reference candidate and `x` is not. Computed property expressions remain references.

## Current matrix

| JavaScript expression node | Total | Unchanged | Identifier repair | Irreducible |
|---|---:|---:|---:|---:|
| ArrayExpression | 3 | 1 | 0 | 2 |
| AssignmentExpression | 61 | 0 | 61 | 0 |
| BinaryExpression | 98 | 0 | 97 | 1 |
| CallExpression | 69 | 0 | 64 | 5 |
| ConditionalExpression | 2 | 0 | 0 | 2 |
| MemberExpression | 185 | 0 | 185 | 0 |
| NewExpression | 6 | 0 | 0 | 6 |
| ObjectExpression | 8 | 3 | 0 | 5 |
| UnaryExpression | 12 | 7 | 4 | 1 |
| **Total** | **444** | **11** | **411** | **22** |

The syntactic gate accepts 422 of 444 measured nodes. This is approximately 95% of these nested expression nodes, not 95% of JavaScript.

## Remaining syntax clusters

The 22 irreducible nodes are concentrated in:

- six `new` expressions;
- two ternary expressions;
- five object expressions, including the nested `Object.assign` data;
- two empty array expressions;
- one `typeof` expression and its containing binary expression;
- `super(...)` calls;
- calls whose children contain an irreducible expression.

These counts overlap structurally. For example, the `Box.js` ternary contains two `new` expressions, and the `Object.assign` call contains nested object expressions.

## Interpretation

The measured graphics arithmetic, indexing, assignment, and member-access syntax mostly survives. The immediate problem is not expression arithmetic and does not justify translating whole expression trees.

Each remaining syntax family requires a separate rule and proof. A passing syntax gate is only permission to run a semantic conformance experiment. It is not evidence that JavaScript coercion, calls, construction, objects, or mutation already behave identically in PowerShell.

## Reproduction

```powershell
pwsh -NoProfile -File .\tests\Measure-GraphicsAdmission.ps1 `
    -AssemblyPath <path-to-Esprima.dll>
```

The test reads the three graphics source files, classifies their expression nodes, and returns both the summary and individual observations. It downloads nothing and requires the parser assembly path explicitly.

## Next proofs

1. Admit typed-array construction with explicit result type, length, indexing, and mutation checks.
2. Admit ternary expressions with true-branch, false-branch, and single-evaluation checks.
3. Admit object literals with nested-property and source-coordinate checks.
4. Determine the honest PowerShell representation of `super(...)` rather than disguising it as an ordinary call.
5. Admit `typeof` only against an explicit JavaScript compatibility table.
6. Rerun the matrix after each proof and require the irreducible count to decrease by exactly the expected nodes.
