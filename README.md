# JS2PS

JS2PS is a conformance and research repository for measuring the grammatical gap between JavaScript source and PowerShell's `System.Management.Automation` parser.

It is not a JavaScript runtime, a Node replacement, or a claim that arbitrary JavaScript already runs as PowerShell. The project preserves original source text where SMA already accepts the intended expression shape and tests small coordinate-based repairs where it does not.

## Approach

```text
JavaScript source
    -> JavaScript syntax tree and exact coordinates
    -> unchanged SMA admission test
    -> bounded reversible source candidates
    -> SMA parse-shape scoring
    -> execution and semantic oracle where available
```

Source parsing and target admission are separate. A construct is not considered supported merely because it parses. Semantic claims require an executable conformance case with an expected result.

There is no supported converter API yet. Early scanner code is retained under `experiments/legacy` because it is known to confuse some indexed access with array literals.

## Current proofs

- reversible registration and removal of an SMA `DynamicKeyword` statement form;
- bounded speculative recovery of PowerShell variable sigils;
- JavaScript-AST-guided identifier repair with exact coordinates;
- greedy hill climbing compared with exhaustive search on bounded expressions;
- a graphics admission matrix over OGL `Box.js`, `Vec3.js`, and `Mat4.js` fixtures.

The graphics matrix currently accepts 422 of 444 measured nested expression nodes unchanged or after identifier repair. This is a statement about that corpus, not a percentage of JavaScript language support.

## Requirements

- PowerShell 7 for SMA parsing and execution tests.
- Esprima.NET 3.0.6 for tests that accept `-AssemblyPath`.
- Node.js and TypeScript 5.9.3 only for the optional TypeScript parser benchmark.

No test downloads dependencies implicitly or searches machine-wide paths for them.

## Verify

Run the complete available gate set:

```powershell
pwsh -NoProfile -File .\tests\Verify.ps1
pwsh -NoProfile -File .\tests\Verify.ps1 -AssemblyPath <path-to-Esprima.dll>
```

Individual tests without an external parser assembly:

```powershell
pwsh -NoProfile -File .\tests\Prove-DynamicKeywordParserExtension.ps1
pwsh -NoProfile -File .\tests\Prove-SpeculativeConvergence.ps1
pwsh -NoProfile -File .\tests\Stage0-Ledger.ps1
```

AST-guided tests require an explicit Esprima assembly:

```powershell
pwsh -NoProfile -File .\tests\Prove-EsprimaIdentifierProjection.ps1 `
    -AssemblyPath <path-to-Esprima.dll>
pwsh -NoProfile -File .\tests\Prove-AstGuidedHillClimb.ps1 `
    -AssemblyPath <path-to-Esprima.dll>
pwsh -NoProfile -File .\tests\Measure-GraphicsAdmission.ps1 `
    -AssemblyPath <path-to-Esprima.dll>
```

## Layout

```text
tests/        repeatable gates and bounded proofs
benchmarks/   parser performance probes
fixtures/     attributed, stable test inputs
docs/         generated matrices and bounded claims
experiments/  exploratory probes that are not release gates
results/      local generated output
tools/        matrix-generation utilities
```

## Non-goals

- wholesale AST regeneration;
- embedding a JavaScript engine as the execution model;
- claiming semantic equivalence from parser acceptance;
- treating `DynamicKeyword` as a general expression-grammar extension;
- moving SMA/IL lowering work into this repository.

SMA and IL emission experiments belong in the separate `SMADirect` project.

## License

JS2PS is available under the MIT License.
