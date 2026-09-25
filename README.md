# JS2PS

JS2PS is a conformance and research repository for measuring the grammatical gap between JavaScript source and PowerShell's `System.Management.Automation` parser.

The goal is for SMA itself to consume and execute JavaScript. It is not a JavaScript
runtime, a Node replacement, or a claim that arbitrary JavaScript already runs.

## Rules

- The JavaScript source is never edited. SMA reads the original text.
- SMA is changed only at runtime, through its own extension points and state, and
  every change is reversible.
- No regular expressions, and no external JavaScript parser.

A construct is not considered supported merely because it parses. Semantic claims
require an executable conformance case with an expected result.

## Current proofs

- reversible registration and removal of an SMA `DynamicKeyword` statement form.

## Requirements

- PowerShell 7 for SMA parsing and execution tests.

No test downloads dependencies implicitly or searches machine-wide paths for them.

## Verify

Run the gate set:

```powershell
pwsh -NoProfile -File .\tests\Verify.ps1
```

The default gate verifies the checked-in OGL files against their pinned local
hash manifest and does not require network access. A separate scheduled and
manually runnable provenance check downloads the immutable npm tarball, verifies
its SHA-512 integrity value, and compares the four retained files byte-for-byte:

```powershell
pwsh -NoProfile -File .\tests\Verify-FixtureProvenance.ps1
```

Individual tests:

```powershell
pwsh -NoProfile -File .\tests\Prove-DynamicKeywordParserExtension.ps1
```

## Layout

```text
tests/        repeatable gates and bounded proofs
fixtures/     pinned, integrity-checked corpus inputs; see fixtures/README.md
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

SMA and IL emission work belongs in the separate `Pwsh` project.

## License

JS2PS is available under the MIT License.
